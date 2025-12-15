/**
 * @description Resolves Git Repository credentials and information from various Copado objects
 * Supports both Metadata Format (Git Snapshot) and Source Format (Git Repository) pipelines
 * 
 * @author Copado AI Assistant
 * @date 2025-12-14
 * @version 2.0 - Full Production Version
 */
public with sharing class GitCredentialResolver {
    
    // Inner class to return structured results
    public class GitCredentialResult {
        @InvocableVariable(label='Success' description='Whether the operation succeeded')
        public Boolean success;
        
        @InvocableVariable(label='Error Message' description='Error message if operation failed')
        public String errorMessage;
        
        @InvocableVariable(label='Git JSON' description='Complete git_json parameter for Copado Functions')
        public String gitJson;
        
        @InvocableVariable(label='Repository ID' description='Salesforce ID of the Git Repository')
        public String repositoryId;
        
        @InvocableVariable(label='Repository Name' description='Name of the Git Repository')
        public String repositoryName;
        
        @InvocableVariable(label='Repository URI' description='Git Repository URI/URL')
        public String repositoryUri;
        
        @InvocableVariable(label='Branch Name' description='Git Branch Name')
        public String branchName;
        
        @InvocableVariable(label='Pipeline Type' description='Metadata Format or Source Format')
        public String pipelineType;
        
        @InvocableVariable(label='Org Credential ID' description='ID of the Org Credential if found')
        public String orgCredentialId;
        
        @InvocableVariable(label='Pipeline ID' description='ID of the Deployment Flow/Pipeline')
        public String pipelineId;
    }
    
    // Input parameter for the invocable method
    public class GitCredentialRequest {
        @InvocableVariable(required=true label='Environment ID' description='Salesforce ID of the Environment record')
        public String environmentId;
    }
    
    /**
     * @description Main invocable method to resolve Git credentials from an Environment
     * @param requests List of GitCredentialRequest objects
     * @return List of GitCredentialResult objects
     */
    @InvocableMethod(label='Get Git Repository Info' description='Resolves Git Repository information from an Environment record' category='Copado')
    public static List<GitCredentialResult> getGitCredential(List<GitCredentialRequest> requests) {
        List<GitCredentialResult> results = new List<GitCredentialResult>();
        
        for (GitCredentialRequest request : requests) {
            results.add(resolveGitCredential(request.environmentId));
        }
        
        return results;
    }
    
    /**
     * @description Core logic to resolve Git credentials
     * @param environmentId Salesforce ID of the Environment
     * @return GitCredentialResult with all Git information
     */
    private static GitCredentialResult resolveGitCredential(String environmentId) {
        GitCredentialResult result = new GitCredentialResult();
        result.success = false;
        
        try {
            // Step 1: Get the Environment record
            copado__Environment__c environment = getEnvironment(environmentId);
            if (environment == null) {
                result.errorMessage = 'Environment not found: ' + environmentId;
                return result;
            }
            
            // Step 2: Try to find Org Credential directly on Environment
            String orgCredentialId = getOrgCredentialFromEnvironment(environment);
            
            // Step 3: If no direct Org Credential, find via Pipeline
            if (String.isBlank(orgCredentialId)) {
                orgCredentialId = getOrgCredentialFromPipeline(environmentId);
            }
            
            // Step 4: If still no Org Credential, check for any Org Credential linked to this Environment
            if (String.isBlank(orgCredentialId)) {
                orgCredentialId = getAnyOrgCredentialForEnvironment(environmentId);
            }
            
            if (String.isBlank(orgCredentialId)) {
                result.errorMessage = buildDetailedErrorMessage(environment);
                return result;
            }
            
            result.orgCredentialId = orgCredentialId;
            
            // Step 5: Get Git Repository information
            GitRepositoryInfo repoInfo = getGitRepositoryInfo(orgCredentialId, environmentId);
            
            if (repoInfo == null || String.isBlank(repoInfo.repositoryId)) {
                result.errorMessage = buildGitRepoErrorMessage(orgCredentialId, environmentId);
                return result;
            }
            
            // Step 6: Populate result
            result.success = true;
            result.repositoryId = repoInfo.repositoryId;
            result.repositoryName = repoInfo.repositoryName;
            result.repositoryUri = repoInfo.repositoryUri;
            result.branchName = repoInfo.branchName;
            result.pipelineType = repoInfo.pipelineType;
            result.pipelineId = repoInfo.pipelineId;
            
            // Step 7: Build git_json parameter
            result.gitJson = buildGitJson(repoInfo);
            
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = 'Unexpected error: ' + e.getMessage() + '\n' + e.getStackTraceString();
        }
        
        return result;
    }
    
    /**
     * @description Get Environment record with related fields
     */
    private static copado__Environment__c getEnvironment(String environmentId) {
        List<copado__Environment__c> environments = [
            SELECT Id, Name, copado__Org_ID__c, copado__Platform__c,
                   copado__Type__c, Branch_Name__c
            FROM copado__Environment__c
            WHERE Id = :environmentId
            LIMIT 1
        ];
        
        return environments.isEmpty() ? null : environments[0];
    }
    
    /**
     * @description Try to get Org Credential directly from Environment
     */
    private static String getOrgCredentialFromEnvironment(copado__Environment__c environment) {
        // Check if there's a direct lookup field (some orgs have custom fields)
        // This is a fallback - most Copado setups don't have this
        return null; // Override this if your org has a custom field
    }
    
    /**
     * @description Find Org Credential via Pipeline (Deployment Flow)
     */
    private static String getOrgCredentialFromPipeline(String environmentId) {
        // Find all Deployment Flow Steps that reference this Environment
        List<copado__Deployment_Flow_Step__c> steps = [
            SELECT Id, copado__Source_Environment__c, copado__Destination_Environment__c,
                   copado__Deployment_Flow__c, copado__Deployment_Flow__r.copado__Git_Repository__c,
                   copado__Branch__c
            FROM copado__Deployment_Flow_Step__c
            WHERE copado__Source_Environment__c = :environmentId
               OR copado__Destination_Environment__c = :environmentId
            LIMIT 1
        ];
        
        if (steps.isEmpty()) {
            return null;
        }
        
        // Now find an Org Credential for this Environment
        List<copado__Org__c> orgCredentials = [
            SELECT Id, Name, copado__Environment__c
            FROM copado__Org__c
            WHERE copado__Environment__c = :environmentId
            AND copado__Oauth_Signature__c != null
            ORDER BY LastModifiedDate DESC
            LIMIT 1
        ];
        
        return orgCredentials.isEmpty() ? null : orgCredentials[0].Id;
    }
    
    /**
     * @description Find any Org Credential linked to this Environment
     */
    private static String getAnyOrgCredentialForEnvironment(String environmentId) {
        List<copado__Org__c> orgCredentials = [
            SELECT Id, Name, copado__Environment__c
            FROM copado__Org__c
            WHERE copado__Environment__c = :environmentId
            ORDER BY LastModifiedDate DESC
            LIMIT 1
        ];
        
        return orgCredentials.isEmpty() ? null : orgCredentials[0].Id;
    }
    
    /**
     * @description Inner class to hold Git Repository information
     */
    private class GitRepositoryInfo {
        String repositoryId;
        String repositoryName;
        String repositoryUri;
        String branchName;
        String pipelineType;
        String pipelineId;
    }
    
    /**
     * @description Get Git Repository information from Org Credential and Environment
     */
    private static GitRepositoryInfo getGitRepositoryInfo(String orgCredentialId, String environmentId) {
        GitRepositoryInfo info = new GitRepositoryInfo();
        
        // First, try Source Format (Git Repository)
        info = getGitRepoFromSourceFormat(environmentId);
        
        if (info != null && String.isNotBlank(info.repositoryId)) {
            info.pipelineType = 'Source Format';
            return info;
        }
        
        // Second, try Metadata Format (Git Snapshot)
        info = getGitRepoFromMetadataFormat(orgCredentialId);
        
        if (info != null && String.isNotBlank(info.repositoryId)) {
            info.pipelineType = 'Metadata Format';
            return info;
        }
        
        return null;
    }
    
    /**
     * @description Get Git Repository from Source Format Pipeline
     */
    private static GitRepositoryInfo getGitRepoFromSourceFormat(String environmentId) {
        // Find Deployment Flow Steps for this Environment
        List<copado__Deployment_Flow_Step__c> steps = [
            SELECT Id, copado__Source_Environment__c, copado__Destination_Environment__c,
                   copado__Deployment_Flow__c, copado__Deployment_Flow__r.copado__Git_Repository__c,
                   copado__Deployment_Flow__r.copado__Git_Repository__r.Name,
                   copado__Deployment_Flow__r.copado__Git_Repository__r.copado__URI__c,
                   copado__Branch__c, copado__Deployment_Flow__r.copado__Main_Branch__c
            FROM copado__Deployment_Flow_Step__c
            WHERE (copado__Source_Environment__c = :environmentId
                   OR copado__Destination_Environment__c = :environmentId)
            AND copado__Deployment_Flow__r.copado__Git_Repository__c != null
            ORDER BY LastModifiedDate DESC
            LIMIT 1
        ];
        
        if (steps.isEmpty()) {
            return null;
        }
        
        copado__Deployment_Flow_Step__c step = steps[0];
        GitRepositoryInfo info = new GitRepositoryInfo();
        
        info.repositoryId = step.copado__Deployment_Flow__r.copado__Git_Repository__c;
        info.repositoryName = step.copado__Deployment_Flow__r.copado__Git_Repository__r.Name;
        info.repositoryUri = step.copado__Deployment_Flow__r.copado__Git_Repository__r.copado__URI__c;
        info.pipelineId = step.copado__Deployment_Flow__c;
        
        // Determine branch name
        if (step.copado__Source_Environment__c == environmentId && String.isNotBlank(step.copado__Branch__c)) {
            info.branchName = step.copado__Branch__c;
        } else {
            info.branchName = step.copado__Deployment_Flow__r.copado__Main_Branch__c;
        }
        
        // Fallback to 'main' if still blank
        if (String.isBlank(info.branchName)) {
            info.branchName = 'main';
        }
        
        return info;
    }
    
    /**
     * @description Get Git Repository from Metadata Format Pipeline (Git Snapshot)
     */
    private static GitRepositoryInfo getGitRepoFromMetadataFormat(String orgCredentialId) {
        // Find Git Snapshots for this Org Credential
        List<copado__Git_Org_Commit__c> snapshots = [
            SELECT Id, copado__Git_Backup__c, copado__Git_Backup__r.Name,
                   copado__Git_Backup__r.copado__Git_Repository__c,
                   copado__Git_Backup__r.copado__Git_Repository__r.Name,
                   copado__Git_Backup__r.copado__Git_Repository__r.copado__URI__c,
                   copado__Git_Backup__r.copado__Branch__c
            FROM copado__Git_Org_Commit__c
            WHERE copado__Org__c = :orgCredentialId
            AND copado__Git_Backup__r.copado__Git_Repository__c != null
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        
        if (snapshots.isEmpty()) {
            return null;
        }
        
        copado__Git_Org_Commit__c snapshot = snapshots[0];
        GitRepositoryInfo info = new GitRepositoryInfo();
        
        info.repositoryId = snapshot.copado__Git_Backup__r.copado__Git_Repository__c;
        info.repositoryName = snapshot.copado__Git_Backup__r.copado__Git_Repository__r.Name;
        info.repositoryUri = snapshot.copado__Git_Backup__r.copado__Git_Repository__r.copado__URI__c;
        info.branchName = snapshot.copado__Git_Backup__r.copado__Branch__c;
        
        // Fallback to 'main' if blank
        if (String.isBlank(info.branchName)) {
            info.branchName = 'main';
        }
        
        return info;
    }
    
    /**
     * @description Build the git_json parameter for Copado Functions
     */
    private static String buildGitJson(GitRepositoryInfo info) {
        Map<String, String> gitMap = new Map<String, String>{
            'id' => info.repositoryId,
            'name' => info.repositoryName,
            'uri' => info.repositoryUri,
            'branch' => info.branchName
        };
        
        return JSON.serialize(gitMap);
    }
    
    /**
     * @description Build detailed error message when no Org Credential is found
     */
    private static String buildDetailedErrorMessage(copado__Environment__c environment) {
        String errorMsg = 'No Org Credential found for Environment: ' + environment.Name + '\n\n';
        errorMsg += 'Possible Causes:\n';
        errorMsg += '1. Environment is not connected to a Pipeline\n';
        errorMsg += '2. No Org Credential exists for this Environment\n';
        errorMsg += '3. Metadata Format Pipeline is missing a Git Snapshot\n';
        errorMsg += '4. Source Format Pipeline is missing a Git Repository\n\n';
        errorMsg += 'Please contact your Copado administrator.';
        
        return errorMsg;
    }
    
    /**
     * @description Build detailed error message when Git Repository cannot be resolved
     */
    private static String buildGitRepoErrorMessage(String orgCredentialId, String environmentId) {
        String errorMsg = 'Unable to resolve Git Repository\n\n';
        errorMsg += 'Org Credential ID: ' + orgCredentialId + '\n';
        errorMsg += 'Environment ID: ' + environmentId + '\n\n';
        errorMsg += 'Possible Causes:\n';
        errorMsg += '1. No Git Repository configured in the Pipeline\n';
        errorMsg += '2. No Git Snapshots exist for this Org Credential\n';
        errorMsg += '3. Pipeline is not properly configured\n\n';
        errorMsg += 'Please verify your Copado Pipeline configuration.';
        
        return errorMsg;
    }
}