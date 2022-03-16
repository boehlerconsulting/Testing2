/**
 *@author       Mats Böhler
 *@created      28.09.2019
 *@version      1.0
 *@since        45.0
 *
 *
 *@description  hwLightningDatatable
 *
 *
 *@changelog    28.09.2019 Mats Böhler - Created
 *
 *
 */

import {LightningElement, wire, track, api} from 'lwc';

// Import custom labels
import zeige from '@salesforce/label/c.Post_Zeige';


export default class hwLightningDatatable extends LightningElement {

    /*API*/
    @api
    get tableColumns() {
        return this.columns;
    }

    set tableColumns(value) {
        this.columns = JSON.parse(JSON.stringify(value));
        this.setShowSortIcon();
    }

    @api
    get tableData() {
        return this.data;
    }

    set tableData(value) {
        if (value) {
            this.data = JSON.parse(JSON.stringify(value));
            this.initializePagination();
        }
    }

    @api sortBy;
    @api sortDirection;
    @api showCheckboxColumn = false;
    @api showSelectAll = false;
    @api isAllSelected = false;
    @api selectedTaskIds;
    @api erledigungstypPicklistValues;
    @api showActionColumn = false;
    @api isTermin = false;
    @api isSelectedByLeadId;
    @api plannedDateByLeadId;
    @api initialSelectionById;
    @api maxRecords = 10000;
    @api actionName;
    @api isMassenzuweisung = false;

    /*TRACK*/

    @track columns;
    @track data;
    @api picklistValue = '5';
    @track recordsToShow;
    @track firstRecordOnPage = 0;
    @track lastRecordOnPage = 0;


    get noData() {
        return this.recordsToShow ? this.recordsToShow.length < 1 : true;
    }

    initializePagination() {
        this.firstRecordOnPage = 1;
        this.lastRecordOnPage = this.totalRecords < this.picklistValueAsInteger ? this.totalRecords : this.picklistValueAsInteger;
        this.setRecordsToShow();
    }

    connectedCallback() {
        if (this.sortBy && this.sortDirection) {
            this.setShowSortIcon();
            this.initializePagination();
        }
    }

    renderedCallback() {
    }

    setRecordsToShow() {
        this.recordsToShow = [];
        for (let i = this.firstRecordOnPage - 1; i < this.lastRecordOnPage; i++) {
            if (this.data[i]) {
                this.recordsToShow.push(this.data[i]);
            }
        }
    }

    get totalRecords() {
        return this.tableData.length;
    }

    get totalRecordsDisplay() {
        return this.tableData
            ? this.tableData.length >= this.maxRecords
                ? this.tableData.length.toString() + '+'
                : this.tableData.length.toString()
            : '0';
    }

    get firstDisabled() {
        return this.picklistValueAsInteger > this.totalRecords || this.previousDisabled;
    }

    firstPage() {
        this.firstRecordOnPage = 1;
        this.lastRecordOnPage = this.picklistValueAsInteger;
        this.setRecordsToShow();
    }

    get previousDisabled() {
        return this.firstRecordOnPage <= 1;
    }

    previousPage() {
        if (this.lastRecordOnPage === this.totalRecords) {
            this.lastRecordOnPage = this.totalRecords - this.picklistValueAsInteger;
            this.firstRecordOnPage = this.lastRecordOnPage - this.picklistValueAsInteger;
        } else {
            this.firstRecordOnPage -= this.picklistValueAsInteger;
            this.lastRecordOnPage -= this.picklistValueAsInteger;
        }
        if (this.firstRecordOnPage <= 1) {
            this.firstRecordOnPage = 1;
            this.lastRecordOnPage = this.picklistValueAsInteger;
        }
        this.setRecordsToShow();
    }

    get nextDisabled() {
        return this.lastRecordOnPage >= this.totalRecords;
    }

    nextPage() {
        this.firstRecordOnPage += this.picklistValueAsInteger;
        this.lastRecordOnPage += this.picklistValueAsInteger;
        if (this.lastRecordOnPage >= this.totalRecords) {
            this.lastRecordOnPage = this.totalRecords;
        }
        this.setRecordsToShow();
    }

    get lastDisabled() {
        return this.nextDisabled;
    }

    lastPage() {
        this.lastRecordOnPage = this.totalRecords;
        this.firstRecordOnPage = this.lastRecordOnPage - this.picklistValueAsInteger + 1;
        this.setRecordsToShow();
    }

    get picklistValueAsInteger() {
        return parseInt(this.picklistValue, 10);
    }

    get options() {
        return [
            {label: '5', value: '5'},
            {label: '10', value: '10'},
            {label: '20', value: '20'},
            {label: '25', value: '25'},
            {label: '50', value: '50'},
        ];
    }


    handleChange(event) {
        this.picklistValue = event.detail.value;
        this.firstRecordOnPage = 1;
        this.lastRecordOnPage = this.totalRecords < this.picklistValueAsInteger ? this.totalRecords : this.picklistValueAsInteger;
        this.setRecordsToShow();
    }

