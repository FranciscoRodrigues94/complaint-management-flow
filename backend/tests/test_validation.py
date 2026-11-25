
from decimal import Decimal

import pytest
from fastapi import HTTPException
from pydantic import ValidationError

from app.domain import validate_transition
from app.main import ComplaintCreate, CostsUpdate, ensure_editable


def valid_complaint():
    return {
        'title': 'Assembly defect',
        'customer': 'Example Industries',
        'item_code': 'TEST-001',
        'category': 'Assembly',
        'severity': 'Medium',
        'description': 'Incorrect component alignment',
        'reporter': 'Alex Morgan',
        'assigned_to': 'Jordan Lee',
        'affected_quantity': 100,
        'rejected_quantity': 10,
        'estimated_cost': '250.00',
    }


def valid_costs():
    return {
        'scrap_cost': '100.50',
        'rework_cost': '50.25',
        'inspection_cost': '25.00',
        'other_cost': '0.00',
        'actor': 'Alex Morgan',
    }


def test_valid_complaint_quantities():
    data = ComplaintCreate.model_validate(valid_complaint())
    assert data.affected_quantity == 100
    assert data.rejected_quantity == 10


@pytest.mark.parametrize('affected,rejected', [
    (10, 11),
    (0, 0),
    (10, -1),
])
def test_invalid_complaint_quantities(affected, rejected):
    data = valid_complaint()
    data.update(affected_quantity=affected, rejected_quantity=rejected)
    with pytest.raises(ValidationError):
        ComplaintCreate.model_validate(data)


@pytest.mark.parametrize('field', [
    'scrap_cost',
    'rework_cost',
    'inspection_cost',
    'other_cost',
])
def test_negative_costs_are_rejected(field):
    data = valid_costs()
    data[field] = '-1.00'
    with pytest.raises(ValidationError):
        CostsUpdate.model_validate(data)


def test_costs_reject_more_than_two_decimal_places():
    data = valid_costs()
    data['scrap_cost'] = '12.345'
    with pytest.raises(ValidationError):
        CostsUpdate.model_validate(data)


def test_valid_costs_preserve_decimal_precision():
    data = CostsUpdate.model_validate(valid_costs())
    assert data.scrap_cost == Decimal('100.50')
    assert data.rework_cost == Decimal('50.25')
    assert data.other_cost == Decimal('0.00')


def test_closed_complaint_is_read_only():
    with pytest.raises(HTTPException) as exc:
        ensure_editable({'status': 'Closed'})
    assert exc.value.status_code == 409


def test_open_complaint_is_editable():
    ensure_editable({'status': 'Open'})


def test_cannot_skip_workflow_stages():
    complaint = {'status': 'Open', 'containment_action': 'Lot quarantined'}
    with pytest.raises(HTTPException) as exc:
        validate_transition(complaint, [], 'Closed')
    assert exc.value.status_code == 409
