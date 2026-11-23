# Five-minute walkthrough for portfolio reviewers

## Goal

Demonstrate a small but meaningful industrial quality workflow instead of generic create/read/update/delete operations.

1. **Dashboard** — Show active complaints, closure rate, severity and overdue actions. All sample data is fictional.
2. **Complaint register** — Search, filter by severity or status and open a case.
3. **New complaint** — Enter customer, product, owner, affected and rejected quantities. Try rejected quantity greater than affected to demonstrate input validation.
4. **Containment** — Save an immediate containment action, then start investigation. Try advancing before saving to see the workflow guard.
5. **Investigation** — Document root cause. Add a corrective action with owner and due date; try submitting before marking it complete. Mark completed, then submit for verification.
6. **Verification** — Record `Ineffective` and return to investigation for rework, or record `Effective`, add evidence and reviewer and close the complaint.
7. **History** — Show entries for the original registration, section updates, actions and transitions.
8. **API mode** — Repeat using local PostgreSQL persistence, inspect `/docs`, and export a report PDF.

## Talking points

- The Flutter interface is intentionally separate from storage behind a repository abstraction.
- FastAPI validates transitions independently from frontend controls.
- PostgreSQL handles identity sequences, related records and transactional updates.
- Actor names are for demonstration; real authentication and verified audit logs are out of scope.
- Tests cover critical workflow constraints and PDF generation.
- Production would require identity, authorization, transport security and additional hardening.

## Suggested screenshots

- Dashboard with seeded fictional metrics
- Complaint lifecycle view with visible workflow progress
- Corrective action tracker showing owners and due dates
- Verification and activity history
- Generated PDF in API mode
