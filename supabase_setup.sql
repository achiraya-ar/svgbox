-- ============================================================
--  SVGBox 2.0.0 — Supabase Complete Setup Script
--  ไฟล์นี้สร้างทุกอย่างที่จำเป็นตั้งแต่ต้น (idempotent)
--  สามารถรันซ้ำได้อย่างปลอดภัยโดยไม่เกิด error
--
--  วิธีใช้:
--    1. เปิด Supabase Dashboard → SQL Editor
--    2. วางเนื้อหาทั้งหมดแล้วกด "Run"
--    3. รันครั้งเดียวก็เพียงพอ (re-run ได้โดยไม่เสียข้อมูล)
-- ============================================================


-- ============================================================
--  EXTENSIONS
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";


-- ============================================================
--  TABLES
-- ============================================================

-- ── svgbox_profiles ──────────────────────────────────────────
--  เก็บข้อมูล profile เพิ่มเติมของผู้ใช้ (ต่อจาก auth.users)
--  สร้างอัตโนมัติผ่าน trigger svgbox_on_auth_user_created

CREATE TABLE IF NOT EXISTS svgbox_profiles (
  id           UUID        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username     TEXT        UNIQUE,
  display_name TEXT,
  avatar_svg   TEXT,
  bio          TEXT,
  phone        TEXT,
  website      TEXT,
  twitter      TEXT,
  instagram    TEXT,
  github       TEXT,
  role         TEXT        NOT NULL DEFAULT 'user'
                           CONSTRAINT svgbox_profiles_role_check
                             CHECK (role IN ('user', 'admin')),
  last_seen_at TIMESTAMPTZ,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE  svgbox_profiles              IS 'SVGBox — ข้อมูลโปรไฟล์ผู้ใช้ (ต่อจาก auth.users)';
COMMENT ON COLUMN svgbox_profiles.role         IS 'สิทธิ์การใช้งาน: user (ทั่วไป) หรือ admin (ผู้ดูแลระบบ)';
COMMENT ON COLUMN svgbox_profiles.last_seen_at IS 'เวลาที่ผู้ใช้เข้าสู่ระบบล่าสุด (อัปเดตอัตโนมัติจาก frontend)';

-- ── Add missing columns for existing databases (idempotent) ──
ALTER TABLE svgbox_profiles ADD COLUMN IF NOT EXISTS avatar_svg   TEXT;
ALTER TABLE svgbox_profiles ADD COLUMN IF NOT EXISTS phone        TEXT;
ALTER TABLE svgbox_profiles ADD COLUMN IF NOT EXISTS website      TEXT;
ALTER TABLE svgbox_profiles ADD COLUMN IF NOT EXISTS twitter      TEXT;
ALTER TABLE svgbox_profiles ADD COLUMN IF NOT EXISTS instagram    TEXT;
ALTER TABLE svgbox_profiles ADD COLUMN IF NOT EXISTS github       TEXT;


-- ── svgbox_assets ─────────────────────────────────────────────
--  เก็บ SVG ที่ผู้ใช้อัปโหลด

CREATE TABLE IF NOT EXISTS svgbox_assets (
  id           UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id      UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name         TEXT        NOT NULL,
  svg_code     TEXT        NOT NULL,
  tags         TEXT[]      NOT NULL DEFAULT '{}',
  category     TEXT        NOT NULL DEFAULT 'Other',
  is_favorite  BOOLEAN     NOT NULL DEFAULT FALSE,
  view_count   INTEGER     NOT NULL DEFAULT 0,
  is_private   BOOLEAN     NOT NULL DEFAULT TRUE,
  status       TEXT        NOT NULL DEFAULT 'approved'
                           CONSTRAINT svgbox_assets_status_check
                             CHECK (status IN ('pending', 'approved', 'rejected')),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT svgbox_assets_name_length
    CHECK (char_length(name) BETWEEN 1 AND 200),
  CONSTRAINT svgbox_assets_svg_not_empty
    CHECK (char_length(svg_code) > 0),
  CONSTRAINT svgbox_assets_category_valid
    CHECK (category IN ('Illustration', 'Icon', 'Logo', 'Animation', 'Other'))
);

COMMENT ON TABLE  svgbox_assets            IS 'SVGBox — SVG assets ที่ผู้ใช้อัปโหลด';
COMMENT ON COLUMN svgbox_assets.svg_code   IS 'Raw SVG markup';
COMMENT ON COLUMN svgbox_assets.tags       IS 'Array of tag strings';
COMMENT ON COLUMN svgbox_assets.view_count IS 'จำนวนครั้งที่ถูกเปิดดู (detail page)';
-- NOTE: COMMENT ON COLUMN is_private / status ถูกย้ายไปไว้หลัง
-- ADD COLUMN IF NOT EXISTS ด้านล่าง เพื่อกัน error "column does not exist"
-- ตอนรันบน DB เก่าที่มี table อยู่แล้วแต่ยังไม่มี column ใหม่

-- ── Add new columns for existing databases (idempotent) ──
-- ต้องรันก่อน COMMENT ON COLUMN และ RLS policies
-- เพื่อให้ column ถูกสร้างก่อนที่จะมีคนอ้างถึง
ALTER TABLE svgbox_assets ADD COLUMN IF NOT EXISTS is_private BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE svgbox_assets ADD COLUMN IF NOT EXISTS status     TEXT    NOT NULL DEFAULT 'approved';

-- ตั้ง COMMENT หลังจาก column ถูกสร้างแน่นอนแล้ว
-- COMMENT ON รันซ้ำได้ (update in place) และไม่ error ถ้า column มีอยู่
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE  table_schema = 'public'
      AND  table_name   = 'svgbox_assets'
      AND  column_name  = 'is_private'
  ) THEN
    COMMENT ON COLUMN svgbox_assets.is_private IS 'TRUE = private (เห็นเฉพาะเจ้าของ), FALSE = public (รออนุมัติ)';
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE  table_schema = 'public'
      AND  table_name   = 'svgbox_assets'
      AND  column_name  = 'status'
  ) THEN
    COMMENT ON COLUMN svgbox_assets.status IS 'pending = รอ admin อนุมัติ, approved = แสดงสาธารณะ, rejected = ถูกปฏิเสธ';
  END IF;
