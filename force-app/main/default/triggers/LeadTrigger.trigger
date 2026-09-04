/**
 * LeadTrigger
 * Thin trigger — all logic lives in LeadAutoAssignmentHandler.
 * Keeping triggers logic-free makes them easy to test, extend, and reason about
 * as more automation gets added over time.
 */
trigger LeadTrigger on Lead (before insert, before update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            LeadAutoAssignmentHandler.assignOwnersOnInsert(Trigger.new);
        }
        if (Trigger.isUpdate) {
            LeadAutoAssignmentHandler.assignOwnersOnUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}
