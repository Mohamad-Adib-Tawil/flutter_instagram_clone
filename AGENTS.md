# AGENTS.md — Halalgram

This repository is executed task-by-task from `docs/HALALGRAM_PLAN.md`.
Read §1 (EXECUTOR CONTRACT) of that file before doing anything.

## Loop
1. Open `docs/HALALGRAM_PLAN.md` §7; pick the first unchecked task whose dependencies are done.
2. Read only that task block, the plan sections it cites, and the files it lists.
3. Change only the listed files. Follow the §3.4 templates and §4 tokens exactly.
4. Run VERIFY-STD (§1.3) until green.
5. Tick `[x]`, add a §10 Progress log row, commit with the exact task message.

## MUST
- Use `fvm flutter` / `fvm dart` for every command.
- Localize every string in both `ar.json` and `en.json`.
- Use design tokens and directional layout (RTL-first).
- STOP and report on: repeated failure, API mismatch, ambiguity, unlisted file/package, OWNER-ACTION.

## MUST NOT
- Add/remove/upgrade packages outside plan §5.
- Use the Supabase `service_role` key or any secret; commit or print `env/dev.json`, `env/prod.json`, or `android/key.properties`.
- Edit migrations 001–003 or any pushed migration; run `supabase db reset`.
- Import `supabase_flutter` outside data/di/core network/bootstrap; import `data/` from presentation/domain.
- Use Instagram branding or add music features.
- Refactor, rename, or reformat code outside the task.

## Stack
Flutter 3.47.2 (fvm), Riverpod 3 + generator, go_router, freezed, fpdart, easy_localization (ar default, en), Supabase (cloud). Android + iOS only.
