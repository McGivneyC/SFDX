@isTest
public class DeleteCalloutLogsTest {

    @testSetup
    static void setup() {
        // Create test records older than 30 days
        List<copadoccmint__Callout_Log__c> calloutLogs = new List<copadoccmint__Callout_Log__c>();
        for (Integer i = 0; i < 200; i++) {
            calloutLogs.add(new copadoccmint__Callout_Log__c(copadoccmint__Response_Body__c='Test Response', copadoccmint__Status_Code__c='200'));
        }
        insert calloutLogs;

        // Create test records within the last 30 days
        List<copadoccmint__Callout_Log__c> recentCalloutLogs = new List<copadoccmint__Callout_Log__c>();
        for (Integer i = 0; i < 100; i++) {
            recentCalloutLogs.add(new copadoccmint__Callout_Log__c(copadoccmint__Response_Body__c='Test Response', copadoccmint__Status_Code__c='200'));
        }
        insert recentCalloutLogs;
    }

    @isTest
    static void testDeleteCalloutLogs() {
        Test.startTest();
        // Set the batch size to 50
        Database.executeBatch(new DeleteCalloutLogs(), 50);
        Test.stopTest();

        // Verify that no callout logs older than 5 days exist
        List<copadoccmint__Callout_Log__c> remainingCalloutLogs = [SELECT Id FROM copadoccmint__Callout_Log__c WHERE CreatedDate < LAST_N_DAYS:5];
        System.assertEquals(0, remainingCalloutLogs.size());

        // Verify that recent callout logs within the last 5 days still exist
        List<copadoccmint__Callout_Log__c> recentCalloutLogs = [SELECT Id FROM copadoccmint__Callout_Log__c WHERE CreatedDate >= LAST_N_DAYS:5];
        System.assertNotEquals(0, recentCalloutLogs.size());
    }
}