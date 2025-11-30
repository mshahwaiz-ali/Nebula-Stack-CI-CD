------------------------------------------------------------
-- KortexSphere Multi-tenant Core (ks_dev)
------------------------------------------------------------

-- Run as postgres superuser:
--   psql -U postgres -f ks_core_master.sql

------------------------------------------------------------
-- 0) Ensure database ks_dev exists
------------------------------------------------------------

\connect ks_dev

------------------------------------------------------------
-- 1) Extensions
------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

------------------------------------------------------------
-- 2) Base RBAC roles (no-login templates)
------------------------------------------------------------
DO $$
BEGIN
   IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ks_admin') THEN
      CREATE ROLE ks_admin NOLOGIN;
   END IF;

   IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ks_writer') THEN
      CREATE ROLE ks_writer NOLOGIN;
   END IF;

   IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ks_readonly') THEN
      CREATE ROLE ks_readonly NOLOGIN;
   END IF;

   IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'backup_user') THEN
      CREATE ROLE backup_user NOLOGIN;
   END IF;
END$$;

------------------------------------------------------------
-- 3) Core tables
------------------------------------------------------------

-- Tenants: 1 row = 1 company (Azure, Amazon, etc.)
CREATE TABLE IF NOT EXISTS public.tenants (
    id         uuid PRIMARY KEY DEFAULT public.uuid_generate_v4(),
    name       text NOT NULL,
    code       text NOT NULL UNIQUE,    -- short code: 'azure', 'amazon'
    plan       text NOT NULL DEFAULT 'free',
    is_active  boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now()
);

-- App users belonging to a tenant (admin / writer / readonly)
CREATE TABLE IF NOT EXISTS public.app_users (
    id            uuid PRIMARY KEY DEFAULT public.uuid_generate_v4(),
    tenant_id     uuid NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    email         text NOT NULL,
    full_name     text,
    role          text NOT NULL CHECK (role IN ('admin','writer','readonly')),
    password      text NOT NULL,    -- sample only: 'admin' etc. (later: hash)
    is_active     boolean NOT NULL DEFAULT true,
    created_at    timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, email)
);

-- Projects per tenant (sample business data)
CREATE TABLE IF NOT EXISTS public.projects (
    id         uuid PRIMARY KEY DEFAULT public.uuid_generate_v4(),
    tenant_id  uuid NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    name       text NOT NULL,
    status     text NOT NULL DEFAULT 'draft',
    budget     numeric(12,2) NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now()
);

-- Optional migrations table
CREATE TABLE IF NOT EXISTS public.schema_migrations (
    version    text PRIMARY KEY,
    applied_at timestamptz NOT NULL DEFAULT now()
);

------------------------------------------------------------
-- 4) Row Level Security on core tables
------------------------------------------------------------

ALTER TABLE public.tenants       ENABLE ROW LEVEL SECURITY;
ALTER TABLE ONLY public.tenants  FORCE ROW LEVEL SECURITY;

ALTER TABLE public.app_users       ENABLE ROW LEVEL SECURITY;
ALTER TABLE ONLY public.app_users  FORCE ROW LEVEL SECURITY;

ALTER TABLE public.projects       ENABLE ROW LEVEL SECURITY;
ALTER TABLE ONLY public.projects  FORCE ROW LEVEL SECURITY;

------------------------------------------------------------
-- 5) GUC-based context helper
------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_user_context(_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    t_id   uuid;
    u_role text;
BEGIN
    SELECT tenant_id, role
      INTO t_id, u_role
    FROM app_users
    WHERE id = _user_id
      AND is_active = true;

    IF t_id IS NULL THEN
        RAISE EXCEPTION 'Invalid or inactive user ID %', _user_id;
    END IF;

    PERFORM set_config('app.tenant_id', t_id::text, false);
    PERFORM set_config('app.user_role', u_role, false);
END;
$$;

------------------------------------------------------------
-- 6) RLS Policies
------------------------------------------------------------

--------------------
-- TENANTS
--------------------
DO $$
BEGIN
  IF NOT EXISTS (
      SELECT 1 FROM pg_policies
      WHERE schemaname = 'public'
        AND tablename  = 'tenants'
        AND policyname = 'tenants_admin_all'
  ) THEN
    CREATE POLICY tenants_admin_all
      ON public.tenants
      TO ks_admin
      USING (true)
      WITH CHECK (true);
  END IF;
END$$;

DO $$
BEGIN
  IF NOT EXISTS (
      SELECT 1 FROM pg_policies
      WHERE schemaname = 'public'
        AND tablename  = 'tenants'
        AND policyname = 'tenants_per_tenant_read'
  ) THEN
    CREATE POLICY tenants_per_tenant_read
      ON public.tenants
      FOR SELECT
      TO ks_readonly, ks_writer
      USING (id::text = current_setting('app.tenant_id', true));
  END IF;
