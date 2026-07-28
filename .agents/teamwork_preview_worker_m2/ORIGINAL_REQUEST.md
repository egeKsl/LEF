## 2026-07-22T14:52:04Z

<USER_REQUEST>
You are Worker M2 (`teamwork_preview_worker`). Your task is to implement Milestone 2: Redesign Auth UI & BLoC for P2P Identity (Requirement R2) in `/home/tommy/messaging`.
Your working directory is `/home/tommy/messaging/.agents/teamwork_preview_worker_m2`. Create your working directory and your own `progress.md` file.

MANDATORY INTEGRITY WARNING: DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A Forensic Auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

Context & Reference:
Read the investigation findings in `/home/tommy/messaging/.agents/teamwork_preview_explorer_phase1_2/handoff.md` and `/home/tommy/messaging/.agents/orchestrator/PROJECT.md`.

Specific Tasks for R2:
1. Update `lib/features/auth/presentation/screens/auth_screen.dart`:
   - Remove `CustomServerTextField` (Target Net-Node selection is obsolete in P2P).
   - Simplify header to `P2P MATRIX // LOCAL IDENTITY GENERATOR`.
   - Update `IDENTITY_LOGIN` tab title to `LOCAL IDENTITY` (allows generating or switching local cryptographic identities).
   - Update `GENERATE_KEY` tab title to `CREATE P2P KEYPAIR` (generates local Ed25519 device key pair).
   - Connect tab action buttons to invoke local keypair / identity generation via `AuthBloc`.
2. Update `lib/features/auth/presentation/bloc/auth_bloc.dart`:
   - Update event handlers to handle local key pair / identity generation (`GenerateKeyPairRequested` or `GenerateLocalIdentityRequested`) calling `_authService.generateLocalIdentity(username: event.username)` instead of remote HTTP password authentication.
3. Hardening fixes:
   - In `MatrixAuthService._normalizeUrl`, ensure exact domain prefix logic (`url == '127.0.0.1'` or `url.startsWith('127.0.0.1:')` or `url == 'localhost'` or `url.startsWith('localhost:')`) so external domain spoofing (e.g. `127.0.0.1.attacker.com`) is prevented, and support `[::1]`.
4. Verification:
   - Run `flutter analyze` from `/home/tommy/messaging` and ensure clean analysis output.
   - Run tests using `flutter test` and document results.

Deliverables: Write your implementation report to `/home/tommy/messaging/.agents/teamwork_preview_worker_m2/handoff.md` including exact modified files, changes made, `flutter analyze` output, and test results. Notify the orchestrator via send_message tool when complete.
</USER_REQUEST>
