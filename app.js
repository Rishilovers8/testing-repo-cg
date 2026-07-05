// ═══════════════════════════════════════════════════════════════════
// CAREERGRAM - Professional Social Network
// Version: 2.0.0
// ═══════════════════════════════════════════════════════════════════

// ── SUPABASE CONFIGURATION ──
let sb = null;
let SUPABASE_URL = '';
let SUPABASE_KEY = '';

// ── GLOBAL STATE ──
let ME = null;
let registeredUsers = [];
let posts = [];
let stories = [];
let notifications = [];
let connections = [];
let commentCache = {}; // Separate cache for comments (post-keyed)
let postInteractions = {}; // User-keyed interactions

// ── HELPER FUNCTIONS ──
function safeJSON(key, fallback) {
  try {
    const v = localStorage.getItem(key);
    return v ? JSON.parse(v) : fallback;
  } catch (e) {
    console.warn('Bad localStorage key:', key);
    localStorage.removeItem(key);
    return fallback;
  }
}

// XSS Protection: Escape HTML in user-generated content
function escapeHTML(text) {
  if (!text) return '';
  return String(text)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#x27;');
}

// Time ago formatter
function timeAgo(date) {
  const seconds = Math.floor((new Date() - new Date(date)) / 1000);
  const intervals = {
    year: 31536000,
    month: 2592000,
    week: 604800,
    day: 86400,
    hour: 3600,
    minute: 60
  };
  
  for (let [unit, secondsInUnit] of Object.entries(intervals)) {
    const interval = Math.floor(seconds / secondsInUnit);
    if (interval >= 1) {
      return interval === 1 ? `1 ${unit} ago` : `${interval} ${unit}s ago`;
    }
  }
  return 'Just now';
}

// Generate unique ID
function generateId() {
  return Date.now().toString(36) + Math.random().toString(36).substr(2);
}

// ── SUPABASE INITIALIZATION ──
async function initSupabase(url, key) {
  if (!url || !key) {
    console.warn('Supabase credentials not provided');
    window._sbKeyValid = false;
    return false;
  }
  
  try {
    SUPABASE_URL = url;
    SUPABASE_KEY = key;
    sb = supabase.createClient(url, key);
    
    // Test connection
    const { data, error } = await sb.from('cg_users').select('count').limit(1);
    if (error) {
      console.error('Supabase connection error:', error);
      window._sbKeyValid = false;
      return false;
    }
    
    window._sbKeyValid = true;
    window._sbConnected = true;
    console.log('✅ Supabase connected');
    return true;
  } catch (e) {
    console.error('Supabase init exception:', e);
    window._sbKeyValid = false;
    return false;
  }
}

// ── SUPABASE CRUD OPERATIONS ──

// Users
async function sbLoadUsers() {
  if (!window._sbKeyValid) return;
  try {
    const { data, error } = await sb.from('cg_users').select('*');
    if (error) return;
    if (data && data.length) {
      registeredUsers = data.map(u => ({
        userId: u.user_id,
        name: u.name,
        email: u.email || '',
        password: u.password,
        accountType: u.account_type || 'jobseeker',
        role: u.role || '',
        company: u.company || '',
        city: u.city || '',
        bio: u.bio || '',
        avatar: u.avatar || '??',
        color: u.color || '#6366f1',
        skills: Array.isArray(u.skills) ? u.skills : [],
        profilePic: u.profile_pic || '',
        isPrivate: u.is_private || false,
        online: true
      }));
      localStorage.setItem('cg_users', JSON.stringify(registeredUsers));
    }
  } catch (e) {
    console.error('sbLoadUsers error:', e);
  }
}

async function sbSaveUser(user) {
  if (!window._sbKeyValid) return;
  try {
    const { error } = await sb.from('cg_users').upsert({
      user_id: user.userId,
      name: user.name,
      email: user.email || '',
      password: user.password,
      account_type: user.accountType || 'jobseeker',
      role: user.role || '',
      company: user.company || '',
      city: user.city || '',
      bio: user.bio || '',
      avatar: user.avatar || '??',
      color: user.color || '#6366f1',
      skills: user.skills || [],
      profile_pic: user.profilePic || '',
      is_private: user.isPrivate || false,
      online: true
    }, { onConflict: 'user_id' });
    
    if (error) console.error('sbSaveUser error:', error);
    else console.log('✅ User synced:', user.userId);
  } catch (e) {
    console.error('sbSaveUser exception:', e);
  }
}

// Posts
async function sbLoadPosts() {
  if (!window._sbKeyValid) return;
  try {
    const { data, error } = await sb.from('cg_posts')
      .select('*')
      .order('created_at', { ascending: false });
    
    if (error) return;
    if (data && data.length) {
      posts = data.map(p => ({
        id: p.id,
        userId: p.user_id,
        content: p.content,
        image: p.image || '',
        likes: p.likes || 0,
        shares: p.shares || 0,
        views: p.views || 0,
        likedBy: p.liked_by || [],
        isJob: p.is_job || false,
        time: timeAgo(p.created_at)
      }));
      localStorage.setItem('cg_posts', JSON.stringify(posts));
    }
  } catch (e) {
    console.error('sbLoadPosts error:', e);
  }
}

