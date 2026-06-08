-- Ref: algorithm original; PostGIS functions per https://postgis.net/docs/
-- Returns: chain_length_m, start lon/lat, end lon/lat for the longest
-- continuous chain (max total length, undirected, no edge reused).
CREATE OR REPLACE FUNCTION longest_chain(
    g        geometry,
    snap_tol double precision DEFAULT 1e-7   -- snapping grid size in CRS units (deg for 4326)
)
RETURNS TABLE(length_km double precision,
              start_longitude double precision, start_latitude double precision,
              end_longitude   double precision, end_latitude   double precision)
LANGUAGE plpgsql AS
$$
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