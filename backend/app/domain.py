from datetime import date
from fastapi import HTTPException

STATUSES = ('Open', 'In Progress', 'Pending Verification', 'Closed')
ACTION_STATUSES = ('Open', 'In Progress', 'Completed')


def validate_quantities(affected: int, rejected: int) -> None:
    if rejected > affected:
        raise HTTPException(status_code=422, detail='Rejected quantity cannot exceed affected quantity.')


def validate_transition(complaint: dict, actions: list[dict], target: str) -> None:
    current = complaint['status']
    allowed = {
        'Open': {'In Progress'},
        'In Progress': {'Pending Verification'},
        'Pending Verification': {'In Progress', 'Closed'},
        'Closed': set(),
    }
    if target not in allowed.get(current, set()):
        raise HTTPException(status_code=409, detail=f'Invalid workflow transition: {current} → {target}.')
    if current == 'Open' and not (complaint.get('containment_action') or '').strip():
        raise HTTPException(status_code=409, detail='Record a containment action before starting the investigation.')
    if current == 'In Progress':
        if not (complaint.get('root_cause') or '').strip():
            raise HTTPException(status_code=409, detail='Document the root cause before submitting for verification.')
        if not actions:
            raise HTTPException(status_code=409, detail='Add at least one corrective action before verification.')
        if any(action['status'] != 'Completed' for action in actions):
            raise HTTPException(status_code=409, detail='All corrective actions must be completed before verification.')
    if current == 'Pending Verification' and target == 'Closed':
        if complaint.get('verification_result') != 'Effective':
            raise HTTPException(status_code=409, detail='A positive effectiveness check is required to close the complaint.')
        if not (complaint.get('verification_notes') or '').strip() or not (complaint.get('verified_by') or '').strip():
            raise HTTPException(status_code=409, detail='Verification notes and reviewer name are required.')
    if current == 'Pending Verification' and target == 'In Progress':
        if complaint.get('verification_result') != 'Ineffective':
            raise HTTPException(status_code=409, detail='Mark verification as ineffective before returning to investigation.')
