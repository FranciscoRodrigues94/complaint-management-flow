"""Local-only demonstration API. Not suitable for deployment without authentication and TLS."""
from contextlib import asynccontextmanager
from datetime import date, datetime, timezone
from os import environ

import psycopg
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.responses import Response
from pydantic import BaseModel, ConfigDict, Field, model_validator
from psycopg.rows import dict_row
from typing import Literal

from .domain import validate_transition
from .reporting import build_report

load_dotenv()
DATABASE_URL = environ.get('DATABASE_URL')
COMPLAINT_COLUMNS = ('id, reference, title, customer, item_code, category, severity, status, description, reporter, '
    'assigned_to, affected_quantity, rejected_quantity, containment_action, root_cause, '
    'verification_result, verification_notes, verified_by, created_at, updated_at')
ACTION_COLUMNS = 'id, complaint_id, title, owner, due_date, status, completed_at'
EVENT_COLUMNS = 'id, complaint_id, event_type, message, actor, created_at'


@asynccontextmanager
async def lifespan(_app: FastAPI):
    if not DATABASE_URL:
        raise RuntimeError('DATABASE_URL is missing. Configure backend/.env for local demo use.')
    yield


app = FastAPI(title='Complaint Management Flow API', version='0.2.0', lifespan=lifespan)


class ComplaintCreate(BaseModel):
    model_config = ConfigDict(extra='forbid', str_strip_whitespace=True)
    title: str = Field(min_length=3, max_length=160)
    customer: str = Field(min_length=2, max_length=120)
    item_code: str = Field(min_length=1, max_length=60)
    category: Literal['Visual defect', 'Dimensional', 'Packaging', 'Assembly', 'Other']
    severity: Literal['Low', 'Medium', 'High']
    description: str = Field(min_length=5, max_length=3000)
    reporter: str = Field(min_length=2, max_length=100)
    assigned_to: str = Field(min_length=2, max_length=100)
    affected_quantity: int = Field(ge=1, le=100000000)
    rejected_quantity: int = Field(ge=0, le=100000000)

    @model_validator(mode='after')
    def check_quantities(self):
        if self.rejected_quantity > self.affected_quantity:
            raise ValueError('Rejected quantity cannot exceed affected quantity.')
        return self


class ContainmentUpdate(BaseModel):
    model_config = ConfigDict(extra='forbid', str_strip_whitespace=True)
    containment_action: str = Field(max_length=3000)
    actor: str = Field(min_length=2, max_length=100)


class InvestigationUpdate(BaseModel):
    model_config = ConfigDict(extra='forbid', str_strip_whitespace=True)
    root_cause: str = Field(max_length=3000)
    actor: str = Field(min_length=2, max_length=100)


class VerificationUpdate(BaseModel):
    model_config = ConfigDict(extra='forbid', str_strip_whitespace=True)
    verification_result: Literal['Not reviewed', 'Effective', 'Ineffective']
    verification_notes: str = Field(max_length=3000)
    verified_by: str = Field(max_length=100)
    actor: str = Field(min_length=2, max_length=100)


class TransitionRequest(BaseModel):
    model_config = ConfigDict(extra='forbid', str_strip_whitespace=True)
    status: Literal['In Progress', 'Pending Verification', 'Closed']
    actor: str = Field(min_length=2, max_length=100)


class ActionCreate(BaseModel):
    model_config = ConfigDict(extra='forbid', str_strip_whitespace=True)
    title: str = Field(min_length=3, max_length=200)
    owner: str = Field(min_length=2, max_length=100)
    due_date: date
    actor: str = Field(min_length=2, max_length=100)


class ActionUpdate(BaseModel):
    model_config = ConfigDict(extra='forbid', str_strip_whitespace=True)
    status: Literal['Open', 'In Progress', 'Completed']
    actor: str = Field(min_length=2, max_length=100)


def connection():
    return psycopg.connect(DATABASE_URL, row_factory=dict_row)


def view(row):
    return {key: value.isoformat() if isinstance(value, (date, datetime)) else value for key, value in row.items()}


def get_existing(conn, complaint_id: int, lock: bool = False):
    suffix = ' FOR UPDATE' if lock else ''
    row = conn.execute(f'SELECT {COMPLAINT_COLUMNS} FROM complaints WHERE id = %s{suffix}', (complaint_id,)).fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail='Complaint not found.')
    return row


def ensure_editable(complaint):
    if complaint['status'] == 'Closed':
        raise HTTPException(status_code=409, detail='Closed complaints are read-only.')


