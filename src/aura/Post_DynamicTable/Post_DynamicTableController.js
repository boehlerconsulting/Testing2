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
    initializeComponent: function (component, event, helper) {
        component.set('v.showSpinner', true);
        component.set('v.PrivateMatchCriteria', component.get('v.MatchCriteria'));
        component.set('v.SelectedRecordsMap', new Map());
        helper.initializePageSizeSelectList(component);
        helper.initializeColumnMetaData(component);
        component.set('v.showSpinner', false);
    },

    updateMatchCriteria: function (component, event, helper) {
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
        let clicked_element = event.target;
        let sort_field = clicked_element.dataset.id;
        let current_sort_field = component.get('v.SortByField');
        let sort_order = component.get('v.SortOrder');
        if (sort_field === current_sort_field) {
            if (sort_order === 'ASC') {
                sort_order = 'DESC';
            } else {
                sort_order = 'ASC';
            }
        } else {
            current_sort_field = sort_field;
            sort_order = 'DESC';
        }
        component.set('v.PageNumber', 1);
        component.set('v.SortByField', current_sort_field);
        component.set('v.SortOrder', sort_order);
        helper.retrieveRecords(component, false);
        component.set('v.showSpinner', false);
    },

    firstPage: function (component, event, helper) {
        component.set('v.showSpinner', true);
        let has_previous = component.get('v.HasPrevious');
        if (has_previous) {
            component.set('v.PageNumber', 1);
            helper.updateTableRows(component);
        }
        component.set('v.showSpinner', false);
    },

    previousPage: function (component, event, helper) {
        component.set('v.showSpinner', true);
        let has_previous = component.get('v.HasPrevious');
        if (has_previous) {
            let page_number = component.get('v.PageNumber');
            page_number = page_number - 1;
            component.set('v.PageNumber', page_number);
            helper.updateTableRows(component);
        }
        component.set('v.showSpinner', false);
    },

    nextPage: function (component, event, helper) {
        component.set('v.showSpinner', true);
        let has_next = component.get('v.HasNext');
        if (has_next) {
            let page_number = component.get('v.PageNumber');
            page_number = page_number + 1;
            component.set('v.PageNumber', page_number);
            helper.updateTableRows(component);
        }
        component.set('v.showSpinner', false);
    },

    lastPage: function (component, event, helper) {
        component.set('v.showSpinner', true);
        let has_next = component.get('v.HasNext');
        if (has_next) {
            let page_number = component.get('v.PageTotal');
            component.set('v.PageNumber', page_number);
            helper.updateTableRows(component);
        }
        component.set('v.showSpinner', false);
    },

    changePageSize: function (component, event, helper) {
        component.set('v.showSpinner', true);
        component.set('v.PageNumber', 1);
        component.set('v.PageSize', component.find('pageSizeInput').get('v.value'));
        helper.updateTableRows(component);
        component.set('v.showSpinner', false);
    },

    navigateToSObject: function (component, event) {
        let record_id = event.currentTarget.id;
        let navigate = $A.get('e.force:navigateToSObject');
        navigate.setParams({
            'recordId': record_id,
            'slideDevName': 'detail'
        });
        navigate.fire();
    },

    editRecord: function (component, event, helper) {

        var selectedAction = event.getParam("value");
        var indexVar = event.getSource().get("v.name");
        var all_records = component.get('v.AllRecords');
        var recordId = all_records[indexVar].Id;

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