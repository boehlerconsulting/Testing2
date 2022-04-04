/**
 *@author       Mats Böhler <mats.boehler@boehlerconsulting.com>
 *@created      06.12.2018
 *@version      1.0
 *@since        44.0
 *
 *
 *@description  Post_DynamicTableHelper.js
 *
 *
 *@changelog    06.12.2018 Mats Böhler <mats.boehler@boehlerconsulting.com> - Created
 *
 *
 */
({
    initializePageSizeSelectList : function(component) {
        let pageSize = component.get('v.PageSize');
        let availablePageSizes = component.get('v.AvailablePageSizes');
        let options = [];
        for(let option in availablePageSizes){
            options.push({
                value: availablePageSizes[option],
                label: availablePageSizes[option],
                selected: (availablePageSizes[option] === pageSize)
            });
        }
        component.find('pageSizeInput').set('v.options', options);
    },

    initializeColumnMetaData : function(component) {
        let action = component.get('c.getColumnMetadata');
        action.setParams({
            sobject_name: component.get('v.SObjectName'),
            field_names: component.get('v.FieldNames'),
            field_labels: component.get('v.FieldLabels'),
            sortable_field_names: component.get('v.SortableFieldNames'),
            reference_fields: component.get('v.ReferenceFields'),
            override_field_type: component.get('v.OverrideFieldType')
        });
        action.setCallback(this, function(response){
            let state = response.getState();
            if(state === 'SUCCESS'){
                let columnMetadataWrapper = JSON.parse(response.getReturnValue());
                if(columnMetadataWrapper.error_message){
                    this.handleErrorMessage(component, columnMetadataWrapper.error_message);
                } else {
                    let fieldNames = component.get('v.FieldNames');
                    let selectionColumn = component.get('v.SelectionColumn');
                    let tableColumns = [];
                    if(selectionColumn){
                        tableColumns.push({
                            is_selection_column: true
                        });
                    }
                    for(let i = 0; i < fieldNames.length; i++){
                        tableColumns.push({
                            is_selection_column: false,
                            field_name: fieldNames[i],
                            field_api_name: columnMetadataWrapper.column_metadata[fieldNames[i]].field_api_name,
                            field_label: columnMetadataWrapper.column_metadata[fieldNames[i]].field_label,
                            field_type: columnMetadataWrapper.column_metadata[fieldNames[i]].field_type,
                            field_override_type: columnMetadataWrapper.column_metadata[fieldNames[i]].field_override_type,
                            field_is_reference: columnMetadataWrapper.column_metadata[fieldNames[i]].field_is_reference,
                            field_is_sortable: columnMetadataWrapper.column_metadata[fieldNames[i]].field_is_sortable
                        });
                    }
                    component.set('v.ColumnMetadata', columnMetadataWrapper.column_metadata);
                    component.set('v.TableColumns', tableColumns);
                    this.retrieveTotalRecords(component);
                    this.retrieveRecords(component, true);
                }
            } else if(state === 'ERROR'){
                this.handleErrorMessage(component, response.getError());
            }
            else{
                //Sonarqube -> do nothing
            }
        });
        $A.enqueueAction(action);
    },

    retrieveTotalRecords : function(component){
        let action = component.get('c.getTotalRecords');
        action.setParams({
            objectName: component.get('v.SObjectName'),
            filialId: component.get('v.accountId'),
            userType: component.get('v.userType'),
            filterValue: component.get('v.filterValue')
        });
        action.setCallback(this, function(response){
            let state = response.getState();
            if(state === 'SUCCESS'){
                let totalRecords = parseInt(response.getReturnValue());
                component.set('v.TotalRecords', totalRecords);
            } else if(state === 'ERROR'){
                this.handleErrorMessage(component, response.getError());
            }
            else{
                //Sonarqube -> do nothing
            }
        });
        $A.enqueueAction(action);
    },

    retrieveRecords : function(component, criteriaHaveChanged){
        var sObjectName = component.get('v.SObjectName');
        let action = component.get( sObjectName === 'Task' ? 'c.getTaskRecords' : 'c.getEventRecords');
        action.setParams({
            filialId: component.get('v.accountId'),
            userType: component.get('v.userType'),
            filterValue: component.get('v.filterValue'),
            sortByField: component.get('v.SortByField'),
            sortOrder: component.get('v.SortOrder')
        });
        action.setCallback(this, function(response){
            let state = response.getState();
            if(state === 'SUCCESS'){
                let sobjectWrapper = JSON.parse(response.getReturnValue());
                if(sobjectWrapper.error_message){
                    this.handleErrorMessage(component, sobjectWrapper.error_message);
                } else {
                    let preserveSelectedRecords = component.get('v.PreserveSelectedRecords');
                    component.set('v.AllRecords', sobjectWrapper.sobjects);
                    component.set('v.TotalRecordsLoaded', sobjectWrapper.sobjects.length);
                    if(!preserveSelectedRecords && criteriaHaveChanged){
                        component.set('v.SelectedRecordsMap', new Map());
                        component.set('v.AllRecordsSelected', false);
                        this.updateSelectedRecords(component);
                    }
                    this.updateTableRows(component);
                }
            } else if(state === 'ERROR'){
                this.handleErrorMessage(component, response.getError());
            }
            else{
                //Sonarqube -> do nothing
            }
        });
        $A.enqueueAction(action);
    },

    updateTableRows : function(component) {
        this.updatePagination(component);
        let allRecords = component.get('v.AllRecords');
        let tableRows = [];
        if(allRecords.length){
            let firstRecordOnPage = component.get('v.FirstRecordOnPage');
            let lastRecordOnPage = component.get('v.LastRecordOnPage');
            let tableColumns = component.get('v.TableColumns');
            let selectedRecordsMap = component.get('v.SelectedRecordsMap');
            for(let i = firstRecordOnPage-1; i < lastRecordOnPage; i++){
                let row = [];
                for(let j = 0; j < tableColumns.length; j++){
                    if(tableColumns[j].is_selection_column){
                        row.push({
                            is_selection_column: true,
                            is_checked: selectedRecordsMap.has(allRecords[i].Id)
                        });
                    } else {
                        let fields = tableColumns[j].field_api_name.split('.');
                        let value;
                        let reference;
                        if(fields.length > 1){
                            let record = allRecords[i];
                            for(let k = 0; k < fields.length-1; k++){
                                record = record[fields[k]];
                            }
                            if(typeof(record) !== 'undefined'){
                                value = record[fields[fields.length-1]];
                                reference = record.Id;
                            }
                        } else {
                            value = allRecords[i][tableColumns[j].field_api_name];
                            reference = allRecords[i].Id;
                        }
                        if(tableColumns[j].field_type === 'PERCENT'){
                            value = (value != null) ? (value * 100) : 0
                        }
                        if(tableColumns[j].field_override_type !== undefined && tableColumns[j].field_override_type !== tableColumns[j].field_type){
                            switch(tableColumns[j].field_override_type){
                                case 'BOOLEAN':{
                                    if(tableColumns[j].field_type === 'CURRENCY'
                                        || tableColumns[j].field_type === 'DOUBLE'
                                        || tableColumns[j].field_type === 'INTEGER'
                                        || tableColumns[j].field_type === 'PERCENT'){
                                        value = (value !== undefined && value !== 0);
                                    } else {
                                        value = (value !== undefined);
                                    }
                                    break;
                                }
                                case 'CURRENCY':{
                                    if(tableColumns[j].field_type !== 'DOUBLE' && tableColumns[j].field_type !== 'INTEGER'){
                                        value = undefined;
                                    }
                                    break;
                                }
                                case 'DATE':{
                                    if(tableColumns[j].field_type !== 'DATETIME'){
                                        value = undefined;
                                    }
                                    break;
                                }
                                case 'DATETIME':{
                                    if(tableColumns[j].field_type !== 'DATE'){
                                        value = undefined;
                                    }
                                    break;
                                }
                                case 'DOUBLE':{
                                    if(tableColumns[j].field_type === 'BOOLEAN'){
                                        value = value ? 1.0 : 0.0;
                                    } else if(tableColumns[j].field_type !== 'CURRENCY'
                                        && tableColumns[j].field_type !== 'INTEGER' && tableColumns[j].field_type !== 'PERCENT'){
                                        value = undefined;
                                    }
                                    break;
                                }
                                case 'INTEGER':{
                                    if(tableColumns[j].field_type === 'BOOLEAN'){
                                        value = value ? 1 : 0;
                                    } else if((tableColumns[j].field_type === 'CURRENCY'
                                        || tableColumns[j].field_type === 'DOUBLE'
                                        || tableColumns[j].field_type === 'PERCENT') && value !== undefined){
                                        value = parseInt(value);
                                    } else {
                                        value = undefined;
                                    }
                                    break;
                                }
                                case 'PERCENT':{
                                    if(tableColumns[j].field_type === 'DOUBLE' || tableColumns[j].field_type === 'INTEGER'){
                                        if(value === undefined){
                                            value = 0;
                                        }
                                    } else {
                                        value = undefined;
                                    }
                                    break;
                                }
                                case 'STRING':{
                                    if(value !== undefined){
                                        value = value.toString();
                                    }
                                    break;
                                }
                                default: //Sonarqube --> do nothing
                                    break;
                            }
                        }

                        row.push({
                            is_selection_column: false,
                            field_type: tableColumns[j].field_override_type ? tableColumns[j].field_override_type : tableColumns[j].field_type,
                            reference: tableColumns[j].field_is_reference ? reference : null,
                            value: value,
                            field_name: tableColumns[j].field_name,
                            accountName: allRecords[i].Account ? allRecords[i].Account.Name : null,
                            mitarbeiterName: allRecords[i].Who ? allRecords[i].Who.Name : null,
                            ownerName: allRecords[i].Owner ? allRecords[i].Owner.Name : null,
                        });
                    }
                }
                tableRows.push(row);
            }
        }
        component.set('v.TableRows', tableRows);
    },

    updatePagination : function(component) {
        let pageNumber = component.get('v.PageNumber');
        let pageSize = component.get('v.PageSize');
        let totalRecords = component.get('v.TotalRecordsLoaded');
        let pagesTotal = Math.ceil(totalRecords / pageSize);
        let firstRecordOnPage = (totalRecords > 0) ? (((pageNumber - 1) * pageSize) + 1) : 0;
        let lastRecordOnPage;
        if((pageNumber * pageSize) > totalRecords){
            lastRecordOnPage = totalRecords;
        } else {
            lastRecordOnPage = (pageNumber * pageSize);
        }
        let hasPrevious = pageNumber > 1;
        let hasNext = pageNumber < pagesTotal;
        component.set('v.PageTotal', pagesTotal);
        component.set('v.FirstRecordOnPage', firstRecordOnPage);
        component.set('v.LastRecordOnPage', lastRecordOnPage);
        component.set('v.HasPrevious', hasPrevious);
        component.set('v.HasNext', hasNext);
        component.find('firstButton').set('v.disabled', (!hasPrevious));
        component.find('previousButton').set('v.disabled', (!hasPrevious));
        component.find('nextButton').set('v.disabled', (!hasNext));
        component.find('lastButton').set('v.disabled', (!hasNext));
    },

    switchRow : function(component, index, isChecked){
        let allRecords = component.get('v.AllRecords');
        let firstRecordOnPage = component.get('v.FirstRecordOnPage');
        let selectedRecordsMap = component.get('v.SelectedRecordsMap');
        let indexOnPage = (firstRecordOnPage + index - 1);
        if(indexOnPage <= allRecords.length){
            allRecords[indexOnPage].is_checked = isChecked;
            if(isChecked){
                selectedRecordsMap.set(allRecords[indexOnPage].Id, allRecords[indexOnPage]);
            } else {
                selectedRecordsMap.delete(allRecords[indexOnPage].Id);
                component.set('v.AllRecordsSelected', false);
            }
        }
        this.updateSelectedRecords(component);
    },

    switchAllRows : function(component, isChecked){
        let allRecords = component.get('v.AllRecords');
        let selectedRecordsMap = component.get('v.SelectedRecordsMap');
        if(isChecked){
            for(let i = 0; i < allRecords.length; i++){
                allRecords[i].is_checked = true;
                selectedRecordsMap.set(allRecords[i].Id, allRecords[i]);
            }
        } else {
            for(let i = 0; i < allRecords.length; i++){
                allRecords[i].is_checked = false;
                selectedRecordsMap.delete(allRecords[i].Id);
            }
        }
        component.set('v.AllRecordsSelected', isChecked);
        this.updateTableRows(component);
        this.updateSelectedRecords(component);
    },

    updateSelectedRecords : function(component){
        let selectedRecordsMap = component.get('v.SelectedRecordsMap');
        component.set('v.SelectedRecords', Array.from(selectedRecordsMap.values()));
    },

    handleErrorMessage : function(component, message){
        let action = $A.get('e.force:showToast');
        action.setParams({
            title: 'DynamicTable Component Error',
            message: message,
            type: 'error'
        });
        action.fire();
        component.set('v.ErrorMessage', message);
    },

    doTaskEdit : function(component, recordId){
        var editRecordEvent = $A.get("e.force:editRecord");
        editRecordEvent.setParams({
            "recordId": recordId,
            "Status": "Erledigt",
            "panelOnDestroyCallback": function() {

                if(component.get("v.accountId")){
                    var navEvt = $A.get("e.force:navigateToSObject");
                    navEvt.setParams({
                        "recordId": component.get("v.accountId"),
                        "slideDevName": "detail"
                    });
                    navEvt.fire();
                }else{
                    $A.get("e.force:navigateHome").fire();
                }
            }
        });
        editRecordEvent.fire();
    },

    doTaskClose : function(component, recordId){
        var editRecordEvent = $A.get("e.force:editRecord");
        editRecordEvent.setParams({
            "recordId": recordId,
            "panelOnDestroyCallback": function() {

                if(component.get("v.accountId")){
                    var navEvt = $A.get("e.force:navigateToSObject");
                    navEvt.setParams({
                        "recordId": component.get("v.accountId"),
                        "slideDevName": "detail"
                    });
                    navEvt.fire();
                }else{
                    $A.get("e.force:navigateHome").fire();
                }
            }
        });
        editRecordEvent.fire();
    },
})