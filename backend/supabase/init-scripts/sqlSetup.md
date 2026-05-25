-- 1. Tạo bảng profiles (Hồ sơ người dùng)
CREATE TABLE public.profiles (
id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL PRIMARY KEY,
username TEXT UNIQUE,
full_name TEXT,
avatar_url TEXT,
is_premium BOOLEAN DEFAULT FALSE,
updated_at TIMESTAMPTZ DEFAULT NOW(),

CONSTRAINT username_length CHECK (char_length(username) >= 3)
);

-- 2. Kích hoạt Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 3. Tạo Policy (Quy tắc bảo mật)
CREATE POLICY "Public profiles are viewable by everyone"
ON public.profiles FOR SELECT USING (true);

CREATE POLICY "Users can insert their own profile"
ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile"
ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- 4. Trigger tự động tạo profile khi có user mới đăng ký qua Auth
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
INSERT INTO public.profiles (id, full_name, avatar_url)
VALUES (new.id, new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'avatar_url');
RETURN NEW;
END;

$$
LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
$$

1. BACKEND: Daily Mood SQL
   -- 1. Tạo bảng daily_moods
   CREATE TABLE public.daily_moods (
   id BIGSERIAL PRIMARY KEY,
   user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
   mood_score INT NOT NULL, -- 1: Rất tệ, 5: Cực tốt
   feeling_text TEXT,
   ai_super_power TEXT, -- Sẽ được Grok AI điền vào ở Phase 5
   money_tip TEXT, -- Cách kiếm tiền từ mood này
   created_at TIMESTAMPTZ DEFAULT NOW()
   );

-- 2. Bảo mật RLS
ALTER TABLE public.daily_moods ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can only see their own moods"
ON public.daily_moods FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own mood"
ON public.daily_moods FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 3. Tạo Index để truy vấn nhanh cho Statistics sau này
CREATE INDEX idx_daily_moods_user_date ON public.daily_moods (user_id, created_at);

1. BACKEND: Newfeed SQL (Tables + Triggers)
   -- 1. Bảng Posts
   CREATE TABLE public.posts (
   id BIGSERIAL PRIMARY KEY,
   user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
   content TEXT NOT NULL,
   image_urls TEXT[] DEFAULT '{}', -- Mảng tối đa 2 ảnh
   likes_count INT DEFAULT 0,
   comments_count INT DEFAULT 0,
   created_at TIMESTAMPTZ DEFAULT NOW()
   );

-- 2. Bảng Likes (để toggle và check trạng thái)
CREATE TABLE public.post_likes (
post_id BIGINT REFERENCES public.posts(id) ON DELETE CASCADE,
user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
PRIMARY KEY (post_id, user_id)
);