END
$$;

-- Backfill status for existing rows that may not have the constraint
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE  conname = 'svgbox_assets_status_check'
  ) THEN
    ALTER TABLE svgbox_assets
      ADD CONSTRAINT svgbox_assets_status_check
      CHECK (status IN ('pending', 'approved', 'rejected'));
  END IF;
END
$$;


-- ── svgbox_favorites ──────────────────────────────────────────
--  เก็บรายการโปรดของผู้ใช้ (many-to-many: user ↔ asset)

CREATE TABLE IF NOT EXISTS svgbox_favorites (
  id         UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID        NOT NULL REFERENCES auth.users(id)     ON DELETE CASCADE,
  asset_id   UUID        NOT NULL REFERENCES svgbox_assets(id)  ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT svgbox_favorites_unique UNIQUE (user_id, asset_id)
);

COMMENT ON TABLE svgbox_favorites IS 'SVGBox — รายการโปรดของผู้ใช้แต่ละคน';


-- ── svgbox_collections ────────────────────────────────────────
--  กลุ่ม / โฟลเดอร์ที่ผู้ใช้สร้างเองเพื่อจัดหมวด SVG

CREATE TABLE IF NOT EXISTS svgbox_collections (
  id          UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name        TEXT        NOT NULL,
  description TEXT,
  is_public   BOOLEAN     NOT NULL DEFAULT FALSE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT svgbox_collections_name_length
    CHECK (char_length(name) BETWEEN 1 AND 100)
);

COMMENT ON TABLE svgbox_collections IS 'SVGBox — คอลเลกชัน / โฟลเดอร์ที่ผู้ใช้สร้าง';


-- ── svgbox_collection_items ───────────────────────────────────
--  ความสัมพันธ์ many-to-many ระหว่าง collections และ assets

CREATE TABLE IF NOT EXISTS svgbox_collection_items (
  id            UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  collection_id UUID        NOT NULL REFERENCES svgbox_collections(id) ON DELETE CASCADE,
  asset_id      UUID        NOT NULL REFERENCES svgbox_assets(id)       ON DELETE CASCADE,
  added_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT svgbox_collection_items_unique UNIQUE (collection_id, asset_id)
);

COMMENT ON TABLE svgbox_collection_items IS 'SVGBox — SVG ที่อยู่ในคอลเลกชัน (many-to-many)';


