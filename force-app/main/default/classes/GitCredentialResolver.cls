/**
 * @description Resolves Git Repository credentials for an Environment
 * Supports both Metadata Format and Source Format Pipelines
 *
 * Usage: Called from a Flow on the Environment record to get Git credentials
 * for running SFDX Code Analyzer or other Functions
 *
 * @author CopadoAI
 * @date 2025-12-10
 */
public with sharing class GitCredentialResolver {

    /**
     * @description Invocable method to get Git Repository credential JSON for an Environment
     * @param requests List of EnvironmentRequest objects containing Environment IDs
     * @return List of GitCredentialResponse objects containing credential JSON
     */
    @InvocableMethod(
        label='Get Git Credential for Environment'
        description='Resolves Git Repository credential for Metadata or Source Format Pipeline'
        category='Copado'
    )
    public static List<GitCredentialResponse> getGitCredential(List<EnvironmentRequest> requests) {
        List<GitCredentialResponse> responses = new List<GitCredentialResponse>();

        if (requests == null || requests.isEmpty()) {
            throw new GitCredentialException('No Environment ID provided');
        }

        String environmentId = requests[0].environmentId;

        try {
            // Step 1: Determine if this is Metadata or Source Format Pipeline
            PipelineInfo pipelineInfo = getPipelineInfo(environmentId);

            // Step 2: Get Git Repository based on pipeline type
            GitRepositoryInfo gitRepoInfo = getGitRepositoryInfo(pipelineInfo);

            // Step 3: Build the git_json credential
            String gitJson = buildGitJson(gitRepoInfo);

            // Step 4: Return the response
            GitCredentialResponse response = new GitCredentialResponse();
            response.gitJson = gitJson;
            response.repositoryId = gitRepoInfo.repositoryId;
            response.repositoryName = gitRepoInfo.repositoryName;
            response.repositoryUri = gitRepoInfo.repositoryUri;
            response.branchName = gitRepoInfo.branchName;
            response.pipelineType = pipelineInfo.pipelineType;
            response.success = true;

            responses.add(response);

        } catch (Exception e) {
            // Return error response
            GitCredentialResponse errorResponse = new GitCredentialResponse();
            errorResponse.success = false;
            errorResponse.errorMessage = e.getMessage();
            errorResponse.stackTrace = e.getStackTraceString();
            responses.add(errorResponse);
        }

        return responses;
    }

    /**
     * @description Gets Pipeline information for the Environment
     * @param environmentId The Environment record ID
     * @return PipelineInfo object containing pipeline details
     */
    private static PipelineInfo getPipelineInfo(String environmentId) {
        PipelineInfo info = new PipelineInfo();

        // First, get the Environment details
        List<copado__Environment__c> environments = [
            SELECT Id,
                   Name,
                   copado__Type__c,
                   copado__Org_ID__c
            FROM copado__Environment__c
            WHERE Id = :environmentId
            LIMIT 1
        ];

        if (environments.isEmpty()) {
            throw new GitCredentialException('Environment not found: ' + environmentId);
        }

        copado__Environment__c env = environments[0];
        info.environmentId = environmentId;
        info.environmentName = env.Name;
        info.environmentType = env.copado__Type__c;
        info.orgId = env.copado__Org_ID__c;

        // Query Deployment Flow Step (Pipeline Connection) to find the Pipeline this Environment belongs to
        List<copado__Deployment_Flow_Step__c> pipelineConnections = [
            SELECT Id,
                   copado__Deployment_Flow__c,
                   copado__Deployment_Flow__r.copado__Platform__c,
                   copado__Deployment_Flow__r.copado__Main_Branch__c,
                   copado__Branch__c,
                   copado__Destination_Branch__c,
                   copado__Source_Environment__c,
                   copado__Destination_Environment__c
            FROM copado__Deployment_Flow_Step__c
            WHERE copado__Source_Environment__c = :environmentId
               OR copado__Destination_Environment__c = :environmentId
            LIMIT 1
        ];

        if (pipelineConnections.isEmpty()) {
            throw new GitCredentialException('No Pipeline found for Environment: ' + env.Name + '. Metadata Format Pipelines require a Git Snapshot on each Environment.');
        }

        copado__Deployment_Flow_Step__c pipeConn = pipelineConnections[0];
        info.pipelineId = pipeConn.copado__Deployment_Flow__c;

        // Determine pipeline type based on Platform field
        // FIXED: Source Format = 'SFDX', Metadata Format = 'Salesforce' or null/empty
        String platform = pipeConn.copado__Deployment_Flow__r.copado__Platform__c;
        info.pipelineType = (platform == 'SFDX') ? 'Source Format' : 'Metadata Format';
        info.mainBranch = pipeConn.copado__Deployment_Flow__r.copado__Main_Branch__c;

        // Get the branch for this environment
        // Use Branch field if source environment, Destination Branch if destination
        if (pipeConn.copado__Source_Environment__c == environmentId) {
            info.environmentBranch = pipeConn.copado__Branch__c;
        } else {
            info.environmentBranch = pipeConn.copado__Destination_Branch__c;
        }

        return info;
    }

    /**
     * @description Gets Git Repository information based on pipeline type
     * @param pipelineInfo The PipelineInfo object
     * @return GitRepositoryInfo object containing repository details
     */
    private static GitRepositoryInfo getGitRepositoryInfo(PipelineInfo pipelineInfo) {
        GitRepositoryInfo gitInfo = new GitRepositoryInfo();

        if (pipelineInfo.pipelineType == 'Source Format') {
            // Source Format: Git Repository is on the Deployment Flow (Pipeline)
            gitInfo = getGitRepoFromPipeline(pipelineInfo);
        } else {
            // Metadata Format: Git Repository is on the Git Snapshot (Git Backup)
            gitInfo = getGitRepoFromSnapshot(pipelineInfo);
        }

        return gitInfo;
    }

    /**
     * @description Gets Git Repository from Deployment Flow (Source Format)
     * @param pipelineInfo The PipelineInfo object
     * @return GitRepositoryInfo object
     */
    private static GitRepositoryInfo getGitRepoFromPipeline(PipelineInfo pipelineInfo) {
        GitRepositoryInfo gitInfo = new GitRepositoryInfo();

        // Query the Deployment Flow to get Git Repository
        List<copado__Deployment_Flow__c> pipelines = [
            SELECT Id,
                   copado__Git_Repository__c,
                   copado__Git_Repository__r.Name,
                   copado__Git_Repository__r.copado__URI__c
            FROM copado__Deployment_Flow__c
            WHERE Id = :pipelineInfo.pipelineId
            LIMIT 1
        ];

        if (pipelines.isEmpty() || pipelines[0].copado__Git_Repository__c == null) {
            throw new GitCredentialException('No Git Repository found on Pipeline: ' + pipelineInfo.pipelineId);
        }

        copado__Deployment_Flow__c pipeline = pipelines[0];

        gitInfo.repositoryId = pipeline.copado__Git_Repository__c;
        gitInfo.repositoryName = pipeline.copado__Git_Repository__r.Name;
        gitInfo.repositoryUri = pipeline.copado__Git_Repository__r.copado__URI__c;

        // Use environment branch if available, otherwise use main branch
        gitInfo.branchName = String.isNotBlank(pipelineInfo.environmentBranch)
            ? pipelineInfo.environmentBranch
            : pipelineInfo.mainBranch;

        return gitInfo;
    }

    /**
     * @description Gets Git Repository from Git Snapshot (Metadata Format)
     * For Metadata Format, we need to:
     * 1. Find the Credential (Org) that matches this Environment's Org ID
     * 2. Find the Git Snapshot that uses that Credential
     * @param pipelineInfo The PipelineInfo object
     * @return GitRepositoryInfo object
     */
    private static GitRepositoryInfo getGitRepoFromSnapshot(PipelineInfo pipelineInfo) {
        GitRepositoryInfo gitInfo = new GitRepositoryInfo();

        // Step 1: Find the Credential (copado__Org__c) that matches this Environment
        // The Org Credential's SFDC Org ID should match the Environment's Org ID
        List<copado__Org__c> credentials = [
            SELECT Id, Name
            FROM copado__Org__c
            WHERE copado__SFDC_Org_ID__c = :pipelineInfo.orgId
            LIMIT 1
        ];

        if (credentials.isEmpty()) {
            throw new GitCredentialException(
                'No Org Credential found for Environment: ' + pipelineInfo.environmentName +
                ' (Org ID: ' + pipelineInfo.orgId + '). ' +
                'Please ensure a validated Org Credential exists for this Environment.'
            );
        }

        String credentialId = credentials[0].Id;

        // Step 2: Query Git Snapshot for this Credential
        List<copado__Git_Backup__c> gitSnapshots = [
            SELECT Id,
                   Name,
                   copado__Git_Repository__c,
                   copado__Git_Repository__r.Name,
                   copado__Git_Repository__r.copado__URI__c,
                   copado__Branch__c,
                   copado__Org__c,
                   copado__Org__r.Name
            FROM copado__Git_Backup__c
            WHERE copado__Org__c = :credentialId
            LIMIT 1
        ];

        if (gitSnapshots.isEmpty()) {
            throw new GitCredentialException(
                'No Git Snapshot found for Environment: ' + pipelineInfo.environmentName +
                '. Metadata Format Pipelines require a Git Snapshot on each Environment.'
            );
        }

        copado__Git_Backup__c gitSnapshot = gitSnapshots[0];

        if (gitSnapshot.copado__Git_Repository__c == null) {
            throw new GitCredentialException('Git Snapshot has no Git Repository configured');
        }

        gitInfo.repositoryId = gitSnapshot.copado__Git_Repository__c;
        gitInfo.repositoryName = gitSnapshot.copado__Git_Repository__r.Name;
        gitInfo.repositoryUri = gitSnapshot.copado__Git_Repository__r.copado__URI__c;
        gitInfo.branchName = gitSnapshot.copado__Branch__c;

        return gitInfo;
    }

    /**
     * @description Builds the git_json credential string
     * @param gitInfo The GitRepositoryInfo object
     * @return JSON string containing Git credential
     */
    private static String buildGitJson(GitRepositoryInfo gitInfo) {
        // Build the git_json structure that Copado Functions expect
        Map<String, Object> gitCredential = new Map<String, Object>{
            'id' => gitInfo.repositoryId,
            'name' => gitInfo.repositoryName,
            'uri' => gitInfo.repositoryUri,
            'branch' => gitInfo.branchName
        };

        return JSON.serialize(gitCredential);
    }

    // ========== INNER CLASSES ==========

    /**
     * @description Input wrapper for Invocable method
     */
    public class EnvironmentRequest {
        @InvocableVariable(required=true label='Environment ID' description='The Copado Environment record ID')
        public String environmentId;
    }

    /**
     * @description Output wrapper for Invocable method
     */
    public class GitCredentialResponse {
        @InvocableVariable(label='Git JSON' description='The git_json credential for Copado Functions')
        public String gitJson;

        @InvocableVariable(label='Repository ID' description='The Git Repository record ID')
        public String repositoryId;

        @InvocableVariable(label='Repository Name' description='The Git Repository name')
        public String repositoryName;

        @InvocableVariable(label='Repository URI' description='The Git Repository URI')
        public String repositoryUri;

        @InvocableVariable(label='Branch Name' description='The branch name for this environment')
        public String branchName;

        @InvocableVariable(label='Pipeline Type' description='Source Format or Metadata Format')
        public String pipelineType;

        @InvocableVariable(label='Success' description='Whether the operation succeeded')
        public Boolean success;

        @InvocableVariable(label='Error Message' description='Error message if operation failed')
        public String errorMessage;

        @InvocableVariable(label='Stack Trace' description='Stack trace if operation failed')
        public String stackTrace;
    }

    /**
     * @description Internal class to hold Pipeline information
     */
    private class PipelineInfo {
        public String pipelineId;
        public String environmentId;
        public String environmentName;
        public String environmentType;
        public String environmentBranch;
        public String pipelineType; // 'Source Format' or 'Metadata Format'
        public String mainBranch;
        public String orgId; // The Salesforce Org ID from the Environment
    }

    /**
     * @description Internal class to hold Git Repository information
     */
    private class GitRepositoryInfo {
        public String repositoryId;
        public String repositoryName;
        public String repositoryUri;
        public String branchName;
    }

    /**
     * @description Custom exception for Git Credential errors
     */
    public class GitCredentialException extends Exception {}
}