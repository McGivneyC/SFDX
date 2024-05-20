import { LightningElement, wire, track } from 'lwc';
import getTips from '@salesforce/apex/CopadoTipController.getTips';
import { refreshApex } from '@salesforce/apex';

// Regular expression to extract URL from HTML anchor tag
var regex = /<a\s+(?:[^>]*?\s+)?href="(.*?)"/;

export default class CopadoTips extends LightningElement {
    @track defaultTip;
    @track randomTip;
    @track showNoTipMessage = false;
    wiredTipsResult;

    @wire(getTips)
    wiredTips(result) {
        this.wiredTipsResult = result;
        const { data, error } = result;
        if (data) {
            console.log('Data received:', data); // Log the data object
            this.defaultTip = data.defaultTip;
            this.randomTip = data.randomTip;
            this.showNoTipMessage = !data.defaultTip && !data.randomTip;
        } else if (error) {
            console.error('Error fetching tips: ', error);
            this.showNoTipMessage = true;
        }
    }

    // Getter function to extract URL from TipURL__c field
    get defaultTipUrl() {
        return this.extractUrl(this.defaultTip);
    }

    get randomTipUrl() {
        return this.extractUrl(this.randomTip);
    }

    extractUrl(tip) {
        if (tip && tip.TipURL__c) {
            const match = tip.TipURL__c.match(regex);
            return match ? match[1] : ''; // Return extracted URL
        }
        return '';
    }

    // Method to refresh the Apex cache and fetch the latest tips
    refreshTips() {
        return refreshApex(this.wiredTipsResult);
    }
}