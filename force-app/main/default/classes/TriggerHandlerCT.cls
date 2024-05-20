public class TriggerHandlerCT {
    private static boolean isRecursive = false;

    public static boolean isTriggerRecursive() {
        return isRecursive;
    }

    public static void setTriggerRecursive(boolean value) {
        isRecursive = value;
    }
public static void handleCopadoTips(List<CopadoTips__c> newTips, Map<Id, CopadoTips__c> oldMap) {
    // Prevent trigger recursion
    if (!isTriggerRecursive()) {
        Set<Id> defaultTipIds = new Set<Id>();
        CopadoTips__c duplicateDefaultTip = null; // Track if multiple default tips are being set

        // Iterate through new records to check for duplicates and set as default
        for (CopadoTips__c tip : newTips) {
            if (tip.DefaultTip__c) {
                if (defaultTipIds.contains(tip.Id)) {
                    tip.addError('Only one CopadoTip record can be set as default.');
                } else {
                    defaultTipIds.add(tip.Id);
                }

                // Track if multiple default tips are being set
                if (duplicateDefaultTip == null) {
                    duplicateDefaultTip = tip;
                } else {
                    duplicateDefaultTip.addError('Only one CopadoTip record can be set as default.');
                    tip.addError('Only one CopadoTip record can be set as default.');
                }
            }
        }

        // For update triggers, check changes against old records
        if (oldMap != null && !oldMap.isEmpty()) {
            for (CopadoTips__c oldTip : oldMap.values()) {
                if (Trigger.newMap != null && Trigger.newMap.containsKey(oldTip.Id)) {
                    CopadoTips__c newTip = (CopadoTips__c) Trigger.newMap.get(oldTip.Id);
                    if (newTip != null && newTip.DefaultTip__c && !defaultTipIds.contains(newTip.Id)) {
                        // If a new record is being set as default, check if there's already another default
                        if (duplicateDefaultTip == null) {
                            duplicateDefaultTip = newTip;
                        } else {
                            duplicateDefaultTip.addError('Only one CopadoTip record can be set as default.');
                            newTip.addError('Only one CopadoTip record can be set as default.');
                        }
                    }
                }
            }
        }
    }
  }
}
