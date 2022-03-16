/**
 *@author       Mats Böhler
 *@created      25.09.2019
 *@version      1.0
 *@since        45.0
 *
 *
 *@description  hwPriorisierungshilfe
 *
 *
 *@changelog    25.09.2019 Mats Böhler - Created
 *
 *
 */

import {LightningElement, wire, track, api} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {CurrentPageReference, NavigationMixin} from 'lightning/navigation';
import {encodeDefaultFieldValues} from 'lightning/pageReferenceUtils';
import {fireEvent, registerListener, unregisterAllListeners} from 'c/pubsub';

// importing apex class methods
import loadData from '@salesforce/apex/HW_Priorisierungshilfe_LC.loadData';
import closeTasks from '@salesforce/apex/HW_Priorisierungshilfe_LC.closeTasks';
import saveTasks from '@salesforce/apex/HW_Priorisierungshilfe_LC.saveTasks';

export default class hwPriorisierungshilfe extends NavigationMixin(LightningElement) {

    @api sObjectType;
    @api recordId;
    @api iconName;
    @api title;
    @api sortBy;
    @api sortDirection;
    @api aufgabenstatusValue;
    @api version;
    @api isTermin = false;
    @api isTerminNotTerminiert = false;
    @api terminZum;
    @api isFiliale = false;
    @api nlBrief;
    @api zeige = 'Alle';
    recordsByTaskId = new Map();
    // reactive variable
    @track data;
    @track columns;
    @track isClosed = this.aufgabenstatusValue === 'geschlossen';
    @track zeitraumValue = '1';
    @track months = parseInt(this.zeitraumValue, 10);
    @track recordContext = null;
    @track showSpinner = true;
    @track initialized = false;
    @track filterCriteria = {};
    @track selectedTaskIds = new Set();
    @track changedTaskIds = new Set();
    @track disableMassClose = true;
    @track showModal = false;
    @track defaultFilter = '5';
    response;
    erledigungstypPicklistValues;

    @wire(CurrentPageReference) pageRef;

    connectedCallback() {
        this.setFilterCriteria();
        this.loadData();
        registerListener('tasksChanged', this.handleTasksChanged, this);
    }

    disconnectedCallback() {

        unregisterAllListeners(this);
    }

    handleTasksChanged(){
        this.loadData();
    }

    get showMassClose() {
        return this.aufgabenstatusValue === 'terminiert';
    }

    get isStandard() {
        return !this.isFiliale && !this.isTermin;
    }

    setFilterCriteria() {
        this.filterCriteria.isClosed = this.isClosed;
        this.filterCriteria.months = this.months;
        this.filterCriteria.recordId = this.recordId;
        this.filterCriteria.sObjectType = this.sObjectType;
        this.filterCriteria.version = this.version;
        this.filterCriteria.sortBy = this.sortBy;
        this.filterCriteria.sortDirection = this.sortDirection;
        this.filterCriteria.aufgabenstatusValue = this.aufgabenstatusValue;
        this.filterCriteria.isScheduled = this.isScheduled;
        if (this.isTermin) {
            this.filterCriteria.terminZum = new Date(this.terminZum);
        }
        if (this.isFiliale) {
            this.filterCriteria.isFiliale = this.isFiliale;
        }
        this.filterCriteria.nlBrief = this.nlBrief;
        if (this.isTerminNotTerminiert) {
            this.filterCriteria.terminZum = null;
        }
        this.filterCriteria.isTerminNotTerminiert = this.isTerminNotTerminiert;
        this.filterCriteria.zeige = this.zeige;
    }

    loadData() {
        loadData({
            filterCriteria: JSON.stringify(this.filterCriteria)
        })

            .then(result => {

                this.response = JSON.parse(result);
                this.data = [];
                for (let i = 0; i < this.response.aufgaben.length; i++) {
                    let task = this.response.aufgaben[i].task;
                    task.Ampel__c = this.response.aufgaben[i].ampel;
                    this.response.aufgaben[i].task.isSelected = false;
                    this.recordsByTaskId.set(this.response.aufgaben[i].task.Id, this.response.aufgaben[i].task);
                    this.data.push(task);
                }
                this.columns = this.response.columns;
                this.erledigungstypPicklistValues = this.response.erledigungstypPicklistValues;
                this.defaultFilter = this.response.setting.defaultFilter.toString();
                this.showSpinner = false;
                this.initialized = true;

            })
            .catch(error => {
                this.error = error;
            });
    }

    get isAkquise() {
        return this.version === 'mit Akquise';
    }

    get aufgabenstatusValues() {
        if (this.version !== 'mit Akquise') {
            return [
                {label: 'offen', value: 'offen'},
                {label: 'nicht begonnen', value: 'Nicht begonnen'},
                {label: 'terminiert', value: 'terminiert'},
                {label: 'geschlossen', value: 'geschlossen'},
            ];
        } else {
            return [
                {label: 'offen', value: 'offen'},
                {label: 'geschlossen', value: 'geschlossen'},
            ];
        }

    }

    handleChangeAufgabenstatus(event) {
        this.aufgabenstatusValue = event.detail.value;
        this.isClosed = this.aufgabenstatusValue === 'geschlossen';
        this.showSpinner = true;
        this.setFilterCriteria();
        this.loadData();
    }

    handleChangeZeige(event) {
        this.zeige = event.detail.value;
        this.showSpinner = true;
        this.setFilterCriteria();
        this.loadData();
    }

    get zeigeValues() {
        return [
            {label: 'Alle', value: 'Alle'},
            {label: 'Filiale', value: 'Filiale'},
            {label: 'Packstation', value: 'Packstation'},
        ];
    }

