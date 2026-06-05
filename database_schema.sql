--
-- PostgreSQL database dump
--

\restrict iBDUTeUhuw9XeFQ6ifFw4JwAGwgsu0mUzGxsTi56mX0ZFUVfMKeUMMIfni56Cfd

-- Dumped from database version 18.4 (72c6e7c)
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
-- Name: connection_points; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.connection_points (
    point_id character varying(10) NOT NULL,
    name character varying(100),
    point_type character varying(20),
    status character varying(20),
    longitude double precision,
    latitude double precision
);


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
    load integer,
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
    load integer,
    end_time timestamp with time zone NOT NULL
);


--
-- Name: grid_import; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.grid_import (
    node_id character varying(12) NOT NULL,
    load integer,
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
-- Name: transmission_lines; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transmission_lines (
    line_id character varying(30) NOT NULL,
    name character varying(100),
    line_type character varying(20),
    length_m double precision,
    kilovolt smallint,
    status character varying(20),
    geometry jsonb
);


--
-- Name: connection_points connection_points_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connection_points
    ADD CONSTRAINT connection_points_pk PRIMARY KEY (point_id);


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
-- Name: transmission_lines transmission_lines_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transmission_lines
    ADD CONSTRAINT transmission_lines_pk PRIMARY KEY (line_id);


--
-- PostgreSQL database dump complete
--

\unrestrict iBDUTeUhuw9XeFQ6ifFw4JwAGwgsu0mUzGxsTi56mX0ZFUVfMKeUMMIfni56Cfd

