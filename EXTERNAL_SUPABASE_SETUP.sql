-- ============================================================
-- VibeCoder External Supabase Bootstrap
-- Run this in your external Supabase SQL editor
-- ============================================================

-- ============= ENUMS =============
DO $$ BEGIN CREATE TYPE public.app_role AS ENUM ('builder', 'hirer', 'admin'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE public.application_status AS ENUM ('applied', 'reviewed', 'shortlisted', 'rejected', 'hired'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE public.availability_status AS ENUM ('available', 'open_to_work', 'unavailable'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE public.builder_type AS ENUM ('freelancer', 'agency', 'student', 'founder'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE public.experience_level AS ENUM ('junior', 'mid', 'senior', 'lead'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE public.job_status AS ENUM ('active', 'closed'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE public.job_type AS ENUM ('full-time', 'part-time', 'freelance', 'internship'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE public.remote_type AS ENUM ('remote', 'hybrid', 'onsite'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE public.upvote_target AS ENUM ('project', 'prompt', 'workflow'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ============= TABLES =============
-- Table: bug_reports
CREATE TABLE public."bug_reports" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "reporter_id" uuid,
  "title" text NOT NULL,
  "description" text NOT NULL,
  "page_url" text,
  "user_agent" text,
  "status" text NOT NULL DEFAULT 'open'::text,
  "created_at" timestamp with time zone NOT NULL DEFAULT now()
);

-- Table: builder_details
CREATE TABLE public."builder_details" (
  "profile_id" uuid NOT NULL,
  "title" text,
  "skills" text[] NOT NULL DEFAULT '{}'::text[],
  "ai_tools" text[] NOT NULL DEFAULT '{}'::text[],
  "github_url" text,
  "linkedin_url" text,
  "website_url" text,
  "experience_level" experience_level,
  "builder_type" builder_type,
  "verified" boolean NOT NULL DEFAULT false,
  "created_at" timestamp with time zone NOT NULL DEFAULT now()
);

-- Table: builder_levels
CREATE TABLE public."builder_levels" (
  "id" integer NOT NULL DEFAULT nextval('builder_levels_id_seq'::regclass),
  "name" text NOT NULL,
  "min_xp" integer NOT NULL,
  "max_xp" integer,
  "badge_emoji" text NOT NULL,
  "badge_color" text NOT NULL,
  "sort_order" integer NOT NULL
);

-- Table: communities
CREATE TABLE public."communities" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "slug" text NOT NULL,
  "name" text NOT NULL,
  "icon" text,
  "description" text NOT NULL,
  "category" text,
  "banner_url" text,
  "icon_url" text,
  "member_count" integer NOT NULL DEFAULT 0,
  "online_count" integer NOT NULL DEFAULT 0,
  "posts_this_week" integer NOT NULL DEFAULT 0,
  "hue" integer NOT NULL DEFAULT 200,
  "rules" text,
  "welcome_message" text,
  "privacy" text NOT NULL DEFAULT 'public'::text,
  "is_official" boolean NOT NULL DEFAULT false,
  "status" text NOT NULL DEFAULT 'approved'::text,
  "stream_channel_id" text,
  "created_by" uuid,
  "created_at" timestamp with time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp with time zone NOT NULL DEFAULT now(),
  "pricing_type" text NOT NULL DEFAULT 'free'::text,
  "price_inr" integer NOT NULL DEFAULT 0,
  "trial_days" integer NOT NULL DEFAULT 0
);

-- Table: community_channels
CREATE TABLE public."community_channels" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "community_id" uuid NOT NULL,
  "slug" text NOT NULL,
  "name" text NOT NULL,
  "description" text,
  "stream_channel_id" text NOT NULL,
  "position" integer NOT NULL DEFAULT 0,
  "created_at" timestamp with time zone NOT NULL DEFAULT now()
);

-- Table: community_invites
CREATE TABLE public."community_invites" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "community_id" uuid NOT NULL,
  "token" text NOT NULL,
  "created_by" uuid,
  "uses" integer NOT NULL DEFAULT 0,
  "max_uses" integer,
  "expires_at" timestamp with time zone,
  "created_at" timestamp with time zone NOT NULL DEFAULT now()
);

-- Table: community_members
CREATE TABLE public."community_members" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "community_id" uuid NOT NULL,
  "profile_id" uuid NOT NULL,
  "role" text NOT NULL DEFAULT 'member'::text,
  "joined_at" timestamp with time zone NOT NULL DEFAULT now(),
  "muted_until" timestamp with time zone,
  "banned" boolean NOT NULL DEFAULT false,
  "status" text NOT NULL DEFAULT 'active'::text,
  "paid_until" timestamp with time zone
);

-- Table: community_payment_requests
CREATE TABLE public."community_payment_requests" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "community_id" uuid NOT NULL,
  "profile_id" uuid NOT NULL,
  "amount_inr" integer NOT NULL,
  "transaction_reference" text NOT NULL,
  "screenshot_url" text,
  "status" text NOT NULL DEFAULT 'pending'::text,
  "reject_reason" text,
  "submitted_at" timestamp with time zone NOT NULL DEFAULT now(),
  "verified_at" timestamp with time zone,
  "verified_by" uuid,
  "created_at" timestamp with time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp with time zone NOT NULL DEFAULT now()
);

-- Table: companies
CREATE TABLE public."companies" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "owner_profile_id" uuid NOT NULL,
  "name" text NOT NULL,
  "logo_url" text,
  "website" text,
  "industry" text,
  "employee_count" text,
  "location" text,
  "description" text,
  "verified" boolean NOT NULL DEFAULT false,
  "created_at" timestamp with time zone NOT NULL DEFAULT now()
);

-- Table: conversations
CREATE TABLE public."conversations" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "user_a" uuid NOT NULL,
  "user_b" uuid NOT NULL,
  "last_message" text,
  "last_message_at" timestamp with time zone DEFAULT now(),
  "created_at" timestamp with time zone NOT NULL DEFAULT now()
);

-- Table: early_access_signups
CREATE TABLE public."early_access_signups" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "email" text NOT NULL,
  "source" text DEFAULT 'welcome_modal'::text,
  "created_at" timestamp with time zone NOT NULL DEFAULT now()
);

-- Table: follows
CREATE TABLE public."follows" (
  "follower_id" uuid NOT NULL,
  "following_id" uuid NOT NULL,
  "created_at" timestamp with time zone NOT NULL DEFAULT now()
);

-- Table: job_applications
CREATE TABLE public."job_applications" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "job_id" uuid NOT NULL,
  "applicant_id" uuid NOT NULL,
  "resume_url" text,
  "cover_note" text,
  "status" application_status NOT NULL DEFAULT 'applied'::application_status,
  "applied_at" timestamp with time zone NOT NULL DEFAULT now()
);

-- Table: jobs
CREATE TABLE public."jobs" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "posted_by" uuid NOT NULL,
  "company_id" uuid,
  "title" text NOT NULL,
  "description" text,
  "requirements" text[] NOT NULL DEFAULT '{}'::text[],
  "nice_to_have" text[] NOT NULL DEFAULT '{}'::text[],
  "job_type" job_type NOT NULL DEFAULT 'full-time'::job_type,
  "location" text,
  "remote_type" remote_type NOT NULL DEFAULT 'remote'::remote_type,
  "salary_min" integer,
  "salary_max" integer,
  "tools_required" text[] NOT NULL DEFAULT '{}'::text[],
  "experience_level" experience_level,
  "status" job_status NOT NULL DEFAULT 'active'::job_status,
  "created_at" timestamp with time zone NOT NULL DEFAULT now()
);

