# Supabase Schema Design Decisions

## 1. Username Normalization Strategy

**Decision:** Use `citext` extension for case-insensitive username storage with unique constraint.

**Rationale:**
- Instagram-style usernames are case-insensitive for discovery (`@john` == `@John`)
- `citext` provides native case-insensitive comparison without application-level normalization
- Unique constraint on `citext` column enforces case-insensitive uniqueness at database level
- Prefix search uses `username ILIKE 'prefix%'` which works natively with `citext`

**Implementation:**
```sql
CREATE EXTENSION IF NOT EXISTS citext;
```
```sql
username CITEXT NOT NULL UNIQUE
```

**Search Query:**
```sql
SELECT * FROM profiles WHERE username ILIKE $1 || '%' LIMIT 20;
```

## 2. Profile Bootstrap Strategy

**Decision:** Use a PostgreSQL trigger on `auth.users` to create profile row, with username derived from email prefix + random suffix if conflict.

**Rationale:**
- Guarantees profile exists for every authenticated user
- Atomic with auth user creation (no partial accounts)
- Username uniqueness handled by database constraint + trigger retry logic
- Flutter only updates profile fields (bio, avatar) after signup

**Trigger Logic:**
1. Extract username candidate from email prefix (before @)
2. Sanitize: lowercase, alphanumeric + underscore only, 3-30 chars
3. If conflict, append `_` + 4-char random suffix
4. Insert profile with generated username

**Flutter Signup Flow:**
1. `supabase.auth.signUp(email, password)` → returns session/user
2. Trigger creates profile automatically
3. Flutter fetches profile, updates bio/avatar if provided
4. If avatar upload fails → profile remains with default avatar, user can retry

## 3. Storage Visibility

**Decision:** Public read, owner write for all buckets. Store object paths in database, generate public URLs in Flutter.

**Buckets:**
- `avatars` → `{user_id}/{uuid}.{ext}`
- `post-images` → `{user_id}/{post_id}/{uuid}.{ext}`
- `reel-videos` → `{user_id}/{reel_id}/{uuid}.{ext}`

**Rationale:**
- Matches current Firebase behavior (public download URLs)
- Simpler client implementation
- Object paths in DB allow future migration to signed URLs if needed
- RLS on storage.objects enforces ownership

## 4. ID Generation

**Decision:** Database-generated UUIDs using `gen_random_uuid()` (pgcrypto).

**Rationale:**
- Native, no extension needed beyond pgcrypto (built into Supabase)
- Firebase already uses UUID v4 for posts/reels — compatible
- No client-side ID generation needed

**Note:** Do NOT create `uuid-ossp` extension — `gen_random_uuid()` from pgcrypto is sufficient.

## 5. Index Strategy

| Table | Index | Justification |
|-------|-------|---------------|
| `posts` | `(user_id, created_at DESC, id DESC)` | User's posts grid + pagination cursor |
| `posts` | `(created_at DESC, id DESC)` | Global feed (home/explore) pagination |
| `reels` | `(created_at DESC, id DESC)` | Reels feed pagination |
| `post_likes` | PK `(post_id, user_id)` | Like existence check, unlike, post like count |
| `post_likes` | `(user_id)` | User's liked posts (if needed later) |
| `reel_likes` | PK `(reel_id, user_id)` | Same as post_likes |
| `reel_likes` | `(user_id)` | User's liked reels |
| `post_comments` | `(post_id, created_at)` | Comments pagination per post |
| `reel_comments` | `(reel_id, created_at)` | Comments pagination per reel |
| `follows` | PK `(follower_id, following_id)` | Follow existence, unfollow |
| `follows` | `(follower_id)` | Following list + count |
| `follows` | `(following_id)` | Followers list + count |
| `profiles` | `username` (citext unique) | Username search + uniqueness |

**No redundant indexes:** PK indexes cover leading columns. Reverse lookups need separate indexes.

## 6. Delete Behavior

| Parent | Child | ON DELETE |
|--------|-------|-----------|
| `profiles` | `posts` | CASCADE |
| `profiles` | `reels` | CASCADE |
| `profiles` | `post_likes` | CASCADE |
| `profiles` | `reel_likes` | CASCADE |
| `profiles` | `post_comments` | CASCADE |
| `profiles` | `reel_comments` | CASCADE |
| `profiles` | `follows` (both FKs) | CASCADE |
| `posts` | `post_likes` | CASCADE |
| `posts` | `post_comments` | CASCADE |
| `reels` | `reel_likes` | CASCADE |
| `reels` | `reel_comments` | CASCADE |

**Rationale:** Deleting a user removes all their content. Deleting a post/reel removes likes/comments. No orphaned social data.

## 7. RLS Strategy

**Principle:** Default deny. Explicit policies per operation per table.

**Profile:**
- SELECT: public (for profile display, search)
- INSERT: `auth.uid() = id` (trigger creates, but policy allows)
- UPDATE: `auth.uid() = id` WITH CHECK `auth.uid() = id`

**Posts/Reels:**
- SELECT: public
- INSERT: `auth.uid() = user_id` WITH CHECK `auth.uid() = user_id`
- UPDATE: `auth.uid() = user_id` WITH CHECK `auth.uid() = user_id` (prevents user_id change)
- DELETE: `auth.uid() = user_id`