-- ============================================================
--  INDEXES
-- ============================================================

CREATE INDEX IF NOT EXISTS svgbox_assets_user_id_idx
  ON svgbox_assets(user_id);

CREATE INDEX IF NOT EXISTS svgbox_assets_category_idx
  ON svgbox_assets(category);

CREATE INDEX IF NOT EXISTS svgbox_assets_created_at_idx
  ON svgbox_assets(created_at DESC);

CREATE INDEX IF NOT EXISTS svgbox_assets_status_idx
  ON svgbox_assets(status);

CREATE INDEX IF NOT EXISTS svgbox_assets_visibility_idx
  ON svgbox_assets(is_private, status);

CREATE INDEX IF NOT EXISTS svgbox_assets_tags_idx
  ON svgbox_assets USING GIN(tags);

CREATE INDEX IF NOT EXISTS svgbox_assets_name_search_idx
  ON svgbox_assets USING GIN(to_tsvector('simple', name));

CREATE INDEX IF NOT EXISTS svgbox_favorites_user_id_idx
  ON svgbox_favorites(user_id);

CREATE INDEX IF NOT EXISTS svgbox_favorites_asset_id_idx
  ON svgbox_favorites(asset_id);

CREATE INDEX IF NOT EXISTS svgbox_collections_user_id_idx
  ON svgbox_collections(user_id);

CREATE INDEX IF NOT EXISTS svgbox_collection_items_collection_id_idx
  ON svgbox_collection_items(collection_id);

CREATE INDEX IF NOT EXISTS svgbox_collection_items_asset_id_idx
  ON svgbox_collection_items(asset_id);

CREATE INDEX IF NOT EXISTS svgbox_profiles_role_idx
  ON svgbox_profiles(role);

CREATE INDEX IF NOT EXISTS svgbox_profiles_last_seen_idx
  ON svgbox_profiles(last_seen_at DESC NULLS LAST);


-- ============================================================
--  FUNCTIONS & TRIGGERS
--  ใช้ CREATE OR REPLACE เพื่อให้รันซ้ำได้โดยไม่ error
-- ============================================================

-- ── Auto-update updated_at ────────────────────────────────────

CREATE OR REPLACE FUNCTION svgbox_set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION svgbox_set_updated_at IS 'Trigger function — ตั้งค่า updated_at เป็น NOW() ก่อน UPDATE';

DROP TRIGGER IF EXISTS svgbox_profiles_updated_at    ON svgbox_profiles;
DROP TRIGGER IF EXISTS svgbox_assets_updated_at      ON svgbox_assets;
DROP TRIGGER IF EXISTS svgbox_collections_updated_at ON svgbox_collections;

CREATE TRIGGER svgbox_profiles_updated_at
  BEFORE UPDATE ON svgbox_profiles
  FOR EACH ROW EXECUTE PROCEDURE svgbox_set_updated_at();

CREATE TRIGGER svgbox_assets_updated_at
  BEFORE UPDATE ON svgbox_assets
  FOR EACH ROW EXECUTE PROCEDURE svgbox_set_updated_at();

CREATE TRIGGER svgbox_collections_updated_at
  BEFORE UPDATE ON svgbox_collections
  FOR EACH ROW EXECUTE PROCEDURE svgbox_set_updated_at();


-- ── Auto-create profile on sign-up ───────────────────────────
--  ทุก user ที่สมัครใหม่จะได้ role = 'user' เสมอ

CREATE OR REPLACE FUNCTION svgbox_handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO svgbox_profiles (id, display_name, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1)),
    'user'
  )
  ON CONFLICT (id) DO NOTHING;  -- safe re-run guard
  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION svgbox_handle_new_user IS
  'Trigger — สร้าง svgbox_profiles row อัตโนมัติเมื่อมี user ใหม่ใน auth.users';

DROP TRIGGER IF EXISTS svgbox_on_auth_user_created ON auth.users;

CREATE TRIGGER svgbox_on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE svgbox_handle_new_user();


-- ── Admin helper: is current user an admin? ───────────────────

CREATE OR REPLACE FUNCTION svgbox_is_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM   svgbox_profiles
    WHERE  id   = auth.uid()
      AND  role = 'admin'
  );
$$;

COMMENT ON FUNCTION svgbox_is_admin IS
  'คืนค่า TRUE ถ้า user ที่ login อยู่มี role = admin';


