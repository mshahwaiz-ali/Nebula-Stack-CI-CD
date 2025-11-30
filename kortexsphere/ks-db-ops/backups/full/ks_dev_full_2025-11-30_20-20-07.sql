--
-- PostgreSQL database dump
--

\restrict 3Mf1qNCypjgNBilo5rk1m6gJGSAaIL6IoJBc2cKUVIkqb2Buf0eK2CKdGvOeZbV

-- Dumped from database version 16.10 (Ubuntu 16.10-0ubuntu0.24.04.1)
-- Dumped by pg_dump version 16.10 (Ubuntu 16.10-0ubuntu0.24.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: ks_dev; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE ks_dev WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'C.UTF-8';


ALTER DATABASE ks_dev OWNER TO postgres;

\unrestrict 3Mf1qNCypjgNBilo5rk1m6gJGSAaIL6IoJBc2cKUVIkqb2Buf0eK2CKdGvOeZbV
\connect ks_dev
\restrict 3Mf1qNCypjgNBilo5rk1m6gJGSAaIL6IoJBc2cKUVIkqb2Buf0eK2CKdGvOeZbV

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: set_user_context(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.set_user_context(_user_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    t_id uuid;
    u_role text;
BEGIN
    SELECT tenant_id, role INTO t_id, u_role
    FROM app_users
    WHERE id = _user_id AND is_active = true;

    IF t_id IS NULL THEN
        RAISE EXCEPTION 'Invalid or inactive user ID %', _user_id;
    END IF;
perform set_config('app.tenant_id', t_id::text,false);
perform set_config('app.user_role', u_role, false);
end;
$$;


ALTER FUNCTION public.set_user_context(_user_id uuid) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: app_users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.app_users (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    tenant_id uuid NOT NULL,
    email text NOT NULL,
    full_name text,
    role text NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE ONLY public.app_users FORCE ROW LEVEL SECURITY;


ALTER TABLE public.app_users OWNER TO postgres;

--
-- Name: projects; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.projects (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    tenant_id uuid NOT NULL,
    name text NOT NULL,
    status text DEFAULT 'draft'::text NOT NULL,
    budget numeric(12,2) DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE ONLY public.projects FORCE ROW LEVEL SECURITY;


ALTER TABLE public.projects OWNER TO postgres;

--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.schema_migrations (
    version text NOT NULL,
    applied_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.schema_migrations OWNER TO postgres;

--
-- Name: tenants; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tenants (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name text NOT NULL,
    code text NOT NULL,
    plan text DEFAULT 'free'::text NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE ONLY public.tenants FORCE ROW LEVEL SECURITY;


ALTER TABLE public.tenants OWNER TO postgres;

--
-- Data for Name: app_users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.app_users (id, tenant_id, email, full_name, role, is_active, created_at) FROM stdin;
\.


--
-- Data for Name: projects; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.projects (id, tenant_id, name, status, budget, created_at) FROM stdin;
335e66d0-0bcf-41cb-b0d1-eacba294cdcb	96e77ced-8e26-48e6-80d0-f9f37edc7984	Main Onboarding Project	active	50000.00	2025-11-30 18:33:46.695627+05
b6bb4199-1304-4634-8f23-6c2aed287129	0118d7b5-4020-4cdf-ad7a-889d24208399	Test Sandbox Project	draft	1000.00	2025-11-30 18:33:46.699764+05
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.schema_migrations (version, applied_at) FROM stdin;
\.


--
-- Data for Name: tenants; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tenants (id, name, code, plan, is_active, created_at) FROM stdin;
96e77ced-8e26-48e6-80d0-f9f37edc7984	KortexSphere Main	ks_main	pro	t	2025-11-30 18:32:18.571624+05
0118d7b5-4020-4cdf-ad7a-889d24208399	KortexSphere Test	ks_test	free	t	2025-11-30 18:32:18.571624+05
\.


--
-- Name: app_users app_users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.app_users
    ADD CONSTRAINT app_users_pkey PRIMARY KEY (id);


--
-- Name: app_users app_users_tenant_email_uniq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.app_users
    ADD CONSTRAINT app_users_tenant_email_uniq UNIQUE (tenant_id, email);


--
-- Name: projects projects_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: tenants tenants_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tenants
    ADD CONSTRAINT tenants_code_key UNIQUE (code);


--
-- Name: tenants tenants_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tenants
    ADD CONSTRAINT tenants_pkey PRIMARY KEY (id);


--
-- Name: app_users app_users_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.app_users
    ADD CONSTRAINT app_users_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: projects projects_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: app_users; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.app_users ENABLE ROW LEVEL SECURITY;

--
-- Name: app_users app_users_admin_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY app_users_admin_all ON public.app_users TO ks_admin USING (true) WITH CHECK (true);


--
-- Name: app_users app_users_per_tenant_delete; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY app_users_per_tenant_delete ON public.app_users FOR DELETE TO ks_writer USING (((tenant_id)::text = current_setting('app.tenant_id'::text, true)));


--
-- Name: app_users app_users_per_tenant_insert; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY app_users_per_tenant_insert ON public.app_users FOR INSERT TO ks_writer WITH CHECK (((tenant_id)::text = current_setting('app.tenant_id'::text, true)));


--
-- Name: app_users app_users_per_tenant_read; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY app_users_per_tenant_read ON public.app_users FOR SELECT TO ks_readonly, ks_writer USING (((tenant_id)::text = current_setting('app.tenant_id'::text, true)));


--
-- Name: app_users app_users_per_tenant_update; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY app_users_per_tenant_update ON public.app_users FOR UPDATE TO ks_writer USING (((tenant_id)::text = current_setting('app.tenant_id'::text, true))) WITH CHECK (((tenant_id)::text = current_setting('app.tenant_id'::text, true)));


--
-- Name: projects; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;

--
-- Name: tenants; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.tenants ENABLE ROW LEVEL SECURITY;

--
-- Name: tenants tenants_admin_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY tenants_admin_all ON public.tenants TO ks_admin USING (true) WITH CHECK (true);


--
-- Name: tenants tenants_per_tenant_read; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY tenants_per_tenant_read ON public.tenants FOR SELECT TO ks_readonly, ks_writer USING (((id)::text = current_setting('app.tenant_id'::text, true)));


--
-- Name: DATABASE ks_dev; Type: ACL; Schema: -; Owner: postgres
--

GRANT ALL ON DATABASE ks_dev TO backup_user;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT USAGE ON SCHEMA public TO ks_readonly;
GRANT USAGE ON SCHEMA public TO ks_writer;
GRANT USAGE ON SCHEMA public TO ks_admin;
GRANT USAGE ON SCHEMA public TO backup_user;


--
-- Name: TABLE app_users; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.app_users TO backup_user;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.app_users TO ks_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.app_users TO ks_writer;
GRANT SELECT ON TABLE public.app_users TO ks_readonly;


--
-- Name: TABLE projects; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.projects TO backup_user;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.projects TO ks_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.projects TO ks_writer;
GRANT SELECT ON TABLE public.projects TO ks_readonly;


--
-- Name: TABLE schema_migrations; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.schema_migrations TO backup_user;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.schema_migrations TO ks_admin;


--
-- Name: TABLE tenants; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.tenants TO backup_user;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.tenants TO ks_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.tenants TO ks_writer;
GRANT SELECT ON TABLE public.tenants TO ks_readonly;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT ON SEQUENCES TO backup_user;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT ON TABLES TO ks_readonly;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT,INSERT,DELETE,UPDATE ON TABLES TO ks_writer;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT,INSERT,DELETE,UPDATE ON TABLES TO ks_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT ON TABLES TO backup_user;


--
-- PostgreSQL database dump complete
--

\unrestrict 3Mf1qNCypjgNBilo5rk1m6gJGSAaIL6IoJBc2cKUVIkqb2Buf0eK2CKdGvOeZbV

