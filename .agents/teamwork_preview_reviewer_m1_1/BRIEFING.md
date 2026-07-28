# BRIEFING — 2026-07-27T19:31:00Z

## Mission
Review lib/core/ (identity, addressing, messaging) against requirements R1, R3, R5.

## 🔒 My Identity
- Archetype: reviewer / critic
- Roles: Core Domain Layer Reviewer 1
- Working directory: /home/tommy/messaging/.agents/teamwork_preview_reviewer_m1_1
- Original parent: 438fe325-b883-448b-9ab2-a9cd5b797584
- Milestone: M1
- Instance: 1 of 1

## 🔒 Key Constraints
- Review-only — do NOT modify implementation code

## Current Parent
- Conversation ID: 438fe325-b883-448b-9ab2-a9cd5b797584
- Updated: 2026-07-27T19:31:00Z

## Review Scope
- **Files to review**: lib/core/ (identity, addressing, messaging), test/core/
- **Interface contracts**: /home/tommy/messaging/.agents/ORIGINAL_REQUEST.md
- **Review criteria**: correctness, style, conformance, integrity violations, stress testing

## Review Checklist
- **Items reviewed**: LocalIdentity, OfflineIdentityService, Base58, ContactAddress, MessageEnvelope, Conversation, E2eCryptoService, README files, barrel exports, test suites
- **Verdict**: REQUEST_CHANGES
- **Unverified claims**: none (all claims verified by running tests and static analysis)

## Attack Surface
- **Hypotheses tested**: 
  - Legacy `lib/core/p2p/` directory deletion check -> FAILED (p2p_node_service.dart still present)
  - `dart analyze lib/core test/core` clean output -> FAILED (1 warning in boundary_concurrency_test.dart:319:13, exit code 2)
  - Timing attack on MAC comparison in `PlaceholderE2eCryptoService` -> FAILED (non-constant-time loop throws on first mismatch)
  - Exported symbol pollution in `addressing.dart` -> FAILED (top-level `min` exported)
- **Vulnerabilities found**: Non-constant time MAC comparison, top-level symbol collision, unremoved legacy P2P file, static analysis warning.
- **Untested angles**: Transport layer adapters (separate review scope)

## Key Decisions Made
- Issued verdict: REQUEST_CHANGES due to critical leftover file `lib/core/p2p/p2p_node_service.dart`, static analysis warning, and security/design findings.

## Artifact Index
- /home/tommy/messaging/.agents/teamwork_preview_reviewer_m1_1/handoff.md — Review Handoff Report
