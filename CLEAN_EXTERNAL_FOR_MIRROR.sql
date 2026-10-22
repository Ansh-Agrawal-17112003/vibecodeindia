-- ============================================================
-- Make the EXTERNAL Supabase a pure passive mirror.
-- Run this in your EXTERNAL Supabase SQL Editor.
--
-- What it does:
--   1. Drops ALL foreign key constraints in public schema
--      (so rows can arrive in any order, and FKs to auth.users
--       — which lives only on Lovable Cloud — don't blow up).
--   2. Drops ALL triggers on mirrored tables (except system
--      constraint triggers) so business logic like "OG spots
--      are full" doesn't block mirror upserts.
--   3. Truncates mirror_outbox on external (leftover garbage
--      from the earlier bug — 9k+ orphan rows).
--
-- Safe to re-run. After this the mirror will just accept
-- whatever Lovable Cloud sends.
-- ============================================================

do $$
declare
  r record;
  mirrored_tables text[] := array[
    'ai_tools','bug_reports','builder_details','builder_levels',
    'communities','community_channels','community_invites','community_members',
    'community_payment_requests','companies','conversations',
    'follows','founder_emails','job_applications','jobs',
    'messages','notifications','og_claim_stats','og_members','og_waitlist',
    'platform_settings','post_bookmarks','post_comments','post_likes',
    'post_reactions','post_reports','posts','profiles','projects',
    'prompts','reviews','saved_jobs','services',
    'subscription_requests','subscriptions','templates','upvotes',
    'user_roles','vibecoin_redemptions','vibecoin_transactions',
    'workflows','xp_transactions','early_access_signups'
  ];
begin
  -- 1) Drop every public foreign key constraint.
  --    The external DB is only a replica target, so public-schema FKs
  --    must not block inserts just because rows arrive out of order or
  --    auth.users is not mirrored there.
  for r in
    select conrelid::regclass::text as tbl, conname
    from pg_constraint
    where contype = 'f'
      and connamespace = 'public'::regnamespace
      and conrelid::regclass::text <> 'public.mirror_outbox'
  loop
    execute format('alter table %s drop constraint %I', r.tbl, r.conname);
    raise notice 'dropped FK % on %', r.conname, r.tbl;
  end loop;

  -- 2) Drop all user-defined triggers on mirrored tables
  for r in
    select event_object_schema as sch, event_object_table as tbl, trigger_name
    from information_schema.triggers
    where event_object_schema = 'public'
      and event_object_table = any(mirrored_tables)
    group by 1,2,3
  loop
    execute format('drop trigger if exists %I on %I.%I', r.trigger_name, r.sch, r.tbl);
    raise notice 'dropped trigger % on %.%', r.trigger_name, r.sch, r.tbl;
  end loop;
end $$;

-- 3) Wipe the orphan queue on external (harmless leftover)
truncate table public.mirror_outbox;

-- Verify: should return 0 FKs and 0 user-defined triggers
select 'remaining_fks' as k, count(*) as n
from pg_constraint
where contype='f'
  and connamespace='public'::regnamespace
  and conrelid::regclass::text <> 'public.mirror_outbox'
union all
select 'remaining_triggers', count(*)
from information_schema.triggers
where event_object_schema='public'
  and trigger_name not like 'RI_ConstraintTrigger_%';

-- If remaining_fks is still not 0, this lists exactly what is left.
select conrelid::regclass::text as table_name, conname as fk_name
from pg_constraint
where contype='f'
  and connamespace='public'::regnamespace
  and conrelid::regclass::text <> 'public.mirror_outbox'
order by 1, 2;
