from app.reporting import build_report
from io import BytesIO
from pypdf import PdfReader


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

def test_pdf_quality_costs_are_calculated_correctly():
    complaint = {
        'reference': 'CMP-2026-9999',
        'title': 'Demo complaint',
        'status': 'Open',
        'customer': 'Example Industries',
        'item_code': 'TEST-001',
        'category': 'Assembly',
        'severity': 'Low',
        'reporter': 'Alex Morgan',
        'assigned_to': 'Jordan Lee',
        'affected_quantity': 10,
        'rejected_quantity': 2,
        'description': 'Example only',
        'estimated_cost': '1000.00',
        'scrap_cost': '100.50',
        'rework_cost': '50.25',
        'inspection_cost': '25.00',
        'other_cost': None,
    }

    pdf_bytes = build_report(complaint, [], [])
    reader = PdfReader(BytesIO(pdf_bytes))
    text = '\n'.join(page.extract_text() for page in reader.pages)

    assert 'CMP-2026-9999' in text
    assert 'EUR 1,000.00' in text
    assert 'EUR 100.50' in text
    assert 'EUR 50.25' in text
    assert 'EUR 25.00' in text
    assert 'Not recorded' in text
    assert 'EUR 175.75' in text