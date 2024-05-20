import { LightningElement, wire, track } from 'lwc';
import getRandomTip from '@salesforce/apex/CopadoTipController.getRandomTip';

export default class CopadoTipBanner extends LightningElement {
    tipDescription;
    tipCount;
    tipId;
    tipCategory;
    @track tipUrl;

    @wire(getRandomTip)
    wiredTips({ error, data }) {
        if (data) {
            this.tipDescription = data.TipDescription__c;
            this.tipCount = data.TipCount__c;
            this.tipId = data.Id;
            this.tipCategory = data.TipCategory__c;
            this.tipUrl = "https://boot-spare8-1.lightning.force.com/" + this.tipId

        } else if (error) {
            console.error('Error fetching random tip:', error);
        }
    }
}