    setShowSortIcon() {
        for (let i = 0; i < this.columns.length; i++) {
            this.tableColumns[i].showSortIcon = this.getSortField(i) === this.sortBy;
        }
    }

    get sortArrow() {

        return this.sortDirection === 'asc' ? 'utility:arrowup' : 'utility:arrowdown'
    }

    getSortField(columnIndex) {
        return this.tableColumns[columnIndex].type === 'lookup'
            ? this.tableColumns[columnIndex].fieldLabel
            : this.tableColumns[columnIndex].fieldName;
    }

    handleSortdata(event) {

        let columnIndex = event.target.dataset.item;
        let column = this.tableColumns[columnIndex];

        if (column && column.allowSort) {
            // field name
            let sortField = this.getSortField(columnIndex);
            this.sortBy = sortField;
            // sort direction
            let currentSortDirection = this.sortDirection;
            this.sortDirection = currentSortDirection === 'asc' ? 'desc' : 'asc';

            // calling sortdata function to sort the data based on direction and selected field
            this.sortData(sortField, this.sortDirection);
            this.setShowSortIcon();
            this.dispatchEvent(
                new CustomEvent('sort', {
                    detail: {
                        sortBy: this.sortBy,
                        sortDirection: this.sortDirection
                    }
                })
            );
        }
    }

    get fieldLabel() {
        return this.column.fieldLabel.includes('.')
            ? this.rowData[this.column.fieldLabel.split('.')[0]][this.column.fieldLabel.split('.')[1]]
            : this.rowData[this.column.fieldLabel];
    }

    sortData(fieldname, direction) {
        // serialize the data before calling sort function
        let parseData = JSON.parse(JSON.stringify(this.tableData));
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

        // set the sorted data to data table data
        this.tableData = parseData;
    }

    handleOnSelected(event) {
        this.data[event.detail.rowIndex].isSelected = event.detail.checked;

        this.dispatchEvent(
            new CustomEvent('selected', {
                detail: {
                    checked: event.detail.checked,
                    taskId: event.detail.taskId,
                    rowIndex: event.detail.rowIndex
                }
            })
        );
    }

    handleOnTypChanged(event) {

        this.dispatchEvent(
            new CustomEvent('typchanged', {
                detail: {
                    erledigungstypValue: event.detail.erledigungstypValue,
                    taskId: event.detail.taskId,
                    rowIndex: event.detail.rowIndex
                }
            })
        );
    }

    handleOnTerminiertChanged(event) {
        this.dispatchEvent(
            new CustomEvent('terminiertchanged', {
                detail: {
                    terminiertValue: event.detail.terminiertValue,
                    taskId: event.detail.taskId,
                    rowIndex: event.detail.rowIndex
                }
            })
        );
    }

    handleOnPlannedChanged(event) {
        this.dispatchEvent(
            new CustomEvent('plannedchanged', {
                detail: {
                    plannedValue: event.detail.plannedValue,
                    leadId: event.detail.leadId,
                    rowIndex: event.detail.rowIndex
                }
            })
        );
    }

    handleShowTasks(event) {
        this.dispatchEvent(
            new CustomEvent('showtasks', {
                detail: {
                    accountId: this.isTermin ? this.recordsToShow[event.detail.value].WhatId : this.recordsToShow[event.detail.value].Id,
                    terminZum: this.isTermin ? this.recordsToShow[event.detail.value].TerminiertZum__c : null,
                }
            })
        );
    }

    handleAction(event) {
        this.dispatchEvent(
            new CustomEvent('action', {
                detail: {
                    recordId: event.detail.value
                }
            })
        );
    }

    handleOnOwnerChanged(event) {
        this.dispatchEvent(
            new CustomEvent('ownerchanged', {
                detail: {
                    ownerId: event.detail.ownerId,
                    leadId: event.detail.leadId,
                    title: event.detail.title,
                    subtitle: event.detail.subtitle
                }
            })
        );
    }

    handleOnDateChanged(event) {
        this.dispatchEvent(
            new CustomEvent('datechanged', {
                detail: {
                    value: event.detail.value,
                    leadId: event.detail.leadId,
                    fieldName: event.detail.fieldName
                }
            })
        );
    }

    handleFieldChanged(event) {
        this.dispatchEvent(
            new CustomEvent('fieldchanged', {
                detail: {
                    value: event.detail.value,
                    leadId: event.detail.leadId,
                    fieldName: event.detail.fieldName
                }
            })
        );
    }

    handleAllSelected() {

        let recordIds = new Set();
        for (let i = 0; i < this.recordsToShow.length; i++) {
            recordIds.add(this.data[i].Id);
        }
        this.dispatchEvent(
            new CustomEvent('allselected', {
                detail: {
                    checked: !this.isAllSelected,
                    recordIds: recordIds
                }
            })
        );
    }

    get isStandardAction() {
        return this.actionName;
    }

    get isFirstPage(){
        return this.firstRecordOnPage === 1;
    }
}