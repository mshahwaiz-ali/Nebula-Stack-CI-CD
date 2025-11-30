--
-- PostgreSQL database dump
--

\restrict UTff1tVtEH4aV0hZYSb060JhOkvVIe8c2q0k4nK2GIWcciuNIzNBOaPUMquD3bq

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

SET default_tablespace = '';

SET default_table_access_method = heap;

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
-- Data for Name: projects; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.projects (id, tenant_id, name, status, budget, created_at) FROM stdin;
335e66d0-0bcf-41cb-b0d1-eacba294cdcb	96e77ced-8e26-48e6-80d0-f9f37edc7984	Main Onboarding Project	active	50000.00	2025-11-30 18:33:46.695627+05
b6bb4199-1304-4634-8f23-6c2aed287129	0118d7b5-4020-4cdf-ad7a-889d24208399	Test Sandbox Project	draft	1000.00	2025-11-30 18:33:46.699764+05
\.


--
-- Name: projects projects_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (id);


--
-- Name: projects projects_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: projects; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;

--
-- Name: TABLE projects; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.projects TO backup_user;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.projects TO ks_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.projects TO ks_writer;
GRANT SELECT ON TABLE public.projects TO ks_readonly;


--
-- PostgreSQL database dump complete
--

\unrestrict UTff1tVtEH4aV0hZYSb060JhOkvVIe8c2q0k4nK2GIWcciuNIzNBOaPUMquD3bq

