BEGIN;
CREATE TEMP TABLE chain_test (id int, label text, geom geometry) ON COMMIT DROP;
-- Case 1: plain LineString  (0,0)-(1,1)-(2,1)
INSERT INTO chain_test VALUES
(1, 'LineString',
 ST_GeomFromText('LINESTRING(0 0, 1 1, 2 1)', 4326));
-- Case 2: MultiLineString, edges A->D, B->D (D wobble +5e-8), C->D (D wobble), D->E
--         (note the wobbling D coordinate to simulate float error)
INSERT INTO chain_test VALUES
(2, 'Multi directed-in',
 ST_GeomFromText('MULTILINESTRING(
    (0 0,          3 0),
    (2.5 0,        3.00000005 0),
    (3 0.5,        2.99999996 0.00000003),
    (3 0,          3 2)
 )', 4326));
-- Case 3: SAME graph, but some edges reversed:
-- D->A (reversed), B->D, D->C (reversed, D wobble), D->E
-- must give the IDENTICAL result (undirected).
INSERT INTO chain_test VALUES
(3, 'Multi mixed-dir',
 ST_GeomFromText('MULTILINESTRING(
    (3 0,          0 0),
    (2.5 0,        3.00000005 0),
    (3.00000002 0, 3 0.5),
    (3 0,          3 2)
 )', 4326));
SELECT
    t.id, t.label, GeometryType(t.geom) AS gtype,
    length_km, start_longitude, start_latitude, end_longitude, end_latitude
FROM chain_test t
CROSS JOIN LATERAL longest_chain(t.geom, 1e-7) AS r
ORDER BY t.id;
COMMIT;