END$$;

--------------------
-- APP_USERS
--------------------
DO $$
BEGIN
  IF NOT EXISTS (
      SELECT 1 FROM pg_policies
      WHERE schemaname = 'public'
        AND tablename  = 'app_users'
        AND policyname = 'app_users_admin_all'
  ) THEN
    CREATE POLICY app_users_admin_all
      ON public.app_users
      TO ks_admin
      USING (true)
      WITH CHECK (true);
  END IF;
END$$;

DO $$
BEGIN
  IF NOT EXISTS (
      SELECT 1 FROM pg_policies
      WHERE schemaname = 'public'
        AND tablename  = 'app_users'
        AND policyname = 'app_users_per_tenant_read'
  ) THEN
    CREATE POLICY app_users_per_tenant_read
      ON public.app_users
      FOR SELECT
      TO ks_readonly, ks_writer
      USING (tenant_id::text = current_setting('app.tenant_id', true));
  END IF;
END$$;

DO $$
BEGIN
  IF NOT EXISTS (
      SELECT 1 FROM pg_policies
      WHERE schemaname = 'public'
        AND tablename  = 'app_users'
        AND policyname = 'app_users_per_tenant_insert'
  ) THEN
    CREATE POLICY app_users_per_tenant_insert
      ON public.app_users
      FOR INSERT
      TO ks_writer
      WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));
  END IF;
END$$;

DO $$
BEGIN
  IF NOT EXISTS (
      SELECT 1 FROM pg_policies
      WHERE schemaname = 'public'
        AND tablename  = 'app_users'
        AND policyname = 'app_users_per_tenant_update'
  ) THEN
    CREATE POLICY app_users_per_tenant_update
      ON public.app_users
      FOR UPDATE
      TO ks_writer
      USING (tenant_id::text = current_setting('app.tenant_id', true))
      WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));
  END IF;
END$$;

DO $$
BEGIN
  IF NOT EXISTS (
      SELECT 1 FROM pg_policies
      WHERE schemaname = 'public'
        AND tablename  = 'app_users'
        AND policyname = 'app_users_per_tenant_delete'
  ) THEN
    CREATE POLICY app_users_per_tenant_delete
      ON public.app_users
      FOR DELETE
      TO ks_writer
      USING (tenant_id::text = current_setting('app.tenant_id', true));
  END IF;
END$$;

--------------------
-- PROJECTS
--------------------
DO $$
BEGIN
  IF NOT EXISTS (
      SELECT 1 FROM pg_policies
      WHERE schemaname = 'public'
        AND tablename  = 'projects'
        AND policyname = 'projects_admin_all'
  ) THEN
    CREATE POLICY projects_admin_all
      ON public.projects
      TO ks_admin
      USING (true)
      WITH CHECK (true);
  END IF;
END$$;

-- READ
DO $$
BEGIN
  IF NOT EXISTS (
      SELECT 1 FROM pg_policies
      WHERE schemaname = 'public'
        AND tablename  = 'projects'
        AND policyname = 'projects_per_tenant_read'
  ) THEN
    CREATE POLICY projects_per_tenant_read
      ON public.projects
      FOR SELECT
      TO ks_readonly, ks_writer
      USING (tenant_id::text = current_setting('app.tenant_id', true));
  END IF;
END$$;

-- INSERT
DO $$
BEGIN
  IF NOT EXISTS (
      SELECT 1 FROM pg_policies
      WHERE schemaname = 'public'
        AND tablename  = 'projects'
        AND policyname = 'projects_per_tenant_insert'
  ) THEN
    CREATE POLICY projects_per_tenant_insert
      ON public.projects
      FOR INSERT
      TO ks_writer
      WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));
  END IF;
END$$;

-- UPDATE
DO $$
BEGIN
  IF NOT EXISTS (
      SELECT 1 FROM pg_policies
      WHERE schemaname = 'public'
        AND tablename  = 'projects'
        AND policyname = 'projects_per_tenant_update'
  ) THEN
    CREATE POLICY projects_per_tenant_update
      ON public.projects
      FOR UPDATE
      TO ks_writer
      USING (tenant_id::text = current_setting('app.tenant_id', true))
      WITH CHECK (tenant_id::text = current_setting('app.tenant_id', true));
  END IF;
END$$;

