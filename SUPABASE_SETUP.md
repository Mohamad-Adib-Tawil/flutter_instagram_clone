# Supabase Local Development Setup

## Prerequisites

- Flutter SDK 3.16+ (current: 3.41.9)
- Dart SDK 3.2+ (current: 3.11.5)
- Supabase CLI 2.x (`brew install supabase/tap/supabase`)

## 1. Create Supabase Project

### Option A: Local Development (Recommended)

```bash
# Start local Supabase stack (requires Docker)
supabase start

# Output will show:
#   API URL: http://127.0.0.1:54321
#   DB URL: postgresql://postgres:postgres@127.0.0.1:54322/postgres
#   Studio URL: http://127.0.0.1:54323
#   anon key: <local-anon-key>
#   service_role key: <local-service-role-key> (NEVER use in Flutter)
```

### Option B: Cloud Project

1. Go to https://supabase.com/dashboard
2. Create new project
3. Note: Project URL and anon key from Settings → API

## 2. Apply Migrations

```bash
# For local development (after supabase start)
supabase db reset

# For linked cloud project
supabase link --project-ref <your-project-ref>
supabase db push
```

Migrations are in `supabase/migrations/`:
- `001_initial_schema.sql` — Tables, indexes, triggers
- `002_rls_policies.sql` — Row Level Security
- `003_storage_buckets.sql` — Storage buckets + policies

## 3. Configure Flutter App

### Development (Local)

```bash
flutter run \
  --dart-define=SUPABASE_URL=http://127.0.0.1:54321 \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<your-local-publishable-key>
```

### Production Build

```bash
flutter build apk \
  --dart-define=SUPABASE_URL=https://<your-project>.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<your-production-publishable-key>
```

### VS Code Launch Configuration

Add to `.vscode/launch.json`:

```json
{
  "configurations": [
    {
      "name": "Flutter (Supabase Local)",
      "request": "launch",
      "type": "dart",
      "toolArgs": [
        "--dart-define=SUPABASE_URL=http://127.0.0.1:54321",
        "--dart-define=SUPABASE_PUBLISHABLE_KEY=<your-local-publishable-key>"
      ]
    }
  ]
}
```

## 4. Verify Setup

Run the app and check console for:
```
✅ Supabase initialized successfully
```

If you see:
```
⚠️ Supabase initialization skipped: Supabase configuration missing...
```
The `--dart-define` values are not being passed correctly.

## 5. Supabase Studio

Local: http://127.0.0.1:54323
Cloud: https://supabase.com/dashboard/project/<project-ref>

Use Studio to:
- Inspect table data
- Test RLS policies (Authentication → Policies)
- Manage storage buckets
- View logs

## 6. Database Management

### Reset Local Database

```bash
supabase db reset
```

### Generate Migration from Schema Changes

```bash
supabase db diff -f migration_name
```

### Apply Migration to Cloud

```bash
supabase db push
```

### Pull Schema from Cloud

```bash
supabase db pull
```

## 7. Storage Testing

Upload test files via Studio or:

```bash
# Using Supabase CLI (requires service_role key - local only)
supabase storage cp local-file.jpg avatars/test-user/uuid.jpg
```

## 8. Environment Variables Reference

| Variable | Required | Description |
|----------|----------|-------------|
| `SUPABASE_URL` | Yes | Project API URL (https://xxx.supabase.co or http://127.0.0.1:54321) |
| `SUPABASE_PUBLISHABLE_KEY` | Yes | Public publishable key (safe for client, formerly anon key) |

**Never use in Flutter:**
- `service_role` key
- Database password
- JWT secret
- Any other privileged credentials

## 9. Troubleshooting

### "relation does not exist"
Run migrations: `supabase db reset` or `supabase db push`

### "permission denied for table"
Check RLS policies in `002_rls_policies.sql` and verify user is authenticated

### "bucket not found"
Run `003_storage_buckets.sql` migration

### "JWT expired" / auth errors
Local Supabase uses short-lived tokens. Re-login or check auth configuration.

### Flutter build fails with "supabase_flutter not found"
Run `flutter pub get` after adding dependency

## 10. Migration Workflow

When modifying schema:

1. Edit SQL in `supabase/migrations/` (create new numbered file)
2. Test locally: `supabase db reset`
3. Verify in Studio
4. Commit migration files
5. Deploy to cloud: `supabase db push`

**Never** modify production schema via Dashboard without creating a migration file.