-- supabase/migrations/003_storage_buckets.sql
-- Storage buckets and policies for media uploads
-- Run order: 3rd (after 001_initial_schema.sql, 002_rls_policies.sql)

-- ============================================================
-- CREATE BUCKETS
-- ============================================================

-- Avatars bucket: profile pictures
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'avatars',
    'avatars',
    true,                              -- Public read access
    5242880,                           -- 5 MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Post images bucket: feed post images
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'post-images',
    'post-images',
    true,
    10485760,                          -- 10 MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Reel videos bucket: reels videos
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'reel-videos',
    'reel-videos',
    true,
    104857600,                         -- 100 MB limit
    ARRAY['video/mp4', 'video/quicktime']
)
ON CONFLICT (id) DO UPDATE SET
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- ============================================================
-- STORAGE POLICIES
-- ============================================================

-- Enable RLS on storage.objects (required for policies to work)
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------------
-- AVATARS BUCKET POLICIES
-- Path convention: avatars/{user_id}/{uuid}.{ext}
-- ------------------------------------------------------------------

-- Public read: anyone can view avatars
CREATE POLICY avatars_public_read
ON storage.objects
FOR SELECT
USING (bucket_id = 'avatars');

-- Insert: authenticated user can upload to their own folder
-- Object name must start with their user_id/
CREATE POLICY avatars_insert_own
ON storage.objects
FOR INSERT
WITH CHECK (
    bucket_id = 'avatars'
    AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Update: user can update their own avatar (replace)
CREATE POLICY avatars_update_own
ON storage.objects
FOR UPDATE
USING (
    bucket_id = 'avatars'
    AND auth.uid()::text = (storage.foldername(name))[1]
)
WITH CHECK (
    bucket_id = 'avatars'
    AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Delete: user can delete their own avatar
CREATE POLICY avatars_delete_own
ON storage.objects
FOR DELETE
USING (
    bucket_id = 'avatars'
    AND auth.uid()::text = (storage.foldername(name))[1]
);

-- ------------------------------------------------------------------
-- POST IMAGES BUCKET POLICIES
-- Path convention: post-images/{user_id}/{post_id}/{uuid}.{ext}
-- ------------------------------------------------------------------

CREATE POLICY post_images_public_read
ON storage.objects
FOR SELECT
USING (bucket_id = 'post-images');

CREATE POLICY post_images_insert_own
ON storage.objects
FOR INSERT
WITH CHECK (
    bucket_id = 'post-images'
    AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY post_images_update_own
ON storage.objects
FOR UPDATE
USING (
    bucket_id = 'post-images'
    AND auth.uid()::text = (storage.foldername(name))[1]
)
WITH CHECK (
    bucket_id = 'post-images'
    AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY post_images_delete_own
ON storage.objects
FOR DELETE
USING (
    bucket_id = 'post-images'
    AND auth.uid()::text = (storage.foldername(name))[1]
);

-- ------------------------------------------------------------------
-- REEL VIDEOS BUCKET POLICIES
-- Path convention: reel-videos/{user_id}/{reel_id}/{uuid}.{ext}
-- ------------------------------------------------------------------

CREATE POLICY reel_videos_public_read
ON storage.objects
FOR SELECT
USING (bucket_id = 'reel-videos');

CREATE POLICY reel_videos_insert_own
ON storage.objects
FOR INSERT
WITH CHECK (
    bucket_id = 'reel-videos'
    AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY reel_videos_update_own
ON storage.objects
FOR UPDATE
USING (
    bucket_id = 'reel-videos'
    AND auth.uid()::text = (storage.foldername(name))[1]
)
WITH CHECK (
    bucket_id = 'reel-videos'
    AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY reel_videos_delete_own
ON storage.objects
FOR DELETE
USING (
    bucket_id = 'reel-videos'
    AND auth.uid()::text = (storage.foldername(name))[1]
);

-- ============================================================
-- NOTES ON STORAGE POLICIES
-- ============================================================
--
-- Path validation:
-- - storage.foldername(name) returns array of path segments
-- - [1] accesses the first segment (user_id)
-- - This ensures user can only write to their own namespace
-- - Malicious path like "other_user/../evil.jpg" is prevented because
--   foldername() normalizes the path
--
-- MIME type validation:
-- - Bucket-level allowed_mime_types provides first line of defense
-- - Flutter should also validate client-side before upload
-- - MIME types can be spoofed; bucket restriction is not absolute security
--
-- File size limits:
-- - Bucket-level file_size_limit enforced by Supabase
-- - Flutter should validate client-side for better UX
--
-- Public access:
-- - All buckets are public (public = true)
-- - This matches current Firebase behavior (public download URLs)
-- - If private access needed later, change bucket to private and use signed URLs
-- - Object paths stored in DB allow URL generation without hardcoding
--
-- Post/Reel ownership validation:
-- - Current policies only validate user_id prefix
-- - This allows user to upload to any post_id/reel_id under their namespace
-- - For stricter validation (user owns the specific post), would need
--   a custom policy function that checks posts/reels table
-- - Deferred to Phase H if needed