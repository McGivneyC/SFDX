public with sharing class CopadoTipController {
    @AuraEnabled(cacheable=true)
    public static Map<String, CopadoTips__c> getTips(Id userStoryId) {
        Map<String, CopadoTips__c> tipMap = new Map<String, CopadoTips__c>(); // Initialize once

        if (userStoryId == null) {
            return tipMap; // Return the initialized empty map
        }

        List<copado__User_Story__c> userStories = [
            SELECT copado__Project__r.Id FROM copado__User_Story__c WHERE Id = :userStoryId WITH SECURITY_ENFORCED LIMIT 1
        ];
        System.debug('User Stories fetched: ' + userStories);
        
        if (userStories.isEmpty()) {
            return tipMap; // Return the initialized empty map
        }

        Id projectId = userStories[0].copado__Project__r.Id;
        Datetime currentSystemTime = System.now();

        List<CopadoTips__c> defaultTips = [
            SELECT Id, Name, TipDescription__c, TipCategory__c, DefaultTip__c, TipStartTime__c, TipEndTime__c, TipURL__c, Project__c
            FROM CopadoTips__c
            WHERE Project__c = :projectId 
            AND DefaultTip__c = TRUE 
            AND TipStartTime__c <= :currentSystemTime 
            AND TipEndTime__c >= :currentSystemTime 
            WITH SECURITY_ENFORCED 
            LIMIT 1
        ];

        if (!defaultTips.isEmpty()) {
            tipMap.put('defaultTip', defaultTips[0]);
        } else {
            Integer tipCount = [SELECT COUNT() FROM CopadoTips__c WHERE Project__c = :projectId WITH SECURITY_ENFORCED ];
            if (tipCount > 0) {
                Integer randomOffset = Integer.valueOf(Math.floor(Math.random() * tipCount));
                List<CopadoTips__c> randomTips = [
                    SELECT Id, Name, TipDescription__c, TipCategory__c, TipURL__c, Project__c
                    FROM CopadoTips__c WHERE Project__c = :projectId WITH SECURITY_ENFORCED LIMIT 1 OFFSET :randomOffset
                ];
                if (!randomTips.isEmpty()) {
                    tipMap.put('randomTip', randomTips[0]);
                }
            }
        }

        return tipMap;
    }
}