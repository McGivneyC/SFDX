import { LightningElement, wire, api } from 'lwc';
import getTips from '@salesforce/apex/CopadoTipController.getTips';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';

export default class CopadoTips extends NavigationMixin(LightningElement) {
    @api recordId; // This gets the record ID when the component is placed on a record page
    defaultTip = null;
    randomTip = null;
    showNoTipMessage = false;
    errorMessage = '';
    wiredTipsResult;

    @wire(getTips, { userStoryId: '$recordId' })
    wiredTips(result) {
        this.wiredTipsResult = result;
        const { data, error } = result;
        if (data) {
            this.defaultTip = data.defaultTip;
            this.randomTip = data.randomTip;
            this.showNoTipMessage = !data.defaultTip && !data.randomTip;
        } else if (error) {
            this.errorMessage = 'Failed to retrieve tips. Please try again later.';
            this.showNoTipMessage = true;
            console.error('Error fetching tips:', error);
        }
    }

    navigateToRecord(event) {
        const recordId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        });
    }

    refreshTips() {
        return refreshApex(this.wiredTipsResult);
    }
}