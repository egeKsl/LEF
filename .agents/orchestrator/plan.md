# Orchestration Plan — SimpleX Flutter Messaging Rebuild

## Strategy
Following Project Pattern with Dual Track E2E strategy.
We decompose the project into 6 sequential milestones (M0 through M5).
As a DISPATCH-ONLY orchestrator, all investigation, implementation, review, testing, and auditing work will be delegated to subagents (`teamwork_preview_explorer`, `teamwork_preview_worker`, `teamwork_preview_reviewer`, `teamwork_preview_challenger`, `teamwork_preview_auditor`).

## Milestones Summary
- **M0: Exploration & Architecture Map**: Inspect existing `lib/` codebase, dependencies in `pubspec.yaml`, mock/matrix/p2p usages.
- **M1: Core Domain Layer**: Build `lib/core/identity/`, `lib/core/addressing/`, `lib/core/messaging/`. Pure domain interfaces and models.
- **M2: Transport & Storage Data Layer**: Build `lib/core/transport/` (`TransportAdapter`, `RelayTransportAdapter`) and `lib/core/storage/` (local SQLite encrypted storage).
- **M3: Legacy Path & Matrix Removal**: Remove Matrix SDK from `pubspec.yaml`, delete `p2p_node_service.dart`, `matrix_auth_service.dart`, mock files, and clean up references.
- **M4: UI & Feature Layer Integration**: Update UI screens and BLoCs to use Domain/Data layers only. New Chat modal (address fingerprint), Relay Settings screen.
- **M5: E2E Verification, Build & Forensic Audit**: Perform static analysis (`flutter analyze`), build check (`flutter build apk --debug`), correctness verification, and forensic integrity audit.
