/**
 *@author       Mats Böhler
 *@created      21.09.2020
 *
 *
 *@description  massenzuweisungFilialen
 *
 *
 *@changelog    21.09.2020 Mats Böhler - Created
 *
 *
 */

import {LightningElement, wire, track, api} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {CurrentPageReference} from 'lightning/navigation';

// importing apex class methods
import loadData from '@salesforce/apex/MassenzuweisungCtrl.loadData';
import saveRecords from '@salesforce/apex/MassenzuweisungCtrl.saveRecords';

export default class MassenzuweisungFilialen extends LightningElement {

    @api iconName = 'standard:account';
    @api title = 'Massenzuweisung von Filialen';
    @api sortBy = 'Name';
    @api sortDirection = 'desc';

    // reactive variable
    @track columns;
    @track showSpinner = true;
    @track initialized = false;
    @track filiale = '';
    @track astName = '';
    @track filialart = '';
    @track nlBrief = '';
    @track strasse = '';
    @track inhaber = '';
    @track showAll = true;
    @track resultSize = 0;
    @track maxRecords = 1000;
    @track changedLeads = new Set();
    response;
    @track recordsByLeadId = new Map();
    @track initialSelectionById = new Map();
    @track tableData;
    @track hasChanges = false;
    @track isSelectedByLeadId = new Map();
    @track selectedLeadIds = new Set();
    @api isAllSelected = false;

    @wire(CurrentPageReference) pageRef;

    constructor() {
        super();
        this.setTabVisibilityHandler();
    }

    connectedCallback() {

        this.loadData();
    }

    setTabVisibilityHandler() {
        // Set the name of the hidden property and the change event for visibility
        var hidden, visibilityChange;
        if (typeof document.hidden !== "undefined") { // Opera 12.10 and Firefox 18 and later support
            hidden = "hidden";
            visibilityChange = "visibilitychange";
        } else if (typeof document.msHidden !== "undefined") {
            hidden = "msHidden";
            visibilityChange = "msvisibilitychange";
        } else if (typeof document.webkitHidden !== "undefined") {
            hidden = "webkitHidden";
            visibilityChange = "webkitvisibilitychange";
        }

        // Warn if the browser doesn't support addEventListener or the Page Visibility API
        if (typeof document.addEventListener === "undefined" || typeof document[hidden] === "undefined") {
            const event = new ShowToastEvent({
                title: 'Error',
                message:
                    'This demo requires a browser, such as Google Chrome or Firefox, that supports the Page Visibility API.',
                variant: 'error',
                mode: 'sticky'

            });
            this.dispatchEvent(event);
        } else {
            // Handle page visibility change
            document.addEventListener(visibilityChange, () => this.handleVisibilityChange(), false);
        }
    }

    handleVisibilityChange() {

        if (!this.hasChanges && this.initialized) {
            this.loadData();
        }
    }

    loadData() {
        loadData({
            filterCriteria: this.loadFilterCriteria()
        })

            .then(result => {

                this.initializeData(result);
                this.isAllSelected = false;
            })
            .catch(error => {
                this.error = error;
                const evt = new ShowToastEvent({
                    title: this.error.statusText,
                    message: this.error.body ? this.error.body.message : '',
                    variant: 'error',
                    mode: 'sticky'
                });
                this.dispatchEvent(evt);
                this.showSpinner = false;
            });
    }

    handleSave() {
        this.save();
    }

