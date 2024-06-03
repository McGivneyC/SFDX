@isTest
private class CopadoTipControllerTest {

    @isTest
    static void testGetTipsWithNullUserStoryId() {
        Map<String, CopadoTips__c> tips = CopadoTipController.getTips(null);
        System.assertEquals(0, tips.size(), 'Expected an empty map when userStoryId is null');
    }

    @isTest
    static void testGetTipsWithNoAssociatedProject() {
        // Setup test data
        copado__User_Story__c userStory = new copado__User_Story__c();
        insert userStory;

        Map<String, CopadoTips__c> tips = CopadoTipController.getTips(userStory.Id);
        System.assertEquals(0, tips.size(), 'Expected an empty map when there is no associated project');
    }

    @isTest
    static void testGetTipsWithNoDefaultTip() {
        // Setup test data
        copado__User_Story__c userStory = setupUserStoryAndProject();
        // No default tips are created

        Map<String, CopadoTips__c> tips = CopadoTipController.getTips(userStory.Id);
        System.assert(tips.isEmpty() || tips.containsKey('randomTip'), 'Expected an empty map or a map with a random tip');
    }

    @isTest
    static void testGetTipsWithDefaultTip() {
        Test.startTest();
        // Setup test data
        copado__User_Story__c userStory = setupUserStoryAndProject();
        CopadoTips__c defaultTip = new CopadoTips__c(
            Name = 'Default Tip',
            TipDescription__c = 'This is a default tip',
            TipCategory__c = 'Other',
            DefaultTip__c = true,
            TipStartTime__c = Datetime.now().addDays(-1),
            TipEndTime__c = Datetime.now().addDays(1)
        );
        insert defaultTip;

        Map<String, CopadoTips__c> tips = CopadoTipController.getTips(userStory.Id);
        Test.stopTest();
        
        System.debug('Tips: ' + tips);
        System.debug('UserStory: ' + userStory.Id);
        System.assertEquals(1, tips.size(), 'Expected a map with one default tip');
        System.assertEquals('Default Tip', tips.get('defaultTip').Name, 'Expected the default tip to be returned');
    }

 private static copado__User_Story__c setupUserStoryAndProject() {
    copado__Project__c project = new copado__Project__c(Name = 'Test Project', copadoccmint__Copado_Integration_Setting__c = 'a1rDy000001pxuuIAA');
    insert project;

    copado__User_Story__c userStory = new copado__User_Story__c(copado__User_Story_Title__c = 'Test User Story', copado__Project__c = project.Id);
    insert userStory;

    return userStory;
}
}