-- ── Session tracking: update last_seen_at ─────────────────────
--  เรียกจาก frontend ผ่าน supabase.rpc('svgbox_update_last_seen')

CREATE OR REPLACE FUNCTION svgbox_update_last_seen()
RETURNS VOID
LANGUAGE sql
SECURITY DEFINER SET search_path = public
AS $$
  UPDATE svgbox_profiles
  SET    last_seen_at = NOW()
  WHERE  id = auth.uid();
$$;

COMMENT ON FUNCTION svgbox_update_last_seen IS
  'อัปเดต last_seen_at ของ user ปัจจุบัน — เรียกผ่าน supabase.rpc() หลัง login';


-- ── Admin: list all users (includes email from auth.users) ────
--  เรียกจาก frontend ผ่าน supabase.rpc('svgbox_admin_list_users')

CREATE OR REPLACE FUNCTION svgbox_admin_list_users()
RETURNS TABLE (
  id           UUID,
  email        TEXT,
  display_name TEXT,
  username     TEXT,
  role         TEXT,
  last_seen_at TIMESTAMPTZ,
  created_at   TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  IF NOT svgbox_is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: admin access required';
  END IF;

  RETURN QUERY
  SELECT
    p.id,
    u.email::TEXT,
    p.display_name,
    p.username,
    p.role,
    p.last_seen_at,
    p.created_at
  FROM   svgbox_profiles p
  JOIN   auth.users      u ON u.id = p.id
  ORDER  BY p.created_at DESC;
END;
$$;

COMMENT ON FUNCTION svgbox_admin_list_users IS
  'Admin only — ดึงรายชื่อ users ทั้งหมดพร้อม email จาก auth.users';


-- ── Admin: delete a user (cascades all their data) ────────────
--  หลังลบแล้ว email นั้นสามารถใช้สมัครสมาชิกใหม่ได้อีกครั้ง
--  เรียกจาก frontend ผ่าน supabase.rpc('svgbox_admin_delete_user', { target_user_id: '...' })

CREATE OR REPLACE FUNCTION svgbox_admin_delete_user(target_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  IF NOT svgbox_is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: admin access required';
  END IF;

  IF target_user_id = auth.uid() THEN
    RAISE EXCEPTION 'Cannot delete your own account via admin panel';
  END IF;

  -- ON DELETE CASCADE จะลบ svgbox_profiles, svgbox_assets ฯลฯ ให้อัตโนมัติ
  DELETE FROM auth.users WHERE id = target_user_id;
END;
$$;

COMMENT ON FUNCTION svgbox_admin_delete_user IS
  'Admin only — ลบ user ออกจาก auth.users (cascade) หลังลบแล้ว email สมัครใหม่ได้';


-- ── Increment view_count (bypasses RLS for guest users) ───────
--  เรียกจาก frontend ผ่าน supabase.rpc('svgbox_increment_view_count', { asset_id: '...' })

CREATE OR REPLACE FUNCTION svgbox_increment_view_count(asset_id UUID)
RETURNS VOID
LANGUAGE sql
SECURITY DEFINER SET search_path = public
AS $$
  UPDATE svgbox_assets
  SET    view_count = view_count + 1
  WHERE  id = asset_id;
$$;

COMMENT ON FUNCTION svgbox_increment_view_count IS
  'เพิ่ม view_count ทีละ 1 — เรียกผ่าน RPC เพื่อให้ guest สามารถเรียกได้';


-- ── Admin: review an SVG (approve / reject / toggle visibility) ──
-- ใช้สำหรับให้ admin อนุมัติ SVG ของ user อื่น
-- เรียกจาก frontend ผ่าน supabase.rpc('svgbox_admin_review_asset', {
--   target_asset_id: '...',
--   new_status: 'approved' | 'rejected' | 'pending',
--   new_is_private: true | false
-- })

CREATE OR REPLACE FUNCTION svgbox_admin_review_asset(
  target_asset_id UUID,
  new_status      TEXT,
  new_is_private  BOOLEAN
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  IF NOT svgbox_is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: admin access required';
  END IF;

  IF new_status NOT IN ('pending', 'approved', 'rejected') THEN
    RAISE EXCEPTION 'Invalid status: must be pending, approved, or rejected';
  END IF;

  UPDATE svgbox_assets
  SET    status     = new_status,
         is_private = new_is_private
  WHERE  id = target_asset_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Asset not found';
  END IF;
END;
$$;

COMMENT ON FUNCTION svgbox_admin_review_asset IS
  'Admin only — อนุมัติ/ปฏิเสธ SVG และเปลี่ยนสถานะ public/private';


-- ── Get assets with per-user favorite flag ─────────────────────

CREATE OR REPLACE FUNCTION svgbox_get_assets_with_favorites(
  p_search   TEXT    DEFAULT NULL,
  p_category TEXT    DEFAULT NULL,
  p_tag      TEXT    DEFAULT NULL,
  p_limit    INTEGER DEFAULT 50,
  p_offset   INTEGER DEFAULT 0
)
RETURNS TABLE (
  id           UUID,
  user_id      UUID,
  name         TEXT,
  svg_code     TEXT,
  tags         TEXT[],
  category     TEXT,
  is_favorite  BOOLEAN,
  view_count   INTEGER,
  created_at   TIMESTAMPTZ,
  updated_at   TIMESTAMPTZ,
  is_favorited BOOLEAN
)
LANGUAGE sql
STABLE
SECURITY DEFINER SET search_path = public
AS $$
  SELECT
    a.id,
    a.user_id,
    a.name,
    a.svg_code,
    a.tags,
    a.category,
    a.is_favorite,
    a.view_count,
    a.created_at,
    a.updated_at,
    EXISTS (
      SELECT 1 FROM svgbox_favorites f
      WHERE  f.asset_id = a.id
        AND  f.user_id  = auth.uid()
    ) AS is_favorited
  FROM  svgbox_assets a
  WHERE
    (p_search   IS NULL OR a.name     ILIKE '%' || p_search || '%')
    AND (p_category IS NULL OR a.category = p_category)
    AND (p_tag      IS NULL OR a.tags    @> ARRAY[p_tag])
    -- เจ้าของ/แอดมินเห็นทุกอย่าง, คนทั่วไปเห็นเฉพาะ approved + public
    AND (
      a.user_id = auth.uid()
      OR svgbox_is_admin()
      OR (a.status = 'approved' AND a.is_private = FALSE)
    )
  ORDER  BY a.created_at DESC
  LIMIT  p_limit
  OFFSET p_offset;
$$;


-- ── Get favorite asset IDs for a user ─────────────────────────
--  เรียกจาก frontend ผ่าน supabase.rpc('svgbox_get_favorite_ids')

CREATE OR REPLACE FUNCTION svgbox_get_favorite_ids()
RETURNS TABLE (asset_id UUID)
LANGUAGE sql
STABLE
SECURITY DEFINER SET search_path = public
AS $$
  SELECT asset_id
  FROM   svgbox_favorites
  WHERE  user_id = auth.uid();
$$;

COMMENT ON FUNCTION svgbox_get_favorite_ids IS
  'คืนรายการ asset_id ที่ user ปัจจุบัน favorite ไว้ทั้งหมด';


-- ============================================================
--  ROW LEVEL SECURITY
--  เปิดใช้งานทุกตาราง
-- ============================================================

ALTER TABLE svgbox_profiles         ENABLE ROW LEVEL SECURITY;
ALTER TABLE svgbox_assets           ENABLE ROW LEVEL SECURITY;
ALTER TABLE svgbox_favorites        ENABLE ROW LEVEL SECURITY;
ALTER TABLE svgbox_collections      ENABLE ROW LEVEL SECURITY;
ALTER TABLE svgbox_collection_items ENABLE ROW LEVEL SECURITY;


-- ============================================================
--  RLS POLICIES
--  DROP IF EXISTS ก่อน CREATE เพื่อให้ re-run ได้โดยไม่ error
-- ============================================================

-- ── svgbox_profiles ──────────────────────────────────────────

DROP POLICY IF EXISTS "svgbox_profiles: public read"      ON svgbox_profiles;
DROP POLICY IF EXISTS "svgbox_profiles: owner insert"     ON svgbox_profiles;
DROP POLICY IF EXISTS "svgbox_profiles: owner update"     ON svgbox_profiles;
DROP POLICY IF EXISTS "svgbox_profiles: admin update any" ON svgbox_profiles;
DROP POLICY IF EXISTS "svgbox_profiles: owner delete"     ON svgbox_profiles;

-- ทุกคนดู profile ได้ (สาธารณะ)
CREATE POLICY "svgbox_profiles: public read"
  ON svgbox_profiles FOR SELECT
  USING (TRUE);

-- เจ้าของเท่านั้นสร้าง profile ของตัวเอง
CREATE POLICY "svgbox_profiles: owner insert"
  ON svgbox_profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- เจ้าของแก้ไข profile ของตัวเอง
CREATE POLICY "svgbox_profiles: owner update"
  ON svgbox_profiles FOR UPDATE
  USING    (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- admin แก้ไข profile ของ user คนไหนก็ได้ (รวมถึงเปลี่ยน role)
CREATE POLICY "svgbox_profiles: admin update any"
  ON svgbox_profiles FOR UPDATE
  USING    (svgbox_is_admin())
  WITH CHECK (svgbox_is_admin());

-- เจ้าของเท่านั้นลบ profile ของตัวเอง
CREATE POLICY "svgbox_profiles: owner delete"
  ON svgbox_profiles FOR DELETE
  USING (auth.uid() = id);


-- ── svgbox_assets ─────────────────────────────────────────────

DROP POLICY IF EXISTS "svgbox_assets: public read"             ON svgbox_assets;
DROP POLICY IF EXISTS "svgbox_assets: authenticated insert"    ON svgbox_assets;
DROP POLICY IF EXISTS "svgbox_assets: owner update"            ON svgbox_assets;
DROP POLICY IF EXISTS "svgbox_assets: owner or admin update"   ON svgbox_assets;
DROP POLICY IF EXISTS "svgbox_assets: owner delete"            ON svgbox_assets;
DROP POLICY IF EXISTS "svgbox_assets: owner or admin delete"   ON svgbox_assets;

-- นโยบายการมองเห็น:
--   - เจ้าของ: เห็น SVG ทุกตัวของตัวเองทุกสถานะ (รวม pending/rejected)
--   - admin: เห็นทั้งหมดทุกสถานะ
--   - public: เห็นเฉพาะ status='approved' AND is_private=false
CREATE POLICY "svgbox_assets: public read"
  ON svgbox_assets FOR SELECT
  USING (
    auth.uid() = user_id                                  -- เจ้าของเห็นทุกตัวของตัวเอง
    OR svgbox_is_admin()                                  -- admin เห็นทั้งหมด
    OR (status = 'approved' AND is_private = FALSE)       -- public เห็นเฉพาะ approved + public
  );

-- เฉพาะผู้ที่ login แล้วอัปโหลด โดยใช้ user_id ของตัวเอง
-- ใช้ auth.uid() IS NOT NULL แทน auth.role() = 'authenticated'
-- เพื่อความเข้ากันได้กับทุก Supabase plan และป้องกัน edge-case JWT
-- ผู้ใช้ทั่วไป insert ต้องมี status='pending' เท่านั้น (admin เท่านั้นที่อนุมัติ)
-- และ is_private ต้องเป็น TRUE เสมอ (เจ้าของ/แอดมินเท่านั้นที่ปลดล็อกเป็น public ได้)
CREATE POLICY "svgbox_assets: authenticated insert"
  ON svgbox_assets FOR INSERT
  WITH CHECK (
    auth.uid() IS NOT NULL
    AND auth.uid() = user_id
    AND (
      svgbox_is_admin()                                     -- admin ใส่ status ใดก็ได้
      OR (status = 'pending' AND is_private = TRUE)          -- user ทั่วไป: pending + private
    )
  );

-- เจ้าของ หรือ admin แก้ไข SVG ได้
-- แต่การเปลี่ยน status และ is_private จำกัดสิทธิ์เพิ่มเติมผ่าน trigger/function
CREATE POLICY "svgbox_assets: owner or admin update"
  ON svgbox_assets FOR UPDATE
  USING    (auth.uid() = user_id OR svgbox_is_admin())
  WITH CHECK (auth.uid() = user_id OR svgbox_is_admin());

-- เจ้าของ หรือ admin ลบ SVG ได้
CREATE POLICY "svgbox_assets: owner or admin delete"
  ON svgbox_assets FOR DELETE
  USING (auth.uid() = user_id OR svgbox_is_admin());


-- ── Guard: only admin can change status / is_private ──────────────────
-- ป้องกันไม่ให้ user ทั่วไปแอบอัปเดต status เป็น 'approved' หรือสับสน is_private
-- trigger นี้จะเช็คว่า:
--   - ถ้าเป็น admin สามารถแก้ทุก field ได้
--   - ถ้าเป็น user ทั่วไป ห้ามเปลี่ยน status และ is_private
CREATE OR REPLACE FUNCTION svgbox_guard_approval_fields()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  IF NOT svgbox_is_admin() THEN
    -- user ทั่วไป ไม่สามารถเปลี่ยน status หรือ is_private
    IF NEW.status IS DISTINCT FROM OLD.status THEN
      RAISE EXCEPTION 'Only admin can change approval status';
    END IF;
    IF NEW.is_private IS DISTINCT FROM OLD.is_private THEN
      RAISE EXCEPTION 'Only admin can change visibility (private/public)';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION svgbox_guard_approval_fields IS
  'Trigger — ป้องกันไม่ให้ user ทั่วไปเปลี่ยน status/is_private (admin เท่านั้น)';

DROP TRIGGER IF EXISTS svgbox_assets_guard_approval ON svgbox_assets;

CREATE TRIGGER svgbox_assets_guard_approval
  BEFORE UPDATE ON svgbox_assets
  FOR EACH ROW EXECUTE PROCEDURE svgbox_guard_approval_fields();


-- ── svgbox_favorites ──────────────────────────────────────────

DROP POLICY IF EXISTS "svgbox_favorites: owner read"   ON svgbox_favorites;
DROP POLICY IF EXISTS "svgbox_favorites: owner insert" ON svgbox_favorites;
DROP POLICY IF EXISTS "svgbox_favorites: owner delete" ON svgbox_favorites;

-- ผู้ใช้ดูรายการโปรดของตัวเองได้เท่านั้น
CREATE POLICY "svgbox_favorites: owner read"
  ON svgbox_favorites FOR SELECT
  USING (auth.uid() = user_id);

-- เพิ่ม favorite ได้เฉพาะ user_id ของตัวเอง
CREATE POLICY "svgbox_favorites: owner insert"
  ON svgbox_favorites FOR INSERT
  WITH CHECK (
    auth.uid() IS NOT NULL
    AND auth.uid() = user_id
  );

-- ลบ favorite ของตัวเองได้เท่านั้น
CREATE POLICY "svgbox_favorites: owner delete"
  ON svgbox_favorites FOR DELETE
  USING (auth.uid() = user_id);


-- ── svgbox_collections ────────────────────────────────────────

DROP POLICY IF EXISTS "svgbox_collections: read public or own"      ON svgbox_collections;
DROP POLICY IF EXISTS "svgbox_collections: authenticated insert"    ON svgbox_collections;
DROP POLICY IF EXISTS "svgbox_collections: owner update"            ON svgbox_collections;
DROP POLICY IF EXISTS "svgbox_collections: owner delete"            ON svgbox_collections;

-- ดู collection ที่ is_public = true ได้ หรือเป็นเจ้าของ
CREATE POLICY "svgbox_collections: read public or own"
  ON svgbox_collections FOR SELECT
  USING (is_public = TRUE OR auth.uid() = user_id);

-- เฉพาะผู้ที่ login แล้วสร้าง collection ของตัวเองได้
CREATE POLICY "svgbox_collections: authenticated insert"
  ON svgbox_collections FOR INSERT
  WITH CHECK (
    auth.uid() IS NOT NULL
    AND auth.uid() = user_id
  );

-- เจ้าของเท่านั้นแก้ไข collection ของตัวเอง
CREATE POLICY "svgbox_collections: owner update"
  ON svgbox_collections FOR UPDATE
  USING    (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- เจ้าของเท่านั้นลบ collection ของตัวเอง
CREATE POLICY "svgbox_collections: owner delete"
  ON svgbox_collections FOR DELETE
  USING (auth.uid() = user_id);


-- ── svgbox_collection_items ───────────────────────────────────

DROP POLICY IF EXISTS "svgbox_collection_items: read if collection visible" ON svgbox_collection_items;
DROP POLICY IF EXISTS "svgbox_collection_items: owner insert"               ON svgbox_collection_items;
DROP POLICY IF EXISTS "svgbox_collection_items: owner delete"               ON svgbox_collection_items;

-- ดูได้ถ้า collection นั้น public หรือเป็นเจ้าของ
CREATE POLICY "svgbox_collection_items: read if collection visible"
  ON svgbox_collection_items FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM svgbox_collections c
      WHERE  c.id      = collection_id
        AND  (c.is_public = TRUE OR c.user_id = auth.uid())
    )
  );

-- เพิ่ม item ได้เฉพาะเจ้าของ collection
CREATE POLICY "svgbox_collection_items: owner insert"
  ON svgbox_collection_items FOR INSERT
  WITH CHECK (
    auth.uid() IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM svgbox_collections c
      WHERE  c.id      = collection_id
        AND  c.user_id = auth.uid()
    )
  );

-- ลบ item ได้เฉพาะเจ้าของ collection
CREATE POLICY "svgbox_collection_items: owner delete"
  ON svgbox_collection_items FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM svgbox_collections c
      WHERE  c.id      = collection_id
        AND  c.user_id = auth.uid()
    )
  );


