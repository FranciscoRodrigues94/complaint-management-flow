-- Ausschließlich in einer neuen, leeren QualityFlow-Datenbank ausführen.
BEGIN;
DO $$ BEGIN
    IF EXISTS (SELECT 1 FROM complaints) OR EXISTS (SELECT 1 FROM corrective_actions) OR EXISTS (SELECT 1 FROM complaint_events) THEN
        RAISE EXCEPTION 'Demo database is not empty. Refusing to duplicate records.';
    END IF;
END $$;

INSERT INTO complaints (reference, title, customer, item_code, category, severity, status, description, reporter, assigned_to,
    affected_quantity, rejected_quantity, containment_action, root_cause, verification_result, verification_notes, verified_by,
    estimated_cost, scrap_cost, rework_cost, inspection_cost, other_cost, created_at, updated_at)
VALUES
('CMP-2026-0001', 'Surface scratches on protective cover', 'Northstar Components', 'NC-1042', 'Visual defect', 'Medium', 'Open', 'Scratches found during incoming inspection of molded covers.', 'Alex Morgan', 'Jordan Lee', 600, 31, '', '', 'Not reviewed', '', '', 850, NULL, NULL, NULL, NULL, '2026-11-02 09:00:00+00', '2026-11-02 09:00:00+00'),
('CMP-2026-0002', 'Dimensional deviation on housing', 'Atlas Mobility', 'AM-2055', 'Dimensional', 'High', 'In Progress', 'Measured housing width exceeds engineering tolerance.', 'Jordan Lee', 'Taylor Reed', 240, 47, 'Quarantine lot and increase inspection to 100%.', 'Fixture calibration drift caused incorrect measurements.', 'Not reviewed', '', '', 2200, 630, 480, 175, 0, '2026-11-05 09:00:00+00', '2026-11-07 09:00:00+00'),
('CMP-2026-0003', 'Incomplete packaging labels', 'Orion Industrial', 'OI-3410', 'Packaging', 'Low', 'Closed', 'Several batches had partially missing labels.', 'Taylor Reed', 'Alex Morgan', 150, 12, 'Hold outgoing cartons and relabel affected stock.', 'Printer feed roller maintenance was overdue.', 'Effective', 'Sample audit of relabeled cartons passed.', 'Jordan Lee', 300, 0, 140, 75, 20, '2026-11-06 09:00:00+00', '2026-11-09 09:00:00+00'),
('CMP-2026-0004', 'Discoloration within production lot', 'Northstar Components', 'NC-1178', 'Visual defect', 'Medium', 'Open', 'Visible color variation found in parts from one production run.', 'Morgan Blake', 'Jordan Lee', 890, 94, '', '', 'Not reviewed', '', '', 1800, NULL, NULL, NULL, NULL, '2026-11-09 09:00:00+00', '2026-11-09 09:00:00+00'),
('CMP-2026-0005', 'Assembly fit issue', 'Atlas Mobility', 'AM-2088', 'Assembly', 'High', 'Pending Verification', 'Final assembly requires excessive fitting force.', 'Alex Morgan', 'Taylor Reed', 480, 58, 'Segregate suspect parts and perform fit checks.', 'Incorrect fixture alignment after tool changeover.', 'Not reviewed', '', '', 1650, 420, 320, 110, 0, '2026-11-11 09:00:00+00', '2026-11-14 09:00:00+00');

-- 45 weitere deterministische Datensätze: insgesamt 12 Open, 18 In Progress,
-- 8 Pending Verification und 12 Closed (einschließlich der fünf obigen).
WITH patterns AS (
    SELECT ARRAY[
        'Surface finish inconsistency', 'Incorrect assembly clearance', 'Packaging label mismatch',
        'Dimensional tolerance exceeded', 'Material discoloration', 'Missing component in delivery',
        'Surface contamination detected', 'Incorrect hole positioning', 'Incomplete production documentation',
        'Excessive component deformation', 'Damaged transportation packaging', 'Functional inspection failure'
    ]::text[] AS titles,
    ARRAY[
        'Visual defect', 'Assembly', 'Packaging', 'Dimensional', 'Visual defect', 'Missing parts',
        'Contamination', 'Dimensional', 'Documentation', 'Dimensional', 'Packaging', 'Functional'
    ]::text[] AS categories,
    ARRAY['Northstar Components','Atlas Mobility','Orion Industrial','Summit Engineering','Vertex Systems','Helix Manufacturing']::text[] AS customers,
    ARRAY['Jordan Lee','Taylor Reed','Alex Morgan','Sam Carter']::text[] AS owners
), generated AS (
    SELECT g.id, g.id - 6 AS idx, p.*,
        CASE WHEN g.id <= 15 THEN 'Open' WHEN g.id <= 32 THEN 'In Progress'
             WHEN g.id <= 39 THEN 'Pending Verification' ELSE 'Closed' END AS case_status,
        ('2026-01-01 09:00:00+00'::timestamptz + ((g.id - 6) * interval '7 days')) AS opened_at
    FROM generate_series(6,50) AS g(id) CROSS JOIN patterns p
)
INSERT INTO complaints (reference, title, customer, item_code, category, severity, status, description, reporter, assigned_to,
    affected_quantity, rejected_quantity, containment_action, root_cause, verification_result, verification_notes, verified_by,
    estimated_cost, scrap_cost, rework_cost, inspection_cost, other_cost, created_at, updated_at)
