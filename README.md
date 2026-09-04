# Salesforce Developer Portfolio

A deployable Salesforce DX project demonstrating bulk-safe Apex automation and a Lightning Web Component for service teams.

## Features

### Lead auto-assignment

`LeadTrigger` delegates to `LeadAutoAssignmentHandler`, which routes Leads by `LeadSource`:

| Lead Source | Queue |
|---|---|
| Web | Web Leads Queue |
| Referral | Referral Leads Queue |
| Partner | Partner Leads Queue |

The implementation uses one SOQL query per trigger execution, performs no DML inside loops, supports batches of 200 records, and avoids changing ownership during unrelated updates.

### Case escalation banner

`caseEscalationBanner` uses Lightning UI API to display a warning when a Case:

- has `High` priority;
- is not `Closed`; and
- has been open for at least four hours.

The included `Case_Record_Page` places the component in the page header and activates it for desktop and mobile.

## Project structure

```text
force-app/main/default/
|-- classes/       Apex handler and tests
|-- triggers/      Lead trigger
|-- lwc/           Case escalation banner
|-- queues/        Lead queue metadata
|-- flexipages/    Case Lightning record page
`-- objects/Case/  Case page activation metadata
```

## Prerequisites

- Salesforce CLI (`sf`)
- A Salesforce org with API access

## Deploy

```bash
sf org login web --alias portfolio-org --set-default
sf project deploy start --manifest manifest/package.xml --target-org portfolio-org
```

## Test

```bash
sf apex run test --tests LeadAutoAssignmentHandlerTest --result-format human --code-coverage --wait 10 --target-org portfolio-org
```

Manual acceptance checks:

1. Create Web, Referral, and Partner Leads and confirm their queue owners.
2. Open a High-priority, non-Closed Case older than four hours and confirm the warning banner appears.
3. Close the Case or reduce its priority and confirm the banner disappears.

## Security

Salesforce CLI state and credentials (`.sf/` and `.sfdx/`) are excluded from version control. Never commit an access token or SFDX authentication URL.
