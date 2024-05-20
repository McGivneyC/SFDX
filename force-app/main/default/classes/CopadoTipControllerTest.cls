@isTest
public class CopadoTipControllerTest {
    
    @testSetup
    static void setupTestData() {
        // Create test data for CopadoTips__c object
        CopadoTips__c defaultTip = new CopadoTips__c(
            Name = 'Default Tip',
            TipDescription__c = 'This is the default tip',
            TipCategory__c = 'Best Practice',
            DefaultTip__c = true,
            TipStartTime__c = System.now().addDays(-1),
            TipEndTime__c = System.now().addDays(1)
        );
        insert defaultTip;

        CopadoTips__c randomTip = new CopadoTips__c(
            Name = 'Random Tip',
            TipDescription__c = 'This is a random tip',
            TipCategory__c = 'Best Practice',
            DefaultTip__c = false,
            TipStartTime__c = System.now().addDays(-2),
            TipEndTime__c = System.now().addDays(2)
        );
        insert randomTip;

        CopadoTips__c expiredTip = new CopadoTips__c(
            Name = 'Expired Default Tip',
            TipDescription__c = 'This is an expired default tip',
            TipCategory__c = 'Best Practice',
            DefaultTip__c = true,
            TipStartTime__c = System.now().addDays(-10),
            TipEndTime__c = System.now().addDays(-5)
        );
        insert expiredTip;
    }

    @isTest
    static void testGetTipsWithDefault() {
        Test.startTest();
        // Call the getTips method
        Map<String, CopadoTips__c> tips = CopadoTipController.getTips();
        Test.stopTest();
        
        // Verify that the default tip is returned
        System.assertNotEquals(null, tips.get('defaultTip'));
        System.assertEquals('Default Tip', tips.get('defaultTip').Name);
        System.assertEquals(null, tips.get('randomTip'));
    }

    @isTest
    static void testGetTipsWithoutDefault() {
        Test.startTest();
        // Deactivate the current default tip
        CopadoTips__c defaultTip = [SELECT Id FROM CopadoTips__c WHERE DefaultTip__c = TRUE LIMIT 1];
        defaultTip.DefaultTip__c = false;
        update defaultTip;

        // Call the getTips method
        Map<String, CopadoTips__c> tips = CopadoTipController.getTips();
        Test.stopTest();
        
        // Verify that the random tip is returned when no default tip is active
        System.assertEquals(null, tips.get('defaultTip'));
        System.assertNotEquals(null, tips.get('randomTip'));
        System.assertEquals('Random Tip', tips.get('randomTip').Name);
    }

    @isTest
    static void testResetDefaultTip() {
        Test.startTest();
        // Call the resetDefaultTip method
        CopadoTipController.resetDefaultTip();
        Test.stopTest();

        // Verify that the expired default tip is reset
        CopadoTips__c expiredTip = [SELECT Id, DefaultTip__c FROM CopadoTips__c WHERE Name = 'Expired Default Tip' LIMIT 1];
        System.assertEquals(false, expiredTip.DefaultTip__c);
    }
}
