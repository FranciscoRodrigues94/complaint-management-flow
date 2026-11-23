-- Ausschließlich in einer neuen, leeren Demo-Datenbank ausführen.
DO $$ BEGIN
    IF EXISTS (SELECT 1 FROM complaints) THEN
        RAISE EXCEPTION 'Demo database is not empty. Refusing to overwrite or duplicate records.';
    END IF;
END $$;
INSERT INTO complaints (reference, title, customer, item_code, category, severity, status, description, reporter, assigned_to, affected_quantity, rejected_quantity, containment_action, root_cause, verification_result, verification_notes, verified_by, created_at)
VALUES
('CMP-2026-0001', 'Surface scratches on protective cover', 'Northstar Components', 'NC-1042', 'Visual defect', 'Medium', 'Open', 'Scratches found during incoming inspection of molded covers.', 'Alex Morgan', 'Jordan Lee', 600, 31, '', '', 'Not reviewed', '', '', '2026-11-02 09:00:00+00'),
('CMP-2026-0002', 'Dimensional deviation on housing', 'Atlas Mobility', 'AM-2055', 'Dimensional', 'High', 'In Progress', 'Measured housing width exceeds engineering tolerance.', 'Jordan Lee', 'Taylor Reed', 240, 47, 'Quarantine lot and increase inspection to 100%.', 'Fixture calibration drift caused incorrect measurements.', 'Not reviewed', '', '', '2026-11-05 09:00:00+00'),
('CMP-2026-0003', 'Incomplete packaging labels', 'Orion Industrial', 'OI-3410', 'Packaging', 'Low', 'Closed', 'Several batches had partially missing labels.', 'Taylor Reed', 'Alex Morgan', 150, 12, 'Hold outgoing cartons and relabel affected stock.', 'Printer feed roller maintenance was overdue.', 'Effective', 'Sample audit of relabeled cartons passed.', 'Jordan Lee', '2026-11-06 09:00:00+00'),
('CMP-2026-0004', 'Discoloration within production lot', 'Northstar Components', 'NC-1178', 'Visual defect', 'Medium', 'Open', 'Visible color variation found in parts from one production run.', 'Morgan Blake', 'Jordan Lee', 890, 94, '', '', 'Not reviewed', '', '', '2026-11-09 09:00:00+00'),
('CMP-2026-0005', 'Assembly fit issue', 'Atlas Mobility', 'AM-2088', 'Assembly', 'High', 'Pending Verification', 'Final assembly requires excessive fitting force.', 'Alex Morgan', 'Taylor Reed', 480, 58, 'Segregate suspect parts and perform fit checks.', 'Incorrect fixture alignment after tool changeover.', 'Not reviewed', '', '', '2026-11-11 09:00:00+00');
INSERT INTO corrective_actions (complaint_id, title, owner, due_date, status, completed_at)
SELECT c.id, x.title, x.owner, x.due_date::date, x.status, CASE WHEN x.status = 'Completed' THEN NOW() ELSE NULL END
FROM (VALUES
 ('CMP-2026-0002', 'Review measurement fixture calibration', 'Taylor Reed', '2026-11-20', 'In Progress'),
 ('CMP-2026-0002', 'Retrain shift on first-off inspection', 'Alex Morgan', '2026-11-25', 'Open'),
 ('CMP-2026-0003', 'Update packaging label checklist', 'Alex Morgan', '2026-11-12', 'Completed'),
 ('CMP-2026-0005', 'Realign assembly fixture', 'Taylor Reed', '2026-11-17', 'Completed'),
 ('CMP-2026-0005', 'Confirm fit with sample lot', 'Jordan Lee', '2026-11-18', 'Completed')
) AS x(reference, title, owner, due_date, status) JOIN complaints c ON c.reference = x.reference;
INSERT INTO complaint_events (complaint_id, event_type, message, actor)
SELECT id, 'seed', 'Fictional portfolio example created', 'Demo system' FROM complaints;
