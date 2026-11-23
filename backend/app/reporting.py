
from decimal import Decimal
from io import BytesIO
from xml.sax.saxutils import escape

from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT, TA_RIGHT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, KeepTogether


def build_report(complaint: dict, actions: list[dict], events: list[dict]) -> bytes:
    output = BytesIO()
    document = SimpleDocTemplate(
        output, pagesize=A4, leftMargin=42, rightMargin=42, topMargin=42,
        bottomMargin=42, title=f"{complaint['reference']} | Complaint Report"
    )
    styles = getSampleStyleSheet()
    styles.add(ParagraphStyle(name='ReportHeading', parent=styles['Heading1'],
        textColor=colors.HexColor('#172554'), fontSize=17, spaceAfter=10))
    styles.add(ParagraphStyle(name='ReportSection', parent=styles['Heading2'],
        textColor=colors.HexColor('#1D4ED8'), spaceBefore=16, spaceAfter=7))
    styles.add(ParagraphStyle(name='ReportText', parent=styles['BodyText'],
        leading=15, spaceAfter=6))
    styles.add(ParagraphStyle(name='CostLabel', parent=styles['BodyText'],
        fontSize=10, leading=14))
    styles.add(ParagraphStyle(name='CostValue', parent=styles['BodyText'],
        fontSize=10, leading=14, alignment=TA_RIGHT))
    styles.add(ParagraphStyle(name='CostTotal', parent=styles['BodyText'],
        fontSize=11, leading=15, textColor=colors.HexColor('#172554'),
        fontName='Helvetica-Bold'))

    story = [
        Paragraph('QUALITYFLOW | COMPLAINT REPORT', styles['ReportHeading']),
        Paragraph('Portfolio demonstration - All sample organizations and records are fictional',
            styles['ReportText']),
        Spacer(1, 12),
    ]

    def display(value) -> str:
        return 'Not provided' if value is None or value == '' else str(value)

    def line(label: str, value) -> Paragraph:
        return Paragraph(
            f'<b>{escape(label)}:</b> {escape(display(value))}',
            styles['ReportText']
        )

    def section(title: str, rows: list[tuple[str, object]]) -> None:
        story.append(Paragraph(title, styles['ReportSection']))
        for label, value in rows:
            story.append(line(label, value))

    def money(value) -> str:
        if value is None or value == '':
            return 'Not recorded'
        return f'EUR {Decimal(str(value)):,.2f}'

    section('Complaint overview', [
        ('Reference', complaint['reference']),
        ('Title', complaint['title']),
        ('Status', complaint['status']),
        ('Customer', complaint['customer']),
        ('Item', complaint['item_code']),
        ('Category', complaint['category']),
        ('Severity', complaint['severity']),
        ('Reporter', complaint['reporter']),
        ('Assigned to', complaint['assigned_to']),
        ('Affected quantity', complaint['affected_quantity']),
        ('Rejected quantity', complaint['rejected_quantity']),
        ('Description', complaint['description']),
    ])

    section('Containment', [
        ('Immediate containment action', complaint.get('containment_action')),
    ])

    section('Investigation', [
        ('Root cause', complaint.get('root_cause')),
    ])

    story.append(Paragraph('Corrective actions', styles['ReportSection']))
    if actions:
        cells = [['Action', 'Owner', 'Due', 'Status']]
        for action in actions:
            cells.append([
                Paragraph(escape(str(action[field])), styles['ReportText'])
                for field in ('title', 'owner', 'due_date', 'status')
            ])
        table = Table(cells, colWidths=[215, 96, 73, 86], repeatRows=1, hAlign='LEFT')
        table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#DBEAFE')),
            ('GRID', (0, 0), (-1, -1), 0.35, colors.HexColor('#CBD5E1')),
            ('VALIGN', (0, 0), (-1, -1), 'TOP'),
            ('TOPPADDING', (0, 0), (-1, -1), 7),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 7),
        ]))
        story.append(table)
    else:
        story.append(Paragraph('No corrective actions recorded.', styles['ReportText']))

    section('Effectiveness verification', [
        ('Result', complaint.get('verification_result')),
        ('Reviewed by', complaint.get('verified_by')),
        ('Verification notes', complaint.get('verification_notes')),
    ])

    cost_fields = [
        ('Scrap cost', 'scrap_cost'),
        ('Rework cost', 'rework_cost'),
        ('Inspection cost', 'inspection_cost'),
        ('Other costs', 'other_cost'),
    ]
    recorded_values = [
        Decimal(str(complaint[key]))
        for _, key in cost_fields
        if complaint.get(key) is not None
    ]
    actual_total = sum(recorded_values, Decimal('0')) if recorded_values else None

    cost_rows = [
        [
            Paragraph('Estimated financial impact', styles['CostLabel']),
            Paragraph(money(complaint.get('estimated_cost')), styles['CostValue']),
        ],
    ]
    for label, key in cost_fields:
        cost_rows.append([
            Paragraph(escape(label), styles['CostLabel']),
            Paragraph(escape(money(complaint.get(key))), styles['CostValue']),
        ])

    cost_rows.append([
        Paragraph('TOTAL RECORDED QUALITY COST', styles['CostTotal']),
        Paragraph(money(actual_total), styles['CostTotal']),
    ])

    cost_table = Table(cost_rows, colWidths=[310, 160], hAlign='LEFT')
    cost_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#EFF6FF')),
        ('BACKGROUND', (0, -1), (-1, -1), colors.HexColor('#DBEAFE')),
        ('LINEABOVE', (0, -1), (-1, -1), 1, colors.HexColor('#93C5FD')),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('TOPPADDING', (0, 0), (-1, -1), 8),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
        ('LEFTPADDING', (0, 0), (-1, -1), 10),
        ('RIGHTPADDING', (0, 0), (-1, -1), 10),
    ]))

    story.append(KeepTogether([
        Paragraph('Quality costs', styles['ReportSection']),
        cost_table,
    ]))
    story.append(Spacer(1, 6))
    story.append(Paragraph(
        'Recorded costs represent the sum of available actual cost values. '
        'Unrecorded categories are excluded; the estimate is not included in the total.',
        styles['ReportText'],
    ))

    document.build(story)
    return output.getvalue()