SELECT format('CMP-2026-%s', lpad(id::text, 4, '0')),
    titles[(idx % 12) + 1], customers[(idx % 6) + 1], 'QF-' || (1000 + id * 17), categories[(idx % 12) + 1],
    (ARRAY['Low','Medium','High'])[(idx % 3) + 1], case_status,
    'Fictional quality incident detected during inspection of lot ' || (1000 + id) || '.',
    'Alex Morgan', owners[(idx % 4) + 1], 100 + (id * 37) % 900, 5 + (id * 11) % 80,
    CASE WHEN case_status <> 'Open' THEN 'Affected stock isolated and inspection initiated.' ELSE '' END,
    CASE WHEN case_status IN ('Pending Verification','Closed') THEN 'Process variation identified during investigation.' ELSE '' END,
    CASE WHEN case_status = 'Closed' THEN 'Effective' ELSE 'Not reviewed' END,
    CASE WHEN case_status = 'Closed' THEN 'Follow-up inspection confirmed effectiveness.' ELSE '' END,
    CASE WHEN case_status = 'Closed' THEN 'Jordan Lee' ELSE '' END,
    (200 + id * 31)::numeric(12,2),
    CASE WHEN case_status = 'Open' THEN NULL ELSE (id * 13 % 550)::numeric(12,2) END,
    CASE WHEN case_status = 'Open' THEN NULL ELSE (id * 17 % 380)::numeric(12,2) END,
    CASE WHEN case_status = 'Open' THEN NULL ELSE (id * 7 % 180)::numeric(12,2) END,
    CASE WHEN case_status = 'Open' THEN NULL ELSE (id * 3 % 90)::numeric(12,2) END,
    opened_at, opened_at + interval '3 days'
FROM generated;

-- Bestehende fünf Fälle: ursprüngliche Maßnahmen beibehalten.
INSERT INTO corrective_actions (complaint_id, title, owner, due_date, status, completed_at)
SELECT c.id, x.title, x.owner, x.due_date::date, x.status,
    CASE WHEN x.status = 'Completed' THEN x.due_date::date::timestamptz ELSE NULL END
FROM (VALUES
 ('CMP-2026-0002', 'Review measurement fixture calibration', 'Taylor Reed', '2026-11-20', 'In Progress'),
 ('CMP-2026-0002', 'Retrain shift on first-off inspection', 'Alex Morgan', '2026-11-25', 'Open'),
 ('CMP-2026-0003', 'Update packaging label checklist', 'Alex Morgan', '2026-11-12', 'Completed'),
 ('CMP-2026-0005', 'Realign assembly fixture', 'Taylor Reed', '2026-11-17', 'Completed'),
 ('CMP-2026-0005', 'Confirm fit with sample lot', 'Jordan Lee', '2026-11-18', 'Completed')
) AS x(reference,title,owner,due_date,status) JOIN complaints c ON c.reference = x.reference;

-- Korrekturmaßnahmen für zusätzliche, bereits untersuchte Fälle.
INSERT INTO corrective_actions (complaint_id, title, owner, due_date, status, completed_at)
SELECT c.id, 'Review process controls for ' || lower(c.category), c.assigned_to,
    (c.created_at + interval '14 days')::date,
    CASE WHEN c.status IN ('Pending Verification','Closed') THEN 'Completed' ELSE 'In Progress' END,
    CASE WHEN c.status IN ('Pending Verification','Closed') THEN c.created_at + interval '12 days' ELSE NULL END
FROM complaints c WHERE c.id >= 6 AND c.status <> 'Open';

INSERT INTO complaint_events (complaint_id, event_type, message, actor, created_at)
SELECT id, 'seed', 'Fictional portfolio example created', 'Demo system', created_at FROM complaints;

-- Die Sequenz bleibt korrekt, auch nach expliziten IDs beim Import.
SELECT setval(pg_get_serial_sequence('complaints','id'), (SELECT MAX(id) FROM complaints), true);

DO $$ DECLARE total_count integer; BEGIN
    SELECT count(*) INTO total_count FROM complaints;
    IF total_count <> 50 THEN RAISE EXCEPTION 'Expected 50 demo complaints, found %', total_count; END IF;
END $$;
COMMIT;