async function sbSavePost(post) {
  if (!window._sbKeyValid) return;
  try {
    const { error } = await sb.from('cg_posts').upsert({
      id: post.id,
      user_id: post.userId,
      content: post.content,
      image: post.image || '',
      likes: post.likes || 0,
      shares: post.shares || 0,
      views: post.views || 0,
      liked_by: post.likedBy || [],
      is_job: post.isJob || false
    }, { onConflict: 'id' });
    
    if (error) console.error('sbSavePost error:', error);
  } catch (e) {
    console.error('sbSavePost exception:', e);
  }
}

async function sbDeletePost(postId) {
  if (!window._sbKeyValid) return;
  try {
    await sb.from('cg_posts').delete().eq('id', postId);
  } catch (e) {
    console.error('sbDeletePost error:', e);
  }
}

// Comments
async function sbLoadComments(postId) {
  if (!window._sbKeyValid) return [];
  try {
    const { data, error } = await sb.from('cg_comments')
      .select('*')
      .eq('post_id', postId)
      .order('created_at', { ascending: true });
    
    if (error) return [];
    return data.map(c => ({
      id: c.id,
      postId: c.post_id,
      userId: c.user_id,
      text: c.text,
      time: timeAgo(c.created_at)
    }));
  } catch (e) {
    console.error('sbLoadComments error:', e);
    return [];
  }
}

async function sbSaveComment(comment) {
  if (!window._sbKeyValid) return;
  try {
    const { error } = await sb.from('cg_comments').insert({
      post_id: comment.postId,
      user_id: comment.userId,
      text: comment.text
    });
    
    if (error) console.error('sbSaveComment error:', error);
  } catch (e) {
    console.error('sbSaveComment exception:', e);
  }
}

// Notifications
async function sbLoadNotifications() {
  if (!window._sbKeyValid || !ME) return;
  try {
    const { data, error } = await sb.from('cg_notifications')
      .select('*')
      .eq('user_id', ME.userId)
      .order('created_at', { ascending: false })
      .limit(50);
    
    if (error) return;
    if (data) {
      notifications = data.map(n => ({
        id: n.id,
        userId: n.user_id,
        fromUserId: n.from_user_id,
        type: n.type,
        text: n.text,
        icon: n.icon || '📬',
        read: n.read || false,
        time: timeAgo(n.created_at)
      }));
      localStorage.setItem('cg_notifs_' + ME.userId, JSON.stringify(notifications));
    }
  } catch (e) {
    console.error('sbLoadNotifications error:', e);
  }
}
}
  try {
    await sb.from('cg_notifications').update({ read: true }).eq('id', notifId);
  } catch (e) {
  }
}

// ── REALTIME SUBSCRIPTIONS ──
function startRealtimeSync() {
  if (!window._sbKeyValid) return;
  
  // Posts realtime
  sb.channel('cg_posts_rt')
    .on('postgres_changes', {
      event: 'INSERT',
      schema: 'public',
      table: 'cg_posts'
    }, (payload) => {
      const p = payload.new;
      if (!posts.find(x => x.id === p.id)) {
        posts.unshift({
          id: p.id,
          userId: p.user_id,
          content: p.content,
          image: p.image || '',
          likes: p.likes || 0,
          shares: p.shares || 0,
          likedBy: p.liked_by || [],
          time: 'Just now'
        });
        localStorage.setItem('cg_posts', JSON.stringify(posts));
        if (typeof renderFeed === 'function') renderFeed();
      }
    })
    .subscribe();
  
  // Comments realtime
  sb.channel('cg_comments_rt')
    .on('postgres_changes', {
      event: 'INSERT',
      schema: 'public',
      table: 'cg_comments'
    }, async (payload) => {
      const c = payload.new;
      if (commentCache[c.post_id]) delete commentCache[c.post_id];
      if (typeof renderFeed === 'function') renderFeed();
    })
    .subscribe();
  
  // Notifications realtime
  sb.channel('cg_notifications_rt')
    .on('postgres_changes', {
      event: 'INSERT',
      schema: 'public',
      table: 'cg_notifications'
    }, async (payload) => {
      const n = payload.new;
      if (n.user_id === ME?.userId) {
        await sbLoadNotifications();
        showToast(n.text || 'New notification', 'info');
      }
    })
    .subscribe();
}

// ── AUTH FUNCTIONS ──
async function login(email, password) {
  const user = registeredUsers.find(u => u.email === email && u.password === password);
  if (!user) {
    showToast('❌ Invalid credentials', 'error');
    return false;
  }
  
  ME = user;
  localStorage.setItem('cg_me', JSON.stringify(ME));
  
  if (window._sbKeyValid) {
    await sbLoadPosts();
    await sbLoadNotifications();
  }
  
  showToast('✅ Welcome back, ' + ME.name, 'success');
  return true;
}