def record_event(conn, complaint_id, event_type, message, actor):
    conn.execute('INSERT INTO complaint_events (complaint_id, event_type, message, actor) VALUES (%s, %s, %s, %s)', (complaint_id, event_type, message, actor))


@app.get('/api/health')
def health():
    with connection() as conn:
        conn.execute('SELECT 1')
    return {'status': 'ok'}


@app.get('/api/complaints')
def list_complaints():
    with connection() as conn:
        rows = conn.execute(f'SELECT {COMPLAINT_COLUMNS} FROM complaints ORDER BY created_at DESC, id DESC').fetchall()
    return [view(row) for row in rows]


@app.get('/api/complaints/{complaint_id}')
def get_complaint(complaint_id: int):
    with connection() as conn:
        return view(get_existing(conn, complaint_id))


@app.post('/api/complaints', status_code=201)
def create_complaint(data: ComplaintCreate):
    with connection() as conn:
        # Die Datenbanksequenz vergibt eine eindeutige ID, auch bei gleichzeitigen Anfragen.
        complaint_id = conn.execute("SELECT nextval(pg_get_serial_sequence('complaints', 'id')) AS id").fetchone()['id']
        reference = f'CMP-{datetime.now(timezone.utc).year}-{complaint_id:04d}'
        row = conn.execute(f'''INSERT INTO complaints
            (id, reference, title, customer, item_code, category, severity, description, reporter, assigned_to, affected_quantity, rejected_quantity)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s) RETURNING {COMPLAINT_COLUMNS}''',
            (complaint_id, reference, data.title, data.customer, data.item_code, data.category, data.severity, data.description, data.reporter, data.assigned_to, data.affected_quantity, data.rejected_quantity)).fetchone()
        record_event(conn, complaint_id, 'created', 'Complaint registered', data.reporter)
    return view(row)


@app.patch('/api/complaints/{complaint_id}/containment')
def update_containment(complaint_id: int, data: ContainmentUpdate):
    with connection() as conn:
        complaint = get_existing(conn, complaint_id, lock=True)
        ensure_editable(complaint)
        if complaint['status'] == 'Pending Verification':
            raise HTTPException(status_code=409, detail='Return to investigation before editing containment.')
        row = conn.execute(f'UPDATE complaints SET containment_action = %s, updated_at = NOW() WHERE id = %s RETURNING {COMPLAINT_COLUMNS}', (data.containment_action, complaint_id)).fetchone()
        record_event(conn, complaint_id, 'containment', 'Containment notes updated', data.actor)
    return view(row)


@app.patch('/api/complaints/{complaint_id}/investigation')
def update_investigation(complaint_id: int, data: InvestigationUpdate):
    with connection() as conn:
        complaint = get_existing(conn, complaint_id, lock=True)
        ensure_editable(complaint)
        if complaint['status'] == 'Pending Verification':
            raise HTTPException(status_code=409, detail='Return to investigation before changing the root cause.')
        row = conn.execute(f'UPDATE complaints SET root_cause = %s, updated_at = NOW() WHERE id = %s RETURNING {COMPLAINT_COLUMNS}', (data.root_cause, complaint_id)).fetchone()
        record_event(conn, complaint_id, 'investigation', 'Root cause documentation updated', data.actor)
    return view(row)


@app.patch('/api/complaints/{complaint_id}/verification')
def update_verification(complaint_id: int, data: VerificationUpdate):
    with connection() as conn:
        complaint = get_existing(conn, complaint_id, lock=True)
        if complaint['status'] != 'Pending Verification':
            raise HTTPException(status_code=409, detail='Verification is only available after completing corrective actions.')
        row = conn.execute(f'''UPDATE complaints SET verification_result = %s, verification_notes = %s,
            verified_by = %s, updated_at = NOW() WHERE id = %s RETURNING {COMPLAINT_COLUMNS}''',
            (data.verification_result, data.verification_notes, data.verified_by, complaint_id)).fetchone()
        record_event(conn, complaint_id, 'verification', f'Effectiveness result: {data.verification_result}', data.actor)
    return view(row)