-- ============================================================
--  PROMOTE USER TO ADMIN
--  ยกเลิก comment บรรทัดด้านล่าง แล้วแทนที่ UUID ด้วย
--  id ของ user ที่ต้องการเลื่อนเป็น admin
--  (หา id ได้จาก Authentication → Users ใน Supabase Dashboard)
-- ============================================================

-- UPDATE svgbox_profiles
--   SET role = 'admin'
--   WHERE id = '<paste-user-uuid-here>';


-- ============================================================
--  VERIFY (optional — uncomment เพื่อตรวจสอบผลลัพธ์)
-- ============================================================

-- ดูโครงสร้างตาราง svgbox_profiles
-- SELECT column_name, data_type, column_default, is_nullable
-- FROM   information_schema.columns
-- WHERE  table_schema = 'public'
--   AND  table_name   = 'svgbox_profiles'
-- ORDER  BY ordinal_position;

-- ดู RLS policies ทั้งหมด
-- SELECT tablename, policyname, cmd, qual
-- FROM   pg_policies
-- WHERE  tablename LIKE 'svgbox_%'
-- ORDER  BY tablename, policyname;

-- ดู functions ทั้งหมด
-- SELECT routine_name, routine_type
-- FROM   information_schema.routines
-- WHERE  routine_schema = 'public'
--   AND  routine_name   LIKE 'svgbox_%'
-- ORDER  BY routine_name;