async function signup(userData) {
  const exists = registeredUsers.find(u => u.email === userData.email);
  if (exists) {
    showToast('❌ Email already registered', 'error');
    return false;
  }
  
  const newUser = {
    userId: generateId(),
    name: userData.name,
    email: userData.email,
    password: userData.password,
    accountType: userData.accountType || 'jobseeker',
    role: userData.role || '',
    company: userData.company || '',
    city: userData.city || '',
    bio: '',
    avatar: userData.name.slice(0, 2).toUpperCase(),
    color: '#' + Math.floor(Math.random() * 16777215).toString(16),
    skills: [],
    profilePic: '',
    isPrivate: false,
    online: true
  };
  
  registeredUsers.push(newUser);
  localStorage.setItem('cg_users', JSON.stringify(registeredUsers));
  
  if (window._sbKeyValid) {
    await sbSaveUser(newUser);
  }
  
  ME = newUser;
  localStorage.setItem('cg_me', JSON.stringify(ME));
  
  showToast('✅ Account created successfully!', 'success');
  return true;
}

function logout() {
  ME = null;
  localStorage.removeItem('cg_me');
  commentCache = {};
  showToast('👋 Logged out', 'info');
}

// ── POST FUNCTIONS ──
async function createPost(content, image = '', isJob = false) {
  if (!ME) {
    showToast('❌ Please login first', 'error');
    return;
  }
  
  const post = {
    id: generateId(),
    userId: ME.userId,
    content: content,
    image: image,
    likes: 0,
    shares: 0,
    views: 0,
    likedBy: [],
    isJob: isJob,
    time: 'Just now'
  };
  
  posts.unshift(post);
  localStorage.setItem('cg_posts', JSON.stringify(posts));
  
  if (window._sbKeyValid) {
    await sbSavePost(post);
  }
  
  showToast('✅ Post created', 'success');
  return post;
}

async function likePost(postId) {
  if (!ME) return;
  
  const post = posts.find(p => p.id === postId);
  if (!post) return;
  
  if (!post.likedBy) post.likedBy = [];
  
  const alreadyLiked = post.likedBy.includes(ME.userId);
  
  if (alreadyLiked) {
    post.likedBy = post.likedBy.filter(id => id !== ME.userId);
    post.likes = Math.max(0, post.likes - 1);
  } else {
    post.likedBy.push(ME.userId);
    post.likes = (post.likes || 0) + 1;
    
    // Send notification to post owner
    if (post.userId !== ME.userId && window._sbKeyValid) {
      await sbSaveNotification({
        userId: post.userId,
        fromUserId: ME.userId,
        type: 'like',
        text: `${ME.name} liked your post`,
        icon: '❤️'
      });
    }
  }
  
  localStorage.setItem('cg_posts', JSON.stringify(posts));
  
  if (window._sbKeyValid) {
    await sbSavePost(post);
  }
}

async function addComment(postId, text) {
  if (!ME || !text.trim()) return;
  
  const comment = {
    id: generateId(),
    postId: postId,
    userId: ME.userId,
    text: text.trim(),
    time: 'Just now'
  };
  
  if (window._sbKeyValid) {
    await sbSaveComment(comment);
    // Clear cache to force reload
    delete commentCache[postId];
    
    // Send notification
    const post = posts.find(p => p.id === postId);
    if (post && post.userId !== ME.userId) {
      await sbSaveNotification({
        userId: post.userId,
        fromUserId: ME.userId,
        type: 'comment',
        text: `${ME.name} commented on your post`,
        icon: '💬'
      });
    }
  }
}

// ── UI HELPER ──
function showToast(message, type = 'info') {
  console.log(`[${type.toUpperCase()}] ${message}`);
  // Implement your toast UI here
}

// ── INITIALIZATION ──
function init() {
  // Load from localStorage
  registeredUsers = safeJSON('cg_users', []);
  posts = safeJSON('cg_posts', []);
  ME = safeJSON('cg_me', null);
  
  if (ME) {
    notifications = safeJSON('cg_notifs_' + ME.userId, []);
  }
  
  console.log('CareerGram initialized');
  console.log('Users:', registeredUsers.length);
  console.log('Posts:', posts.length);
  console.log('Logged in:', ME ? ME.name : 'No');
}

// Auto-initialize when loaded
if (typeof window !== 'undefined') {
  window.CareerGram = {
    init,
    initSupabase,
    login,
    signup,
    logout,
    createPost,
    likePost,
    addComment,
    sbLoadUsers,
    sbLoadPosts,
    sbLoadComments,
    sbLoadNotifications,
    startRealtimeSync,
    escapeHTML,
    timeAgo,
    generateId,
    // Expose state for debugging
    getState: () => ({ ME, posts, users: registeredUsers, notifications })
  };
}

console.log('✅ CareerGram JS loaded');
