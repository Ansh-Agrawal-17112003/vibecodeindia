# Migrate VibeCoder to Your External Supabase

This project is being switched from Lovable Cloud (managed Supabase) to your own external Supabase instance.

## What was changed in code

- `src/integrations/supabase/client.ts` — browser client now prefers `EXTERNAL_SUPABASE_URL` / `EXTERNAL_SUPABASE_ANON_KEY` (injected at build time via `vite.config.ts`), falls back to Lovable Cloud vars.
- `src/integrations/supabase/client.server.ts` — admin client prefers `EXTERNAL_SUPABASE_URL` / `EXTERNAL_SUPABASE_SERVICE_ROLE_KEY`.
- `src/integrations/supabase/auth-middleware.ts` — server auth middleware prefers the external URL + anon key.
- `vite.config.ts` — bakes the external URL + anon key into `import.meta.env` so the browser bundle can see them (Lovable reserves the `VITE_` secret-name prefix, so we bridge here).

All Supabase Auth flows (`supabase.auth.signInWithPassword`, `signUp`, `onAuthStateChange`, session persistence, password reset) already use `supabase-js`, so they'll route to your external project automatically.

## Secrets you added (via Lovable secure input)

- `EXTERNAL_SUPABASE_URL`
- `EXTERNAL_SUPABASE_ANON_KEY`
- `EXTERNAL_SUPABASE_SERVICE_ROLE_KEY`

## What you still need to do — one-time setup in your external Supabase

### 1. Run the schema bootstrap

Open your external Supabase project → **SQL Editor** → paste the contents of `EXTERNAL_SUPABASE_SETUP.sql` (in the project root) and run it. This creates:

- 9 enum types (`app_role`, `job_type`, `remote_type`, etc.)
- 31 tables (profiles, communities, jobs, projects, messages, XP/vibecoin ledgers, etc.)
- All primary keys, foreign keys, unique constraints, indexes
- All security-definer functions (`handle_new_user`, `has_role`, `award_xp`, `award_vibecoins`, `check_daily_login`, `get_or_create_conversation`, message/follow/upvote triggers, etc.)
- All triggers
- RLS enabled on every public table + all policies
- Storage buckets: avatars, banners, project-covers, portfolio-images, resumes, payment-screenshots, message-attachments
- The `on_auth_user_created` trigger on `auth.users` that auto-creates a `profiles` row

### 2. Seed reference data (optional)

`builder_levels` and `platform_settings` will be empty. Insert your own tiers or copy from the Lovable Cloud DB.

### 3. Enable Auth providers

- **Email/password** — enable in Authentication → Providers → Email.
- **Google OAuth** — you're no longer on the Lovable OAuth broker. In your Supabase dashboard:
  - Authentication → Providers → Google → enable.
  - Add your Google OAuth Client ID + Secret (from Google Cloud Console).
  - Add `<your-site>/auth/callback` to the redirect URLs.
  - Replace any `lovable.auth.signInWithOAuth("google", …)` call with `supabase.auth.signInWithOAuth({ provider: "google", options: { redirectTo: window.location.origin }})`.

### 4. Configure redirect URLs

Authentication → URL Configuration:
- **Site URL** → your production domain.
- **Redirect URLs** → add `http://localhost:8080/**` and any preview / production origins.

### 5. Storage bucket policies

The bootstrap only creates the buckets. You'll want RLS policies on `storage.objects` for each — e.g. authenticated users can upload to `avatars/{auth.uid()}/*`.

## Testing checklist

1. Sign up with email/password → check the `profiles` row is created automatically.
2. Sign in → confirm `check_daily_login` runs (XP transaction row added).
3. Send a direct message → confirm `messages` real-time works.
4. Create a project → confirm upvote counters increment.

## Rolling back

If something is off, remove or clear the three `EXTERNAL_SUPABASE_*` secrets — the client will automatically fall back to the original Lovable Cloud instance.
