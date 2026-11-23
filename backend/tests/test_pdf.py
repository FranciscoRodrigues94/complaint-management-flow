from app.reporting import build_report


def test_pdf_report_contains_pdf_header():
    complaint = {
        'reference': 'CMP-2026-9999', 'title': 'Demo complaint', 'status': 'Open', 'customer': 'Example Industries',
        'item_code': 'TEST-001', 'category': 'Assembly', 'severity': 'Low', 'reporter': 'Alex Morgan',
        'assigned_to': 'Jordan Lee', 'affected_quantity': 10, 'rejected_quantity': 2,
        'description': 'Example only', 'containment_action': '', 'root_cause': '',
        'verification_result': 'Not reviewed', 'verified_by': '', 'verification_notes': '',
    }
    output = build_report(complaint, [], [])
    assert output.startswith(b'%PDF')
    assert len(output) > 1000
