public with sharing class CopadoTipController {
    @AuraEnabled(cacheable=true)
    public static CopadoTips__c getRandomTip() {
        // Retrieve all CopadoTips__c records
        List<CopadoTips__c> allTips = [SELECT Id, Name, TipDescription__c, TipCount__c FROM CopadoTips__c];

        // Log the number of CopadoTips__c records retrieved
        System.debug('Number of CopadoTips__c records retrieved: ' + allTips.size());
        System.debug(' TipCount__c retrieved: ' + allTips);

        // Generate a random index
        Integer randomIndex = (Integer)Math.floor(Math.random() * allTips.size());

        // Return a random CopadoTips__c record
        return allTips[randomIndex];
    }
}