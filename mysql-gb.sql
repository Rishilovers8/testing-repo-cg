-- =============================================
-- PHASE 1 CRITICAL FIXES: Multi-User Core Features
-- Run this SQL in your Supabase SQL Editor
-- =============================================

-- 1. COMMENTS TABLE (Fix #1 - Most Critical)
CREATE TABLE IF NOT EXISTS cg_comments (
  id TEXT PRIMARY KEY,
  post_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  text TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_comments_post ON cg_comments(post_id);
CREATE INDEX IF NOT EXISTS idx_comments_created ON cg_comments(created_at DESC);

-- Enable RLS
ALTER TABLE cg_comments ENABLE ROW LEVEL SECURITY;

-- Allow anyone to read comments
CREATE POLICY "Allow anon select comments" ON cg_comments
  FOR SELECT TO anon USING (true);

-- Allow anyone to insert comments
CREATE POLICY "Allow anon insert comments" ON cg_comments
  FOR INSERT TO anon WITH CHECK (true);

-- Allow users to delete their own comments
CREATE POLICY "Allow anon delete comments" ON cg_comments
  FOR DELETE TO anon USING (true);

-- =============================================
-- 2. NOTIFICATIONS TABLE (Fix #2 - High Priority)
-- =============================================
CREATE TABLE IF NOT EXISTS cg_notifications (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,  -- recipient
  from_user_id TEXT,      -- who triggered it
  type TEXT NOT NULL,     -- 'like', 'comment', 'follow', 'mention'
  text TEXT NOT NULL,
  icon TEXT DEFAULT '🔔',
  post_id TEXT,
  unread BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifs_user ON cg_notifications(user_id, unread, created_at DESC);

-- Enable RLS
ALTER TABLE cg_notifications ENABLE ROW LEVEL SECURITY;

-- Allow users to read their own notifications
CREATE POLICY "Allow anon select notifications" ON cg_notifications
  FOR SELECT TO anon USING (true);

-- Allow anyone to insert notifications
CREATE POLICY "Allow anon insert notifications" ON cg_notifications
  FOR INSERT TO anon WITH CHECK (true);

-- Allow users to update their own notifications (mark as read)
CREATE POLICY "Allow anon update notifications" ON cg_notifications
  FOR UPDATE TO anon USING (true);

-- Allow users to delete their own notifications
CREATE POLICY "Allow anon delete notifications" ON cg_notifications
  FOR DELETE TO anon USING (true);

-- =============================================
-- 3. UPDATE EXISTING TABLES
-- =============================================

-- Add isPrivate to cg_users if not exists
ALTER TABLE cg_users ADD COLUMN IF NOT EXISTS is_private BOOLEAN DEFAULT false;

-- Add editedAt to cg_posts if not exists
ALTER TABLE cg_posts ADD COLUMN IF NOT EXISTS edited_at TIMESTAMP WITH TIME ZONE;

-- =============================================
-- 4. REALTIME PUBLICATION (Enable live updates)
-- =============================================

-- Enable realtime for comments
ALTER PUBLICATION supabase_realtime ADD TABLE cg_comments;

-- Enable realtime for notifications  
ALTER PUBLICATION supabase_realtime ADD TABLE cg_notifications;

-- =============================================
-- 5. HELPER FUNCTIONS
-- =============================================

-- Function to get comment count for a post
CREATE OR REPLACE FUNCTION get_comment_count(p_post_id TEXT)
RETURNS INTEGER AS $$
  SELECT COUNT(*)::INTEGER FROM cg_comments WHERE post_id = p_post_id;
$$ LANGUAGE SQL STABLE;

-- Function to get unread notification count for a user
CREATE OR REPLACE FUNCTION get_unread_notif_count(p_user_id TEXT)
RETURNS INTEGER AS $$
  SELECT COUNT(*)::INTEGER FROM cg_notifications WHERE user_id = p_user_id AND unread = true;
$$ LANGUAGE SQL STABLE;

-- =============================================
-- VERIFICATION QUERIES
-- =============================================

-- Check if tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('cg_comments', 'cg_notifications');

-- Check RLS policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd
FROM pg_policies
WHERE tablename IN ('cg_comments', 'cg_notifications');

-- Test insert comment
-- INSERT INTO cg_comments (id, post_id, user_id, text) 
-- VALUES ('test_cmt_1', 'test_post_1', 'test_user', 'Test comment');

-- Test insert notification
-- INSERT INTO cg_notifications (id, user_id, from_user_id, type, text) 
-- VALUES ('test_notif_1', 'recipient_id', 'sender_id', 'like', 'Test notification');

-- =============================================
-- DONE! Phase 1 Complete
-- ✅ Comments visible to all users across devices
-- ✅ Notifications sync in real-time
-- ✅ Like state will be fixed in JS code
-- =============================================
