-- supabase/migrations/002_rls_policies.sql
-- Row Level Security policies for all application tables
-- Run order: 2nd (after 001_initial_schema.sql)

-- ============================================================
-- ENABLE RLS ON ALL TABLES
-- ============================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reels ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.post_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reel_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.post_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reel_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- PROFILES POLICIES
-- ============================================================

-- Public read: anyone can view profiles (for profile pages, search, post attribution)
CREATE POLICY profiles_select_all
ON public.profiles
FOR SELECT
USING (true);

-- Insert: trigger creates profile, but policy allows authenticated user to create their own
-- WITH CHECK ensures the row being inserted has id = auth.uid()
CREATE POLICY profiles_insert_own
ON public.profiles
FOR INSERT
WITH CHECK (auth.uid() = id);

-- Update: user can only update their own profile
-- USING: can only target rows where id = auth.uid()
-- WITH CHECK: resulting row must still have id = auth.uid() (prevents id change)
CREATE POLICY profiles_update_own
ON public.profiles
FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- No DELETE policy: users cannot delete their profile (cascades from auth.users delete)

-- ============================================================
-- POSTS POLICIES
-- ============================================================

-- Public read: feed, explore, profile grids
CREATE POLICY posts_select_all
ON public.posts
FOR SELECT
USING (true);

-- Insert: user creates post with their own user_id
CREATE POLICY posts_insert_own
ON public.posts
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Update: user can update their own posts
-- USING + WITH CHECK both enforce user_id = auth.uid() (prevents ownership transfer)
CREATE POLICY posts_update_own
ON public.posts
FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Delete: user can delete their own posts
CREATE POLICY posts_delete_own
ON public.posts
FOR DELETE
USING (auth.uid() = user_id);

-- ============================================================
-- REELS POLICIES (identical to posts)
-- ============================================================

CREATE POLICY reels_select_all
ON public.reels
FOR SELECT
USING (true);

CREATE POLICY reels_insert_own
ON public.reels
FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY reels_update_own
ON public.reels
FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY reels_delete_own
ON public.reels
FOR DELETE
USING (auth.uid() = user_id);

-- ============================================================
-- POST LIKES POLICIES
-- ============================================================

-- Public read: like counts, like status
CREATE POLICY post_likes_select_all
ON public.post_likes
FOR SELECT
USING (true);

-- Insert: user likes as themselves
-- WITH CHECK ensures user_id = auth.uid()
CREATE POLICY post_likes_insert_own
ON public.post_likes
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Delete: user unlikes their own like
CREATE POLICY post_likes_delete_own
ON public.post_likes
FOR DELETE
USING (auth.uid() = user_id);

-- No UPDATE policy: likes are immutable (delete + re-insert if needed)

-- ============================================================
-- REEL LIKES POLICIES (identical to post_likes)
-- ============================================================

CREATE POLICY reel_likes_select_all
ON public.reel_likes
FOR SELECT
USING (true);

CREATE POLICY reel_likes_insert_own
ON public.reel_likes
FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY reel_likes_delete_own
ON public.reel_likes
FOR DELETE
USING (auth.uid() = user_id);

-- ============================================================
-- POST COMMENTS POLICIES
-- ============================================================

-- Public read: comments displayed on posts
CREATE POLICY post_comments_select_all
ON public.post_comments
FOR SELECT
USING (true);

-- Insert: user comments as themselves
CREATE POLICY post_comments_insert_own
ON public.post_comments
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Update: user can edit their own comment
CREATE POLICY post_comments_update_own
ON public.post_comments
FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Delete: user can delete their own comment
-- OR post owner can delete any comment on their post (moderation)
CREATE POLICY post_comments_delete_own_or_post_owner
ON public.post_comments
FOR DELETE
USING (
    auth.uid() = user_id
    OR EXISTS (
        SELECT 1 FROM public.posts p
        WHERE p.id = post_comments.post_id
        AND p.user_id = auth.uid()
    )
);

-- ============================================================
-- REEL COMMENTS POLICIES (identical to post_comments)
-- ============================================================

CREATE POLICY reel_comments_select_all
ON public.reel_comments
FOR SELECT
USING (true);

CREATE POLICY reel_comments_insert_own
ON public.reel_comments
FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY reel_comments_update_own
ON public.reel_comments
FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY reel_comments_delete_own_or_reel_owner
ON public.reel_comments
FOR DELETE
USING (
    auth.uid() = user_id
    OR EXISTS (
        SELECT 1 FROM public.reels r
        WHERE r.id = reel_comments.reel_id
        AND r.user_id = auth.uid()
    )
);

-- ============================================================
-- FOLLOWS POLICIES
-- ============================================================

-- Public read: follower/following lists, counts, isFollowing checks
CREATE POLICY follows_select_all
ON public.follows
FOR SELECT
USING (true);

-- Insert: user follows someone (follower_id = auth.uid())
-- WITH CHECK enforces follower_id = auth.uid() (cannot follow on behalf of another)
CREATE POLICY follows_insert_own
ON public.follows
FOR INSERT
WITH CHECK (auth.uid() = follower_id);

-- Delete: user unfollows (follower_id = auth.uid())
CREATE POLICY follows_delete_own
ON public.follows
FOR DELETE
USING (auth.uid() = follower_id);

-- No UPDATE: follow relationships are immutable (delete + re-insert)

-- ============================================================
-- POLICY VALIDATION QUERIES (for manual testing)
-- ============================================================
-- Run these as different authenticated users to verify policies work:
--
-- Test: A can update A profile
-- UPDATE public.profiles SET bio = 'test' WHERE id = 'A_uid'; -- Should succeed
--
-- Test: A cannot update B profile
-- UPDATE public.profiles SET bio = 'hack' WHERE id = 'B_uid'; -- Should fail (0 rows)
--
-- Test: A can create post as A
-- INSERT INTO public.posts (user_id, image_path) VALUES ('A_uid', 'path'); -- Succeed
--
-- Test: A cannot create post as B
-- INSERT INTO public.posts (user_id, image_path) VALUES ('B_uid', 'path'); -- Fail
--
-- Test: A cannot update post user_id to B
-- UPDATE public.posts SET user_id = 'B_uid' WHERE id = 'post_id'; -- Fail (WITH CHECK)
--
-- Test: A can like as A
-- INSERT INTO public.post_likes (post_id, user_id) VALUES ('post', 'A_uid'); -- Succeed
--
-- Test: A cannot insert like as B
-- INSERT INTO public.post_likes (post_id, user_id) VALUES ('post', 'B_uid'); -- Fail
--
-- Test: A can follow B as A
-- INSERT INTO public.follows (follower_id, following_id) VALUES ('A_uid', 'B_uid'); -- Succeed
--
-- Test: A cannot create follow as B
-- INSERT INTO public.follows (follower_id, following_id) VALUES ('B_uid', 'C_uid'); -- Fail
--
-- Test: A cannot self-follow
-- INSERT INTO public.follows (follower_id, following_id) VALUES ('A_uid', 'A_uid'); -- Fail (CHECK)
--
-- Test: Post owner can delete comment by C on A's post
-- DELETE FROM public.post_comments WHERE id = 'comment_by_C' AND post_id = 'post_by_A'; -- Succeed if A