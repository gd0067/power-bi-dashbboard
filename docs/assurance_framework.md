# Revenue Assurance & Financial Governance Framework
**Enterprise Standard Operating Procedure (SOP)**  
**Target:** Commercial Operations, Internal Audit, Financial Controllership

---

## 1. Executive Summary

Revenue leakage and operational non-compliance represent substantial profit erosion in omnichannel retail and enterprise commerce. This framework formalizes the anomaly detection algorithms, escalation workflows, and risk mitigation procedures embedded across our SQL Data Warehouse and Power BI analytics dashboard.

---

## 2. Risk Taxonomy & Threshold Matrix

| Risk Category | Anomaly Trigger / Condition | Severity Tier | Financial Impact | Automated Action / Escalation |
| :--- | :--- | :--- | :--- | :--- |
| **Negative Margin Override** | Realized Unit Price < Unit Cost (`GrossMargin < 0`) | **Critical** | Direct margin cash loss | Automated hold on sales rep commission; mandatory VP Commercial sign-off. |
| **Rogue Discount Leakage** | Discount % >= 25.00% without Delegation of Authority (DoA) code | **High** | Diluted top-line revenue & margin compression | Automated flag into `fact_assurance_audit_logs`; escalation to Regional Sales Director. |
| **Disputed Settlement Exposure** | Unpaid balance with payment status `Disputed Settlement` & Credit Rating BBB/BB | **High** | Bad debt write-off risk | Credit lock applied to customer account; legal notice protocol initiated. |
| **Operational SLA Breach** | Delivery shipping transit time exceeds guaranteed carrier window (e.g. SLA-24 > 4 days) | **Medium** | Carrier penalty & customer goodwill concessions | Freight invoice clawback claim filed automatically with 3PL logistics partner. |

---

## 3. The 4-Stage Assurance Life Cycle

```
┌─────────────────┐       Trigger Met       ┌─────────────────┐
│ 1. DETECTION    │ ──────────────────────> │ 2. LOGGING      │
│ - Daily SQL sp  │                         │ - Record into   │
│ - VertiPaq DAX  │                         │   Audit Table   │
└─────────────────┘                         └─────────────────┘
                                                     │
                                                     ▼
┌─────────────────┐      Audit Review       ┌─────────────────┐
│ 4. RESOLUTION   │ <────────────────────── │ 3. INVESTIGATION│
│ - System Fix    │                         │ - Root Cause    │
│ - Clawback Sign │                         │ - Stakeholder   │
└─────────────────┘                         └─────────────────┘
```

1. **Detection:** Daily automated batch execution (`edw.sp_RunRevenueAssuranceAudit`) screens all newly staged transactional line items against governance rules.
2. **Logging:** Identified anomalies are committed to `edw.FactAssuranceAuditLogs` with calculated financial exposure and unique `AuditLogID`.
3. **Investigation:** Internal audit analysts access Page 2 and Page 4 of the Power BI Assurance Dashboard to inspect line-item histories, price books, and sales representative behavior.
4. **Resolution & Sign-off:** Findings are marked as either `Resolved - Mitigated` (e.g., retro-invoice generated, freight credit received) or escalated to executive governance.
