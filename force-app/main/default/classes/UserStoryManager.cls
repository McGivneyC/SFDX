public class UserStoryManager {
    // Method to retrieve the project related to a user story
    public static copado__Project__c getProjectFromUserStory(Id userStoryId) {
        
        copado__User_Story__c userStory = [
            SELECT copado__Project__r.Id
            FROM copado__User_Story__c 
            WHERE Id = :userStoryId
            WITH SECURITY_ENFORCED

        ];
        System.debug(userStory.copado__Project__r);
        return userStory.copado__Project__r; // Returns the related Project record
    }
}