@app.post('/api/complaints/{complaint_id}/transition')
def transition_complaint(complaint_id: int, data: TransitionRequest):
    with connection() as conn:
        complaint = get_existing(conn, complaint_id, lock=True)
        actions = conn.execute(f'SELECT {ACTION_COLUMNS} FROM corrective_actions WHERE complaint_id = %s FOR UPDATE', (complaint_id,)).fetchall()
        validate_transition(complaint, actions, data.status)
        if complaint['status'] == 'Pending Verification' and data.status == 'In Progress':
            # Nach fehlgeschlagener Prüfung ist eine erneute Wirksamkeitsprüfung erforderlich.
            row = conn.execute(f'''UPDATE complaints SET status = %s, verification_result = 'Not reviewed',
                verification_notes = '', verified_by = '', updated_at = NOW() WHERE id = %s RETURNING {COMPLAINT_COLUMNS}''',
                (data.status, complaint_id)).fetchone()
        else:
            row = conn.execute(f'UPDATE complaints SET status = %s, updated_at = NOW() WHERE id = %s RETURNING {COMPLAINT_COLUMNS}', (data.status, complaint_id)).fetchone()
        record_event(conn, complaint_id, 'status', f'Status changed: {complaint["status"]} → {data.status}', data.actor)
    return view(row)


@app.get('/api/actions')
def list_actions():
    with connection() as conn:
        rows = conn.execute(f'SELECT {ACTION_COLUMNS} FROM corrective_actions ORDER BY due_date, id').fetchall()
    return [view(row) for row in rows]


@app.post('/api/complaints/{complaint_id}/actions', status_code=201)
def create_action(complaint_id: int, data: ActionCreate):
    with connection() as conn:
        complaint = get_existing(conn, complaint_id, lock=True)
        ensure_editable(complaint)
        if complaint['status'] == 'Pending Verification':
            raise HTTPException(status_code=409, detail='Return to investigation before adding corrective actions.')
        row = conn.execute(f'''INSERT INTO corrective_actions (complaint_id, title, owner, due_date)
            VALUES (%s, %s, %s, %s) RETURNING {ACTION_COLUMNS}''',
            (complaint_id, data.title, data.owner, data.due_date)).fetchone()
        record_event(conn, complaint_id, 'action', f'Corrective action created: {data.title}', data.actor)
    return view(row)


@app.patch('/api/actions/{action_id}')
def update_action(action_id: int, data: ActionUpdate):
    with connection() as conn:
        # Einheitliche Sperrreihenfolge: zuerst Reklamation, dann Maßnahme.
        action_ref = conn.execute('SELECT complaint_id FROM corrective_actions WHERE id = %s', (action_id,)).fetchone()
        if not action_ref:
            raise HTTPException(status_code=404, detail='Corrective action not found.')
        complaint = get_existing(conn, action_ref['complaint_id'], lock=True)
        action = conn.execute(f'SELECT {ACTION_COLUMNS} FROM corrective_actions WHERE id = %s FOR UPDATE', (action_id,)).fetchone()
        if not action:
            raise HTTPException(status_code=404, detail='Corrective action not found.')
        ensure_editable(complaint)
        if complaint['status'] == 'Pending Verification':
            raise HTTPException(status_code=409, detail='Return to investigation before editing corrective actions.')
        row = conn.execute(f'''UPDATE corrective_actions SET status = %s,
            completed_at = CASE WHEN %s = 'Completed' THEN NOW() ELSE NULL END
            WHERE id = %s RETURNING {ACTION_COLUMNS}''', (data.status, data.status, action_id)).fetchone()
        record_event(conn, action['complaint_id'], 'action', f'Action status changed: {action["status"]} → {data.status}', data.actor)
    return view(row)


@app.get('/api/complaints/{complaint_id}/events')
def list_events(complaint_id: int):
    with connection() as conn:
        get_existing(conn, complaint_id)
        rows = conn.execute(f'SELECT {EVENT_COLUMNS} FROM complaint_events WHERE complaint_id = %s ORDER BY created_at DESC, id DESC', (complaint_id,)).fetchall()
    return [view(row) for row in rows]


@app.get('/api/complaints/{complaint_id}/report.pdf')
def complaint_report(complaint_id: int):
    with connection() as conn:
        complaint = get_existing(conn, complaint_id)
        actions = conn.execute(f'SELECT {ACTION_COLUMNS} FROM corrective_actions WHERE complaint_id = %s ORDER BY due_date', (complaint_id,)).fetchall()
        events = conn.execute(f'SELECT {EVENT_COLUMNS} FROM complaint_events WHERE complaint_id = %s ORDER BY created_at DESC', (complaint_id,)).fetchall()
    pdf = build_report(view(complaint), [view(x) for x in actions], [view(x) for x in events])
    return Response(pdf, media_type='application/pdf', headers={'Content-Disposition': f'attachment; filename="{complaint["reference"]}.pdf"'})
