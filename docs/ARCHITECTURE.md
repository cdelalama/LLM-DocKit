# <PROJECT_NAME> Architecture (Optional)

> Version: 0.1.0-draft
> Last Updated: <YYYY-MM-DD>
> Status: Design | Implementing | Stable
> Authors: <Names>

## Overview

Describe the system at a high level:
- What it is
- Who uses it
- Where it runs
- What the primary inputs/outputs are

## Non-negotiables

- <Invariant / constraint>
- <Invariant / constraint>

## High-Level Architecture

Layers/components (example):
1. Core domain logic (shared)
2. Runners/adapters (CLI/API/worker)
3. UI/clients

## Key Flows

### Flow 1: <Name>
1. <Step>
2. <Step>

### Flow 2: <Name>
1. <Step>
2. <Step>

## Contracts

Define the stable contracts that other components depend on:
- APIs (OpenAPI / gRPC / etc.)
- Event schemas (JSON events, message bus payloads)
- File formats (artifact schemas, CSV conventions)

Link to `docs/operations/API_CONTRACT.md` if applicable.

## Storage & Data Layout

Where data lives and why:
- On-disk layout: <paths>
- Database tables: <if any>
- Retention/cleanup policy: <if any>

## Security & Privacy Notes

- AuthN/AuthZ: <if any>
- Secrets management: <where>
- Data sensitivity: <PII considerations>

## Roadmap

Phases/milestones in order:
1. <Phase 0> - <goal>
2. <Phase 1> - <goal>

