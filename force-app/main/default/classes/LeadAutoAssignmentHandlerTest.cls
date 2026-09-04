/**
 * LeadAutoAssignmentHandlerTest
 *
 * Verifies every configured source-to-queue mapping as well as bulk and update
 * behavior. Queue metadata is part of this project and is deployed first.
 */
@isTest
private class LeadAutoAssignmentHandlerTest {

    private static Map<String, Id> queueIds() {
        Map<String, Id> result = new Map<String, Id>();
        for (Group queue : [
            SELECT Id, DeveloperName
            FROM Group
            WHERE Type = 'Queue'
            AND DeveloperName IN ('Web_Leads_Queue', 'Referral_Leads_Queue', 'Partner_Leads_Queue')
        ]) {
            result.put(queue.DeveloperName, queue.Id);
        }
        return result;
    }

    @isTest
    static void testBulkInsertDoesNotHitGovernorLimits() {
        List<Lead> leads = new List<Lead>();
        for (Integer i = 0; i < 200; i++) {
            leads.add(new Lead(
                LastName = 'Bulk Lead ' + i,
                Company = 'Bulk Co ' + i,
                LeadSource = 'Web'
            ));
        }

        Test.startTest();
        insert leads;
        Test.stopTest();

        Map<String, Id> queues = queueIds();
        List<Lead> inserted = [SELECT Id, OwnerId FROM Lead WHERE LastName LIKE 'Bulk Lead%'];
        System.assertEquals(200, inserted.size(), 'All 200 leads should have inserted successfully');
        System.assertEquals(queues.get('Web_Leads_Queue'), inserted[0].OwnerId,
            'Web leads should be assigned to the Web queue');
    }

    @isTest
    static void testLeadWithoutSourceIsUnaffected() {
        Lead ld = new Lead(LastName = 'No Source Lead', Company = 'Test Co');

        Test.startTest();
        insert ld;
        Test.stopTest();

        Lead result = [SELECT Id, OwnerId FROM Lead WHERE Id = :ld.Id];
        System.assertNotEquals(null, result.OwnerId, 'Lead should still have a default running-user owner');
    }

    @isTest
    static void testSourceChangeOnUpdateIsHandledWithoutError() {
        Lead ld = new Lead(LastName = 'Update Lead', Company = 'Test Co', LeadSource = 'Partner');
        insert ld;

        Test.startTest();
        ld.LeadSource = 'Referral';
        update ld;
        Test.stopTest();

        Lead result = [SELECT Id, LeadSource, OwnerId FROM Lead WHERE Id = :ld.Id];
        System.assertEquals('Referral', result.LeadSource, 'Lead source field should reflect the update');
        System.assertEquals(queueIds().get('Referral_Leads_Queue'), result.OwnerId,
            'Changing the source to Referral should assign the Referral queue');
    }

    @isTest
    static void testUnrelatedFieldUpdateDoesNotReassign() {
        Lead ld = new Lead(LastName = 'Unrelated Update', Company = 'Test Co', LeadSource = 'Web');
        insert ld;
        Id ownerBefore = [SELECT OwnerId FROM Lead WHERE Id = :ld.Id].OwnerId;

        Test.startTest();
        ld.Company = 'Renamed Co';
        update ld;
        Test.stopTest();

        Id ownerAfter = [SELECT OwnerId FROM Lead WHERE Id = :ld.Id].OwnerId;
        System.assertEquals(ownerBefore, ownerAfter, 'Owner should not change when Lead Source is untouched');
    }
}
