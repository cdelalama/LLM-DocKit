#!/usr/bin/env python3
"""Own a single Claude Stop invocation, including its shell descendants."""
import ctypes
import os
from pathlib import Path
import shutil
import signal
import subprocess
import sys
import time

POLL = 0.05
# Leave time to return a blocking result before the client's twenty-second timeout.
BUDGET = 15.0


def fail(message):
    print("DocKit Stop incomplete: " + message, file=sys.stderr, flush=True)
    return 2


def posix_stop(command, deadline):
    import select

    # The guardian is the leader of a fresh session. Its private pipe closes
    # even if the client kills the launcher without allowing a finally block.
    cancel_read, cancel_write = os.pipe()
    status_read, status_write = os.pipe()
    caller = os.getppid()
    pid = os.fork()
    if pid == 0:
        os.close(cancel_write)
        os.close(status_read)
        try:
            os.setsid()
        except OSError:
            os._exit(2)
        status = 2
        try:
            if not select.select([cancel_read], [], [], 0)[0]:
                worker = subprocess.Popen(command)
                while time.monotonic() < deadline:
                    if select.select([cancel_read], [], [], POLL)[0]:
                        break
                    rc = worker.poll()
                    if rc is not None:
                        status = rc if rc >= 0 else 2
                        break
                else:
                    fail("time budget exceeded")
        except OSError as exc:
            fail(str(exc))
        finally:
            try:
                os.write(status_write, bytes([status]))
            finally:
                # Includes this guardian and any remaining children of the gate.
                os.killpg(0, signal.SIGKILL)
        os._exit(2)

    os.close(status_write)
    os.close(cancel_read)
    try:
        while os.getppid() == caller and time.monotonic() < deadline + 0.5:
            if select.select([status_read], [], [], POLL)[0]:
                message = os.read(status_read, 1)
                if message:
                    return message[0]
                return fail("supervisor exited unexpectedly")
        return fail("caller disappeared or timeout")
    finally:
        os.close(cancel_write)
        os.close(status_read)
        # Reap the guardian. Its PID is reserved until waitpid returns. If it
        # died unexpectedly, its surviving group must also be retired.
        try:
            os.killpg(pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        os.waitpid(pid, 0)


def windows_stop(command, deadline):
    from ctypes import wintypes as wt

    class BasicLimits(ctypes.Structure):
        _fields_ = [
            ("process_time", ctypes.c_int64), ("job_time", ctypes.c_int64),
            ("flags", wt.DWORD), ("min_ws", ctypes.c_size_t), ("max_ws", ctypes.c_size_t),
            ("active_limit", wt.DWORD), ("affinity", ctypes.c_size_t),
            ("priority", wt.DWORD), ("scheduling", wt.DWORD),
        ]

    class Limits(ctypes.Structure):
        _fields_ = [
            ("basic", BasicLimits), ("io_counters", ctypes.c_uint64 * 6),
            ("process_memory", ctypes.c_size_t), ("job_memory", ctypes.c_size_t),
            ("peak_process", ctypes.c_size_t), ("peak_job", ctypes.c_size_t),
        ]

    kernel = ctypes.WinDLL("kernel32", use_last_error=True)

    def function(name, result, *args):
        fn = getattr(kernel, name)
        fn.restype, fn.argtypes = result, args
        return fn

    create = function("CreateJobObjectW", wt.HANDLE, ctypes.c_void_p, wt.LPCWSTR)
    configure = function("SetInformationJobObject", wt.BOOL, wt.HANDLE, ctypes.c_int,
                         ctypes.c_void_p, wt.DWORD)
    assign = function("AssignProcessToJobObject", wt.BOOL, wt.HANDLE, wt.HANDLE)
    current = function("GetCurrentProcess", wt.HANDLE)
    open_process = function("OpenProcess", wt.HANDLE, wt.DWORD, wt.BOOL, wt.DWORD)
    wait = function("WaitForSingleObject", wt.DWORD, wt.HANDLE, wt.DWORD)

    # Git Bash can insert native sh/bash forwarding processes between Claude
    # and Python. Watch each wrapper and the client that owns the outer shell.
    # Query just these parents, using pinned handles rather than scanning PIDs.
    image_name = function("QueryFullProcessImageNameW", wt.BOOL, wt.HANDLE, wt.DWORD,
                          wt.LPWSTR, ctypes.POINTER(wt.DWORD))
    times = function("GetProcessTimes", wt.BOOL, wt.HANDLE,
                     *([ctypes.POINTER(wt.FILETIME)] * 4))
    query = ctypes.WinDLL("ntdll").NtQueryInformationProcess
    query.argtypes = [wt.HANDLE, wt.ULONG, ctypes.c_void_p, wt.ULONG, ctypes.c_void_p]
    query.restype = wt.LONG

    def created(handle):
        fields = [wt.FILETIME() for _ in range(4)]
        if not times(handle, *(ctypes.byref(field) for field in fields)):
            raise ctypes.WinError(ctypes.get_last_error())
        return (fields[0].dwHighDateTime << 32) | fields[0].dwLowDateTime

    callers = []
    pid = os.getppid()
    child_created = created(current())
    for _ in range(12):
        parent = open_process(0x00101000, False, pid)  # SYNCHRONIZE | QUERY_LIMITED_INFORMATION
        if not parent or wait(parent, 0) != 258 or created(parent) > child_created:
            return fail("cannot establish caller identity")
        callers.append(parent)
        name = ctypes.create_unicode_buffer(32768)
        length = wt.DWORD(len(name))
        if not image_name(parent, 0, name, ctypes.byref(length)):
            return fail("cannot identify caller executable")
        if Path(name.value).name.lower() not in {"sh.exe", "bash.exe"}:
            break
        # ProcessBasicInformation ends with the creator PID in its sixth
        # pointer-sized field on both 32- and 64-bit Windows.
        info = (ctypes.c_size_t * 6)()
        if query(parent, 0, ctypes.byref(info), ctypes.sizeof(info), None) < 0:
            return fail("cannot identify shell owner")
        child_created, pid = created(parent), info[5]
    else:
        return fail("shell chain exceeds supported depth")
    job = create(None, None)  # anonymous, non-inheritable handle
    limits = Limits()
    limits.basic.flags = 0x2000  # JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE
    # Enroll this one-shot launcher BEFORE spawning the shell. Children inherit
    # membership, but never the handle. Windows releases it on launcher exit,
    # including TerminateProcess. Closing it here would kill us before return.
    if not job or not configure(job, 9, ctypes.byref(limits), ctypes.sizeof(limits)):
        return fail("cannot configure validation Job Object")
    if not assign(job, current()):
        return fail("cannot enter validation Job Object")
    worker = subprocess.Popen(command)
    while time.monotonic() < deadline:
        if any(wait(handle, 0) != 258 for handle in callers):
            return fail("caller exited")
        rc = worker.poll()
        if rc is not None:
            return rc
        time.sleep(POLL)
    return fail("time budget exceeded")


def main():
    gate = Path(__file__).resolve().with_name("dockit-session-gate.sh")
    shell = shutil.which("sh")
    if os.name == "nt" and not shell:
        git = shutil.which("git")
        if git:
            bundled = Path(git).parent.parent / "bin" / "sh.exe"
            if bundled.is_file():
                shell = str(bundled)
    if not shell or not gate.is_file():
        return fail("shell or session gate unavailable")
    if not sys.executable:
        return fail("Python executable unavailable")
    os.environ["DOCKIT_PYTHON"] = Path(sys.executable).as_posix()
    command = [shell, str(gate), "--guarded-stop-worker", *sys.argv[1:]]
    try:
        deadline = time.monotonic() + BUDGET
        return (windows_stop if os.name == "nt" else posix_stop)(command, deadline)
    except OSError as exc:
        return fail(str(exc))


if __name__ == "__main__":
    sys.exit(main())
