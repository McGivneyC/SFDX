public with sharing class CopadoTipController {
    @AuraEnabled(cacheable=true)
    public static Map<String, CopadoTips__c> getTips() {
        Map<String, CopadoTips__c> tipMap = new Map<String, CopadoTips__c>();
        
        //Get the current system time
        Datetime currentDateTime = Datetime.now();

        // Debugging the current system time as a string
        // System.debug('Current system time in the desired format as a string: ' + currentDateTime.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ'));

        // Query to get the default Copado Tip
        List<CopadoTips__c> defaultTips = [
            SELECT Id, Name, TipDescription__c, TipCategory__c, DefaultTip__c, TipStartTime__c, TipEndTime__c, TipURL__c
            FROM CopadoTips__c
            WHERE DefaultTip__c = TRUE
            AND TipStartTime__c <= :currentDateTime
            AND TipEndTime__c >= :currentDateTime
            LIMIT 1 WITH SECURITY_ENFORCED
        ];

        if (!defaultTips.isEmpty()) {
            tipMap.put('defaultTip', defaultTips[0]);
        } else {
            // Get the count of all active tips
            Integer tipCount = [SELECT COUNT() FROM CopadoTips__c];

            if (tipCount > 0) {
                // Generate a random offset within the count of active tips
                Integer randomOffset = Integer.valueOf(Math.floor(Math.random() * tipCount));

                // Query for a random tip using the OFFSET clause
                List<CopadoTips__c> randomTips = [
                    SELECT Id, Name, TipDescription__c, TipCategory__c, TipURL__c
                    FROM CopadoTips__c
                    LIMIT 1
                    OFFSET :randomOffset WITH SECURITY_ENFORCED
                ];

                if (!randomTips.isEmpty()) {
                    tipMap.put('randomTip', randomTips[0]);
                }
            }
        }

        return tipMap;
    }

}