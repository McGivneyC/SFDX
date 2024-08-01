import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

const FIELDS = ['copado__User_Story__c.Manual_Tasks_Present__c'];

export default class ManualTaskEnforcer extends LightningElement {
    @api recordId;
    hasManualTasks = false;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            this.hasManualTasks = data.fields.Manual_Tasks_Present__c.value > 0;
        } else if (error) {
            console.error('Error retrieving record:', error);
            this.hasManualTasks = false;
        }
    }
}