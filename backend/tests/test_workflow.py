import pytest
from fastapi import HTTPException
from app.domain import validate_transition


def complaint(**fields):
    return {'status': 'Open', 'containment_action': '', 'root_cause': '', 'verification_result': 'Not reviewed', 'verification_notes': '', 'verified_by': '', **fields}


def action(status='Completed'):
    return {'status': status}


def test_open_cannot_advance_without_containment():
    with pytest.raises(HTTPException) as exc:
        validate_transition(complaint(), [], 'In Progress')
    assert exc.value.status_code == 409


def test_containment_allows_investigation():
    validate_transition(complaint(containment_action='Quarantine affected lot'), [], 'In Progress')


def test_investigation_requires_cause_and_completed_actions():
    with pytest.raises(HTTPException):
        validate_transition(complaint(status='In Progress', root_cause='Misalignment'), [action('Open')], 'Pending Verification')
    with pytest.raises(HTTPException):
        validate_transition(complaint(status='In Progress'), [action()], 'Pending Verification')
    with pytest.raises(HTTPException):
        validate_transition(complaint(status='In Progress', root_cause='Misalignment'), [], 'Pending Verification')
    validate_transition(complaint(status='In Progress', root_cause='Misalignment'), [action()], 'Pending Verification')


def test_closure_needs_effective_verification_and_reviewer():
    with pytest.raises(HTTPException):
        validate_transition(complaint(status='Pending Verification'), [action()], 'Closed')
    validate_transition(complaint(status='Pending Verification', verification_result='Effective', verification_notes='Sample inspection passed', verified_by='Alex Morgan'), [action()], 'Closed')


def test_ineffective_verification_can_return_to_investigation():
    validate_transition(complaint(status='Pending Verification', verification_result='Ineffective'), [action()], 'In Progress')
    with pytest.raises(HTTPException):
        validate_transition(complaint(status='Pending Verification', verification_result='Effective'), [action()], 'In Progress')


def test_closed_case_cannot_be_reopened():
    with pytest.raises(HTTPException):
        validate_transition(complaint(status='Closed'), [], 'In Progress')
