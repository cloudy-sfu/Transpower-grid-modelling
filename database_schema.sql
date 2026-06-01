--
-- PostgreSQL database dump
--

\restrict 730uN2wvAF9BQBbnjYcco8onK9U0EvNYM90sC2WcOIhRrX0VjIiH97uTs3NQ9xx

-- Dumped from database version 18.4 (365f1e4)
-- Dumped by pg_dump version 18.3

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_table_access_method = heap;

--
-- Name: embedded_generation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.embedded_generation (
    poc character varying(8) NOT NULL,
    end_time time with time zone NOT NULL,
    load double precision
);


--
-- Name: generation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.generation (
    gen_code character varying(8) NOT NULL,
    end_time time with time zone NOT NULL,
    load double precision
);


--
-- Name: generator; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.generator (
    gen_code character varying(64) NOT NULL,
    poc_code character varying(8),
    fuel_code character varying(8)
);


--
-- Name: grid_export; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.grid_export (
    node_id character varying(16) NOT NULL,
    end_time time with time zone NOT NULL,
    load double precision
);


--
-- Name: grid_import; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.grid_import (
    node_id character varying(16) NOT NULL,
    end_time time with time zone NOT NULL,
    load double precision
);


--
-- Name: grid_nodes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.grid_nodes (
    node_id character varying(16) NOT NULL,
    poc character varying(8),
    nwk_code character varying(4),
    generation_type character varying(2)
);


--
-- Name: embedded_generation embedded_generation_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.embedded_generation
    ADD CONSTRAINT embedded_generation_pk PRIMARY KEY (end_time, poc);


--
-- Name: generation generation_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.generation
    ADD CONSTRAINT generation_pk PRIMARY KEY (gen_code, end_time);


--
-- Name: generator generator_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.generator
    ADD CONSTRAINT generator_pk PRIMARY KEY (gen_code);


--
-- Name: grid_export grid_export_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grid_export
    ADD CONSTRAINT grid_export_pk PRIMARY KEY (node_id, end_time);


--
-- Name: grid_import grid_import_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grid_import
    ADD CONSTRAINT grid_import_pk PRIMARY KEY (end_time, node_id);


--
-- Name: grid_nodes grid_nodes_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grid_nodes
    ADD CONSTRAINT grid_nodes_pk PRIMARY KEY (node_id);


--
-- PostgreSQL database dump complete
--

\unrestrict 730uN2wvAF9BQBbnjYcco8onK9U0EvNYM90sC2WcOIhRrX0VjIiH97uTs3NQ9xx

