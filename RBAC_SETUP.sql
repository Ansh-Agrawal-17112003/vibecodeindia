-- ============================================================================
-- VibeCode RBAC Setup — run this on your EXTERNAL Supabase project
-- After EXTERNAL_SUPABASE_SETUP.sql has already run.
-- Idempotent: safe to re-run.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. Extend profiles with role + moderation state
-- ---------------------------------------------------------------------------
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS role text NOT NULL DEFAULT 'user'
    CHECK (role IN ('super_admin','admin','user')),
  ADD COLUMN IF NOT EXISTS is_banned boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS is_suspended boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS suspended_until timestamptz,
  ADD COLUMN IF NOT EXISTS ban_reason text,
  ADD COLUMN IF NOT EXISTS last_active_at timestamptz;

CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);

-- ---------------------------------------------------------------------------
-- 2. Seed the two hardcoded Super Admins
-- ---------------------------------------------------------------------------
UPDATE public.profiles SET role = 'super_admin'
WHERE id IN (
  SELECT id FROM auth.users
  WHERE lower(email) IN (
    'jaiambeypropertydealers@gmail.com',
    'rishujaiswal1826@gmail.com'
  )
);

-- ---------------------------------------------------------------------------
-- 3. Helper functions (SECURITY DEFINER, no recursion — read profiles directly)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_user_role()
RETURNS text LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid()
$$;

CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'super_admin')
$$;

CREATE OR REPLACE FUNCTION public.is_admin_or_above()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('super_admin','admin'))
$$;

CREATE OR REPLACE FUNCTION public.is_active_user()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid()
      AND is_banned = false
      AND (is_suspended = false OR suspended_until IS NULL OR suspended_until < now())
  )
$$;

GRANT EXECUTE ON FUNCTION public.get_user_role() TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.is_super_admin() TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.is_admin_or_above() TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.is_active_user() TO authenticated, anon;

-- ---------------------------------------------------------------------------
-- 4. profiles RLS — add super_admin override + protect role column
-- ---------------------------------------------------------------------------
-- Trigger: block non-super-admin from changing their own role or ban fields
CREATE OR REPLACE FUNCTION public.enforce_profile_role_immutability()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF public.is_super_admin() THEN
    RETURN NEW;
  END IF;
  IF NEW.role IS DISTINCT FROM OLD.role
     OR NEW.is_banned IS DISTINCT FROM OLD.is_banned
     OR NEW.is_suspended IS DISTINCT FROM OLD.is_suspended
     OR NEW.suspended_until IS DISTINCT FROM OLD.suspended_until
     OR NEW.ban_reason IS DISTINCT FROM OLD.ban_reason THEN
    RAISE EXCEPTION 'Cannot modify role or moderation fields';
  END IF;
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_profiles_role_immutable ON public.profiles;
CREATE TRIGGER trg_profiles_role_immutable
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.enforce_profile_role_immutability();

DROP POLICY IF EXISTS "profiles_superadmin_all" ON public.profiles;
CREATE POLICY "profiles_superadmin_all" ON public.profiles
  FOR ALL TO authenticated
  USING (public.is_super_admin())
  WITH CHECK (public.is_super_admin());

-- ---------------------------------------------------------------------------
-- 5. posts table (referenced by spec — general social posts)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.posts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  author_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  body text NOT NULL,
  media_url text,
  visibility text NOT NULL DEFAULT 'public' CHECK (visibility IN ('public','followers','private')),
  like_count integer NOT NULL DEFAULT 0,
  comment_count integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT ON public.posts TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.posts TO authenticated;
GRANT ALL ON public.posts TO service_role;
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "posts_public_read" ON public.posts;
CREATE POLICY "posts_public_read" ON public.posts FOR SELECT
  USING (visibility = 'public' OR author_id = auth.uid() OR public.is_admin_or_above());

DROP POLICY IF EXISTS "posts_authenticated_insert" ON public.posts;
CREATE POLICY "posts_authenticated_insert" ON public.posts FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = author_id AND public.is_active_user());

DROP POLICY IF EXISTS "posts_own_update" ON public.posts;
CREATE POLICY "posts_own_update" ON public.posts FOR UPDATE TO authenticated
  USING (auth.uid() = author_id OR public.is_admin_or_above());

DROP POLICY IF EXISTS "posts_own_delete" ON public.posts;
CREATE POLICY "posts_own_delete" ON public.posts FOR DELETE TO authenticated
  USING (auth.uid() = author_id OR public.is_admin_or_above());

-- ---------------------------------------------------------------------------
-- 6. reports table
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  target_type text NOT NULL CHECK (target_type IN ('user','post','job','service','community','comment','project','prompt','workflow')),
  target_id uuid NOT NULL,
  reason text NOT NULL,
  description text,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','reviewed','resolved','dismissed')),
  resolved_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  resolved_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.reports TO authenticated;
GRANT ALL ON public.reports TO service_role;
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "reports_own_insert" ON public.reports;
CREATE POLICY "reports_own_insert" ON public.reports FOR INSERT TO authenticated
  WITH CHECK (reporter_id = auth.uid());

DROP POLICY IF EXISTS "reports_own_read" ON public.reports;
CREATE POLICY "reports_own_read" ON public.reports FOR SELECT TO authenticated
  USING (reporter_id = auth.uid() OR public.is_admin_or_above());

DROP POLICY IF EXISTS "reports_admin_update" ON public.reports;
CREATE POLICY "reports_admin_update" ON public.reports FOR UPDATE TO authenticated
  USING (public.is_admin_or_above());

CREATE INDEX IF NOT EXISTS idx_reports_status ON public.reports(status);
CREATE INDEX IF NOT EXISTS idx_reports_target ON public.reports(target_type, target_id);

-- ---------------------------------------------------------------------------
-- 7. Admin override policies on existing tables
--    (Additive — do not drop existing user-scoped policies)
-- ---------------------------------------------------------------------------
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['jobs','projects','services','communities','community_members','job_applications']
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS "admin_all_%1$s" ON public.%1$I', t);
    EXECUTE format(
      'CREATE POLICY "admin_all_%1$s" ON public.%1$I FOR ALL TO authenticated USING (public.is_admin_or_above()) WITH CHECK (public.is_admin_or_above())',
      t
    );
  END LOOP;
END $$;

-- Super admin can see all messages (moderation)
DROP POLICY IF EXISTS "messages_superadmin_read" ON public.messages;
CREATE POLICY "messages_superadmin_read" ON public.messages FOR SELECT TO authenticated
  USING (public.is_super_admin());

-- ---------------------------------------------------------------------------
-- Done. Verify:
--   SELECT id, display_name, role FROM public.profiles WHERE role != 'user';
-- ---------------------------------------------------------------------------
