@isTest
public class UserStoryManagerTest {
    
    // Utility method to create a test integration setting record (required field) project
    private static copado__Project__c createTestProject() {
    copadoccmint__Copado_Integration_Setting__c integrationSetting = new copadoccmint__Copado_Integration_Setting__c(Name = 'Test Integration', copadoccmint__Named_Credential__c = 'Test', copadoccmint__External_System__c = 'Jira');
         insert integrationSetting;
         
        
    copado__Project__c project = new copado__Project__c(Name = 'Test Project', copadoccmint__Copado_Integration_Setting__c = IntegrationSetting.Id);
        insert project;
        return project;
    }
    
    // Utility method to create a test user story linked to a project
    private static copado__User_Story__c createTestUserStory(copado__Project__c project) {
        copado__User_Story__c userStory = new copado__User_Story__c(
            copado__User_Story_Title__c = 'Test User Story',
            copado__Project__c = project.Id
        );
        insert userStory;
        return userStory;
    }
    
    // Test method to verify that the correct project is retrieved from a user story
    @isTest
    static void testGetProjectFromUserStory() {
        // Setup test data
        copado__Project__c testProject = createTestProject();
        copado__User_Story__c testUserStory = createTestUserStory(testProject);
        
        // Test
        Test.startTest();
        copado__Project__c retrievedProject = UserStoryManager.getProjectFromUserStory(testUserStory.Id);
        Test.stopTest();
        
        // Verify
        System.assertEquals(testProject.Id, retrievedProject.Id, 'The retrieved project should match the one related to the user story');
    }
}