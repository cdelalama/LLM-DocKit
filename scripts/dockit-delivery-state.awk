# Fixed-width append journal replay. Unknown events and impossible transitions fail.
BEGIN { FS="|"; limit_a=attempts; limit_r=reviews; pending=0; count_a=0; count_r=0; blockers=0; approved="-"; integration="-"; decl="-"; integration_time=0; integration_artifact="-"; last_time=0 }
function bad() { invalid=1; exit 1 }
function integer(v) { return v ~ /^(0|[1-9][0-9]*)$/ && length(v)<=10 }
{
 if (NF!=10 || $1!=NR || !integer($1) || !integer($2) || $2<last_time) bad()
 last_time=$2
 for(i=3;i<=10;i++) if ($i !~ /^[A-Za-z0-9_.:\/@+-]+$/) bad()
 if(NR==1 && $3!="init") bad()
 if($3=="init") { if(NR!=1 || !integer($5) || !integer($6) || $5<1 || $6<1 || $5>10 || $6>10) bad(); decl=$4; limit_a=$5; limit_r=$6 }
 else if($3=="evidence") { if(!integer($6) || ($7!="pass" && $7!="fail")) bad() }
 else if($3=="review") {
   if(!integer($6) || ($5!="approved" && $5!="changes") || ($5=="approved" && $6!=0)) bad()
   count_r++; if(count_r>limit_r) bad(); blockers=$6; approved=($5=="approved" ? $4 : "-")
 }
 else if($3=="integration") { integration=$4; integration_time=$2; integration_artifact=$6 }
 else if($3=="begin") { if(pending || count_a>=limit_a) bad(); count_a++; pending=$1; current_cause=$5; pending_failed=0 }
 else if($3=="finish") {
   if(!pending || !integer($4) || $4!=pending || ($5!="success" && $5!="failure") || ($6!="yes" && $6!="no") || ($5=="success" && $6!="yes") || pending_failed) bad()
   if($5=="failure") failed[current_cause]=1
   if($6=="yes") pending=0; else pending_failed=1
 }
 else if($3=="recovered") { if(!pending || $4!=pending) bad(); failed[current_cause]=1; pending=0 }
 else if($3=="reassess") {
   if(pending || !integer($5) || !integer($6) || $5<count_a || $6<count_r || $5>count_a+10 || $6>count_r+10) bad()
   decl=$4; limit_a=$5; limit_r=$6; for(f in failed) delete failed[f]
 }
 else bad()
}
END {
 if(invalid || NR==0) exit 1
 print "declaration|" decl
 print "attempts|" count_a
 print "reviews|" count_r
 print "attempt_limit|" limit_a
 print "review_limit|" limit_r
 print "pending|" pending
 for(f in failed) print "failed_cause|" f
 print "blockers|" blockers
 print "approved|" approved
 print "integration|" integration
 print "integration_time|" integration_time
 print "integration_artifact|" integration_artifact
}
