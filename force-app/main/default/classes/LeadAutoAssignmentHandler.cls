/**
 * LeadAutoAssignmentHandler
 *
 * Routes Leads to the correct owning Queue based on Lead Source.
 * Runs on insert (always) and on update (only when Lead Source changes),
 * so reps who've already started working a lead don't get it silently
 * reassigned for unrelated edits.
 *
 * Bulk-safe: single SOQL query outside any loop, no DML here (owner is
 * set on the in-memory records before they're saved by the platform).
 */
public with sharing class LeadAutoAssignmentHandler {

    // Extend this map as new lead sources / queues are added — no other code needs to change.
    private static final Map<String, String> SOURCE_TO_QUEUE = new Map<String, String>{
        'Web' => 'Web_Leads_Queue',
        'Referral' => 'Referral_Leads_Queue',
        'Partner' => 'Partner_Leads_Queue'
    };

    public static void assignOwnersOnInsert(List<Lead> newLeads) {
        assignOwners(newLeads, null);
    }

    public static void assignOwnersOnUpdate(List<Lead> newLeads, Map<Id, Lead> oldMap) {
        assignOwners(newLeads, oldMap);
    }

    private static void assignOwners(List<Lead> leads, Map<Id, Lead> oldMap) {
        Map<String, Id> queueNameToId = getQueueIdsByDeveloperName(
            new Set<String>(SOURCE_TO_QUEUE.values())
        );

        for (Lead ld : leads) {
            Boolean isNewRecord = (oldMap == null);
            Boolean sourceChanged = !isNewRecord
                && oldMap.get(ld.Id).LeadSource != ld.LeadSource;

            if ((isNewRecord || sourceChanged) && String.isNotBlank(ld.LeadSource)) {
                String queueDevName = SOURCE_TO_QUEUE.get(ld.LeadSource);
                if (queueDevName != null && queueNameToId.containsKey(queueDevName)) {
                    ld.OwnerId = queueNameToId.get(queueDevName);
                }
            }
        }
    }

    private static Map<String, Id> getQueueIdsByDeveloperName(Set<String> devNames) {
        Map<String, Id> result = new Map<String, Id>();
        for (Group g : [
            SELECT Id, DeveloperName
            FROM Group
            WHERE Type = 'Queue' AND DeveloperName IN :devNames
        ]) {
            result.put(g.DeveloperName, g.Id);
        }
        return result;
    }
}
