-- =====================================================
-- CareerGram v2.5 - Correct Supabase Schema
-- =====================================================
-- This schema matches the ACTUAL app code in index.html
-- Generated based on actual sb.from() calls in the application
-- =====================================================

-- USERS TABLE
CREATE TABLE IF NOT EXISTS cg_users (
  user_id TEXT PRIMARY KEY,
  password TEXT NOT NULL, -- WARNING: Currently stored as plaintext in app
  name TEXT NOT NULL,
  email TEXT,
  account_type TEXT DEFAULT 'jobseeker', -- 'jobseeker', 'recruiter', 'creator'
  role TEXT,
  company TEXT,
  city TEXT,
  experience TEXT,
  avatar TEXT DEFAULT '👤',
  color TEXT DEFAULT '#6366f1',
  bio TEXT,
  skills JSONB DEFAULT '[]'::jsonb,
  online BOOLEAN DEFAULT true,
  connections INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- POSTS TABLE
CREATE TABLE IF NOT EXISTS cg_posts (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES cg_users(user_id) ON DELETE CASCADE,
  content TEXT,
  image TEXT, -- URL only, no base64 (app filters those out)
  time TEXT NOT NULL,
  likes INTEGER DEFAULT 0,
  liked_by JSONB DEFAULT '[]'::jsonb, -- Array of user_ids
  views INTEGER DEFAULT 0,
  shares INTEGER DEFAULT 0,
  is_job BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_posts_user ON cg_posts(user_id);
CREATE INDEX IF NOT EXISTS idx_posts_created ON cg_posts(created_at DESC);

-- COMMENTS TABLE
CREATE TABLE IF NOT EXISTS cg_comments (
  id TEXT PRIMARY KEY,
  post_id TEXT NOT NULL REFERENCES cg_posts(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL REFERENCES cg_users(user_id) ON DELETE CASCADE,
  text TEXT NOT NULL,
  time TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_comments_post ON cg_comments(post_id);

-- NOTIFICATIONS TABLE
CREATE TABLE IF NOT EXISTS cg_notifications (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES cg_users(user_id) ON DELETE CASCADE,
  from_user_id TEXT NOT NULL REFERENCES cg_users(user_id) ON DELETE CASCADE,
  type TEXT NOT NULL, -- 'like', 'comment', 'follow', 'mention', 'share'
  text TEXT NOT NULL,
  icon TEXT DEFAULT '🔔',
  post_id TEXT, -- Can be NULL for non-post notifications (like follow)
  unread BOOLEAN DEFAULT true, -- NOTE: 'unread' not 'read' (matches app code)
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user ON cg_notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON cg_notifications(user_id, unread);

-- STORIES TABLE
CREATE TABLE IF NOT EXISTS cg_stories (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES cg_users(user_id) ON DELETE CASCADE,
  type TEXT DEFAULT 'emoji', -- 'emoji', 'poll', 'job', etc.
  data TEXT, -- Job details JSON or poll options
  emoji TEXT DEFAULT '📸',
  caption TEXT,
  posted_at BIGINT NOT NULL, -- Unix timestamp
  expires_at BIGINT NOT NULL, -- Unix timestamp
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_stories_user ON cg_stories(user_id);
CREATE INDEX IF NOT EXISTS idx_stories_expires ON cg_stories(expires_at);

-- VIDEOS/REELS TABLE
CREATE TABLE IF NOT EXISTS cg_videos (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES cg_users(user_id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  duration TEXT DEFAULT '0:00',
  views TEXT DEFAULT '0',
  category TEXT, -- 'career', 'interview', 'coding', 'design', 'resume'
  level TEXT, -- 'beginner', 'intermediate', 'advanced'
  thumbnail TEXT,
  video_data TEXT, -- NOTE: 'video_data' not 'video_url' (matches app code)
  storage_path TEXT, -- For Supabase Storage reference
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_videos_user ON cg_videos(user_id);
CREATE INDEX IF NOT EXISTS idx_videos_category ON cg_videos(category);

-- MESSAGES TABLE (for chat)
CREATE TABLE IF NOT EXISTS cg_messages (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  room_id TEXT NOT NULL, -- Format: 'user1_user2' (sorted alphabetically)
  from_user TEXT NOT NULL REFERENCES cg_users(user_id) ON DELETE CASCADE,
  text TEXT,
  image TEXT,
  time TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_messages_room ON cg_messages(room_id);
CREATE INDEX IF NOT EXISTS idx_messages_created ON cg_messages(created_at);

-- CONNECTIONS TABLE (follower relationships)
CREATE TABLE IF NOT EXISTS cg_connections (
  id BIGSERIAL PRIMARY KEY,
  follower_id TEXT NOT NULL REFERENCES cg_users(user_id) ON DELETE CASCADE,
  following_id TEXT NOT NULL REFERENCES cg_users(user_id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(follower_id, following_id)
);

CREATE INDEX IF NOT EXISTS idx_connections_follower ON cg_connections(follower_id);
CREATE INDEX IF NOT EXISTS idx_connections_following ON cg_connections(following_id);

-- CALLS TABLE (WebRTC signaling)
CREATE TABLE IF NOT EXISTS cg_calls (
  id TEXT PRIMARY KEY,
  caller_id TEXT NOT NULL REFERENCES cg_users(user_id) ON DELETE CASCADE,
  callee_id TEXT NOT NULL REFERENCES cg_users(user_id) ON DELETE CASCADE,
  call_type TEXT NOT NULL, -- 'audio' or 'video'
  status TEXT DEFAULT 'ringing', -- 'ringing', 'active', 'ended', 'declined', 'missed'
  offer JSONB, -- WebRTC offer SDP
  answer JSONB, -- WebRTC answer SDP
  ice_candidates JSONB DEFAULT '[]'::jsonb, -- Array of ICE candidates
  started_at TIMESTAMPTZ DEFAULT NOW(),
  ended_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_calls_callee ON cg_calls(callee_id, status);
CREATE INDEX IF NOT EXISTS idx_calls_started ON cg_calls(started_at);

-- GROUPS TABLE (chat groups/channels)
CREATE TABLE IF NOT EXISTS cg_groups (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  icon TEXT DEFAULT '👥',
  type TEXT DEFAULT 'group', -- 'group' or 'channel'
  creator_id TEXT NOT NULL REFERENCES cg_users(user_id) ON DELETE CASCADE,
  members JSONB DEFAULT '[]'::jsonb, -- Array of user_ids
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_groups_creator ON cg_groups(creator_id);
CREATE INDEX IF NOT EXISTS idx_groups_type ON cg_groups(type);

-- =====================================================
-- ROW LEVEL SECURITY (RLS) - OPTIONAL BUT RECOMMENDED
-- =====================================================
-- Enable RLS for production security
-- ALTER TABLE cg_users ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE cg_posts ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE cg_comments ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE cg_notifications ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE cg_stories ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE cg_videos ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE cg_messages ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE cg_connections ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE cg_calls ENABLE ROW LEVEL SECURITY;

-- Example RLS policies (uncomment and customize as needed):
-- CREATE POLICY "Users can read all profiles" ON cg_users FOR SELECT USING (true);
-- CREATE POLICY "Users can update own profile" ON cg_users FOR UPDATE USING (user_id = current_setting('app.current_user_id'));
-- CREATE POLICY "Anyone can read posts" ON cg_posts FOR SELECT USING (true);
-- CREATE POLICY "Users can insert own posts" ON cg_posts FOR INSERT WITH CHECK (user_id = current_setting('app.current_user_id'));

-- =====================================================
-- REALTIME SUBSCRIPTIONS (OPTIONAL)
-- =====================================================
-- Enable realtime for live updates
-- ALTER PUBLICATION supabase_realtime ADD TABLE cg_messages;
-- ALTER PUBLICATION supabase_realtime ADD TABLE cg_notifications;
-- ALTER PUBLICATION supabase_realtime ADD TABLE cg_calls;
-- ALTER PUBLICATION supabase_realtime ADD TABLE cg_posts;

-- =====================================================
-- NOTES
-- =====================================================
-- 1. PASSWORD SECURITY WARNING:
--    App currently stores passwords as plaintext.
--    For production, implement client-side hashing or use Supabase Auth.
--
-- 2. STORAGE FOR LARGE FILES:
--    App avoids sending base64 images to DB (too large).
--    For production, use Supabase Storage for images/videos.
--
-- 3. COLUMN NAME MATCHES:
--    - 'video_data' (not 'video_url')
--    - 'unread' boolean (not 'read')
--    - 'follower_id' / 'following_id' (matches app exactly)
--
-- 4. CLEANUP:
--    Consider adding a cron job to delete expired stories:
--    DELETE FROM cg_stories WHERE expires_at < EXTRACT(EPOCH FROM NOW()) * 1000;
