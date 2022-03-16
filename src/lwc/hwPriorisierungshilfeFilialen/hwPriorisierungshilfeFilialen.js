/**
 *@author       Mats Böhler
 *@created      15.10.2019
 *@version      1.0
 *@since        45.0
 *
 *
 *@description  hwPriorisierungshilfeFilialen
 *
 *
 *@changelog    15.10.2019 Mats Böhler - Created
 *
 *
 */

import {LightningElement, wire, track, api} from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { registerListener, unregisterAllListeners, fireEvent } from 'c/pubsub';

// importing apex class methods
import loadData from '@salesforce/apex/HW_Priorisierungshilfe_LC.loadData';

export default class hwPriorisierungshilfeFilialen extends LightningElement {

    @api recordId;
    @api iconName;
    @api title;

    // reactive variable
    @track data;
    @track columns;
    @track showSpinner = true;
    @track initialized = false;
    @track filterCriteria = {};
    @track sortBy = 'Nummerierung__c';
    @track sortDirection = 'asc';
    @track filialId;
    @track nlBrief;
    @track defaultFilter = '5';
    @track showModal = false;

    sObjectType = 'Account';

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
        this.filterCriteria.nlBrief = this.nlBrief;
    }

    loadData() {
        loadData({
            filterCriteria: JSON.stringify(this.filterCriteria)
        })

            .then(result => {
                let response = JSON.parse(result);
                this.data = [];
                for (let i = 0; i < response.filialen.length; i++) {
                    let account = response.filialen[i].account;
                    account.Ampel__c = response.filialen[i].ampel;
                    this.data.push(account);
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
        
        this.filialId = event.detail.accountId;
        this.showModal = true;
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