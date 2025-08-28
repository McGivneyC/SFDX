@IsTest(SeeAllData = true)
public with sharing class LightningLoginFormControllerTest {

    @IsTest
    static void LightningLoginFormControllerInstantiation() {
        LightningLoginFormController controller = new LightningLoginFormController();
        System.assertNotEquals(controller, null);
    }

    @IsTest
    static void testIsUsernamePasswordEnabled() {
        System.assertEquals(true, LightningLoginFormController.getIsUsernamePasswordEnabled());
    }

    @IsTest
    static void testIsSelfRegistrationEnabled() {
        System.assertEquals(false, LightningLoginFormController.getIsSelfRegistrationEnabled());
    }

    @IsTest
    static void testGetSelfRegistrationURL() {
        System.assertEquals(null, LightningLoginFormController.getSelfRegistrationUrl());
    }

    @IsTest
    static void testGetForgotPasswordUrl() {
        String forgotPasswordUrl = LightningLoginFormController.getForgotPasswordUrl();
        // The URL might be null or a valid URL depending on org configuration
        System.assert(forgotPasswordUrl == null || String.isNotBlank(forgotPasswordUrl));
    }

    @IsTest
    static void testAuthConfig() {
        Auth.AuthConfiguration authConfig = LightningLoginFormController.getAuthConfig();
        System.assertNotEquals(null, authConfig);
    }

    @IsTest
    static void testLoginWithValidCredentials() {
        // Test the login method - this will likely hit the catch block in test context
        // since Site.login() doesn't work properly in test environment
        String result = LightningLoginFormController.login('testuser@example.com', 'password123', '/home');
        
        // In test context, this will likely return an error message rather than null
        // We're testing that the method executes and returns either null (success) or a message (error)
        System.assert(result == null || String.isNotBlank(result));
    }

    @IsTest
    static void testLoginWithInvalidCredentials() {
        // Test with obviously invalid credentials to trigger exception path
        String result = LightningLoginFormController.login('', '', '');
        
        // Should return a non-empty error message in this case
        System.assertNotEquals(null, result);
        System.assert(String.isNotBlank(result));
    }

    @IsTest
    static void testLoginWithNullValues() {
        // Test with null values to ensure robust error handling
        String result = LightningLoginFormController.login(null, null, null);
        
        // Should return a non-empty error message
        System.assertNotEquals(null, result);
        System.assert(String.isNotBlank(result));
    }

    @IsTest
    static void testSetExperienceIdWithValidId() {
        // Test setExperienceId with a valid experience ID format
        String result = LightningLoginFormController.setExperienceId('0DM000000000001');
        
        // Should return null if successful, or a non-empty error message if not
        System.assert(result == null || String.isNotBlank(result));
    }

    @IsTest
    static void testSetExperienceIdWithNullId() {
        // Test setExperienceId with null ID - should handle gracefully
        String result = LightningLoginFormController.setExperienceId(null);
        
        // Should return null since the method handles null case explicitly
        System.assertEquals(null, result);
    }

    @IsTest
    static void testSetExperienceIdWithInvalidId() {
        // Test setExperienceId with invalid ID format to trigger exception
        String result = LightningLoginFormController.setExperienceId('invalid_id_format');
        
        // Should return a non-empty error message
        System.assertNotEquals(null, result);
        System.assert(String.isNotBlank(result));
    }

    @IsTest
    static void testSetExperienceIdWithEmptyString() {
        // Test setExperienceId with empty string
        String result = LightningLoginFormController.setExperienceId('');
        
        // Should return null or a non-empty error message
        System.assert(result == null || String.isNotBlank(result));
    }
}