-- 3. Bảng Comments (chuẩn bị cho Phase 6)
CREATE TABLE public.comments (
id BIGSERIAL PRIMARY KEY,
post_id BIGINT REFERENCES public.posts(id) ON DELETE CASCADE,
user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
content TEXT NOT NULL,
created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. TRIGGER: Tự động cập nhật likes_count khi có người Like/Unlike
CREATE OR REPLACE FUNCTION public.handle_post_like()
RETURNS TRIGGER AS $$
BEGIN
IF (TG_OP = 'INSERT') THEN
UPDATE public.posts SET likes_count = likes_count + 1 WHERE id = NEW.post_id;
ELSIF (TG_OP = 'DELETE') THEN
UPDATE public.posts SET likes_count = likes_count - 1 WHERE id = OLD.post_id;
END IF;
RETURN NULL;
END;

$$
LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_post_like_changed
  AFTER INSERT OR DELETE ON public.post_likes
  FOR EACH ROW EXECUTE FUNCTION public.handle_post_like();

-- 5. RLS Policies
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.post_likes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Ai cũng xem được bài viết" ON public.posts FOR SELECT USING (true);
CREATE POLICY "Chỉ chủ bài viết mới được đăng" ON public.posts FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Ai cũng xem được lượt like" ON public.post_likes FOR SELECT USING (true);
CREATE POLICY "User chỉ được like/unlike chính mình" ON public.post_likes FOR ALL USING (auth.uid() = user_id);
$$

1. BACKEND: Supabase Storage Setup
   -- Cho phép mọi người xem ảnh
   CREATE POLICY "Public Access" ON storage.objects FOR SELECT USING (bucket_id = 'posts_images');

-- Chỉ user đã login mới được upload ảnh vào thư mục của họ
CREATE POLICY "Authenticated Users can upload" ON storage.objects FOR INSERT
WITH CHECK (
bucket_id = 'posts_images' AND
auth.role() = 'authenticated'
);

-- Chỉ chủ nhân mới được xóa ảnh
CREATE POLICY "Users can delete own images" ON storage.objects FOR DELETE
USING (bucket_id = 'posts_images' AND auth.uid() = owner);

1. BACKEND: Comment Trigger & RLS
   -- 1. TRIGGER: Tự động cập nhật comments_count trong bảng posts
   CREATE OR REPLACE FUNCTION public.handle_comment_count()
   RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    UPDATE public.posts SET comments_count = comments_count + 1 WHERE id = NEW.post_id;
  ELSIF (TG_OP = 'DELETE') THEN
    UPDATE public.posts SET comments_count = comments_count - 1 WHERE id = OLD.post_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_comment_changed
AFTER INSERT OR DELETE ON public.comments
FOR EACH ROW EXECUTE FUNCTION public.handle_comment_count();

-- 2. RLS cho bảng comments
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Ai cũng xem được comment" ON public.comments FOR SELECT USING (true);
CREATE POLICY "User đã login mới được comment" ON public.comments FOR INSERT WITH CHECK (auth.uid() = user_id);

1. BACKEND: Marketplace SQL
   -- 1. Bảng Gigs (Chợ kỹ năng)
   CREATE TABLE public.gigs (
   id BIGSERIAL PRIMARY KEY,
   user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
   title TEXT NOT NULL,
   description TEXT NOT NULL,
   price_estimate TEXT, -- Ví dụ: "500k - 1tr" hoặc "Thỏa thuận"
   category TEXT DEFAULT 'General', -- Code, Design, Vibe, Chilling...
   image_url TEXT,
   is_active BOOLEAN DEFAULT TRUE,
   created_at TIMESTAMPTZ DEFAULT NOW()
   );

-- 2. Kích hoạt RLS
ALTER TABLE public.gigs ENABLE ROW LEVEL SECURITY;

-- 3. Policy: Ai cũng xem được Gig đang active
CREATE POLICY "Public can view active gigs"
ON public.gigs FOR SELECT USING (is_active = true);

-- 4. Policy: Chỉ chủ nhân mới được tạo/sửa/xóa
CREATE POLICY "Users can manage own gigs"
ON public.gigs FOR ALL USING (auth.uid() = user_id);

-- 5. Index để lọc nhanh theo Category và thời gian
CREATE INDEX idx_gigs_category ON public.gigs(category);
CREATE INDEX idx_gigs_created_at ON public.gigs(created_at DESC);

1. BACKEND: Chat SQL
   -- 1. Bảng Messages
   CREATE TABLE public.messages (
   id BIGSERIAL PRIMARY KEY,
   sender_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
   receiver_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
   room_id TEXT NOT NULL, -- Định dạng: "uuid1_uuid2" (theo thứ tự alphabet)
   content TEXT NOT NULL,
   is_read BOOLEAN DEFAULT FALSE,
   created_at TIMESTAMPTZ DEFAULT NOW()
   );

-- 2. Kích hoạt RLS
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- 3. Policy: Chỉ người gửi hoặc người nhận mới được xem tin nhắn
CREATE POLICY "Users can view their own messages"
ON public.messages FOR SELECT
USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

-- 4. Policy: Chỉ người gửi mới được insert
CREATE POLICY "Users can send messages"
ON public.messages FOR INSERT
WITH CHECK (auth.uid() = sender_id);

-- 5. Index để load tin nhắn cực nhanh
CREATE INDEX idx_messages_room_id ON public.messages(room_id);
CREATE INDEX idx_messages_created_at ON public.messages(created_at DESC);

1. BACKEND: Cập nhật Profile cho Premium
   -- 1. Thêm cột premium_until vào bảng profiles
   ALTER TABLE public.profiles
   ADD COLUMN IF NOT EXISTS premium_until TIMESTAMPTZ;

-- 2. Tạo Function kiểm tra trạng thái Premium (Dùng cho Backend logic nếu cần)
CREATE OR REPLACE FUNCTION is_user_premium(user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
RETURN EXISTS (
SELECT 1 FROM public.profiles
WHERE id = user_id AND premium_until > NOW()
);
END;

$$
LANGUAGE plpgsql SECURITY DEFINER;


1. BACKEND: View tối ưu cho Profile
CREATE OR REPLACE FUNCTION get_user_stats(target_user_id UUID)
RETURNS TABLE(post_count BIGINT, mood_count BIGINT) AS
$$

BEGIN
RETURN QUERY
SELECT
(SELECT COUNT(_) FROM public.posts WHERE user_id = target_user_id),
(SELECT COUNT(_) FROM public.daily_moods WHERE user_id = target_user_id);
END;

$$
LANGUAGE plpgsql SECURITY DEFINER;


1. BACKEND: Materialized View & Auto-refresh
-- 1. Tạo Materialized View để tổng hợp mood trong 7 ngày gần nhất
CREATE MATERIALIZED VIEW community_mood_stats AS
SELECT
    mood_score,
    COUNT(*) as count,
    date_trunc('day', created_at) as stat_date
FROM public.daily_moods
WHERE created_at > NOW() - INTERVAL '7 days'
GROUP BY mood_score, stat_date
ORDER BY stat_date ASC, mood_score ASC;

-- 2. Index để truy vấn View cực nhanh
CREATE INDEX idx_mood_stats_date ON community_mood_stats(stat_date);

-- 3. Cấp quyền truy cập cho người dùng (View không hỗ trợ RLS trực tiếp nhưng kế thừa từ bảng gốc)
GRANT SELECT ON community_mood_stats TO authenticated;

-- 4. Logic Refresh View (Dùng Cron Job của Supabase - pg_cron)
-- Lưu ý: Trong Dashboard Supabase 2026, bro có thể set lịch mỗi 10 phút chạy lệnh này:
-- REFRESH MATERIALIZED VIEW community_mood_stats;
$$
