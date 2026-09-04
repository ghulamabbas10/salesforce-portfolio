import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

const FIELDS = ['Case.Priority', 'Case.Status', 'Case.CreatedDate', 'Case.CaseNumber'];
const ESCALATION_THRESHOLD_HOURS = 4;

/**
 * CaseEscalationBanner
 *
 * Drop this on a Case record page. It shows a warning banner when a case is
 * High priority, still open, and has sat past ESCALATION_THRESHOLD_HOURS —
 * so agents notice at a glance instead of digging through list views.
 */
export default class CaseEscalationBanner extends LightningElement {
    @api recordId;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    caseRecord;

    get priority() {
        return this.caseRecord?.data?.fields?.Priority?.value;
    }

    get status() {
        return this.caseRecord?.data?.fields?.Status?.value;
    }

    get caseNumber() {
        return this.caseRecord?.data?.fields?.CaseNumber?.value;
    }

    get createdDate() {
        return this.caseRecord?.data?.fields?.CreatedDate?.value;
    }

    get hoursOpen() {
        if (!this.createdDate) {
            return 0;
        }
        const createdMs = new Date(this.createdDate).getTime();
        return (Date.now() - createdMs) / (1000 * 60 * 60);
    }

    get isEscalated() {
        return (
            this.priority === 'High' &&
            this.status !== 'Closed' &&
            this.hoursOpen >= ESCALATION_THRESHOLD_HOURS
        );
    }

    get bannerMessage() {
        return `Case ${this.caseNumber} is High priority and has been open for ${Math.floor(
            this.hoursOpen
        )}+ hours without resolution.`;
    }
}
