global class DeleteCalloutLogs implements Database.Batchable<sObject> {
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id FROM copadoccmint__Callout_Log__c WHERE CreatedDate < LAST_N_DAYS:5]);
    }

    global void execute(Database.BatchableContext bc, List<sObject> scope) {
        List<copadoccmint__Callout_Log__c> calloutLogsToDelete = (List<copadoccmint__Callout_Log__c>) scope;
        delete calloutLogsToDelete;
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('Batch job finished successfully');
    }
}