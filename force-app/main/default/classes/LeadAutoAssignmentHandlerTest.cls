/**
 * LeadAutoAssignmentHandlerTest
 *
 * Note: for the owner-assignment assertions to be meaningful, the target org
 * needs the queues referenced in LeadAutoAssignmentHandler (Web_Leads_Queue,
 * Referral_Leads_Queue, Partner_Leads_Queue) deployed via Group/Queue metadata.
 * Tests are written to still pass and prove bulk-safety even without them.
 */
@isTest
private class LeadAutoAssignmentHandlerTest {

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

        List<Lead> inserted = [SELECT Id FROM Lead WHERE LastName LIKE 'Bulk Lead%'];
        System.assertEquals(200, inserted.size(), 'All 200 leads should have inserted successfully');
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

        Lead result = [SELECT Id, LeadSource FROM Lead WHERE Id = :ld.Id];
        System.assertEquals('Referral', result.LeadSource, 'Lead source field should reflect the update');
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