-- ดูจำนวน users และ SVGs
-- SELECT
--   (SELECT COUNT(*) FROM svgbox_profiles)         AS total_users,
--   (SELECT COUNT(*) FROM svgbox_profiles WHERE role = 'admin') AS admins,
--   (SELECT COUNT(*) FROM svgbox_assets)            AS total_svgs;


-- ============================================================
--  SUMMARY
-- ============================================================
--
--  ตาราง (5):
--    svgbox_profiles          — โปรไฟล์ผู้ใช้ + role + last_seen_at
--    svgbox_assets            — SVG assets (หลัก)
--    svgbox_favorites         — รายการโปรด (user ↔ asset)
--    svgbox_collections       — คอลเลกชัน / โฟลเดอร์
--    svgbox_collection_items  — SVG ใน collection (many-to-many)
--
--  Triggers (4):
--    svgbox_on_auth_user_created  — สร้าง profile อัตโนมัติเมื่อสมัคร
--    svgbox_profiles_updated_at   — อัปเดต updated_at อัตโนมัติ
--    svgbox_assets_updated_at     — อัปเดต updated_at อัตโนมัติ
--    svgbox_collections_updated_at— อัปเดต updated_at อัตโนมัติ
--
--  Functions (7):
--    svgbox_set_updated_at()                  — trigger helper
--    svgbox_handle_new_user()                 — trigger: สร้าง profile
--    svgbox_is_admin()                        — ตรวจสอบสิทธิ์ admin
--    svgbox_update_last_seen()                — บันทึกเวลา login
--    svgbox_admin_list_users()                — admin: ดู users ทั้งหมด
--    svgbox_admin_delete_user(uuid)           — admin: ลบ user
--    svgbox_increment_view_count(uuid)        — เพิ่ม view count
--    svgbox_get_assets_with_favorites(...)    — ดึง SVG + is_favorited
--
--  RLS: เปิดทุกตาราง — 14 policies ทั้งหมด
--
-- ============================================================
