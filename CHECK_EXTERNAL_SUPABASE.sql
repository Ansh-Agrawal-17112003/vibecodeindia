-- ============================================================
-- VibeCoder External Supabase — Sync Verification (single result)
-- Paste into external Supabase SQL Editor and Run.
-- Returns ONE table with counts + missing-tables info.
-- ============================================================

with expected(t) as (values
  ('ai_tools'),('bug_reports'),('builder_details'),('builder_levels'),
  ('communities'),('community_channels'),('community_invites'),('community_members'),
  ('community_payment_requests'),('companies'),('conversations'),
  ('follows'),('founder_emails'),('job_applications'),('jobs'),
  ('messages'),('notifications'),('og_claim_stats'),('og_members'),('og_waitlist'),
  ('platform_settings'),('post_bookmarks'),('post_comments'),('post_likes'),
  ('post_reactions'),('post_reports'),('posts'),('profiles'),('projects'),
  ('prompts'),('reviews'),('saved_jobs'),('services'),
  ('subscription_requests'),('subscriptions'),('templates'),('upvotes'),
  ('user_roles'),('vibecoin_redemptions'),('vibecoin_transactions'),
  ('workflows'),('xp_transactions')
),
present as (
  select e.t
  from expected e
  where exists (
    select 1 from pg_tables p
    where p.schemaname='public' and p.tablename=e.t
  )
),
counts as (
  select t, (xpath('/row/c/text()',
              query_to_xml(format('select count(*) as c from public.%I', t),
                           true, false, '')))[1]::text::bigint as row_count
  from present
)
select
  e.t as table_name,
  case when p.t is null then 'MISSING' else 'ok' end as status,
  coalesce(c.row_count, 0) as row_count
from expected e
left join present p on p.t = e.t
left join counts  c on c.t = e.t
order by
  case when p.t is null then 0 else 1 end,  -- missing tables first
  e.t;
