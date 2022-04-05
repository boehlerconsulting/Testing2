/**
 *@author       Mats Böhler <mats.boehler@boehlerconsulting.com>
 *@created      06.12.2018
 *@version      1.0
 *@since        44.0
 *
 *
 *@description  Post_DynamicTableController.js
 *
 *
 *@changelog    06.12.2018 Mats Böhler <mats.boehler@boehlerconsulting.com> - Created
 *
 *
 */
({
    initializeComponent: function (component, _event, helper) {
        component.set('v.showSpinner', true);
        component.set('v.PrivateMatchCriteria', component.get('v.MatchCriteria'));
        component.set('v.SelectedRecordsMap', new Map());
        helper.initializePageSizeSelectList(component);
        helper.initializeColumnMetaData(component);
        component.set('v.showSpinner', false);
    },

    updateMatchCriteria: function (component, _event, helper) {
        component.set('v.showSpinner', true);
        component.set('v.PrivateMatchCriteria', component.get("v.MatchCriteria"));
        helper.retrieveTotalRecords(component);
        helper.retrieveRecords(component, false);
        component.set('v.showSpinner', false);
    },

    selectRecord: function (component, event, helper) {
        helper.switchRow(component, parseInt(event.target.dataset.id), event.target.checked);
    },

    selectAllRecords: function (component, event, helper) {
        helper.switchAllRows(component, event.target.checked);
    },

    changeSort: function (component, event, helper) {
        component.set('v.showSpinner', true);
        let clickedElement = event.target;
        let sortField = clickedElement.dataset.id;
        let currentSortField = component.get('v.SortByField');
        let sortOrder = component.get('v.SortOrder');
        if (sortField === currentSortField) {
            if (sortOrder === 'ASC') {
                sortOrder = 'DESC';
            } else {
                sortOrder = 'ASC';
            }
        } else {
            currentSortField = sortField;
            sortOrder = 'DESC';
        }
        component.set('v.PageNumber', 1);
        component.set('v.SortByField', currentSortField);
        component.set('v.SortOrder', sortOrder);
        helper.retrieveRecords(component, false);
        component.set('v.showSpinner', false);
    },

    firstPage: function (component, _event, helper) {
        component.set('v.showSpinner', true);
        let hasPrevious = component.get('v.HasPrevious');
        if (hasPrevious) {
            component.set('v.PageNumber', 1);
            helper.updateTableRows(component);
        }
        component.set('v.showSpinner', false);
    },

    previousPage: function (component, _event, helper) {
        component.set('v.showSpinner', true);
        let hasPrevious = component.get('v.HasPrevious');
        if (hasPrevious) {
            let pageNumber = component.get('v.PageNumber');
            pageNumber = pageNumber - 1;
            component.set('v.PageNumber', pageNumber);
            helper.updateTableRows(component);
        }
        component.set('v.showSpinner', false);
    },

    nextPage: function (component, _event, helper) {
        component.set('v.showSpinner', true);
        let hasNext = component.get('v.HasNext');
        if (hasNext) {
            let pageNumber = component.get('v.PageNumber');
            pageNumber = pageNumber + 1;
            component.set('v.PageNumber', pageNumber);
            helper.updateTableRows(component);
        }
        component.set('v.showSpinner', false);
    },

    lastPage: function (component, _event, helper) {
        component.set('v.showSpinner', true);
        let hasNext = component.get('v.HasNext');
        if (hasNext) {
            let pageNumber = component.get('v.PageTotal');
            component.set('v.PageNumber', pageNumber);
            helper.updateTableRows(component);
        }
        component.set('v.showSpinner', false);
    },

    changePageSize: function (component, _event, helper) {
        component.set('v.showSpinner', true);
        component.set('v.PageNumber', 1);
        component.set('v.PageSize', component.find('pageSizeInput').get('v.value'));
        helper.updateTableRows(component);
        component.set('v.showSpinner', false);
    },

    navigateToSObject: function (_component, event) {
        let recordId = event.currentTarget.id;
        let navigate = $A.get('e.force:navigateToSObject');
        navigate.setParams({
            'recordId': recordId,
            'slideDevName': 'detail'
        });
        navigate.fire();
    },

    editRecord: function (component, event, helper) {
        let selectedAction = event.getParam("value");
        let indexVar = event.getSource().get("v.name");
        let allRecords = component.get('v.AllRecords');
        let recordId = allRecords[indexVar].Id;

        switch (selectedAction) {
            case "1":
                helper.doTaskEdit(component, recordId);
                break;
            case "2":
                helper.doTaskClose(component, recordId);
                break;
            default: //Sonarqube --> do nothing
                break;
        }
    },
})