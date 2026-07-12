# CareerGram v2.5 🚀

A professional social networking platform for job seekers, recruiters, and content creators — designed as a single-file Progressive Web App (PWA).

## 📁 Project Structure

```
careergram/
├── index.html                    ← Main app (ONLY file you need)
├── supabase-schema-correct.sql   ← Database schema (matches app code)
├── FIXES-COMPLETED.md            ← Recent bug fixes log
├── README.md                     ← This file
├── config.yaml                   ← App configuration
├── config-loader.js              ← Config loader (optional)
└── app.js                        ← Empty stub (can delete)
```

## 🎯 Core Features

### User Types
- **Job Seekers** — Create profiles, post updates, apply to jobs
- **Recruiters** — Post job openings, browse candidates
- **Content Creators** — Share career advice videos/reels

### Features
- ✅ Posts with images, likes, comments, shares
- ✅ Stories (24h expiry, emoji/poll/job types)
- ✅ Video reels with categories & difficulty levels
- ✅ Real-time chat (1-on-1 and groups)
- ✅ WebRTC video/audio calls (mutual followers only)
- ✅ Connections (follow/unfollow system)
- ✅ Notifications (likes, comments, follows)
- ✅ Search (users by name/role/skills)
- ✅ Profile management (work experience, education, certifications)
- ✅ Light/Dark mode toggle
- ✅ Offline-first (localStorage fallback)
- ✅ AI Assistant (Rishi AI for career advice)

## 🚀 Quick Start

### Option 1: Standalone (No Database)
1. Open `index.html` in a browser
2. Everything works via localStorage
3. No setup needed!

### Option 2: With Supabase (Multi-device sync)

#### Step 1: Create Supabase Project
1. Go to [supabase.com](https://supabase.com)
2. Create new project
3. Copy your project URL and anon key

#### Step 2: Run SQL Schema
1. Go to Supabase SQL Editor
2. Copy contents of `supabase-schema-correct.sql`
3. Paste and run (creates all tables)

#### Step 3: Configure App
Edit `index.html` around line 1387:

```javascript
const SUPABASE_URL_DEFAULT='https://your-project.supabase.co';
const SUPABASE_KEY_DEFAULT='your-anon-key-here';
```

**Alternative:** Use localStorage override (no code edit):
```javascript
localStorage.setItem('cg_sb_url_override', 'https://your-project.supabase.co');
localStorage.setItem('cg_sb_key_override', 'your-anon-key-here');
```

#### Step 4: Open App
- Open `index.html` in browser
- App will auto-detect Supabase and sync data

## 🔐 Security Status

### ✅ Fixed Issues (Latest)
1. **Notification field mismatch** — `unread` field now consistent
2. **Crash-proofing** — All `save.*` functions wrapped in try/catch
3. **XSS protection** — User names escaped in posts, comments, chat, profile, search

### ⚠️ Known Limitations
1. **Password storage** — Currently plaintext (not hashed)
2. **Some XSS gaps** — Video titles, story captions, group names not yet escaped
3. **No global error handler** — Uncaught errors can crash app
4. **Large images** — No automatic compression for profile pictures

### 🛡️ Production Recommendations
- [ ] Implement password hashing or use Supabase Auth
- [ ] Enable Row Level Security (RLS) in Supabase
- [ ] Add CSP headers
- [ ] Use Supabase Storage for images/videos (not base64 in DB)
- [ ] Add rate limiting for API calls
- [ ] Escape remaining user-generated content

## 🗄️ Database Schema Notes

The SQL schema (`supabase-schema-correct.sql`) is **verified to match actual app code**:

### Key Differences from Generic Schemas
- ✅ `cg_notifications.unread` (not `read`)
- ✅ `cg_videos.video_data` (not `video_url`)
- ✅ `cg_connections` has `follower_id`/`following_id` (not `connected_user_id`)
- ✅ Posts have `liked_by` JSONB array for tracking who liked
- ✅ Stories use Unix timestamps (`posted_at`, `expires_at`)

### Tables Created
- `cg_users` — User accounts & profiles
- `cg_posts` — Feed posts (with likes, views, shares)
- `cg_comments` — Post comments
- `cg_notifications` — User notifications
- `cg_stories` — 24-hour stories
- `cg_videos` — Career reels/videos
- `cg_messages` — Chat messages
- `cg_connections` — Follow relationships
- `cg_calls` — WebRTC call signaling

## 🎨 Architecture

### Data Flow
```
┌─────────────────┐
│   localStorage  │ ← Primary storage (always works)
│   (offline)     │
└────────┬────────┘
         │
         ├─ Sync on startup
         │
         ▼
┌─────────────────┐
│   Supabase DB   │ ← Cloud sync (optional)
│   (realtime)    │
└─────────────────┘
```

### Key Design Patterns
- **Offline-first:** App works without internet
- **Progressive enhancement:** Supabase adds sync, not required
- **Single file:** All code in one HTML file for simplicity
- **No build step:** Runs directly in browser
- **PWA ready:** Can be installed as desktop/mobile app

## 🔧 Configuration

### Changing Supabase Credentials
**Method 1:** Edit `index.html` constants (permanent)
```javascript
const SUPABASE_URL_DEFAULT='https://newproject.supabase.co';
const SUPABASE_KEY_DEFAULT='new-key';
```

**Method 2:** Use localStorage (temporary, survives page reload)
```javascript
localStorage.setItem('cg_sb_url_override', 'https://newproject.supabase.co');
localStorage.setItem('cg_sb_key_override', 'new-key');
```

**Method 3:** Use `config.yaml` + `config-loader.js` (advanced)

### Clearing All Data
```javascript
localStorage.clear(); // Then refresh page
```

## 🐛 Troubleshooting

### "Supabase connection failed"
- Check URL/key are correct
- Verify tables exist (run SQL schema)
- Check browser console for errors

### "Posts not showing"
- Check `localStorage.getItem('cg_posts')`
- If empty, create a test post
- Check for JS errors in console

### "Can't make video call"
- Calls require mutual follow relationship
- Both users must be online
- Requires Supabase for signaling
- Browser must grant camera/mic permissions

### "localStorage quota exceeded"
- App saves images as base64 (very large)
- Clear old data: Settings → Delete All My Data
- Or use Supabase Storage for images

## 📝 Development Notes

### Adding a New Feature
1. All code is in `<script>` tags in `index.html`
2. State is stored in global variables or localStorage
3. UI is updated via `innerHTML` or `textContent`
4. For DB sync, add Supabase calls in try/catch blocks

### Code Organization (in index.html)
- Lines 1-1390: CSS & HTML structure
- Lines 1391-1475: Save/load utilities
- Lines 1476-2700: Supabase functions
- Lines 2701-5600: Feature implementations
- Event listeners throughout

### Testing
- Open browser DevTools → Console
- Check for errors
- Use `localStorage` commands to inspect data
- Test with Supabase URL invalid to verify offline mode

## 📊 Stats
- **Single file:** ~5800 lines
- **No dependencies:** Pure vanilla JS + Supabase CDN
- **Mobile responsive:** Works on any screen size
- **PWA capable:** Installable on desktop/mobile

## 🤝 Contributing
This is a single-file app, so modifications are straightforward:
1. Edit `index.html`
2. Test in browser
3. Update SQL schema if you change DB structure

## 📄 License
Open source — use freely

## 🔄 Recent Changes (see FIXES-COMPLETED.md)
- Fixed notification unread/read field mismatch
- Added try/catch to all save functions
- Escaped user names to prevent XSS
- Cleaned up inconsistent documentation files
