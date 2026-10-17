-- supabase/migrations/001_initial_schema.sql
-- Initial schema for Instagram clone migration
-- Run order: 1st

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";    -- gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS "citext";      -- Case-insensitive text for usernames

-- ============================================================
-- PROFILES
-- Extends auth.users with application-specific profile data
-- ============================================================
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username CITEXT NOT NULL UNIQUE,
    bio TEXT NOT NULL DEFAULT '',
    avatar_path TEXT,                          -- Storage object path, nullable
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.profiles IS 'User profiles extending auth.users. One profile per authenticated user.';
COMMENT ON COLUMN public.profiles.avatar_path IS 'Supabase Storage object path in avatars bucket. Null = default avatar.';

-- Index for username search (prefix match via ILIKE uses this btree index)
-- Unique constraint already creates index, but explicit for documentation
-- CREATE INDEX idx_profiles_username ON public.profiles(username); -- Redundant with UNIQUE

-- ============================================================
-- POSTS
-- User posts with image, caption, location
-- ============================================================
CREATE TABLE public.posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    image_path TEXT NOT NULL,                  -- Storage object path in post-images bucket
    caption TEXT,
    location TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.posts IS 'User posts (images with caption/location).';

-- Composite index for user's posts grid + pagination
CREATE INDEX idx_posts_user_created ON public.posts(user_id, created_at DESC, id DESC);
-- Composite index for global feed pagination (home/explore)
CREATE INDEX idx_posts_created ON public.posts(created_at DESC, id DESC);

-- ============================================================
-- REELS
-- User reels (videos with caption)
-- ============================================================
CREATE TABLE public.reels (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    video_path TEXT NOT NULL,                  -- Storage object path in reel-videos bucket
    caption TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.reels IS 'User reels (short videos with caption).';

-- Composite index for reels feed pagination
CREATE INDEX idx_reels_created ON public.reels(created_at DESC, id DESC);
-- User's reels grid (if needed later)
CREATE INDEX idx_reels_user_created ON public.reels(user_id, created_at DESC, id DESC);

-- ============================================================
-- POST LIKES
-- Junction table for post likes (idempotent via PK)
-- ============================================================
CREATE TABLE public.post_likes (
    post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (post_id, user_id)
);

COMMENT ON TABLE public.post_likes IS 'Post likes. PK ensures idempotency (one like per user per post).';

-- Reverse lookup: posts liked by a user (for "your likes" feature if added)
CREATE INDEX idx_post_likes_user ON public.post_likes(user_id);

-- ============================================================
-- REEL LIKES
-- Junction table for reel likes
-- ============================================================
CREATE TABLE public.reel_likes (
    reel_id UUID NOT NULL REFERENCES public.reels(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (reel_id, user_id)
);

COMMENT ON TABLE public.reel_likes IS 'Reel likes. PK ensures idempotency.';

CREATE INDEX idx_reel_likes_user ON public.reel_likes(user_id);

-- ============================================================
-- POST COMMENTS
-- Comments on posts
-- ============================================================
CREATE TABLE public.post_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.post_comments IS 'Comments on posts.';

-- Pagination index for comments on a post
CREATE INDEX idx_post_comments_post_created ON public.post_comments(post_id, created_at);

-- ============================================================
-- REEL COMMENTS
-- Comments on reels
-- ============================================================
CREATE TABLE public.reel_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reel_id UUID NOT NULL REFERENCES public.reels(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.reel_comments IS 'Comments on reels.';

CREATE INDEX idx_reel_comments_reel_created ON public.reel_comments(reel_id, created_at);

-- ============================================================
-- FOLLOWS
-- User follow relationships
-- ============================================================
CREATE TABLE public.follows (
    follower_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    following_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (follower_id, following_id),
    CONSTRAINT no_self_follow CHECK (follower_id <> following_id)
);

COMMENT ON TABLE public.follows IS 'Follow relationships. PK ensures one follow per pair. CHECK prevents self-follow.';

-- Follower's following list + count
CREATE INDEX idx_follows_follower ON public.follows(follower_id);
-- Following's followers list + count
CREATE INDEX idx_follows_following ON public.follows(following_id);

-- ============================================================
-- UPDATED_AT TRIGGER FUNCTION
-- ============================================================
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.update_updated_at_column() IS 'Trigger function to maintain updated_at timestamp on row modification.';

-- Attach trigger to tables with updated_at
CREATE TRIGGER trigger_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER trigger_posts_updated_at
    BEFORE UPDATE ON public.posts
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER trigger_reels_updated_at
    BEFORE UPDATE ON public.reels
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER trigger_post_comments_updated_at
    BEFORE UPDATE ON public.post_comments
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER trigger_reel_comments_updated_at
    BEFORE UPDATE ON public.reel_comments
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================
-- PROFILE BOOTSTRAP TRIGGER
-- Creates profile row automatically on auth.users insert
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    username_base TEXT;
    username_candidate CITEXT;
    attempt INT := 0;
    max_attempts CONSTANT INT := 5;
    suffix TEXT;
BEGIN
    -- Extract username from email prefix (before @)
    username_base := split_part(NEW.email, '@', 1);

    -- Sanitize: lowercase, alphanumeric + underscore only
    username_base := regexp_replace(lower(username_base), '[^a-z0-9_]', '', 'g');

    -- Enforce length constraints
    IF length(username_base) < 3 THEN
        username_base := 'user';
    ELSIF length(username_base) > 30 THEN
        username_base := substr(username_base, 1, 30);
    END IF;

    -- Reserved usernames that cannot be claimed
    IF username_base IN ('admin', 'administrator', 'root', 'api', 'www', 'mail', 'email',
                         'support', 'help', 'info', 'about', 'blog', 'app', 'web',
                         'mobile', 'settings', 'config', 'system', 'superuser') THEN
        username_base := 'user';
    END IF;

    -- Try to insert with unique username, retry with suffix on conflict
    WHILE attempt < max_attempts LOOP
        IF attempt = 0 THEN
            username_candidate := username_base;
        ELSE
            suffix := substr(encode(gen_random_bytes(3), 'hex'), 1, 6);
            username_candidate := username_base || '_' || suffix;
        END IF;

        BEGIN
            INSERT INTO public.profiles (id, username)
            VALUES (NEW.id, username_candidate);
            EXIT; -- Success, exit loop
        EXCEPTION WHEN unique_violation THEN
            attempt := attempt + 1;
            CONTINUE; -- Retry with suffix
        END;
    END LOOP;

    IF attempt >= max_attempts THEN
        RAISE EXCEPTION 'Failed to generate unique username after % attempts', max_attempts;
    END IF;

    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.handle_new_user() IS
'Trigger on auth.users INSERT. Creates a profile row with unique username derived from email.';

-- Attach trigger to auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- GRANT USAGE ON SEQUENCES (not needed for UUIDs, but explicit)
-- ============================================================
-- No sequences used (UUID PKs), so no grants needed.