**Likes:**
- SELECT: public
- INSERT: `auth.uid() = user_id` WITH CHECK `auth.uid() = user_id`
- DELETE: `auth.uid() = user_id`

**Comments:**
- SELECT: public
- INSERT: `auth.uid() = user_id` WITH CHECK `auth.uid() = user_id`
- UPDATE: `auth.uid() = user_id` WITH CHECK `auth.uid() = user_id`
- DELETE: `auth.uid() = user_id` OR `post.user_id = auth.uid()` (post owner can moderate)

**Follows:**
- SELECT: public
- INSERT: `auth.uid() = follower_id` WITH CHECK `auth.uid() = follower_id`
- DELETE: `auth.uid() = follower_id`

**Storage:**
- `avatars`: owner path prefix match
- `post-images`: owner path prefix match
- `reel-videos`: owner path prefix match

## 8. Timestamp Strategy

All tables: `created_at TIMESTAMPTZ NOT NULL DEFAULT now()`

Mutable tables (profiles, posts, reels, comments): `updated_at TIMESTAMPTZ NOT NULL DEFAULT now()` + trigger

## 9. Username Validation Rules

| Rule | Value |
|------|-------|
| Min length | 3 |
| Max length | 30 |
| Allowed chars | `a-z`, `0-9`, `_` (underscore) |
| Case | Stored as citext (case-insensitive), displayed as-entered |
| Trimming | Leading/trailing whitespace removed |
| Uniqueness | Database-enforced (citext unique constraint) |
| Reserved | Block list in trigger (admin, api, www, etc.) |

## 10. File Validation Rules (Application Layer)

| Type | Max Size | MIME Types | Extensions |
|------|----------|------------|------------|
| Avatar | 5 MB | image/jpeg, image/png, image/webp | .jpg, .jpeg, .png, .webp |
| Post Image | 10 MB | image/jpeg, image/png, image/webp | .jpg, .jpeg, .png, .webp |
| Reel Video | 100 MB | video/mp4, video/quicktime | .mp4, .mov |

**Note:** Storage policies don't enforce MIME/size — Flutter validates before upload.

## 11. Pagination Cursor Design

**Cursor Format:** `created_at|id` (base64 encoded JSON)

**Query Pattern:**
```sql
SELECT * FROM posts
WHERE (created_at, id) < ($cursor_created_at, $cursor_id)
ORDER BY created_at DESC, id DESC
LIMIT $limit;
```

**Rationale:** Composite cursor handles duplicate timestamps. Keyset pagination avoids OFFSET performance issues.

## 12. Auth Migration Risk

**Status:** REQUIRES VERIFICATION BEFORE PRODUCTION DATA MIGRATION

**Current Users:** Unknown if production data exists. Firebase password hashes (scrypt) not directly portable to Supabase (bcrypt). Options:
1. Users reset passwords on first Supabase login
2. Supabase Firebase Auth Import (requires Blaze plan, hash migration)
3. Hybrid: keep Firebase Auth, migrate only data (not recommended)

**Decision:** Do not destroy Firebase Auth. Phase C will implement Supabase Auth alongside Firebase for new users. Production migration strategy decided later.

## 13. Realtime

**Phase B:** Do NOT enable realtime on any tables. Prepare schema only.
**Phase I:** Evaluate per-feature:
- Comments: likely enable
- Feed: likely NOT enable (polling sufficient)
- Likes: optimistic UI, no realtime needed
- Follows: polling sufficient

## 14. Deviations from Phase A Proposal

| Phase A Proposal | Phase B Decision | Reason |
|------------------|------------------|--------|
| `username TEXT UNIQUE` | `username CITEXT UNIQUE` | Case-insensitive uniqueness required |
| `uuid-ossp` extension | pgcrypto `gen_random_uuid()` | Native, no extra extension |
| Auto profile trigger simple | Trigger with conflict resolution | Username conflicts must be handled |
| Single comments table | Separate `post_comments`, `reel_comments` | Real FKs, simpler RLS |
| `likes_count` columns | No counters initially | Correctness first, add later if needed |
| Realtime in foundation | No realtime in foundation | Phase I decision |
| Remove Firebase deps in B | Keep Firebase deps | Coexistence required |

## 15. Remaining Risks

1. **Username trigger race condition** — Two simultaneous signups with same email prefix could conflict. Mitigation: trigger uses `INSERT ... ON CONFLICT` with retry loop (max 3 attempts).

2. **Storage policy path validation** — Malicious client could attempt path traversal. Mitigation: Policies use `position(name in object_path) = 1` pattern matching.

3. **Feed performance** — Global feed query on large dataset. Mitigation: Composite index + keyset pagination. Monitor query plans.

4. **Avatar upload failure** — User has profile but no avatar. Mitigation: Default avatar URL in app, retry UI.

5. **Comment moderation** — Post owner can delete any comment on their post. RLS policy allows this via `post.user_id = auth.uid()`. Verify this works with join.

6. **Search performance** — `ILIKE 'prefix%'` on citext uses btree index. For substring search (`%term%`), would need trigram. Current UX: prefix search only.

---

*Document updated during Phase B.1 — Final Schema Design*