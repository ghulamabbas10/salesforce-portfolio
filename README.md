# Salesforce Developer Portfolio — Ghulam Abbas

A small SFDX-structured repo showcasing hands-on Apex and Lightning Web Component work, built to demonstrate real Salesforce development patterns (trigger handler framework, bulkification, wire service, SLDS styling).

## What's inside

| Feature | Type | Folder |
|---|---|---|
| Lead Auto-Assignment | Apex Trigger + Handler + Test Class | `force-app/main/default/triggers`, `classes` |
| Case Escalation Banner | Lightning Web Component | `force-app/main/default/lwc/caseEscalationBanner` |

## 1. Lead Auto-Assignment (Apex)

**Business problem:** Inbound leads sat unassigned for hours because owner assignment was manual. This trigger routes new/updated leads to the correct queue based on Lead Source, in bulk-safe fashion, using a trigger-handler pattern (no logic in the trigger itself).

- `LeadTrigger.trigger` — thin trigger, delegates to handler
- `LeadAutoAssignmentHandler.cls` — bulkified assignment logic, one SOQL query outside the loop
- `LeadAutoAssignmentHandlerTest.cls` — bulk insert test (200 records), update test, negative-path test

## 2. Case Escalation Banner (LWC)

**Business problem:** Support agents were missing high-priority cases that sat open too long. This component renders a warning banner directly on the Case record page when a case is `High` priority, not `Closed`, and has been open past a configurable threshold.

- Uses `@wire(getRecord)` from `lightning/uiRecordApi` — no Apex call needed for this data
- Configurable via a single constant (`ESCALATION_THRESHOLD_HOURS`)
- Styled with SLDS utility classes, no custom framework dependencies

## Tech

Apex · Lightning Web Components · SOQL · SLDS · SFDX project structure

## Deploying

This repo follows standard SFDX layout. To deploy to a scratch org or sandbox:

```bash
sf project deploy start --source-dir force-app
```

Note: the queues referenced in `LeadAutoAssignmentHandler.cls` (`Web_Leads_Queue`, `Referral_Leads_Queue`, `Partner_Leads_Queue`) need to exist in the target org for owner assignment to take effect — the code degrades gracefully (no error) if they don't.
