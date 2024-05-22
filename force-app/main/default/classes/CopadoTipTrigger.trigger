trigger CopadoTipTrigger on CopadoTips__c (before insert, before update) {
    if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate) && !TriggerHandlerCT.isTriggerRecursive()) {
        // Set trigger recursion flag
        TriggerHandlerCT.setTriggerRecursive(true); 
        
        // Reset trigger recursion flag
        TriggerHandlerCT.setTriggerRecursive(false);
        
        // Step 1: Prevent users from marking more than one CopadoTips__c record as default
        TriggerHandlerCT.handleCopadoTips(Trigger.new, Trigger.oldMap);
        
        // Step 2: Clean up old Copado Tip records where DefaultTip__c = true and TipEndTime__c < currentDateTime
        CopadoTipController.resetDefaultTip();
        
        
    }
}
