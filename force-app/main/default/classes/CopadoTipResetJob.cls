public class CopadoTipResetJob implements Queueable {
    public void execute(QueueableContext context) {
        // Get the current datetime in UTC
        Datetime nowUtc = Datetime.now();

        // Query CopadoTips__c records that are set as default and their end time is in the past
        List<CopadoTips__c> tipsToReset = [SELECT Id, DefaultTip__c, TipEndTime__c
                                           FROM CopadoTips__c
                                           WHERE DefaultTip__c = true AND TipEndTime__c < :nowUtc];

        if (!tipsToReset.isEmpty()) {
            for (CopadoTips__c tip : tipsToReset) {
                tip.DefaultTip__c = false;
            }
            try {
                update tipsToReset;
            } catch (DmlException e) {
                System.debug('Error updating Copado Tips: ' + e.getMessage());
            }
        }
    }
}