    handleOnChangeNlBrief(event) {
        this.nlBrief = event.detail.value;
        this.showSpinner = true;
        this.setFilterCriteria();
        this.loadData();
    }

    get zeitraumValues() {
        return [
            {label: 'letzten Monat', value: '1'},
            {label: 'letzte 3 Monate', value: '3'},
            {label: 'letzte 6 Monate', value: '6'},
        ];
    }

    handleChangeZeitraum(event) {
        this.zeitraumValue = event.detail.value;
        this.months = parseInt(this.zeitraumValue, 10);
        this.showSpinner = true;
        this.setFilterCriteria();
        this.loadData();
    }

    get versionValues() {
        return [
            {label: 'mit Akquise', value: 'mit Akquise'},
            {label: 'ohne Akquise', value: 'ohne Akquise'},
        ];
    }

    handleChangeVersion(event) {
        this.version = event.detail.value;
        this.showSpinner = true;
        this.setFilterCriteria();
        this.loadData();
    }

    get titel() {
        if (this.isTermin && this.isTerminNotTerminiert) {
            return 'Noch nicht terminiert';
        }
        if (this.isTermin) {
            return 'Termin';
        }
        return this.title;
    }

    get isScheduled() {
        return this.aufgabenstatusValue === 'terminiert';
    }

    handleOnSelected(event) {
        if (event.detail.checked === true && !this.selectedTaskIds.has(event.detail.taskId)) {
            this.selectedTaskIds.add(event.detail.taskId);
        }
        if (event.detail.checked !== true && this.selectedTaskIds.has(event.detail.taskId)) {
            this.selectedTaskIds.delete(event.detail.taskId);
        }
        this.disableMassClose = this.selectedTaskIds.size === 0;
    }

    handleShowModal() {
        this.showModal = true;
    }

    handleHideModal() {
        this.showModal = false;
    }

    handleCloseTasks() {
        this.showModal = false;
        this.showSpinner = true;
        this.setArray();
        this.closeTasks();
    }

    setArray() {
        this.response.data = [];
        for (let [key, task] of this.recordsByTaskId) {
            this.response.data.push(task);
        }
    }

    closeTasks() {

        this.filterCriteria.selectedTaskIds = Array.from(this.selectedTaskIds).join(' ');
        this.filterCriteria.changedTaskIds = Array.from(this.changedTaskIds).join(' ');

        closeTasks({
            filterCriteria: JSON.stringify(this.filterCriteria),
            tasksString: JSON.stringify(this.response.data),
        })

            .then(result => {
                this.response = JSON.parse(result);
                this.data = [];
                for (let i = 0; i < this.response.aufgaben.length; i++) {
                    let task = this.response.aufgaben[i].task;
                    task.Ampel__c = this.response.aufgaben[i].ampel;
                    this.response.aufgaben[i].task.isSelected = false;
                    this.recordsByTaskId.set(this.response.aufgaben[i].task.Id, this.response.aufgaben[i].task);
                    this.data.push(task);
                }
                this.columns = this.response.columns;
                this.showSpinner = false;
                this.initialized = true;
                this.showModal = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Erfolg',
                        message: 'Die Aufgaben wurden erfolgreich geschlossen.',
                        variant: 'success',
                    }));
                fireEvent(this.pageRef, 'tasksChanged', null);
            })
            .catch(error => {
                this.error = error;
                const evt = new ShowToastEvent({
                    title: this.error.statusText,
                    message: this.error.body.message,
                    variant: 'error',
                    mode: 'sticky'
                });
                this.dispatchEvent(evt);
                this.showModal = false;
                this.showSpinner = false;
            });
    }

    handleOnTypChanged(event) {
        this.recordsByTaskId.get(event.detail.taskId).Typc__c = event.detail.erledigungstypValue;
        this.changedTaskIds.add(event.detail.taskId);
    }

    handleOnTerminiertChanged(event) {
        this.recordsByTaskId.get(event.detail.taskId).TerminiertZum__c = event.detail.terminiertValue ? event.detail.terminiertValue : null;
        this.changedTaskIds.add(event.detail.taskId);
    }

    handleSaveTasks() {
        this.showSpinner = true;
        this.setArray();
        this.saveTasks();
    }

    saveTasks() {
        saveTasks({
            filterCriteria: JSON.stringify(this.filterCriteria),
            tasksString: JSON.stringify(this.response.data),
            changedTasks: Array.from(this.changedTaskIds).join(' ')
        })

            .then(result => {
                this.response = JSON.parse(result);
                this.data = [];
                for (let i = 0; i < this.response.aufgaben.length; i++) {
                    let task = this.response.aufgaben[i].task;
                    task.Ampel__c = this.response.aufgaben[i].ampel;
                    this.response.aufgaben[i].task.isSelected = false;
                    this.recordsByTaskId.set(this.response.aufgaben[i].task.Id, this.response.aufgaben[i].task);
                    this.data.push(task);
                }
                this.columns = this.response.columns;
                this.showSpinner = false;
                this.initialized = true;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Erfolg',
                        message: 'Die Aufgaben wurden erfolgreich gespeichert.',
                        variant: 'success',
                    }));
                fireEvent(this.pageRef, 'tasksChanged', null);
            })
            .catch(error => {
                this.error = error;
                const evt = new ShowToastEvent({
                    title: this.error.statusText,
                    message: this.error.body.message,
                    variant: 'error',
                    mode: 'sticky'
                });
                this.dispatchEvent(evt);
                this.showSpinner = false;
            });
    }
}