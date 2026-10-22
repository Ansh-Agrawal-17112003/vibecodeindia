-- ============================================================
-- Is Google OAuth connected to this Supabase project?
-- Run in: External Supabase → SQL Editor
-- ============================================================
-- Note: provider client_id / client_secret live in GoTrue runtime
-- config, NOT in the database. SQL can only prove Google is
-- connected by finding users who signed in through it.
-- => Do ONE Google sign-in on the site first, then run this.
-- ============================================================

-- 1) One-line verdict
select
  case
    when exists (select 1 from auth.identities where provider = 'google')
      then '✅ GOOGLE IS CONNECTED — at least one user has signed in with Google'
    else '❌ NO GOOGLE SIGN-INS YET — provider may be disabled, or nobody has tried it'
  end as status;

-- 2) Provider breakdown (should list "google" once it works)
select
  provider,
  count(*)                as identities,
  count(distinct user_id) as users,
  min(created_at)         as first_seen,
  max(last_sign_in_at)    as last_used
from auth.identities
group by provider
order by identities desc;

-- 3) Most recent Google sign-ins
select
  u.email,
  i.created_at              as linked_at,
  i.last_sign_in_at         as last_google_signin,
  i.identity_data->>'email' as google_email,
  i.identity_data->>'name'  as google_name
from auth.identities i
join auth.users u on u.id = i.user_id
where i.provider = 'google'
order by i.last_sign_in_at desc nulls last
limit 10;

-- 4) Users with Google linked (via app metadata)
select
  email,
  raw_app_meta_data->>'provider'   as primary_provider,
  raw_app_meta_data->'providers'   as all_providers,
  created_at,
  last_sign_in_at
from auth.users
where (raw_app_meta_data->'providers') ? 'google'
order by last_sign_in_at desc nulls last
limit 10;
