# Five-Minute Walkthrough for Portfolio Reviewers

## Goal

Demonstrate a practical industrial quality management workflow, focusing on complaint handling, corrective actions, and process improvement.

QualityFlow combines complaint registration, corrective action tracking, workflow validation, quality cost analysis, and reporting.

The application can be explored in Demo Mode without installing Python or PostgreSQL.

## Quick Start

**Requirements:** Flutter SDK with Windows desktop support.

From the project root:

```powershell
flutter pub get
flutter run -d windows
```

The application starts with 50 fictional complaints.

Demo Mode stores changes in memory and resets when the application restarts.

## Five-Minute Demonstration

### 1. Dashboard — Quality Performance

Open the Dashboard and review:

- Total and active complaints
- Closure rate
- High-severity complaints
- Overdue corrective actions
- Defect categories and monthly trends
- Recorded quality costs by category
- Overview of corrective actions requiring attention
- List of recent complaints and their current statuses

**Key point:** QualityFlow turns complaint records into operational and financial indicators.

### 2. Complaint Register

Open the complaint register in "Complaints"

Demonstrate searching, filtering by status or severity, and opening an existing case.

**Key point:** Records can be organized and retrieved according to operational priorities.

### 3. Create a Complaint

Create a fictional complaint with customer, product, description, responsible person, affected and rejected quantities.

Optionally enter an estimated financial impact.

Try entering a rejected quantity greater than the affected quantity to demonstrate validation.

**Key point:** Input constraints help prevent inconsistent records.

### 4. Workflow and Corrective Actions

Open a complaint and demonstrate the workflow:

`Open → In Progress → Pending Verification → Closed`

- Record a containment action before starting the investigation.
- Document the root cause.
- Add a corrective action with an owner and due date.
- Attempt to advance before the corrective action is completed.
- Complete the action and submit the complaint for verification.

Explain that an ineffective verification can return the complaint to investigation, while successful closure requires an effective result, verification notes and a reviewer.

**Key point:** The workflow enforces process requirements instead of relying only on manual discipline.

### 5. Quality Cost Management

Open the Quality Costs tab of an editable complaint.

Review the estimated financial impact and enter actual costs for scrap, rework, inspection and other expenses.

Observe the calculated total.

**Key point:** Estimated financial impact is tracked separately from actual recorded costs.

### 6. History and Traceability

Open the History tab and review the recorded events.

**Key point:** Business-relevant changes and transitions can be traced, although actor names are manually declared and not authenticated.

## Optional Full-Stack Demonstration

For a more technical review, run QualityFlow in API Mode with the local FastAPI backend and PostgreSQL.

Demonstrate:

- Persistent records after restarting the application
- REST API endpoints through `http://127.0.0.1:8000/docs`
- Server-side validation of workflow transitions
- Storage of corrective actions and quality costs
- PDF report generation with complaint details and financial information

Unlike Demo Mode, API Mode persists changes in PostgreSQL.

Refer to the main README for setup instructions.

## Technical Talking Points

**Architecture**

Flutter communicates with data sources through a `ComplaintRepository` abstraction. Two implementations support in-memory demonstrations and persistent REST API operations.

**Backend validation**

FastAPI and Pydantic validate incoming data. Workflow transitions are enforced by the backend independently of Flutter controls.

**Database design**

PostgreSQL stores complaints, corrective actions and activity history using relational tables, sequences and transactional operations.

**Quality cost management**

Financial inputs use decimal validation. Actual costs are calculated separately from estimated impact.

**Testing and CI**

The backend includes 21 automated Python tests covering workflow rules, input validation, financial constraints and PDF reporting.

Flutter tests and static analysis are also executed automatically through GitHub Actions.

**Security and limitations**

QualityFlow is a local demonstration application. Authentication, role-based authorization, HTTPS and verified individual audit attribution are outside its current scope.

## Suggested Screenshots

The main README includes screenshots demonstrating:

- Dashboard overview and analytics
- Complaint distribution
- Complaint register and workflow
- Corrective action tracking
- Quality cost management
- PDF reporting

## AI-Assisted Development

QualityFlow was developed with AI assistance for implementation, debugging, refactoring and testing.

Development involved hands-on requirements definition, workflow design, architectural decisions, integration, manual verification and iterative validation.

The project demonstrates practical full-stack development and the use of AI as an engineering support tool.

## Project Scope

QualityFlow v1.0.0 is an educational portfolio demonstration, not a certified or production-ready enterprise quality management system.