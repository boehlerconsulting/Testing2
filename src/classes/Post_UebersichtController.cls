/**
 *@author       Mats Böhler <mats.boehler@boehlerconsulting.com>
 *@created      03.12.2018
 *@version      1.0
 *@since        44.0
 *
 *
 *@description  Post_UebersichtController
 *
 *
 *@changelog    03.12.2018 Mats Böhler <mats.boehler@boehlerconsulting.com> - Created
 *              
 * 
 */
public with sharing class Post_UebersichtController {
	
	private static Map<Id, String> recordTypesById { get; set; }
	public List<String> fieldsToQuery = new List<String>();
	public List<String> referenceFields;
	public List<String> overrideFieldType;
	public List<String> fieldLabels;
	public String filterCriteria { get; set; }
	public String sortString { get; set; }
	public String filterValue { get; set; }
	public List<SelectOptionLightning> taskFilter = new List<SelectOptionLightning>();
	
	@AuraEnabled
	public static String initialize ( String accountId, String userType, String objectName ) {
		Post_UebersichtController ctrl = new Post_UebersichtController();
		
		/*try {*/
			
			if ( objectName == 'Task' ) {
				ctrl = initializeTaskComponent( ctrl, userType, accountId );
			}
			else if ( objectName == 'Event' ) {
				ctrl = initializeEventComponent( ctrl, accountId );
			}
			else{
				//Sonarqube --> do nothing
			}
		/*}
		catch ( Exception e ) {
			throw new AuraHandledException ( e.getMessage() );
		}*/
		
		return JSON.serialize( ctrl );
	}
	
	@AuraEnabled
	public static String getFilterCriteria ( String accountId, String userType, String filterValue, String objectName ) {
		
		Post_UebersichtController ctrl = new Post_UebersichtController();
		
		/*try {*/
			if ( objectName == 'Task' ) {
				ctrl = initializeTaskComponent( ctrl, userType, accountId, filterValue );
			}
			else if ( objectName == 'Event' ) {
				ctrl = initializeEventComponent( ctrl, accountId, filterValue );
			}
			else{
				//Sonarqube --> do nothing
			}
		/*}
		catch ( Exception e ) {
			throw new AuraHandledException ( e.getMessage() );
		}*/
		
		return JSON.serialize( ctrl );
	}
	
	@AuraEnabled
	public static List<String> fetchRecordTypeValues ( String objectName ) {
		
		/*try {*/
			List<RecordTypeInfo> recordTypeInfos = Schema.getGlobalDescribe().get( objectName ).getDescribe().getRecordTypeInfos();
			recordTypesById = new Map<Id, String>();
			for ( RecordTypeInfo recordTypeInfo : recordTypeInfos ) {
				if ( recordTypeInfo.getName() != 'Master'
						&& recordTypeInfo.isAvailable()
						&& recordTypeInfo.isActive() ) {
					recordTypesById.put( recordTypeInfo.getRecordTypeId(), recordTypeInfo.getName() );
				}
			}
		/*}
		catch ( Exception e ) {
			throw new AuraHandledException ( e.getMessage() );
		}*/
		return recordTypesById.values();
	}
	
	@AuraEnabled
	public static Id getRecordTypeIds ( String objectName, String recordTypeLabel ) {
		try {
			return Schema.getGlobalDescribe().get( objectName ).getDescribe().getRecordTypeInfosByName().get( recordTypeLabel ).getRecordTypeId();
		}
		catch ( Exception e ) {
			throw new AuraHandledException ( e.getMessage() );
		}
	}
	
	private static Post_UebersichtController initializeTaskComponent ( Post_UebersichtController ctrl, String userType, String accountId ) {
		Post_AufgabenUebersicht visualforceController = new Post_AufgabenUebersicht();
		visualforceController.userTypAttribute = userType;
		visualforceController.accountIdAttribute = accountId;
		ctrl.fieldsToQuery.addAll( visualforceController.aufgabenFelderIds.keySet() );
		if ( String.isNotBlank( accountId ) ) {
			ctrl.referenceFields = new List<String> {
					'Subject', 'WhoId', 'OwnerId'
			};
			ctrl.overrideFieldType = new List<String> {
					'Subject:STRING', 'WhoId:STRING', 'OwnerId:STRING'
			};
			ctrl.fieldLabels = new List<String> {
					'WhoId:Mitarbeiter', 'OwnerId:Zugeordnet zu'
			};
		}
		else if ( userType == 'AG' ) {
			ctrl.referenceFields = new List<String> {
					'Subject'
			};
			ctrl.overrideFieldType = new List<String> {
					'Subject:STRING'
			};
			ctrl.fieldLabels = new List<String> {
			};
		}
		else if ( userType == 'AN' ) {
			ctrl.referenceFields = new List<String> {
					'Subject'
			};
			ctrl.overrideFieldType = new List<String> {
					'Subject:STRING'
			};
			ctrl.fieldLabels = new List<String> {
			};
		}
		else{
			//Sonarqube --> do nothing
		}
		ctrl.filterCriteria = visualforceController.aufgabenAbfrageFilter;
		ctrl.sortString = visualforceController.aufgabenSortierung;
		ctrl.filterValue = visualforceController.taskFilter;
		for ( SelectOption selectOption : visualforceController.aufgabenFilter ) {
			ctrl.taskFilter.add( new SelectOptionLightning( selectOption.getValue(), selectOption.getLabel() ) );
		}
		return ctrl;
	}
	
	private static Post_UebersichtController initializeEventComponent ( Post_UebersichtController ctrl, String accountId ) {
		Post_EreignisUebersicht visualforceController = new Post_EreignisUebersicht();
		visualforceController.accountIdAttribute = accountId;
		ctrl.fieldsToQuery.addAll( visualforceController.ereignisFelderIds.keySet() );
		ctrl.referenceFields = new List<String> {
				'Subject', 'OwnerId'
		};
		ctrl.overrideFieldType = new List<String> {
				'Subject:STRING', 'OwnerId:STRING'
		};
		ctrl.fieldLabels = new List<String> {
				'WhoId:Mitarbeiter', 'OwnerId:Zugeordnet zu'
		};
		ctrl.filterCriteria = visualforceController.ereignisAbfrageFilter;
		ctrl.sortString = visualforceController.ereignisSortierung;
		ctrl.filterValue = visualforceController.ereignisFilter;
		for ( SelectOption selectOption : visualforceController.ereignisFilterOptions ) {
			ctrl.taskFilter.add( new SelectOptionLightning( selectOption.getValue(), selectOption.getLabel() ) );
		}
		return ctrl;
	}
	
	private static Post_UebersichtController initializeTaskComponent (
			Post_UebersichtController ctrl,
			String userType,
			String accountId,
			String filterValue ) {
		Post_AufgabenUebersicht visualforceController = new Post_AufgabenUebersicht();
		visualforceController.userTypAttribute = userType;
		visualforceController.accountIdAttribute = accountId;
		visualforceController.taskFilter = filterValue;
		ctrl.fieldsToQuery.addAll( visualforceController.aufgabenFelderIds.keySet() );
		ctrl.filterCriteria = visualforceController.aufgabenAbfrageFilter;
		ctrl.sortString = visualforceController.aufgabenSortierung;
		ctrl.filterValue = visualforceController.taskFilter;
		for ( SelectOption selectOption : visualforceController.aufgabenFilter ) {
			ctrl.taskFilter.add( new SelectOptionLightning( selectOption.getValue(), selectOption.getLabel() ) );
		}
		return ctrl;
	}
	
	private static Post_UebersichtController initializeEventComponent ( Post_UebersichtController ctrl, String accountId, String filterValue ) {
		Post_EreignisUebersicht visualforceController = new Post_EreignisUebersicht();
		visualforceController.accountIdAttribute = accountId;
		visualforceController.ereignisFilter = filterValue;
		ctrl.fieldsToQuery.addAll( visualforceController.ereignisFelderIds.keySet() );
		ctrl.filterCriteria = visualforceController.ereignisAbfrageFilter;
		ctrl.sortString = visualforceController.ereignisSortierung;
		ctrl.filterValue = visualforceController.ereignisFilter;
		for ( SelectOption selectOption : visualforceController.ereignisFilterOptions ) {
			ctrl.taskFilter.add( new SelectOptionLightning( selectOption.getValue(), selectOption.getLabel() ) );
		}
		return ctrl;
	}
	
	public class SelectOptionLightning {
		public SelectOptionLightning ( String value, String label ) {
			this.value = value;
			this.label = label;
			this.disabled = false;
			this.escapeItem = false;
		}
		
		@AuraEnabled
		public String label { get; set; }
		@AuraEnabled
		public String value { get; set; }
		@AuraEnabled
		public Boolean disabled { get; set; }
		@AuraEnabled
		public Boolean escapeItem { get; set; }
	
	}
}