from io import BytesIO
from xml.sax.saxutils import escape
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_LEFT
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, KeepTogether


def build_report(complaint: dict, actions: list[dict], events: list[dict]) -> bytes:
    output = BytesIO()
    document = SimpleDocTemplate(output, pagesize=A4, leftMargin=42, rightMargin=42, topMargin=42, bottomMargin=42, title=f"{complaint['reference']} | Complaint Report")
    styles = getSampleStyleSheet()
    styles.add(ParagraphStyle(name='ReportHeading', parent=styles['Heading1'], textColor=colors.HexColor('#172554'), fontSize=17, spaceAfter=10))
    styles.add(ParagraphStyle(name='ReportSection', parent=styles['Heading2'], textColor=colors.HexColor('#1D4ED8'), spaceBefore=16, spaceAfter=7))
    styles.add(ParagraphStyle(name='ReportText', parent=styles['BodyText'], leading=15, spaceAfter=6))
    story = [Paragraph('COMPLAINT MANAGEMENT FLOW', styles['ReportHeading']), Paragraph('Portfolio demonstration · All sample organizations and records are fictional', styles['ReportText']), Spacer(1, 12)]

    def line(label: str, value) -> Paragraph:
        return Paragraph(f'<b>{escape(label)}:</b> {escape(str(value or "Not provided"))}', styles['ReportText'])

    def section(title: str, rows: list[tuple[str, object]]) -> None:
        story.append(Paragraph(title, styles['ReportSection']))
        for label, value in rows:
            story.append(line(label, value))

    section('Complaint overview', [
        ('Reference', complaint['reference']), ('Title', complaint['title']), ('Status', complaint['status']),
        ('Customer', complaint['customer']), ('Item', complaint['item_code']), ('Category', complaint['category']),
        ('Severity', complaint['severity']), ('Reporter', complaint['reporter']), ('Assigned to', complaint['assigned_to']),
        ('Affected quantity', complaint['affected_quantity']), ('Rejected quantity', complaint['rejected_quantity']),
        ('Description', complaint['description']),
    ])
    section('Containment', [('Immediate containment action', complaint.get('containment_action'))])
    section('Investigation', [('Root cause', complaint.get('root_cause'))])
    story.append(Paragraph('Corrective actions', styles['ReportSection']))
    if actions:
        cells = [['Action', 'Owner', 'Due', 'Status']]
        for action in actions:
            cells.append([Paragraph(escape(str(action[field])), styles['ReportText']) for field in ('title', 'owner', 'due_date', 'status')])
        table = Table(cells, colWidths=[215, 96, 73, 86], repeatRows=1, hAlign='LEFT')
        table.setStyle(TableStyle([('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#DBEAFE')), ('GRID', (0, 0), (-1, -1), 0.35, colors.HexColor('#CBD5E1')), ('VALIGN', (0, 0), (-1, -1), 'TOP'), ('TOPPADDING', (0, 0), (-1, -1), 7), ('BOTTOMPADDING', (0, 0), (-1, -1), 7)]))
        story.append(table)
    else:
        story.append(Paragraph('No corrective actions recorded.', styles['ReportText']))
    section('Effectiveness verification', [('Result', complaint.get('verification_result')), ('Reviewed by', complaint.get('verified_by')), ('Verification notes', complaint.get('verification_notes'))])
    story.append(Paragraph('Activity history', styles['ReportSection']))
    for event in events[:30]:
        story.append(line(str(event['created_at']), f"{event['actor']} · {event['message']}"))
    if not events:
        story.append(Paragraph('No events recorded.', styles['ReportText']))
    document.build(story)
    return output.getvalue()
