# Complaint Management Flow

**A standalone industrial complaint and non-conformity workflow demo** built with Flutter (Windows), FastAPI and PostgreSQL.

![Portfolio demo](https://img.shields.io/badge/status-portfolio%20demo-blue) ![Flutter](https://img.shields.io/badge/frontend-Flutter-02569B) ![FastAPI](https://img.shields.io/badge/backend-FastAPI-05998B) ![PostgreSQL](https://img.shields.io/badge/database-PostgreSQL-4169E1)

> This is an independent educational/portfolio application. All customer names, staff names, materials, complaints and sample records are fictitious. No confidential company source code, branding or production data are included.

## Why this project exists

A spreadsheet can register an incident, but it cannot reliably ensure that containment was recorded, corrective actions were completed or the effectiveness of a fix was verified. This application demonstrates an end-to-end workflow with explicit state transitions, traceable actions and server-side business rules.

## Features

- **Complaint register:** create quality incidents, search and filter by status/severity, review ownership and scope.
- **Four-step workflow:** containment, root-cause investigation, corrective actions, effectiveness verification.
- **Protected transitions:** cannot start investigation without containment, submit for verification without a root cause and completed corrective actions, or close without a positive verification with reviewer and evidence.
- **Corrective action tracker:** owner, due date, status, overdue highlighting and editing.
- **Dashboard:** case volumes, closure rate, severity alerts, overdue actions and category distribution.
- **Activity history:** logs important changes and status transitions. Actor names are manually entered, not authenticated.
- **PDF report (API mode):** exports a generated report containing complaint details, actions, verification and history.
- **Two execution modes:** in-memory demo without infrastructure, and persistent FastAPI/PostgreSQL mode.
- **Automated tests:** seven backend checks plus Flutter widget and demo-workflow tests.

## Screenshots

Add screenshots after running the application under `docs/screenshots/` (Dashboard, complaint detail, action tracker, PDF report).

## Reviewer walkthrough

See [docs/RECRUITER_DEMO.md](docs/RECRUITER_DEMO.md) for a short scenario showing business value, guarded workflow transitions and PDF reporting.

## Project layout

```text
complaint_management_flow/
├── lib/
│   ├── main.dart
│   ├── models/
│   ├── pages/
│   ├── services/
│   └── widgets/
├── backend/
│   ├── app/             # FastAPI routes, workflow rules, PDF generation
│   ├── sql/             # Fresh database schema and fictional seed data
│   ├── tests/           # Python tests
│   ├── compose.yaml     # Optional local-only PostgreSQL Docker service
│   └── .env.example
├── docs/
│   └── ARCHITECTURE.md
└── pubspec.yaml         # Retained from the original Flutter project
```

## Quick start: offline demo (no database)

Prerequisites: Flutter stable with Windows desktop support.

```powershell
flutter pub get
flutter analyze
flutter run -d windows
```

The demo loads five fictional cases and allows **creating complaints, completing workflow steps and managing actions**. In-memory changes reset when the app restarts. PDF generation is available in API mode only.

Run Flutter tests with:

```powershell
flutter test
```

## Full stack: FastAPI + PostgreSQL

### Option A: Local database with Docker (recommended)

Docker Desktop must be running.

```powershell
cd backend
docker compose up -d db
Copy-Item .env.example .env
py -3 -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements-dev.txt
.\.venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
```

Docker binds PostgreSQL to **127.0.0.1:5433**, so it will not interfere with an existing installation on port 5432. The schema and fictional seed data are loaded automatically **only when the Docker database volume is first created**. The credentials in `compose.yaml` are **local demonstration credentials only**, not suitable for deployment.

Open <http://127.0.0.1:8000/docs> for the interactive OpenAPI documentation.

In another terminal, from the Flutter project root:

```powershell
flutter run -d windows --dart-define=USE_API=true --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

For a permanent local PostgreSQL installation, create a **new, empty** `complaint_management_demo` database using pgAdmin. Run `backend/sql/001_schema.sql` and then `backend/sql/002_seed_demo.sql` in the correct database, update `backend/.env` with its credentials, and start the API with the same Uvicorn command. The schema scripts target fresh demo databases, **not an existing company database or a previously installed starter schema**.

### Tests

From `backend/` after installing `requirements-dev.txt`:

```powershell
.\.venv\Scripts\python.exe -m pytest -q
```

### API routes

| Method | Path | Purpose |
|---|---|---|
| GET | `/api/health` | Check API/database connection |
| GET / POST | `/api/complaints` | List/create complaints |
| GET | `/api/complaints/{id}` | Get one case |
| PATCH | `/api/complaints/{id}/containment` | Save containment notes |
| PATCH | `/api/complaints/{id}/investigation` | Save root-cause analysis |
| PATCH | `/api/complaints/{id}/verification` | Save verification outcome |
| POST | `/api/complaints/{id}/transition` | Advance or return the workflow |
| GET / POST | `/api/actions`, `/api/complaints/{id}/actions` | List/create corrective actions |
| PATCH | `/api/actions/{id}` | Update action status |
| GET | `/api/complaints/{id}/events` | Read activity history |
| GET | `/api/complaints/{id}/report.pdf` | Export report as PDF |

## Security limitations

**Local demo only.** There is **no authentication, authorization or HTTPS**. The demo actor is self-declared, so it does not provide verified audit attribution. Do not expose the API beyond `127.0.0.1` or deploy it with real company data without adding authentication, server-side role checks, HTTPS, secrets management, migrations and a deployment security review. Docker sample credentials must be changed for non-demo use.

No corporate servers, identities, internal identifiers, proprietary documents or private datasets are needed.

## Design trade-offs

- No extra Flutter packages: the desktop UI is easy to run and review.
- Business validation runs in the FastAPI domain layer **even if Flutter validation is bypassed**.
- The demo repository mirrors the API rules for offline exploration but does not replace backend enforcement.
- Database relationships and transactional updates preserve consistency; no complaint deletion is exposed.
- PDF generation is server-side with ReportLab to keep UI dependencies small.
- A dedicated `complaint_events` table logs business-relevant changes, but is **not a tamper-proof audit trail**.

## Developer note

Implemented as a portfolio-focused, AI-assisted development exercise. Architecture, workflow definition, integration, testing and user experience are demonstrated in the repository. The demo is intentionally smaller than an enterprise production system.
