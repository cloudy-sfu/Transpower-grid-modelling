--
-- PostgreSQL database dump
--

\restrict n4MjyDTObqzN8UNLMBE76aJf1UaEKKCURxJqCfTvJZqSPazJrxhRDPHqY3DvDeD

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

--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';


--
-- Name: longest_chain(public.geometry, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.longest_chain(g public.geometry, snap_tol double precision DEFAULT 0.0000001) RETURNS TABLE(length_km double precision, start_longitude double precision, start_latitude double precision, end_longitude double precision, end_latitude double precision)
    LANGUAGE plpgsql
    AS $$
DECLARE
    n_parts int;
BEGIN
    -- Build edge table: each LineString part -> one edge with snapped node keys.
    DROP TABLE IF EXISTS _edges;
    CREATE TEMP TABLE _edges ON COMMIT DROP AS
    SELECT
        path[1]                                              AS eid,
        ST_AsText(ST_SnapToGrid(ST_StartPoint(geom), snap_tol)) AS na,
        ST_AsText(ST_SnapToGrid(ST_EndPoint(geom),   snap_tol)) AS nb,
        ST_StartPoint(geom)                                  AS pa,  -- original coords
        ST_EndPoint(geom)                                    AS pb,
        ST_Length(geom::geography) / 1000.0                  AS len
    FROM (
        SELECT (ST_Dump(g)).geom AS geom, (ST_Dump(g)).path AS path
    ) d
    WHERE GeometryType(geom) = 'LINESTRING';

    SELECT count(*) INTO n_parts FROM _edges;
    IF n_parts = 0 THEN RETURN; END IF;

    -- Directed adjacency: every edge usable from either endpoint.
    DROP TABLE IF EXISTS _adj;
    CREATE TEMP TABLE _adj ON COMMIT DROP AS
    SELECT eid, na AS frm, nb AS too, pa AS pfrm, pb AS ptoo, len FROM _edges
    UNION ALL
    SELECT eid, nb AS frm, na AS too, pb AS pfrm, pa AS ptoo, len FROM _edges;

    -- Recursive enumeration of simple paths (no repeated edge).
    -- start_node carried so we can report the originating terminal.
    RETURN QUERY
    WITH RECURSIVE walk AS (
        SELECT a.eid, a.too AS cur, a.len AS total,
               ARRAY[a.eid] AS used,
               a.pfrm AS start_pt, a.ptoo AS end_pt
        FROM _adj a
      UNION ALL
        SELECT a.eid, a.too, w.total + a.len,
               w.used || a.eid,
               w.start_pt, a.ptoo
        FROM walk w
        JOIN _adj a ON a.frm = w.cur
        WHERE NOT (a.eid = ANY(w.used))
    )
    SELECT total,
           ST_X(start_pt), ST_Y(start_pt),
           ST_X(end_pt),   ST_Y(end_pt)
    FROM walk
    ORDER BY total DESC
    LIMIT 1;
END;
$$;


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
    geometry public.geometry(Geometry,4326)
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

\unrestrict n4MjyDTObqzN8UNLMBE76aJf1UaEKKCURxJqCfTvJZqSPazJrxhRDPHqY3DvDeD