    save() {
        if (this.hasChanges) {
            this.showSpinner = true;
            saveRecords({
                filterCriteria: this.loadFilterCriteria(),
                recordsString: JSON.stringify(Array.from(this.recordsByLeadId.values())),
                changedRecords: Array.from(this.changedLeads).join(' '),
            })

                .then(result => {

                    this.initializeData(result);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Erfolg',
                            message: 'Die Filiale(n) wurden erfolgreich gespeichert.',
                            variant: 'success',
                        }));
                    this.hasChanges = false;
                    this.dispatchChangeEvent(this.hasChanges);
                    this.isAllSelected = false;
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

    loadFilterCriteria() {
        return [
            'Account',
            this.filiale,
            this.astName,
            this.filialart,
            this.nlBrief,
            this.strasse,
            this.inhaber,
            this.showAll,
            this.sortBy,
            this.sortDirection,
            this.maxRecords
        ]
    }

    initializeData(result) {
        this.response = JSON.parse(result);
        this.recordsByLeadId = new Map();
        this.isSelectedByLeadId = new Map();
        this.selectedLeadIds = new Set();
        this.initialSelectionById = new Map();
        for (let i = 0; i < this.response.data.length; i++) {
            this.recordsByLeadId.set(this.response.data[i].Id, this.response.data[i]);
            this.isSelectedByLeadId.set(this.response.data[i].Id, false);
            this.initialSelectionById.set(this.response.data[i].Id, [
                {
                    id: this.response.data[i].Id,
                    sObjectType: 'User',
                    icon: 'standard:user',
                    title: this.response.data[i].Owner.Name,
                    subtitle: this.response.data[i].Owner.UserRole.Name
                }
            ]);
        }
        this.tableData = this.sortData(
            this.sortBy,
            this.sortDirection,
            Array.from(this.recordsByLeadId.values())
        );
        this.columns = this.response.columns;
        this.resultSize = this.response.data.length;
        this.showSpinner = false;
        this.initialized = true;
    }

    handleOnChangeFiliale(event) {
        this.showSpinner = true;
        this.filiale = event.detail.value;
        this.loadData();
    }

    handleOnChangeAstName(event) {
        this.showSpinner = true;
        this.astName = event.detail.value;
        this.loadData();
    }

    handleOnChangeFilialart(event) {
        this.showSpinner = true;
        this.filialart = event.detail.value;
        this.loadData();
    }

    handleOnChangeNlBrief(event) {
        this.showSpinner = true;
        this.nlBrief = event.detail.value;
        this.loadData();
    }

    handleOnChangeStrasse(event) {
        this.showSpinner = true;
        this.strasse = event.detail.value;
        this.loadData();
    }

    handleOnChangeInhaber(event) {
        this.showSpinner = true;
        this.inhaber = event.detail.value;
        this.loadData();
    }

    @track isShowAllSelected = false;

    handleShowAll() {
        this.showSpinner = true;
        this.isShowAllSelected = !this.isShowAllSelected;
        this.showAll = !this.isShowAllSelected;
        this.loadData();
    }

    get variantShowAll() {
        return 'brand-outline';
    }

    handleOnSelected(event) {
        if (event.detail.checked === true && !this.selectedLeadIds.has(event.detail.taskId)) {
            this.selectedLeadIds.add(event.detail.taskId);
        }
        if (event.detail.checked !== true && this.selectedLeadIds.has(event.detail.taskId)) {
            this.selectedLeadIds.delete(event.detail.taskId);
        }
        this.isSelectedByLeadId.set(event.detail.taskId, event.detail.checked);
    }

    handleOnAllSelected(event) {
        let recordIds = Array.from(event.detail.recordIds);
        this.isAllSelected = event.detail.checked;
        for (let i = 0; i < recordIds.length; i++) {

            if (event.detail.checked === true && !this.selectedLeadIds.has(recordIds[i])) {
                this.selectedLeadIds.add(recordIds[i]);
            }
            if (event.detail.checked !== true && this.selectedLeadIds.has(recordIds[i])) {
                this.selectedLeadIds.delete(recordIds[i]);
            }
            this.isSelectedByLeadId.set(recordIds[i], event.detail.checked);
        }
        for (let selectedLeadId of this.selectedLeadIds) {
            this.recordsByLeadId.get(selectedLeadId).isSelected = event.detail.checked;
        }
        this.tableData = this.sortData(
            this.sortBy,
            this.sortDirection,
            Array.from(this.recordsByLeadId.values())
        );
    }

    handleOnOwnerChanged(event) {
        this.changedLeads.add(event.detail.leadId);
        this.recordsByLeadId.get(event.detail.leadId).OwnerId = event.detail.ownerId;

        for (let selectedLeadId of this.selectedLeadIds) {
            this.recordsByLeadId.get(selectedLeadId).OwnerId = event.detail.ownerId;
            this.recordsByLeadId.get(selectedLeadId).Owner.UserRole.Name = event.detail.subtitle;
            this.changedLeads.add(selectedLeadId);
            this.initialSelectionById.set(selectedLeadId, [
                {
                    id: selectedLeadId,
                    sObjectType: 'User',
                    icon: 'standard:user',
                    title: event.detail.title,
                    subtitle: event.detail.subtitle
                }
            ]);
        }
        this.hasChanges = true;
        this.dispatchChangeEvent(this.hasChanges);
        this.tableData = this.sortData(
            this.sortBy,
            this.sortDirection,
            Array.from(this.recordsByLeadId.values())
        );
    }

    sortData(fieldname, direction, data) {
        // serialize the data before calling sort function
        let parseData = JSON.parse(JSON.stringify(data));
        // Return the value stored in the field
        let keyValue = (a) => {
            let value = a[fieldname] ? a[fieldname].toString().toUpperCase() : a[fieldname];
            if (fieldname.includes('.') && a[fieldname.split('.')[0]]  ) {
                value = a[fieldname.split('.')[0]][fieldname.split('.')[1]];
            }
            return value;
        };

        // cheking reverse direction
        let isReverse = direction === 'asc' ? 1 : -1;

        // sorting data
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';

            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });

        return parseData;
    }

    handleOnSort(event) {
        this.sortBy = event.detail.sortBy;
        this.sortDirection = event.detail.sortDirection;
    }

    dispatchChangeEvent(isChanged) {
        this.dispatchEvent(
            new CustomEvent('changed', {
                detail: {
                    isChanged: isChanged
                }
            })
        );
    }
}