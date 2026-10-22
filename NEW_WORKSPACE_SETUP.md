# New Workspace Setup — Connect to Existing External Supabase

Follow these steps in order. Total time: ~20 minutes.

---

## Prerequisites

- Your external Supabase project already has: schema, RLS policies, functions, triggers, Google OAuth configured.
- You know your external Supabase project ref (looks like `abcdefghijklmnop`).
- You have these values from external Supabase → **Project Settings → API**:
  - Project URL (e.g. `https://abcdefghijklmnop.supabase.co`)
  - `anon` / `publishable` key
  - `service_role` key (keep secret)

---

## Step 1 — Create the new Lovable project

1. Go to Lovable → create a new project in your target workspace.
2. **CRITICAL: Do NOT enable Lovable Cloud.** If prompted, decline.
   - If Cloud gets enabled, it locks in its own managed Supabase and overwrites `src/integrations/supabase/client.ts` and `.env`. You can't undo it.

---

## Step 2 — Connect a fresh GitHub repo

1. In the new project: Plus (+) → GitHub → Connect project → create a **new empty repo**.
2. Clone that new repo locally.
3. Clone your existing repo (this project) locally as well.

---

## Step 3 — Copy frontend files across

Copy **everything** from the existing repo into the new one, **except**:

**Skip (Lovable Cloud managed — will be regenerated / not needed):**
- `.env`
- `src/integrations/supabase/client.ts`
- `src/integrations/supabase/client.server.ts`
- `src/integrations/supabase/auth-middleware.ts`
- `src/integrations/supabase/auth-attacher.ts`
- `src/integrations/supabase/types.ts` (regenerate in Step 6)
- `src/integrations/lovable/` (Lovable Cloud OAuth broker — you'll use plain Supabase auth instead)
- `supabase/config.toml`
- `node_modules/`, `dist/`, `.lovable/`

**Also skip these migration-helper files (already applied to your external DB):**
- `EXTERNAL_SUPABASE_SETUP.sql`
- `CLEAN_EXTERNAL_FOR_MIRROR.sql`
- `CHECK_EXTERNAL_SUPABASE.sql`
- `CHECK_GOOGLE_AUTH.sql`
- `RBAC_SETUP.sql`
- `MIGRATE_TO_EXTERNAL_SUPABASE.md`

Commit and push to the new repo. Lovable will sync it in.

---

## Step 4 — Set environment variables in the new project

In the new Lovable project → Settings → Environment / Secrets, add:

| Name | Value | Scope |
|---|---|---|
| `VITE_SUPABASE_URL` | `https://<your-ref>.supabase.co` | client + server |
| `VITE_SUPABASE_PUBLISHABLE_KEY` | your anon key | client + server |
| `VITE_SUPABASE_PROJECT_ID` | `<your-ref>` | client + server |
| `SUPABASE_URL` | `https://<your-ref>.supabase.co` | server only |
| `SUPABASE_PUBLISHABLE_KEY` | your anon key | server only |
| `SUPABASE_SERVICE_ROLE_KEY` | your service role key | server only (secret) |
| `SUPABASE_PROJECT_ID` | `<your-ref>` | server only |

---

## Step 5 — Configure Supabase redirect URLs

In external Supabase → **Authentication → URL Configuration**:

- **Site URL:** your new production domain (or preview URL for now)
- **Redirect URLs:** add
  - `http://localhost:8080/**`
  - `https://<new-project-preview>.lovable.app/**`
  - `https://<your-production-domain>/**`
  - Any callback path you use, e.g. `/auth-callback`

---

## Step 6 — Regenerate Supabase types

Locally, with the Supabase CLI installed:

```bash
npx supabase gen types typescript --project-id <your-external-ref> > src/integrations/supabase/types.ts
```

Commit and push. This gives you accurate TypeScript types for every table.

---

## Step 7 — Replace the Supabase client files

Since you're not using Lovable Cloud, use plain Supabase clients. Create these:

**`src/integrations/supabase/client.ts`** (browser)

```ts
import { createClient } from '@supabase/supabase-js';
import type { Database } from './types';

export const supabase = createClient<Database>(
  import.meta.env.VITE_SUPABASE_URL!,
  import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY!,
  { auth: { persistSession: true, autoRefreshToken: true } }
);
```

**`src/integrations/supabase/client.server.ts`** (server, service role)

```ts
import { createClient } from '@supabase/supabase-js';
import type { Database } from './types';

export const supabaseAdmin = createClient<Database>(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!,
  { auth: { persistSession: false, autoRefreshToken: false } }
);
```

---

## Step 8 — Replace the Google sign-in call

Anywhere the code uses:

```ts
import { lovable } from '@/integrations/lovable';
await lovable.auth.signInWithOAuth('google', { redirect_uri: window.location.origin });
```

Replace with plain Supabase:

```ts
import { supabase } from '@/integrations/supabase/client';
await supabase.auth.signInWithOAuth({
  provider: 'google',
  options: { redirectTo: `${window.location.origin}/auth-callback` },
});
```

Delete `src/integrations/lovable/` and the `@lovable.dev/cloud-auth-js` dependency.

---

## Step 9 — Test

1. Open the new project's preview URL.
2. Sign in with Google → should redirect to Google → back to `/auth-callback` → land signed in.
3. Confirm your existing user account works (same DB, same users).
4. Load a page that reads data (profiles, feed, jobs) — should show existing data.

---

## Rollback

If anything is off, this project (the current one on Lovable Cloud) is untouched and still works. You can keep both running until the new one is fully verified, then point your custom domain at the new project.

---

## Do NOT

- Do not enable Lovable Cloud in the new project.
- Do not commit the `service_role` key — only set it as a server-side secret.
- Do not delete the external Supabase project during migration.