-- Table: messages
CREATE TABLE public."messages" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "conversation_id" uuid NOT NULL,
  "sender_id" uuid NOT NULL,
  "recipient_id" uuid NOT NULL,
  "body" text,
  "read_at" timestamp with time zone,
  "created_at" timestamp with time zone NOT NULL DEFAULT now(),
  "reply_to_id" uuid,
  "attachment_url" text,
  "attachment_type" text,
  "attachment_name" text
);

-- Table: notifications
CREATE TABLE public."notifications" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "user_id" uuid NOT NULL,
  "actor_id" uuid,
  "type" text NOT NULL,
  "title" text NOT NULL,
  "body" text,
  "link" text,
  "read_at" timestamp with time zone,
  "created_at" timestamp with time zone NOT NULL DEFAULT now()
);

-- Table: payment_otps
CREATE TABLE public."payment_otps" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "user_id" uuid NOT NULL,
  "purpose" text NOT NULL,
  "reference" text NOT NULL,
  "amount" numeric NOT NULL,
  "otp_code" text NOT NULL,
  "status" text NOT NULL DEFAULT 'pending'::text,
  "expires_at" timestamp with time zone NOT NULL,
  "verified_at" timestamp with time zone,
  "created_at" timestamp with time zone NOT NULL DEFAULT now()
);

-- Table: platform_settings
CREATE TABLE public."platform_settings" (
  "key" text NOT NULL,
  "value" text,
  "updated_at" timestamp with time zone NOT NULL DEFAULT now(),
  "updated_by" uuid
);

-- Table: profiles
CREATE TABLE public."profiles" (
  "id" uuid NOT NULL,
  "username" text,
  "display_name" text,
  "avatar_url" text,
  "banner_url" text,
  "bio" text,
  "location" text,
  "roles" text[] NOT NULL DEFAULT '{}'::text[],
  "availability_status" availability_status DEFAULT 'available'::availability_status,
  "follower_count" integer NOT NULL DEFAULT 0,
  "following_count" integer NOT NULL DEFAULT 0,
  "onboarded_at" timestamp with time zone,
  "created_at" timestamp with time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp with time zone NOT NULL DEFAULT now(),
  "total_xp" integer NOT NULL DEFAULT 0,
  "current_level" text NOT NULL DEFAULT 'Vibe Starter'::text,
  "vibecoin_balance" integer NOT NULL DEFAULT 0,
  "login_streak" integer NOT NULL DEFAULT 0,
  "longest_streak" integer NOT NULL DEFAULT 0,
  "last_login_date" date,
  "streak_badges" text[] NOT NULL DEFAULT '{}'::text[],
  "boosted_until" timestamp with time zone
);

-- Table: projects
CREATE TABLE public."projects" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "builder_id" uuid NOT NULL,
  "title" text NOT NULL,
  "cover_image_url" text,
  "problem_solved" text,
  "solution" text,
  "tools_used" text[] NOT NULL DEFAULT '{}'::text[],
  "industry" text,
  "live_demo_url" text,
  "github_url" text,
  "case_study" text,
  "tags" text[] NOT NULL DEFAULT '{}'::text[],
  "upvote_count" integer NOT NULL DEFAULT 0,
  "created_at" timestamp with time zone NOT NULL DEFAULT now(),
  "featured_until" timestamp with time zone
);

-- Table: reviews
CREATE TABLE public."reviews" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "reviewer_id" uuid NOT NULL,
  "reviewed_profile_id" uuid,
  "reviewed_service_id" uuid,
  "rating" integer NOT NULL,
  "comment" text,
  "created_at" timestamp with time zone NOT NULL DEFAULT now()
);

-- Table: saved_jobs
CREATE TABLE public."saved_jobs" (
  "profile_id" uuid NOT NULL,
  "job_id" uuid NOT NULL,
  "created_at" timestamp with time zone NOT NULL DEFAULT now()
);

-- Table: search_usage
CREATE TABLE public."search_usage" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "profile_id" uuid NOT NULL,
  "month_year" text NOT NULL,
  "search_count" integer NOT NULL DEFAULT 0,
  "created_at" timestamp with time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp with time zone NOT NULL DEFAULT now()
);

-- Table: services
CREATE TABLE public."services" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "builder_id" uuid NOT NULL,
  "title" text NOT NULL,
  "description" text,
  "cover_image_url" text,
  "category" text,
  "packages" jsonb NOT NULL DEFAULT '[]'::jsonb,
  "rating_avg" numeric NOT NULL DEFAULT 0,
  "created_at" timestamp with time zone NOT NULL DEFAULT now()
);

-- Table: subscription_requests
CREATE TABLE public."subscription_requests" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "profile_id" uuid NOT NULL,
  "requested_plan" text NOT NULL,
  "amount" integer NOT NULL,
  "transaction_reference" text,
  "payment_screenshot_url" text,
  "status" text NOT NULL DEFAULT 'pending'::text,
  "rejection_reason" text,
  "submitted_at" timestamp with time zone NOT NULL DEFAULT now(),
  "verified_at" timestamp with time zone,
  "verified_by" uuid
);

-- Table: subscriptions
CREATE TABLE public."subscriptions" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "profile_id" uuid NOT NULL,
  "plan" text NOT NULL DEFAULT 'free'::text,
  "status" text NOT NULL DEFAULT 'active'::text,
  "current_period_start" timestamp with time zone NOT NULL DEFAULT now(),
  "current_period_end" timestamp with time zone,
  "created_at" timestamp with time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp with time zone NOT NULL DEFAULT now()
);

-- Table: upvotes
CREATE TABLE public."upvotes" (
  "profile_id" uuid NOT NULL,
  "target_type" upvote_target NOT NULL,
  "target_id" uuid NOT NULL,
  "created_at" timestamp with time zone NOT NULL DEFAULT now()
);

-- Table: user_roles
CREATE TABLE public."user_roles" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "user_id" uuid NOT NULL,
  "role" app_role NOT NULL,
  "created_at" timestamp with time zone NOT NULL DEFAULT now()
);

-- Table: vibecoin_redemptions
CREATE TABLE public."vibecoin_redemptions" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "profile_id" uuid NOT NULL,
  "amount_coins" integer NOT NULL,
  "amount_inr" integer NOT NULL,
  "upi_id" text NOT NULL,
  "status" text NOT NULL DEFAULT 'pending'::text,
  "admin_note" text,
  "requested_at" timestamp with time zone NOT NULL DEFAULT now(),
  "paid_at" timestamp with time zone,
  "updated_at" timestamp with time zone NOT NULL DEFAULT now()
);

-- Table: vibecoin_transactions
CREATE TABLE public."vibecoin_transactions" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "profile_id" uuid NOT NULL,
  "type" text NOT NULL,
  "amount" integer NOT NULL,
  "reason" text NOT NULL,
  "reference_id" uuid,
  "created_at" timestamp with time zone NOT NULL DEFAULT now()
);

-- Table: xp_transactions
CREATE TABLE public."xp_transactions" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "profile_id" uuid NOT NULL,
  "action_type" text NOT NULL,
  "xp_earned" integer NOT NULL,
  "reference_id" uuid,
  "reference_type" text,
  "created_at" timestamp with time zone NOT NULL DEFAULT now()
);

