# SVGBox — Supabase Setup Guide

คู่มือตั้งค่า Supabase ตั้งแต่เริ่มต้น รวมถึงกรณี **ย้าย Supabase project ใหม่** เมื่อต้องการเริ่มฐานข้อมูลใหม่ทั้งหมด

---

## 📋 สารบัญ

1. [ภาพรวม](#ภาพรวม)
2. [เริ่ม Supabase project ใหม่](#เริ่ม-supabase-project-ใหม่)
3. [รัน supabase_setup.sql](#รัน-supabase_setupsql)
4. [ตั้งค่า Environment Variables](#ตั้งค่า-environment-variables)
5. [Promote Admin คนแรก](#promote-admin-คนแรก)
6. [ตรวจสอบการตั้งค่า](#ตรวจสอบการตั้งค่า)
7. [รันแอป](#รันแอป)
8. [เมื่อย้าย Supabase project ใหม่](#เมื่อย้าย-supabase-project-ใหม่)
9. [Troubleshooting](#troubleshooting)

---

## ภาพรวม

ไฟล์ `supabase_setup.sql` เป็น **สคริปต์เดียวที่ครบทุกอย่าง** (idempotent) สำหรับ:
- สร้าง 5 tables: `svgbox_profiles`, `svgbox_assets`, `svgbox_favorites`, `svgbox_collections`, `svgbox_collection_items`
- สร้าง indexes
- สร้าง 11 functions (triggers + RPCs)
- ตั้งค่า Row Level Security (RLS) — **14 policies**
- เพิ่ม columns ใหม่ (status, is_private) สำหรับ feature approval

**รันได้หลายครั้ง** โดยไม่ error และไม่ทำลายข้อมูลเดิม

> 💡 **Tip:** ไฟล์ SQL ทำงาน **idempotent** ทุก statement ใช้ `CREATE OR REPLACE`, `DROP IF EXISTS`, `ADD COLUMN IF NOT EXISTS` หรือตรวจสอบก่อนสร้าง — ย้าย DB เมื่อไหร่ก็แค่รันใหม่ได้เลย

---

## เริ่ม Supabase project ใหม่

### 1. สร้าง project ใน Supabase

1. ไปที่ [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. คลิก **"New Project"**
3. กรอกข้อมูล:
   - **Name**: `svgbox` (หรือชื่ออื่น)
   - **Database Password**: ตั้งรหัสผ่านที่แข็งแรง (เก็บไว้ในที่ปลอดภัย)
   - **Region**: เลือก region ที่ใกล้ผู้ใช้ที่สุด (เช่น `Singapore` สำหรับคนไทย)
   - **Pricing Plan**: Free tier ใช้ได้
4. คลิก **"Create new project"** และรอประมาณ 2-3 นาที

### 2. ดึง API Keys

1. ไปที่ **Project Settings** (⚙️) → **API**
2. คัดลอก 2 ค่านี้:
   - **Project URL** (เช่น `https://abcdefghij.supabase.co`)
   - **Project API keys → `anon` `public`** (JWT ยาว ๆ ขึ้นต้นด้วย `eyJ...`)

> ⚠️ **อย่าใช้** `service_role` key ใน frontend — key นี้ bypass RLS ทั้งหมด

---

## รัน supabase_setup.sql

### 1. เปิด SQL Editor

1. ใน Supabase Dashboard → **SQL Editor** (ไอคอนรูป terminal ทางซ้าย)
2. คลิก **"New query"** (ปุ่ม + มุมบนขวา)

### 2. รันสคริปต์

1. เปิดไฟล์ `supabase_setup.sql` ในโปรเจกต์
2. **คัดลอกทั้งไฟล์** (Cmd+A / Ctrl+A → Cmd+C / Ctrl+C)
3. วางใน SQL Editor
4. คลิก **"Run"** (ปุ่งสีเขียวมุมล่างขวา) หรือกด `Cmd+Enter` / `Ctrl+Enter`
5. รอสักครู่ (อาจใช้เวลา 5-15 วินาที)
6. ตรวจสอบผลลัพธ์:
   - ✅ สำเร็จ: เห็น "Success. No rows returned" หรือไม่มี error
   - ❌ ล้มเหลว: มี error message สีแดง — ดู [Troubleshooting](#troubleshooting)

### 3. ทำซ้ำได้

- รันซ้ำได้ตามต้องการ — ถ้ามี column/function ใหม่ในเวอร์ชันใหม่ จะถูกเพิ่มให้
- ไม่ลบข้อมูลเก่า (idempotent)
- ถ้ามี column เดิมอยู่แล้ว จะข้าม

---

## ตั้งค่า Environment Variables

### 1. สร้างไฟล์ `.env` ใน root ของโปรเจกต์

```bash
# macOS / Linux
cp .env.example .env

# Windows (PowerShell)
Copy-Item .env.example .env
```

### 2. แก้ไขค่าใน `.env`

```env
# Supabase Project URL — looks like https://xxxxxxxxxxxx.supabase.co
VITE_SUPABASE_URL=https://your-project-ref.supabase.co

# Anon / public key — the long "eyJ..." JWT labeled "anon public"
# Safe to expose to the browser (RLS protects your data)
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

> 🔑 **หา key ได้ที่ไหน:** Supabase Dashboard → Project Settings (⚙️) → API

### 3. ตรวจสอบว่า `.env` ถูก ignore ใน git

ควรมี `.env` ใน `.gitignore` (โปรเจกต์นี้ ignore ไว้แล้ว — ห้าม commit key ขึ้น repo!)

---

## Promote Admin คนแรก

> ⚠️ **ขั้นตอนนี้สำคัญ** — ต้องทำหลังจาก user คนแรกสมัครสมาชิก เพราะ trigger `svgbox_on_auth_user_created` จะสร้าง profile ให้อัตโนมัติ แต่ role จะเป็น `user` เสมอ

### 1. หา User ID

1. ไปที่ Supabase Dashboard → **Authentication** → **Users**
2. หาคนที่จะให้เป็น admin → คลิกเข้าไป
3. คัดลอก **User UID** (UUID ยาว ๆ)

### 2. รัน SQL Promote

1. ไปที่ **SQL Editor** → **New query**
2. พิมพ์ (แทนที่ `<paste-user-uuid-here>` ด้วย UUID ที่คัดลอกมา):

```sql
UPDATE svgbox_profiles
SET role = 'admin'
WHERE id = '<paste-user-uuid-here>';
```

3. คลิก **Run**
4. ตรวจสอบ: ต้องเห็น "Success. 1 row affected"

### 3. ทางเลือก: ใช้ Comment ใน supabase_setup.sql

ที่ท้ายไฟล์ `supabase_setup.sql` มี snippet พร้อมใช้:

```sql
-- ยกเลิก comment และแทนที่ UUID
-- UPDATE svgbox_profiles
--   SET role = 'admin'
--   WHERE id = '<paste-user-uuid-here>';
```

---

## ตรวจสอบการตั้งค่า

### 1. ตรวจสอบ Tables

SQL Editor → New query:

```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name LIKE 'svgbox_%'
ORDER BY table_name;
```

**ผลที่คาดหวัง:** 5 tables (`svgbox_assets`, `svgbox_collection_items`, `svgbox_collections`, `svgbox_favorites`, `svgbox_profiles`)

### 2. ตรวจสอบ Functions

```sql
SELECT routine_name
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name LIKE 'svgbox_%'
ORDER BY routine_name;
```

**ผลที่คาดหวัง:** 11 functions

### 3. ตรวจสอบ RLS Policies

```sql
SELECT tablename, policyname, cmd
FROM pg_policies
WHERE tablename LIKE 'svgbox_%'
ORDER BY tablename, policyname;
```

**ผลที่คาดหวัง:** 14 policies

### 4. ตรวจสอบ Columns สำคัญ

```sql
-- ตรวจว่ามี columns ใหม่ (status, is_private)
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'svgbox_assets'
  AND column_name IN ('status', 'is_private');
```

**ผลที่คาดหวัง:** 2 rows

### 5. ตรวจสอบ Admin User

```sql
-- ดูจำนวน admin + user
SELECT
  (SELECT COUNT(*) FROM svgbox_profiles WHERE role = 'admin') AS admins,
  (SELECT COUNT(*) FROM svgbox_profiles) AS total_users;
```

---

## รันแอป

```bash
# ติดตั้ง dependencies (ถ้ายังไม่ได้ทำ)
npm install

# Development server
npm run dev

# Build สำหรับ production
npm run build
```

### ทดสอบการทำงาน

1. เปิด [http://localhost:5173](http://localhost:5173)
2. **สมัครสมาชิก** ด้วย email + password
3. ตรวจสอบใน Supabase → **Authentication** → **Users** ว่ามี user ใหม่
4. ตรวจสอบใน **Table Editor** → `svgbox_profiles` ว่ามี row ใหม่ (role = 'user')
5. **Login** เข้าแอป ทดสอบ:
   - อัปโหลด SVG → ดูใน `svgbox_assets` ว่า row ใหม่ status = 'pending'
   - ดู SVG ของตัวเอง → status badge แสดง "Pending"

### ทดสอบ Admin

1. Login ด้วย user ที่ promote เป็น admin
2. ไปที่ `/admin` (admin panel)
3. ตรวจสอบ:
   - Tab "Users" → เห็นรายชื่อ user
   - Tab "All SVGs" → เห็น SVG pending
   - กด Approve / Reject / Toggle Public-Private → ทำงาน

---

## เมื่อย้าย Supabase project ใหม่

> เคสนี้: ต้องการเริ่มฐานข้อมูลใหม่ทั้งหมด (ข้อมูลเก่าไม่เอา)

### Checklist

- [ ] **Backup ข้อมูลเก่า** (ถ้าต้องการเก็บไว้) — ดู [วิธี backup](#วิธี-backup)
- [ ] **Export users list** (ถ้าต้องการเก็บ) — Supabase Dashboard → Authentication → Users → Export
- [ ] สร้าง Supabase project ใหม่
- [ ] ดึง API keys ใหม่
- [ ] รัน `supabase_setup.sql` ใน project ใหม่
- [ ] อัปเดต `.env` ด้วย key ใหม่
- [ ] Promote admin ใหม่ (ต้องสมัคร user ใหม่ก่อน)
- [ ] ทดสอบ login + อัปโหลด SVG
- [ ] Deploy (ถ้าใช้ Vercel/Netlify) → อัปเดต env vars ใน hosting platform

### วิธี Backup

```bash
# ใช้ pg_dump (ผ่าน Supabase connection string)
PGPASSWORD='<db_password>' pg_dump "postgresql://postgres:<db_password>@db.<project_ref>.supabase.co:5432/postgres" -Fc -f svgbox_backup.dump

# หรือใช้ Supabase Dashboard → Database → Backups (ถ้าใช้ paid plan)
```

### Deploy Env Vars

**Vercel:**
1. Project → Settings → Environment Variables
2. เพิ่ม `VITE_SUPABASE_URL` และ `VITE_SUPABASE_ANON_KEY`
3. Redeploy

**Netlify:**
1. Site settings → Build & deploy → Environment
2. เพิ่ม env vars เดียวกัน
3. Trigger deploy

---

## Troubleshooting

### ❌ Error: "ERROR: 42703: column 'is_private' of relation 'svgbox_assets' does not exist"

**สาเหตุ:** ไฟล์เก่าที่เคยรัน มี comment `COMMENT ON COLUMN` รันก่อน `ALTER TABLE ADD COLUMN`

**แก้:** ใช้ไฟล์ `supabase_setup.sql` เวอร์ชันล่าสุด (มีการแก้แล้ว — comment อยู่ใน DO block ที่เช็คก่อน)

### ❌ Error: "ERROR: 23505: duplicate key value violates unique constraint"

**สาเหตุ:** พยายาม promote user เป็น admin ซ้ำ หรือมี username ซ้ำ

**แก้:** ใช้ `ON CONFLICT` clause หรือตรวจสอบข้อมูลก่อน

### ❌ Error: "permission denied for table svgbox_profiles"

**สาเหตุ:** RLS policy block การเข้าถึง — อาจเป็นเพราะ user ยังไม่ได้ login

**แก้:** ตรวจสอบว่า login แล้ว และ JWT token ถูกส่งไปกับ request

### ❌ Login แล้ว แต่ role ไม่ใช่ admin

**สาเหตุ:** ลืม promote user เป็น admin หลังสมัคร

**แก้:** รัน SQL promote ใน [Promote Admin คนแรก](#promote-admin-คนแรก)

### ❌ หน้าแอปโหลดไม่ได้ / ขึ้น error

**ตรวจสอบ:**
1. ไฟล์ `.env` มี key ครบและถูกต้อง
2. Restart dev server (Vite ไม่ hot-reload env vars)
3. เปิด Browser DevTools → Console ดู error
4. ตรวจว่า Supabase project ยังไม่ถูก pause (free tier จะ pause หลังไม่ใช้งาน 7 วัน)

### ❌ "supabaseUrl is required" error

**สาเหตุ:** ไฟล์ `.env` ไม่มี หรือมีค่าผิด

**แก้:** ตรวจสอบ:
```bash
# ตรวจว่าไฟล์ .env มีอยู่
ls -la .env

# ดูเนื้อหา
cat .env
```

ต้องมีบรรทัด `VITE_SUPABASE_URL=...` และ `VITE_SUPABASE_ANON_KEY=...` ครบ

### ❌ Build สำเร็จ แต่ production ใช้งานไม่ได้

**ตรวจสอบ:**
1. Env vars ใน hosting platform ถูกต้อง
2. ไม่มี key ที่ขึ้นต้นด้วย `service_role` ใน env (ต้องใช้ `anon` เท่านั้น)
3. Supabase project URL ไม่มี trailing slash

---

## 📝 สรุป Quick Start

```bash
# 1. ติดตั้ง dependencies
npm install

# 2. สร้าง .env
cp .env.example .env
# แก้ค่า VITE_SUPABASE_URL และ VITE_SUPABASE_ANON_KEY

# 3. รัน supabase_setup.sql ใน Supabase SQL Editor

# 4. สมัคร user แรก + promote เป็น admin
# ใน SQL Editor:
# UPDATE svgbox_profiles SET role = 'admin' WHERE id = '<user-uuid>';

# 5. รันแอป
npm run dev
```

เสร็จแล้ว! 🎉
