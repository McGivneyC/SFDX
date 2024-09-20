public with sharing class TriggerHandlerCT {
    //test us bundle unit test
    private static boolean isRecursive = false;
    private static boolean cleanupJobEnqueued = false;

    public static boolean isTriggerRecursive() {
        return isRecursive;
    }

    public static void setTriggerRecursive(boolean value) {
        isRecursive = value;
    }

    public static boolean hasCleanupJobBeenEnqueued() {
        return cleanupJobEnqueued;
    }

    public static void setCleanupJobEnqueued(boolean value) {
        cleanupJobEnqueued = value;
    }

    public static void handleCopadoTips(List<CopadoTips__c> newTips, Map<Id, CopadoTips__c> oldMap) {
        if (isRecursive) {
            return;
        }
        try {
            isRecursive = true;

            // Extract IDs from newTips into a Set
            Set<Id> newTipIds = new Set<Id>();
            for (CopadoTips__c tip : newTips) {
                newTipIds.add(tip.Id);
            }

            // Query existing default tips excluding the new ones
            Map<Id, CopadoTips__c> defaultTipsByProject = new Map<Id, CopadoTips__c>();
            for (CopadoTips__c tip : [SELECT Id, Project__c, DefaultTip__c FROM CopadoTips__c WHERE DefaultTip__c = true AND Id NOT IN :newTipIds WITH SECURITY_ENFORCED]) {
                defaultTipsByProject.put(tip.Project__c, tip);
            }

            for (CopadoTips__c tip : newTips) {
                if (tip.DefaultTip__c) {
                    CopadoTips__c existingDefault = defaultTipsByProject.get(tip.Project__c);
                    if (existingDefault != null && existingDefault.Id != tip.Id) {
                        tip.addError('Only one default CopadoTip record can be set per project.');
                    } else {
                        // Update the map to reflect the new default
                        defaultTipsByProject.put(tip.Project__c, tip);
                    }
                }
            }

            // Reset other defaults if necessary
            for (CopadoTips__c tip : defaultTipsByProject.values()) {
                if (tip.DefaultTip__c && !newTipIds.contains(tip.Id)) {
                    tip.DefaultTip__c = false;
                    update tip;
                }
            }
        } finally {
            isRecursive = false;
        }
    }
}