/**
 *@author       Martin Kruck
 *@created      18.10.2019
 *@version      1.0
 *@since        45.0
 *
 *
 *@description  hwPriorisierungshilfeTermine
 *
 *
 *@changelog    18.10.2019 Martin Kruck - Created
 *
 *
 */

import {LightningElement, wire, track, api} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import { registerListener, unregisterAllListeners, fireEvent } from 'c/pubsub';

// importing apex class methods
import loadData from '@salesforce/apex/HW_Priorisierungshilfe_LC.loadData';

export default class hwPriorisierungshilfeTermine extends LightningElement {

    @api recordId;
    @api iconName;
    @api title;

    // reactive variable
    @track data;
    @track columns;
    @track showSpinner = true;
    @track initialized = false;
    @track filterCriteria = {};
    @track sortBy = 'TerminiertZum__c';
    @track sortDirection = 'asc';
    @track showModal = false;
    @track terminId;
    @track version;
    @track terminZum;
    @track nlBrief;
    @track defaultFilter = '5';

    sObjectType = 'Termin';

    @wire(CurrentPageReference) pageRef;

    connectedCallback() {
        this.setFilterCriteria();
        this.loadData();
        registerListener('tasksChanged', this.handleTasksChanged, this);
    }

    disconnectedCallback() {

        unregisterAllListeners(this);
    }

    handleTasksChanged(event){
        this.loadData();
    }

    setFilterCriteria() {

        this.filterCriteria.recordId = this.recordId;
        this.filterCriteria.sObjectType = this.sObjectType;
        this.filterCriteria.sortBy = this.sortBy;
        this.filterCriteria.sortDirection = this.sortDirection;
        this.filterCriteria.nlBrief = this.nlBrief;
    }

    loadData() {
        loadData({
            filterCriteria: JSON.stringify(this.filterCriteria)
        })

            .then(result => {
                let response = JSON.parse(result);
                this.data = [];
                for (let i = 0; i < response.termine.length; i++) {
                    let task = response.termine[i].task;
                    task.Ampel__c = response.termine[i].ampel;
                    this.data.push(task);
                }
                this.columns = response.columns;
                this.defaultFilter = response.setting.defaultFilter.toString();
                this.showSpinner = false;
                this.initialized = true;
            })
            .catch(error => {
                this.error = error;

            });
    }

    get titel() {
        return this.title;
    }

    handleShowModal(event){
        this.showModal = true;
    }

    handleHideModal(event){
        this.showModal = false;
        this.loadData();
    }

    handleShowTasks(event){
        this.showModal = true;
        this.terminId = event.detail.accountId;
        this.version = 'ohne Akquise';
        this.terminZum = event.detail.terminZum;
    }

    handleOnChangeNlBrief(event) {
        this.nlBrief = event.detail.value;
        this.showSpinner = true;
        this.setFilterCriteria();
        this.loadData();
    }

    get returnBooleanTrue(){
        return true;
    }
}