-- DELETE
DO $$
BEGIN
  IF NOT EXISTS (
      SELECT 1 FROM pg_policies
      WHERE schemaname = 'public'
        AND tablename  = 'projects'
        AND policyname = 'projects_per_tenant_delete'
  ) THEN
    CREATE POLICY projects_per_tenant_delete
      ON public.projects
      FOR DELETE
      TO ks_writer
      USING (tenant_id::text = current_setting('app.tenant_id', true));
  END IF;
END$$;

------------------------------------------------------------
-- 7) Privileges (GRANTs)
------------------------------------------------------------

GRANT USAGE ON SCHEMA public TO ks_readonly, ks_writer, ks_admin, backup_user;

GRANT SELECT ON TABLE public.tenants      TO backup_user;
GRANT SELECT, INSERT, UPDATE, DELETE      ON public.tenants TO ks_admin, ks_writer;
GRANT SELECT                              ON public.tenants TO ks_readonly;

GRANT SELECT ON TABLE public.app_users    TO backup_user;
GRANT SELECT, INSERT, UPDATE, DELETE      ON public.app_users TO ks_admin, ks_writer;
GRANT SELECT                              ON public.app_users TO ks_readonly;

GRANT SELECT ON TABLE public.projects     TO backup_user;
GRANT SELECT, INSERT, UPDATE, DELETE      ON public.projects TO ks_admin, ks_writer;
GRANT SELECT                              ON public.projects TO ks_readonly;

GRANT SELECT ON TABLE public.schema_migrations TO backup_user;
GRANT SELECT, INSERT, UPDATE, DELETE           ON public.schema_migrations TO ks_admin;

------------------------------------------------------------
-- 8) Tenant provisioning function
------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.provision_tenant(
    p_name text,
    p_code text,
    p_plan text DEFAULT 'pro'
)
RETURNS uuid
LANGUAGE plpgsql
AS $$
DECLARE
    v_tenant_id  uuid;
    v_code       text;
    v_admin_role text;
    v_writer_role text;
    v_read_role   text;
BEGIN
    v_code := lower(p_code);

    INSERT INTO public.tenants (name, code, plan)
    VALUES (p_name, v_code, p_plan)
    RETURNING id INTO v_tenant_id;

    v_admin_role  := v_code || '_admin';
    v_writer_role := v_code || '_writer';
    v_read_role   := v_code || '_readonly';

    -- Admin login role (inherits ks_admin privileges)
    EXECUTE format(
      'DO $b$ BEGIN
         IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = %L) THEN
           CREATE ROLE %I LOGIN PASSWORD %L IN ROLE ks_admin;
         END IF;
       END $b$;',
       v_admin_role, v_admin_role, 'admin'
    );

    -- Writer login role (inherits ks_writer)
    EXECUTE format(
      'DO $b$ BEGIN
         IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = %L) THEN
           CREATE ROLE %I LOGIN PASSWORD %L IN ROLE ks_writer;
         END IF;
       END $b$;',
       v_writer_role, v_writer_role, 'admin'
    );

    -- Readonly login role (inherits ks_readonly)
    EXECUTE format(
      'DO $b$ BEGIN
         IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = %L) THEN
           CREATE ROLE %I LOGIN PASSWORD %L IN ROLE ks_readonly;
         END IF;
       END $b$;',
       v_read_role, v_read_role, 'admin'
    );

    -- Default admin user row for HTML/API login
    INSERT INTO public.app_users (tenant_id, email, full_name, role, password)
    VALUES (
        v_tenant_id,
        v_code || '_admin@example.local',
        p_name || ' Admin',
        'admin',
        'admin'
    );

    RETURN v_tenant_id;
END;
$$;

------------------------------------------------------------
-- 9) Sample seed data (Azure + Amazon tenants)
------------------------------------------------------------

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.tenants WHERE code = 'azure') THEN
    PERFORM public.provision_tenant('Azure Corporation', 'azure');
  END IF;
END$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.tenants WHERE code = 'amazon') THEN
    PERFORM public.provision_tenant('Amazon Retail', 'amazon');
  END IF;
END$$;

-- Sample projects for each tenant (idempotent)
INSERT INTO public.projects (tenant_id, name, status, budget)
SELECT t.id, 'Main Onboarding Project', 'active', 50000
FROM public.tenants t
WHERE t.code = 'azure'
  AND NOT EXISTS (
      SELECT 1 FROM public.projects p
      WHERE p.tenant_id = t.id
        AND p.name = 'Main Onboarding Project'
  );

INSERT INTO public.projects (tenant_id, name, status, budget)
SELECT t.id, 'Sandbox Pilot Project', 'draft', 1000
FROM public.tenants t
WHERE t.code = 'amazon'
  AND NOT EXISTS (
      SELECT 1 FROM public.projects p
      WHERE p.tenant_id = t.id
        AND p.name = 'Sandbox Pilot Project'
  );
