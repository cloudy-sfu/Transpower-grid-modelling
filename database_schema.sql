--
-- PostgreSQL database dump
--

\restrict wZFetuvKTcdQyggyBKiFCMjyRZlRmapDGhYHqeYLl82EsZioeHwE0jsdfWalXM6

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
    load double precision,
    end_time timestamp with time zone NOT NULL
);


--
-- Name: generation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.generation (
    gen_code character varying(64) NOT NULL,
    load double precision,
    end_time timestamp with time zone NOT NULL
);


--
-- Name: generator; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.generator (
    gen_code character varying(64) NOT NULL,
    poc character varying(8),
    fuel_code character varying(8)
);


--
-- Name: grid_export; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.grid_export (
    node_id character varying(12) NOT NULL,
    load double precision,
    end_time timestamp with time zone NOT NULL
);


--
-- Name: grid_import; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.grid_import (
    node_id character varying(12) NOT NULL,
    load double precision,
    end_time timestamp with time zone NOT NULL
);


--
-- Name: grid_nodes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.grid_nodes (
    node_id character varying(12) NOT NULL,
    poc character varying(8),
    generation_type character varying(2)
);


--
-- Name: embedded_generation embedded_generation_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.embedded_generation
    ADD CONSTRAINT embedded_generation_pk PRIMARY KEY (poc, end_time);


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
    ADD CONSTRAINT grid_import_pk PRIMARY KEY (node_id, end_time);


--
-- Name: grid_nodes grid_nodes_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grid_nodes
    ADD CONSTRAINT grid_nodes_pk PRIMARY KEY (node_id);


--
-- PostgreSQL database dump complete
--

\unrestrict wZFetuvKTcdQyggyBKiFCMjyRZlRmapDGhYHqeYLl82EsZioeHwE0jsdfWalXM6