-- ============= CONSTRAINTS =============
ALTER TABLE public."bug_reports" ADD CONSTRAINT "bug_reports_reporter_id_fkey" FOREIGN KEY (reporter_id) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public."bug_reports" ADD CONSTRAINT "bug_reports_pkey" PRIMARY KEY (id);
ALTER TABLE public."builder_details" ADD CONSTRAINT "builder_details_profile_id_fkey" FOREIGN KEY (profile_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE public."builder_details" ADD CONSTRAINT "builder_details_pkey" PRIMARY KEY (profile_id);
ALTER TABLE public."builder_levels" ADD CONSTRAINT "builder_levels_pkey" PRIMARY KEY (id);
ALTER TABLE public."builder_levels" ADD CONSTRAINT "builder_levels_name_key" UNIQUE (name);
ALTER TABLE public."communities" ADD CONSTRAINT "communities_privacy_check" CHECK ((privacy = ANY (ARRAY['public'::text, 'private'::text])));
ALTER TABLE public."communities" ADD CONSTRAINT "communities_pricing_type_check" CHECK ((pricing_type = ANY (ARRAY['free'::text, 'paid_monthly'::text, 'paid_onetime'::text])));
ALTER TABLE public."communities" ADD CONSTRAINT "communities_status_check" CHECK ((status = ANY (ARRAY['pending'::text, 'approved'::text, 'rejected'::text])));
ALTER TABLE public."communities" ADD CONSTRAINT "communities_created_by_fkey" FOREIGN KEY (created_by) REFERENCES profiles(id) ON DELETE SET NULL;
ALTER TABLE public."communities" ADD CONSTRAINT "communities_pkey" PRIMARY KEY (id);
ALTER TABLE public."communities" ADD CONSTRAINT "communities_slug_key" UNIQUE (slug);
ALTER TABLE public."community_channels" ADD CONSTRAINT "community_channels_community_id_fkey" FOREIGN KEY (community_id) REFERENCES communities(id) ON DELETE CASCADE;
ALTER TABLE public."community_channels" ADD CONSTRAINT "community_channels_pkey" PRIMARY KEY (id);
ALTER TABLE public."community_channels" ADD CONSTRAINT "community_channels_community_id_slug_key" UNIQUE (community_id, slug);
ALTER TABLE public."community_invites" ADD CONSTRAINT "community_invites_created_by_fkey" FOREIGN KEY (created_by) REFERENCES profiles(id) ON DELETE SET NULL;
ALTER TABLE public."community_invites" ADD CONSTRAINT "community_invites_community_id_fkey" FOREIGN KEY (community_id) REFERENCES communities(id) ON DELETE CASCADE;
ALTER TABLE public."community_invites" ADD CONSTRAINT "community_invites_pkey" PRIMARY KEY (id);
ALTER TABLE public."community_invites" ADD CONSTRAINT "community_invites_token_key" UNIQUE (token);
ALTER TABLE public."community_members" ADD CONSTRAINT "community_members_role_check" CHECK ((role = ANY (ARRAY['member'::text, 'contributor'::text, 'moderator'::text, 'admin'::text])));
ALTER TABLE public."community_members" ADD CONSTRAINT "community_members_status_check" CHECK ((status = ANY (ARRAY['active'::text, 'pending_payment'::text, 'suspended'::text])));
ALTER TABLE public."community_members" ADD CONSTRAINT "community_members_community_id_fkey" FOREIGN KEY (community_id) REFERENCES communities(id) ON DELETE CASCADE;
ALTER TABLE public."community_members" ADD CONSTRAINT "community_members_profile_id_fkey" FOREIGN KEY (profile_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE public."community_members" ADD CONSTRAINT "community_members_pkey" PRIMARY KEY (id);
ALTER TABLE public."community_members" ADD CONSTRAINT "community_members_community_id_profile_id_key" UNIQUE (community_id, profile_id);
ALTER TABLE public."community_payment_requests" ADD CONSTRAINT "community_payment_requests_status_check" CHECK ((status = ANY (ARRAY['pending'::text, 'verified'::text, 'rejected'::text])));
ALTER TABLE public."community_payment_requests" ADD CONSTRAINT "community_payment_requests_profile_id_fkey" FOREIGN KEY (profile_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE public."community_payment_requests" ADD CONSTRAINT "community_payment_requests_community_id_fkey" FOREIGN KEY (community_id) REFERENCES communities(id) ON DELETE CASCADE;
ALTER TABLE public."community_payment_requests" ADD CONSTRAINT "community_payment_requests_verified_by_fkey" FOREIGN KEY (verified_by) REFERENCES profiles(id) ON DELETE SET NULL;
ALTER TABLE public."community_payment_requests" ADD CONSTRAINT "community_payment_requests_pkey" PRIMARY KEY (id);
ALTER TABLE public."companies" ADD CONSTRAINT "companies_owner_profile_id_fkey" FOREIGN KEY (owner_profile_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE public."companies" ADD CONSTRAINT "companies_pkey" PRIMARY KEY (id);
ALTER TABLE public."conversations" ADD CONSTRAINT "conv_pair_order" CHECK ((user_a < user_b));
ALTER TABLE public."conversations" ADD CONSTRAINT "conversations_user_b_fkey" FOREIGN KEY (user_b) REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public."conversations" ADD CONSTRAINT "conversations_user_a_fkey" FOREIGN KEY (user_a) REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public."conversations" ADD CONSTRAINT "conversations_pkey" PRIMARY KEY (id);
ALTER TABLE public."conversations" ADD CONSTRAINT "conversations_user_a_user_b_key" UNIQUE (user_a, user_b);
ALTER TABLE public."early_access_signups" ADD CONSTRAINT "early_access_source_len" CHECK (((source IS NULL) OR (char_length(source) <= 64)));
ALTER TABLE public."early_access_signups" ADD CONSTRAINT "early_access_email_len" CHECK (((char_length(email) >= 5) AND (char_length(email) <= 255)));
ALTER TABLE public."early_access_signups" ADD CONSTRAINT "early_access_signups_pkey" PRIMARY KEY (id);
ALTER TABLE public."early_access_signups" ADD CONSTRAINT "early_access_signups_email_key" UNIQUE (email);
ALTER TABLE public."follows" ADD CONSTRAINT "follows_check" CHECK ((follower_id <> following_id));
ALTER TABLE public."follows" ADD CONSTRAINT "follows_following_id_fkey" FOREIGN KEY (following_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE public."follows" ADD CONSTRAINT "follows_follower_id_fkey" FOREIGN KEY (follower_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE public."follows" ADD CONSTRAINT "follows_pkey" PRIMARY KEY (follower_id, following_id);
ALTER TABLE public."job_applications" ADD CONSTRAINT "job_applications_job_id_fkey" FOREIGN KEY (job_id) REFERENCES jobs(id) ON DELETE CASCADE;
ALTER TABLE public."job_applications" ADD CONSTRAINT "job_applications_applicant_id_fkey" FOREIGN KEY (applicant_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE public."job_applications" ADD CONSTRAINT "job_applications_pkey" PRIMARY KEY (id);
ALTER TABLE public."job_applications" ADD CONSTRAINT "job_applications_job_id_applicant_id_key" UNIQUE (job_id, applicant_id);
ALTER TABLE public."jobs" ADD CONSTRAINT "jobs_company_id_fkey" FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE SET NULL;
ALTER TABLE public."jobs" ADD CONSTRAINT "jobs_posted_by_fkey" FOREIGN KEY (posted_by) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE public."jobs" ADD CONSTRAINT "jobs_pkey" PRIMARY KEY (id);
ALTER TABLE public."messages" ADD CONSTRAINT "messages_sender_id_fkey" FOREIGN KEY (sender_id) REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public."messages" ADD CONSTRAINT "messages_reply_to_id_fkey" FOREIGN KEY (reply_to_id) REFERENCES messages(id) ON DELETE SET NULL;
ALTER TABLE public."messages" ADD CONSTRAINT "messages_recipient_id_fkey" FOREIGN KEY (recipient_id) REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public."messages" ADD CONSTRAINT "messages_conversation_id_fkey" FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE;
ALTER TABLE public."messages" ADD CONSTRAINT "messages_pkey" PRIMARY KEY (id);
ALTER TABLE public."notifications" ADD CONSTRAINT "notifications_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public."notifications" ADD CONSTRAINT "notifications_actor_id_fkey" FOREIGN KEY (actor_id) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public."notifications" ADD CONSTRAINT "notifications_pkey" PRIMARY KEY (id);
ALTER TABLE public."payment_otps" ADD CONSTRAINT "payment_otps_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public."payment_otps" ADD CONSTRAINT "payment_otps_pkey" PRIMARY KEY (id);
ALTER TABLE public."platform_settings" ADD CONSTRAINT "platform_settings_updated_by_fkey" FOREIGN KEY (updated_by) REFERENCES profiles(id);
ALTER TABLE public."platform_settings" ADD CONSTRAINT "platform_settings_pkey" PRIMARY KEY (key);
ALTER TABLE public."profiles" ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public."profiles" ADD CONSTRAINT "profiles_pkey" PRIMARY KEY (id);
ALTER TABLE public."profiles" ADD CONSTRAINT "profiles_username_key" UNIQUE (username);
ALTER TABLE public."projects" ADD CONSTRAINT "projects_builder_id_fkey" FOREIGN KEY (builder_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE public."projects" ADD CONSTRAINT "projects_pkey" PRIMARY KEY (id);
ALTER TABLE public."reviews" ADD CONSTRAINT "reviews_rating_check" CHECK (((rating >= 1) AND (rating <= 5)));
ALTER TABLE public."reviews" ADD CONSTRAINT "reviews_check" CHECK (((reviewed_profile_id IS NOT NULL) OR (reviewed_service_id IS NOT NULL)));
ALTER TABLE public."reviews" ADD CONSTRAINT "reviews_check1" CHECK (((reviewer_id <> reviewed_profile_id) OR (reviewed_profile_id IS NULL)));
ALTER TABLE public."reviews" ADD CONSTRAINT "reviews_reviewer_id_fkey" FOREIGN KEY (reviewer_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE public."reviews" ADD CONSTRAINT "reviews_reviewed_profile_id_fkey" FOREIGN KEY (reviewed_profile_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE public."reviews" ADD CONSTRAINT "reviews_reviewed_service_id_fkey" FOREIGN KEY (reviewed_service_id) REFERENCES services(id) ON DELETE CASCADE;
ALTER TABLE public."reviews" ADD CONSTRAINT "reviews_pkey" PRIMARY KEY (id);
ALTER TABLE public."saved_jobs" ADD CONSTRAINT "saved_jobs_job_id_fkey" FOREIGN KEY (job_id) REFERENCES jobs(id) ON DELETE CASCADE;
ALTER TABLE public."saved_jobs" ADD CONSTRAINT "saved_jobs_profile_id_fkey" FOREIGN KEY (profile_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE public."saved_jobs" ADD CONSTRAINT "saved_jobs_pkey" PRIMARY KEY (profile_id, job_id);
ALTER TABLE public."search_usage" ADD CONSTRAINT "search_usage_profile_id_fkey" FOREIGN KEY (profile_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE public."search_usage" ADD CONSTRAINT "search_usage_pkey" PRIMARY KEY (id);
ALTER TABLE public."search_usage" ADD CONSTRAINT "search_usage_profile_id_month_year_key" UNIQUE (profile_id, month_year);
ALTER TABLE public."services" ADD CONSTRAINT "services_builder_id_fkey" FOREIGN KEY (builder_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE public."services" ADD CONSTRAINT "services_pkey" PRIMARY KEY (id);
ALTER TABLE public."subscription_requests" ADD CONSTRAINT "subscription_requests_requested_plan_check" CHECK ((requested_plan = ANY (ARRAY['pro'::text, 'business'::text])));
ALTER TABLE public."subscription_requests" ADD CONSTRAINT "subscription_requests_status_check" CHECK ((status = ANY (ARRAY['pending'::text, 'verified'::text, 'rejected'::text])));
ALTER TABLE public."subscription_requests" ADD CONSTRAINT "subscription_requests_verified_by_fkey" FOREIGN KEY (verified_by) REFERENCES profiles(id);
ALTER TABLE public."subscription_requests" ADD CONSTRAINT "subscription_requests_profile_id_fkey" FOREIGN KEY (profile_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE public."subscription_requests" ADD CONSTRAINT "subscription_requests_pkey" PRIMARY KEY (id);
ALTER TABLE public."subscriptions" ADD CONSTRAINT "subscriptions_plan_check" CHECK ((plan = ANY (ARRAY['free'::text, 'pro'::text, 'business'::text])));
ALTER TABLE public."subscriptions" ADD CONSTRAINT "subscriptions_status_check" CHECK ((status = ANY (ARRAY['active'::text, 'expired'::text, 'cancelled'::text])));
ALTER TABLE public."subscriptions" ADD CONSTRAINT "subscriptions_profile_id_fkey" FOREIGN KEY (profile_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE public."subscriptions" ADD CONSTRAINT "subscriptions_pkey" PRIMARY KEY (id);
ALTER TABLE public."subscriptions" ADD CONSTRAINT "subscriptions_profile_id_key" UNIQUE (profile_id);
ALTER TABLE public."upvotes" ADD CONSTRAINT "upvotes_profile_id_fkey" FOREIGN KEY (profile_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE public."upvotes" ADD CONSTRAINT "upvotes_pkey" PRIMARY KEY (profile_id, target_type, target_id);
ALTER TABLE public."user_roles" ADD CONSTRAINT "user_roles_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public."user_roles" ADD CONSTRAINT "user_roles_pkey" PRIMARY KEY (id);
ALTER TABLE public."user_roles" ADD CONSTRAINT "user_roles_user_id_role_key" UNIQUE (user_id, role);
ALTER TABLE public."vibecoin_redemptions" ADD CONSTRAINT "vibecoin_redemptions_amount_coins_check" CHECK ((amount_coins >= 500));
ALTER TABLE public."vibecoin_redemptions" ADD CONSTRAINT "vibecoin_redemptions_status_check" CHECK ((status = ANY (ARRAY['pending'::text, 'approved'::text, 'paid'::text, 'rejected'::text])));
ALTER TABLE public."vibecoin_redemptions" ADD CONSTRAINT "vibecoin_redemptions_profile_id_fkey" FOREIGN KEY (profile_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE public."vibecoin_redemptions" ADD CONSTRAINT "vibecoin_redemptions_pkey" PRIMARY KEY (id);
ALTER TABLE public."vibecoin_transactions" ADD CONSTRAINT "vibecoin_transactions_type_check" CHECK ((type = ANY (ARRAY['earned'::text, 'spent'::text, 'redeemed'::text])));
ALTER TABLE public."vibecoin_transactions" ADD CONSTRAINT "vibecoin_transactions_profile_id_fkey" FOREIGN KEY (profile_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE public."vibecoin_transactions" ADD CONSTRAINT "vibecoin_transactions_pkey" PRIMARY KEY (id);
ALTER TABLE public."xp_transactions" ADD CONSTRAINT "xp_transactions_profile_id_fkey" FOREIGN KEY (profile_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE public."xp_transactions" ADD CONSTRAINT "xp_transactions_pkey" PRIMARY KEY (id);

-- ============= INDEXES =============
CREATE INDEX idx_payreq_profile ON public.community_payment_requests USING btree (profile_id);
CREATE INDEX idx_payreq_status ON public.community_payment_requests USING btree (status, submitted_at DESC);
CREATE INDEX idx_messages_conv ON public.messages USING btree (conversation_id, created_at DESC);
CREATE INDEX idx_notifs_user ON public.notifications USING btree (user_id, created_at DESC);
CREATE UNIQUE INDEX reviews_reviewer_profile_unique ON public.reviews USING btree (reviewer_id, reviewed_profile_id) WHERE (reviewed_profile_id IS NOT NULL);
CREATE INDEX vc_tx_profile_idx ON public.vibecoin_transactions USING btree (profile_id, created_at DESC);
CREATE INDEX xp_tx_profile_idx ON public.xp_transactions USING btree (profile_id, created_at DESC);

-- ============= FUNCTIONS =============
CREATE OR REPLACE FUNCTION public.activate_subscription_on_verify()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF NEW.status = 'verified' AND (OLD.status IS DISTINCT FROM 'verified') THEN
    INSERT INTO public.subscriptions (profile_id, plan, status, current_period_start, current_period_end)
    VALUES (NEW.profile_id, NEW.requested_plan, 'active', now(), now() + INTERVAL '30 days')
    ON CONFLICT (profile_id) DO UPDATE
      SET plan = EXCLUDED.plan,
          status = 'active',
          current_period_start = now(),
          current_period_end = now() + INTERVAL '30 days',
          updated_at = now();
    NEW.verified_at = now();
  END IF;
  RETURN NEW;
END $function$
;
CREATE OR REPLACE FUNCTION public.after_message_insert()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  _sender_name TEXT;
BEGIN
  UPDATE public.conversations
    SET last_message = NEW.body, last_message_at = NEW.created_at
    WHERE id = NEW.conversation_id;

  SELECT display_name INTO _sender_name FROM public.profiles WHERE id = NEW.sender_id;
  INSERT INTO public.notifications(user_id, actor_id, type, title, body, link)
  VALUES (NEW.recipient_id, NEW.sender_id, 'message',
          COALESCE(_sender_name, 'Someone') || ' sent you a message',
          LEFT(NEW.body, 120), '/messages?c=' || NEW.conversation_id);
  RETURN NEW;
END $function$
;
CREATE OR REPLACE FUNCTION public.award_vibecoins(_type text, _amount integer, _reason text, _reference_id uuid DEFAULT NULL::uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  _uid uuid := auth.uid();
  _new_balance integer;
  _signed integer;
BEGIN
  IF _uid IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
  IF _type NOT IN ('earned','spent','redeemed') THEN RAISE EXCEPTION 'Invalid type'; END IF;
  IF _amount <= 0 THEN RAISE EXCEPTION 'Amount must be positive'; END IF;

  _signed := CASE WHEN _type = 'earned' THEN _amount ELSE -_amount END;

  UPDATE public.profiles
    SET vibecoin_balance = vibecoin_balance + _signed
    WHERE id = _uid
    RETURNING vibecoin_balance INTO _new_balance;

  IF _new_balance < 0 THEN
    RAISE EXCEPTION 'Insufficient VibeCoin balance';
  END IF;

  INSERT INTO public.vibecoin_transactions(profile_id, type, amount, reason, reference_id)
  VALUES (_uid, _type, _amount, _reason, _reference_id);

  RETURN _new_balance;
END $function$
;
CREATE OR REPLACE FUNCTION public.award_xp(_action_type text, _xp integer, _reference_id uuid DEFAULT NULL::uuid, _reference_type text DEFAULT NULL::text)
 RETURNS TABLE(new_total_xp integer, new_level text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  _uid uuid := auth.uid();
  _total integer;
  _level text;
BEGIN
  IF _uid IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
  IF _xp <= 0 THEN RAISE EXCEPTION 'XP must be positive'; END IF;

  INSERT INTO public.xp_transactions(profile_id, action_type, xp_earned, reference_id, reference_type)
  VALUES (_uid, _action_type, _xp, _reference_id, _reference_type);

  UPDATE public.profiles
    SET total_xp = total_xp + _xp
    WHERE id = _uid
    RETURNING total_xp INTO _total;

  SELECT name INTO _level FROM public.builder_levels
    WHERE min_xp <= _total AND (max_xp IS NULL OR max_xp >= _total)
    ORDER BY sort_order DESC LIMIT 1;

  UPDATE public.profiles SET current_level = _level WHERE id = _uid;

  RETURN QUERY SELECT _total, _level;
END $function$
;
CREATE OR REPLACE FUNCTION public.bump_community_member_count()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.communities SET member_count = member_count + 1 WHERE id = NEW.community_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.communities SET member_count = GREATEST(member_count - 1, 0) WHERE id = OLD.community_id;
  END IF;
  RETURN NULL;
END $function$
;
CREATE OR REPLACE FUNCTION public.bump_follow_counts()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.profiles SET follower_count = follower_count + 1 WHERE id = NEW.following_id;
    UPDATE public.profiles SET following_count = following_count + 1 WHERE id = NEW.follower_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.profiles SET follower_count = GREATEST(follower_count - 1,0) WHERE id = OLD.following_id;
    UPDATE public.profiles SET following_count = GREATEST(following_count - 1,0) WHERE id = OLD.follower_id;
  END IF;
  RETURN NULL;
END $function$
;
CREATE OR REPLACE FUNCTION public.bump_project_upvotes()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF TG_OP = 'INSERT' AND NEW.target_type = 'project' THEN
    UPDATE public.projects SET upvote_count = upvote_count + 1 WHERE id = NEW.target_id;
  ELSIF TG_OP = 'DELETE' AND OLD.target_type = 'project' THEN
    UPDATE public.projects SET upvote_count = GREATEST(upvote_count - 1,0) WHERE id = OLD.target_id;
  END IF;
  RETURN NULL;
END $function$
;
CREATE OR REPLACE FUNCTION public.check_daily_login()
 RETURNS TABLE(streak integer, xp_awarded integer, milestone text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  _uid uuid := auth.uid();
  _today date := (now() AT TIME ZONE 'Asia/Kolkata')::date;
  _last date;
  _streak integer;
  _longest integer;
  _badges text[];
  _milestone text := NULL;
  _bonus integer := 0;
BEGIN
  IF _uid IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;

  SELECT last_login_date, login_streak, longest_streak, streak_badges
    INTO _last, _streak, _longest, _badges
    FROM public.profiles WHERE id = _uid;

  IF _last = _today THEN
    RETURN QUERY SELECT _streak, 0, NULL::text; RETURN;
  ELSIF _last = _today - 1 THEN
    _streak := COALESCE(_streak, 0) + 1;
  ELSE
    _streak := 1;
  END IF;

  _longest := GREATEST(COALESCE(_longest, 0), _streak);

  IF _streak = 7 AND NOT ('Week Warrior' = ANY(_badges)) THEN
    _badges := _badges || 'Week Warrior'; _milestone := 'Week Warrior'; _bonus := 100;
  ELSIF _streak = 30 AND NOT ('Month Builder' = ANY(_badges)) THEN
    _badges := _badges || 'Month Builder'; _milestone := 'Month Builder'; _bonus := 500;
  ELSIF _streak = 100 AND NOT ('Centurion' = ANY(_badges)) THEN
    _badges := _badges || 'Centurion'; _milestone := 'Centurion'; _bonus := 1000;
  END IF;

  UPDATE public.profiles
    SET last_login_date = _today,
        login_streak = _streak,
        longest_streak = _longest,
        streak_badges = _badges,
        total_xp = total_xp + 25 + _bonus
    WHERE id = _uid;

  INSERT INTO public.xp_transactions(profile_id, action_type, xp_earned)
  VALUES (_uid, 'DAILY_LOGIN', 25);

  IF _bonus > 0 THEN
    INSERT INTO public.xp_transactions(profile_id, action_type, xp_earned)
    VALUES (_uid, 'STREAK_MILESTONE_' || _streak, _bonus);
  END IF;

  RETURN QUERY SELECT _streak, 25 + _bonus, _milestone;
END $function$
;
CREATE OR REPLACE FUNCTION public.get_community_invite(_token text)
 RETURNS TABLE(id uuid, community_id uuid, token text, uses integer, max_uses integer, expires_at timestamp with time zone, created_by uuid, created_at timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT id, community_id, token, uses, max_uses, expires_at, created_by, created_at
  FROM public.community_invites
  WHERE token = _token
  LIMIT 1;
$function$
;
CREATE OR REPLACE FUNCTION public.get_or_create_conversation(_other uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
DECLARE
  _me UUID := auth.uid();
  _a UUID; _b UUID; _id UUID;
BEGIN
  IF _me IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
  IF _me = _other THEN RAISE EXCEPTION 'Cannot message self'; END IF;
  IF _me < _other THEN _a := _me; _b := _other; ELSE _a := _other; _b := _me; END IF;
  SELECT id INTO _id FROM public.conversations WHERE user_a = _a AND user_b = _b;
  IF _id IS NULL THEN
    INSERT INTO public.conversations(user_a, user_b) VALUES (_a, _b) RETURNING id INTO _id;
  END IF;
  RETURN _id;
END $function$
;
CREATE OR REPLACE FUNCTION public.get_public_platform_settings()
 RETURNS TABLE(key text, value text)
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$
  SELECT key, value FROM public.platform_settings WHERE key IN ('free_search_limit');
$function$
;
CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  INSERT INTO public.profiles (id, display_name, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email,'@',1)),
    NEW.raw_user_meta_data->>'avatar_url'
  );
  RETURN NEW;
END $function$
;
CREATE OR REPLACE FUNCTION public.has_role(_user_id uuid, _role app_role)
 RETURNS boolean
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$
  SELECT EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = _user_id AND role = _role)
$function$
;
CREATE OR REPLACE FUNCTION public.increment_search_usage()
 RETURNS integer
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
DECLARE
  _uid UUID := auth.uid();
  _month TEXT := to_char(now(), 'YYYY-MM');
  _count INTEGER;
BEGIN
  IF _uid IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
  INSERT INTO public.search_usage (profile_id, month_year, search_count)
  VALUES (_uid, _month, 1)
  ON CONFLICT (profile_id, month_year) DO UPDATE
    SET search_count = public.search_usage.search_count + 1,
        updated_at = now()
  RETURNING search_count INTO _count;
  RETURN _count;
END $function$
;
CREATE OR REPLACE FUNCTION public.touch_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
BEGIN NEW.updated_at = now(); RETURN NEW; END $function$
;

-- ============= TRIGGERS =============
CREATE TRIGGER trg_touch_communities BEFORE UPDATE ON public.communities FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
CREATE TRIGGER trg_bump_community_member_count AFTER INSERT OR DELETE ON public.community_members FOR EACH ROW EXECUTE FUNCTION bump_community_member_count();
CREATE TRIGGER trg_touch_payment_requests BEFORE UPDATE ON public.community_payment_requests FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
CREATE TRIGGER follows_count_trg AFTER INSERT OR DELETE ON public.follows FOR EACH ROW EXECUTE FUNCTION bump_follow_counts();
CREATE TRIGGER trg_after_message_insert AFTER INSERT ON public.messages FOR EACH ROW EXECUTE FUNCTION after_message_insert();
CREATE TRIGGER trg_search_usage_touch BEFORE UPDATE ON public.search_usage FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
CREATE TRIGGER trg_activate_subscription BEFORE UPDATE ON public.subscription_requests FOR EACH ROW EXECUTE FUNCTION activate_subscription_on_verify();
CREATE TRIGGER trg_subs_touch BEFORE UPDATE ON public.subscriptions FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
CREATE TRIGGER upvotes_count_trg AFTER INSERT OR DELETE ON public.upvotes FOR EACH ROW EXECUTE FUNCTION bump_project_upvotes();
CREATE TRIGGER trg_redemptions_updated BEFORE UPDATE ON public.vibecoin_redemptions FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

-- ============= RLS =============
ALTER TABLE public."bug_reports" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."builder_details" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."builder_levels" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."communities" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."community_channels" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."community_invites" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."community_members" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."community_payment_requests" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."companies" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."conversations" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."early_access_signups" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."follows" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."job_applications" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."jobs" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."messages" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."notifications" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."payment_otps" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."platform_settings" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."profiles" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."projects" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."reviews" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."saved_jobs" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."search_usage" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."services" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."subscription_requests" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."subscriptions" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."upvotes" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."user_roles" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."vibecoin_redemptions" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."vibecoin_transactions" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."xp_transactions" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Reporter can view own" ON public."bug_reports" AS PERMISSIVE FOR SELECT TO public USING (((auth.uid() = reporter_id) OR has_role(auth.uid(), 'admin'::app_role)));
CREATE POLICY "Users file bug reports" ON public."bug_reports" AS PERMISSIVE FOR INSERT TO public WITH CHECK ((((auth.uid() IS NULL) AND (reporter_id IS NULL)) OR ((auth.uid() IS NOT NULL) AND (reporter_id = auth.uid()))));
CREATE POLICY "Builder details public" ON public."builder_details" AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "Owner writes builder details" ON public."builder_details" AS PERMISSIVE FOR ALL TO authenticated USING ((auth.uid() = profile_id)) WITH CHECK ((auth.uid() = profile_id));
CREATE POLICY "Levels are public" ON public."builder_levels" AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "Anyone can view approved communities" ON public."communities" AS PERMISSIVE FOR SELECT TO public USING (((status = 'approved'::text) OR (created_by = auth.uid())));
CREATE POLICY "Authenticated users can create pending communities" ON public."communities" AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK (((auth.uid() = created_by) AND (status = 'pending'::text) AND (is_official = false)));
CREATE POLICY "Creator or platform admin can update community" ON public."communities" AS PERMISSIVE FOR UPDATE TO authenticated USING (((created_by = auth.uid()) OR has_role(auth.uid(), 'admin'::app_role))) WITH CHECK (((created_by = auth.uid()) OR has_role(auth.uid(), 'admin'::app_role)));
CREATE POLICY "Anyone can view community channels" ON public."community_channels" AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "Authenticated members can create invites" ON public."community_invites" AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK (((auth.uid() = created_by) AND (EXISTS ( SELECT 1
   FROM community_members cm
  WHERE ((cm.community_id = community_invites.community_id) AND (cm.profile_id = auth.uid()))))));
CREATE POLICY "Creators can delete own invites" ON public."community_invites" AS PERMISSIVE FOR DELETE TO authenticated USING (((auth.uid() = created_by) OR (EXISTS ( SELECT 1
   FROM communities c
  WHERE ((c.id = community_invites.community_id) AND (c.created_by = auth.uid()))))));
CREATE POLICY "Creators can view own invites" ON public."community_invites" AS PERMISSIVE FOR SELECT TO authenticated USING (((auth.uid() = created_by) OR (EXISTS ( SELECT 1
   FROM communities c
  WHERE ((c.id = community_invites.community_id) AND (c.created_by = auth.uid()))))));
CREATE POLICY "Anyone can view community members" ON public."community_members" AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "Community mods/admins can update roles" ON public."community_members" AS PERMISSIVE FOR UPDATE TO authenticated USING ((EXISTS ( SELECT 1
   FROM community_members cm
  WHERE ((cm.community_id = community_members.community_id) AND (cm.profile_id = auth.uid()) AND (cm.role = ANY (ARRAY['moderator'::text, 'admin'::text]))))));
CREATE POLICY "Users can join a community themselves" ON public."community_members" AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK ((auth.uid() = profile_id));
CREATE POLICY "Users can leave themselves" ON public."community_members" AS PERMISSIVE FOR DELETE TO authenticated USING ((auth.uid() = profile_id));
CREATE POLICY "Admins update payment requests" ON public."community_payment_requests" AS PERMISSIVE FOR UPDATE TO authenticated USING (has_role(auth.uid(), 'admin'::app_role)) WITH CHECK (has_role(auth.uid(), 'admin'::app_role));
CREATE POLICY "Users insert own payment requests" ON public."community_payment_requests" AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK (((profile_id = auth.uid()) AND (status = 'pending'::text)));
CREATE POLICY "Users read own payment requests" ON public."community_payment_requests" AS PERMISSIVE FOR SELECT TO authenticated USING (((profile_id = auth.uid()) OR has_role(auth.uid(), 'admin'::app_role)));
CREATE POLICY "Companies public" ON public."companies" AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "Owner writes company" ON public."companies" AS PERMISSIVE FOR ALL TO authenticated USING ((auth.uid() = owner_profile_id)) WITH CHECK ((auth.uid() = owner_profile_id));
CREATE POLICY "members create convs" ON public."conversations" AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK (((auth.uid() = user_a) OR (auth.uid() = user_b)));
CREATE POLICY "members read convs" ON public."conversations" AS PERMISSIVE FOR SELECT TO authenticated USING (((auth.uid() = user_a) OR (auth.uid() = user_b)));
CREATE POLICY "members update convs" ON public."conversations" AS PERMISSIVE FOR UPDATE TO authenticated USING (((auth.uid() = user_a) OR (auth.uid() = user_b)));
CREATE POLICY "admins can read" ON public."early_access_signups" AS PERMISSIVE FOR SELECT TO authenticated USING (has_role(auth.uid(), 'admin'::app_role));
CREATE POLICY "anyone can subscribe" ON public."early_access_signups" AS PERMISSIVE FOR INSERT TO anon, authenticated WITH CHECK (((email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'::text) AND (length(email) <= 255)));
CREATE POLICY "Follows public" ON public."follows" AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "User follows" ON public."follows" AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK ((auth.uid() = follower_id));
CREATE POLICY "User unfollows" ON public."follows" AS PERMISSIVE FOR DELETE TO authenticated USING ((auth.uid() = follower_id));
CREATE POLICY "Applicant inserts own app" ON public."job_applications" AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK ((auth.uid() = applicant_id));
CREATE POLICY "Applicant sees own apps" ON public."job_applications" AS PERMISSIVE FOR SELECT TO authenticated USING ((auth.uid() = applicant_id));
CREATE POLICY "Applicant updates own app" ON public."job_applications" AS PERMISSIVE FOR UPDATE TO authenticated USING ((auth.uid() = applicant_id)) WITH CHECK ((auth.uid() = applicant_id));
CREATE POLICY "Poster sees apps to their jobs" ON public."job_applications" AS PERMISSIVE FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM jobs j
  WHERE ((j.id = job_applications.job_id) AND (j.posted_by = auth.uid())))));
CREATE POLICY "Poster updates app status" ON public."job_applications" AS PERMISSIVE FOR UPDATE TO authenticated USING ((EXISTS ( SELECT 1
   FROM jobs j
  WHERE ((j.id = job_applications.job_id) AND (j.posted_by = auth.uid()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM jobs j
  WHERE ((j.id = job_applications.job_id) AND (j.posted_by = auth.uid())))));
CREATE POLICY "Active jobs public" ON public."jobs" AS PERMISSIVE FOR SELECT TO public USING (((status = 'active'::job_status) OR (auth.uid() = posted_by)));
CREATE POLICY "Hirers post jobs" ON public."jobs" AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK (((auth.uid() = posted_by) AND has_role(auth.uid(), 'hirer'::app_role)));
CREATE POLICY "Poster deletes job" ON public."jobs" AS PERMISSIVE FOR DELETE TO authenticated USING ((auth.uid() = posted_by));
CREATE POLICY "Poster updates job" ON public."jobs" AS PERMISSIVE FOR UPDATE TO authenticated USING ((auth.uid() = posted_by)) WITH CHECK ((auth.uid() = posted_by));
CREATE POLICY "members read msgs" ON public."messages" AS PERMISSIVE FOR SELECT TO authenticated USING (((auth.uid() = sender_id) OR (auth.uid() = recipient_id)));
CREATE POLICY "recipient mark read" ON public."messages" AS PERMISSIVE FOR UPDATE TO authenticated USING ((auth.uid() = recipient_id));
CREATE POLICY "sender insert msgs" ON public."messages" AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK ((auth.uid() = sender_id));
CREATE POLICY "own notifs delete" ON public."notifications" AS PERMISSIVE FOR DELETE TO authenticated USING ((auth.uid() = user_id));
CREATE POLICY "own notifs read" ON public."notifications" AS PERMISSIVE FOR SELECT TO authenticated USING ((auth.uid() = user_id));
CREATE POLICY "own notifs update" ON public."notifications" AS PERMISSIVE FOR UPDATE TO authenticated USING ((auth.uid() = user_id));
CREATE POLICY "own otps" ON public."payment_otps" AS PERMISSIVE FOR ALL TO authenticated USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));
CREATE POLICY "Admins read settings" ON public."platform_settings" AS PERMISSIVE FOR SELECT TO authenticated USING (has_role(auth.uid(), 'admin'::app_role));
CREATE POLICY "Admins write settings" ON public."platform_settings" AS PERMISSIVE FOR ALL TO authenticated USING (has_role(auth.uid(), 'admin'::app_role)) WITH CHECK (has_role(auth.uid(), 'admin'::app_role));
CREATE POLICY "Public can read allowlisted settings" ON public."platform_settings" AS PERMISSIVE FOR SELECT TO anon, authenticated USING ((key = 'free_search_limit'::text));
CREATE POLICY "Profiles are public" ON public."profiles" AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "Users insert own profile" ON public."profiles" AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK ((auth.uid() = id));
CREATE POLICY "Users update own profile" ON public."profiles" AS PERMISSIVE FOR UPDATE TO authenticated USING ((auth.uid() = id)) WITH CHECK ((auth.uid() = id));
CREATE POLICY "Owner writes project" ON public."projects" AS PERMISSIVE FOR ALL TO authenticated USING ((auth.uid() = builder_id)) WITH CHECK ((auth.uid() = builder_id));
CREATE POLICY "Projects public" ON public."projects" AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "Reviewer deletes review" ON public."reviews" AS PERMISSIVE FOR DELETE TO authenticated USING ((auth.uid() = reviewer_id));
CREATE POLICY "Reviewer edits review" ON public."reviews" AS PERMISSIVE FOR UPDATE TO authenticated USING ((auth.uid() = reviewer_id)) WITH CHECK ((auth.uid() = reviewer_id));
CREATE POLICY "Reviews public" ON public."reviews" AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "Users can create reviews" ON public."reviews" AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK (((auth.uid() = reviewer_id) AND ((reviewed_profile_id IS NULL) OR (reviewed_profile_id <> auth.uid()))));
CREATE POLICY "User saves jobs" ON public."saved_jobs" AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK ((auth.uid() = profile_id));
CREATE POLICY "User sees own saved jobs" ON public."saved_jobs" AS PERMISSIVE FOR SELECT TO authenticated USING ((auth.uid() = profile_id));
CREATE POLICY "User unsaves jobs" ON public."saved_jobs" AS PERMISSIVE FOR DELETE TO authenticated USING ((auth.uid() = profile_id));
CREATE POLICY "Users manage own usage" ON public."search_usage" AS PERMISSIVE FOR ALL TO authenticated USING ((auth.uid() = profile_id)) WITH CHECK ((auth.uid() = profile_id));
CREATE POLICY "Owner writes service" ON public."services" AS PERMISSIVE FOR ALL TO authenticated USING ((auth.uid() = builder_id)) WITH CHECK ((auth.uid() = builder_id));
CREATE POLICY "Services public" ON public."services" AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "Admins update requests" ON public."subscription_requests" AS PERMISSIVE FOR UPDATE TO authenticated USING (has_role(auth.uid(), 'admin'::app_role)) WITH CHECK (has_role(auth.uid(), 'admin'::app_role));
CREATE POLICY "Users create own requests" ON public."subscription_requests" AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK ((auth.uid() = profile_id));
CREATE POLICY "Users read own requests" ON public."subscription_requests" AS PERMISSIVE FOR SELECT TO authenticated USING (((auth.uid() = profile_id) OR has_role(auth.uid(), 'admin'::app_role)));
CREATE POLICY "Admins update subscriptions" ON public."subscriptions" AS PERMISSIVE FOR UPDATE TO authenticated USING (has_role(auth.uid(), 'admin'::app_role)) WITH CHECK (has_role(auth.uid(), 'admin'::app_role));
CREATE POLICY "Users insert own subscription" ON public."subscriptions" AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK ((auth.uid() = profile_id));
CREATE POLICY "Users read own subscription" ON public."subscriptions" AS PERMISSIVE FOR SELECT TO authenticated USING (((auth.uid() = profile_id) OR has_role(auth.uid(), 'admin'::app_role)));
CREATE POLICY "Upvotes public" ON public."upvotes" AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "User removes upvote" ON public."upvotes" AS PERMISSIVE FOR DELETE TO authenticated USING ((auth.uid() = profile_id));
CREATE POLICY "User upvotes" ON public."upvotes" AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK ((auth.uid() = profile_id));
CREATE POLICY "Admins can delete roles" ON public."user_roles" AS PERMISSIVE FOR DELETE TO authenticated USING (has_role(auth.uid(), 'admin'::app_role));
CREATE POLICY "Admins can insert roles" ON public."user_roles" AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK (has_role(auth.uid(), 'admin'::app_role));
CREATE POLICY "Admins can update roles" ON public."user_roles" AS PERMISSIVE FOR UPDATE TO authenticated USING (has_role(auth.uid(), 'admin'::app_role)) WITH CHECK (has_role(auth.uid(), 'admin'::app_role));
CREATE POLICY "Users see own roles" ON public."user_roles" AS PERMISSIVE FOR SELECT TO authenticated USING ((auth.uid() = user_id));
CREATE POLICY "Admins update redemptions" ON public."vibecoin_redemptions" AS PERMISSIVE FOR UPDATE TO authenticated USING (has_role(auth.uid(), 'admin'::app_role)) WITH CHECK (has_role(auth.uid(), 'admin'::app_role));
CREATE POLICY "Users create own redemptions" ON public."vibecoin_redemptions" AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK ((auth.uid() = profile_id));
CREATE POLICY "Users view own redemptions" ON public."vibecoin_redemptions" AS PERMISSIVE FOR SELECT TO authenticated USING ((auth.uid() = profile_id));
CREATE POLICY "Users insert own coins" ON public."vibecoin_transactions" AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK ((auth.uid() = profile_id));
CREATE POLICY "Users view own coins" ON public."vibecoin_transactions" AS PERMISSIVE FOR SELECT TO authenticated USING ((auth.uid() = profile_id));
CREATE POLICY "Users insert own xp" ON public."xp_transactions" AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK ((auth.uid() = profile_id));
CREATE POLICY "Users view own xp" ON public."xp_transactions" AS PERMISSIVE FOR SELECT TO authenticated USING ((auth.uid() = profile_id));

-- ============= GRANTS =============
GRANT SELECT, INSERT, UPDATE, DELETE ON public."bug_reports" TO authenticated;
GRANT ALL ON public."bug_reports" TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public."builder_details" TO authenticated;
GRANT ALL ON public."builder_details" TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public."builder_levels" TO authenticated;
GRANT ALL ON public."builder_levels" TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public."communities" TO authenticated;
GRANT ALL ON public."communities" TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public."community_channels" TO authenticated;
GRANT ALL ON public."community_channels" TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public."community_invites" TO authenticated;
GRANT ALL ON public."community_invites" TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public."community_members" TO authenticated;
GRANT ALL ON public."community_members" TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public."community_payment_requests" TO authenticated;
GRANT ALL ON public."community_payment_requests" TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public."companies" TO authenticated;
GRANT ALL ON public."companies" TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public."conversations" TO authenticated;
GRANT ALL ON public."conversations" TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public."early_access_signups" TO authenticated;
GRANT ALL ON public."early_access_signups" TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public."follows" TO authenticated;
GRANT ALL ON public."follows" TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public."job_applications" TO authenticated;
GRANT ALL ON public."job_applications" TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public."jobs" TO authenticated;
GRANT ALL ON public."jobs" TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public."messages" TO authenticated;
GRANT ALL ON public."messages" TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public."notifications" TO authenticated;
GRANT ALL ON public."notifications" TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public."payment_otps" TO authenticated;
GRANT ALL ON public."payment_otps" TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public."platform_settings" TO authenticated;
GRANT ALL ON public."platform_settings" TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public."profiles" TO authenticated;
GRANT ALL ON public."profiles" TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public."projects" TO authenticated;
GRANT ALL ON public."projects" TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public."reviews" TO authenticated;
GRANT ALL ON public."reviews" TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public."saved_jobs" TO authenticated;
GRANT ALL ON public."saved_jobs" TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public."search_usage" TO authenticated;
GRANT ALL ON public."search_usage" TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public."services" TO authenticated;
GRANT ALL ON public."services" TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public."subscription_requests" TO authenticated;
GRANT ALL ON public."subscription_requests" TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public."subscriptions" TO authenticated;
GRANT ALL ON public."subscriptions" TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public."upvotes" TO authenticated;
GRANT ALL ON public."upvotes" TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public."user_roles" TO authenticated;
GRANT ALL ON public."user_roles" TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public."vibecoin_redemptions" TO authenticated;
GRANT ALL ON public."vibecoin_redemptions" TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public."vibecoin_transactions" TO authenticated;
GRANT ALL ON public."vibecoin_transactions" TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public."xp_transactions" TO authenticated;
GRANT ALL ON public."xp_transactions" TO service_role;

-- ============= STORAGE BUCKETS =============
-- Run these in your external Supabase to recreate buckets
INSERT INTO storage.buckets (id, name, public) VALUES ('avatars','avatars',false) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('banners','banners',false) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('project-covers','project-covers',false) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('portfolio-images','portfolio-images',false) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('resumes','resumes',false) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('payment-screenshots','payment-screenshots',false) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('message-attachments','message-attachments',false) ON CONFLICT (id) DO NOTHING;

-- ============= AUTH TRIGGER =============
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
