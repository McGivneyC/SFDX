@isTest
public class CopadoTipControllerTest {
    
    @isTest
    static void testGetRandomTip() {
        // Create test data
        CopadoTips__c testTip1 = new CopadoTips__c(Name = 'Test Tip 1', TipDescription__c = 'Test Description 1');
        CopadoTips__c testTip2 = new CopadoTips__c(Name = 'Test Tip 2', TipDescription__c = 'Test Description 2');
        insert new List<CopadoTips__c>{ testTip1, testTip2 };

        // Call the method being tested
        CopadoTips__c randomTip = CopadoTipController.getRandomTip();

        // Assert that the returned tip is not null
        System.assertNotEquals(null, randomTip, 'Returned tip should not be null');

        // Assert that the returned tip is one of the test tips
        System.assertEquals(true, randomTip.Name == 'Test Tip 1' || randomTip.Name == 'Test Tip 2', 'Returned tip should be one of the test tips');
    }
}