/**
 *@author       Mats Böhler
 *@created      18.09.2020
 *
 *
 *@description  MassenzuweisungAufgabenCtrl
 *
 *
 *@changelog    18.09.2020 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class MassenzuweisungCtrl {
	
	private List<MassenzuweisungUebersicht__mdt> columnDefinitions = new List<MassenzuweisungUebersicht__mdt>();
	@TestVisible
	private List<Column> columns = new List<Column>();
	@TestVisible
	private List<SObject> data = new List<SObject>();
	private String fields = '';
	private MassenzuweisungFilterCriteria filterCriteria;
	
	@AuraEnabled
	public static String loadData ( String [] filterCriteria ) {
		
		MassenzuweisungCtrl instance = new MassenzuweisungCtrl();
		instance.filterCriteria = new MassenzuweisungFilterCriteria( filterCriteria );
		instance.loadColumnDefinitions();
		instance.createColumns();
		instance.loadRecords();
		return JSON.serialize( instance );
	}
	
	@AuraEnabled
	public static String saveRecords ( String [] filterCriteria, String recordsString, String changedRecords ) {
		List<SObject> sObjects = ( List<SObject> ) JSON.deserialize( recordsString, List<SObject>.class ) ;
		List<SObject> recordsToBeSaved = new List<SObject>();
		for ( SObject sobj : sObjects ) {
			if ( changedRecords.contains( sobj.Id ) ) {
				SObject recordToSave = sobj.Id.getSobjectType().newSObject( sobj.Id );
				recordToSave.put( 'OwnerId', sobj.get( 'OwnerId' ) );
				recordsToBeSaved.add( recordToSave );
			}
		}
		try {
			update recordsToBeSaved;
		}
		catch ( Exception e ) {
			
			throw new AuraHandledException( e.getMessage() );
		}
		return loadData( filterCriteria );
	}
	
	@AuraEnabled(Cacheable=true)
	public static List<LookupSearchResult> searchOwners ( String searchTerm, List<String> selectedIds ) {
		
		User currentUser = [ SELECT Id, OrgE_DP__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1 ];
		
		List<LookupSearchResult> results = new List<LookupSearchResult>();
		searchTerm = '%' + DynamicQuery.removeRestrictedCharacters( searchTerm ) + '%';
		for ( User user : [
				SELECT
						Id,
						Name,
						UserRole.Name
				FROM User
				WHERE ( Profile.UserLicense.LicenseDefinitionKey = 'SFDC'
				OR Profile.UserLicense.LicenseDefinitionKey = 'FDC_SUB')
				AND Name LIKE :searchTerm
				AND OrgE_DP__c = :currentUser.OrgE_DP__c
		] ) {
			results.add(
					new LookupSearchResult(
							user.Id,
							'User',
							'standard:user',
							user.Name,
							user.UserRole.Name
					)
			);
		}
		results.sort();
		return results;
	}
	
	private void loadColumnDefinitions () {
		columnDefinitions = [
				SELECT
						Id,
						LabelSpalte__c,
						Feldlabel__c,
						Feldname__c,
						Feldtyp__c,
						Sortierbar__c,
						Nummerierung__c,
						Spaltenformatierung__c
				FROM MassenzuweisungUebersicht__mdt
				WHERE Objekt__c = :filterCriteria.getVersion()
				ORDER BY Nummerierung__c ASC NULLS LAST
		];
	}
	
	private void createColumns () {
		Set<String> queryFields = new Set<String>();
		for ( MassenzuweisungUebersicht__mdt columnDefinition : columnDefinitions ) {
			Column column = new Column();
			column.label = columnDefinition.LabelSpalte__c;
			column.fieldName = columnDefinition.Feldname__c;
			column.type = columnDefinition.Feldtyp__c;
			column.fieldLabel = columnDefinition.Feldlabel__c;
			column.allowSort = columnDefinition.Sortierbar__c;
			column.position = columnDefinition.Nummerierung__c;
			column.isEditable = column.fieldName == 'OwnerId';
			column.style = columnDefinition.Spaltenformatierung__c;
			columns.add( column );
			queryFields.add( columnDefinition.Feldlabel__c );
			queryFields.add( columnDefinition.Feldname__c );
		}
		for ( String queryField : queryFields ) {
			fields += queryField + ',';
		}
		fields = fields.contains( 'Id,' ) ? fields : fields + 'Id,';
		if ( filterCriteria.getVersion() == 'Account' ) {
			fields = fields.contains( 'ShippingCity' ) ? fields : fields + 'ShippingCity,';
			fields = fields.contains( 'ShippingPostalCode' ) ? fields : fields + 'ShippingPostalCode,';
		}
		columns.sort();
		fields = fields.removeEnd( ',' );
	}
	
	private void loadRecords () {
		switch on filterCriteria.getVersion() {
			when 'Task' {
				loadTasks();
			}
			when 'Account' {
				loadAccounts();
			}
			when else {
				return;
			}
		}
	}
	
	private void loadTasks () {
		
		String currentUserOrgedp = loadCurrentUser().OrgE_DP__c;
		
		String query = 'SELECT Owner.UserRole.Name, '
				+ fields
				+ ' FROM ' + filterCriteria.getVersion()
				+ ' WHERE isClosed = false';
		
		if ( String.isNotEmpty( filterCriteria.getZugeordnetZu() ) ) {
			query += ' AND Owner.Name LIKE \'%' + filterCriteria.getZugeordnetZu() + '%\' ';
		}
		if ( String.isNotEmpty( filterCriteria.getAufgabenart() ) ) {
			query += ' AND Aufgabenart__c LIKE \'%' + filterCriteria.getAufgabenart() + '%\' ';
		}
		if ( String.isNotEmpty( filterCriteria.getAstName() ) ) {
			query += ' AND PriohilfeAstname__c LIKE \'%' + filterCriteria.getAstName() + '%\' ';
		}
		if ( String.isNotEmpty( filterCriteria.getDebitor() ) ) {
			query += ' AND Account.Debitor_ASt_ID__c LIKE \'%' + filterCriteria.getDebitor() + '%\' ';
		}
		if ( String.isNotEmpty( filterCriteria.getErledigungBisZum() ) ) {
			query += ' AND Erledigung_bis_zum__c <= ' + filterCriteria.getErledigungBisZum();
		}
		String currentUserId = UserInfo.getUserId();
		if ( !filterCriteria.getShowAll() ) {
			query += ' AND OwnerId = :currentUserId ';
		}
		else {
			query += ' AND ( OrgE_DP_des_Inhabers__c = :currentUserOrgedp OR OwnerId = :currentUserId )';
		}
		query += addSorting();
		data = Database.query( query );
	}
	
	private void loadAccounts () {
		
		User currentUser = loadCurrentUser();
		String currentUserOrgedp = currentUser.OrgE_DP__c;
		currentUserOrgedp = currentUserOrgedp.length() > 8 ? currentUserOrgedp.substring( 8 ) : currentUserOrgedp;
		String currentUserId = currentUser.Id;
		
		String query = 'SELECT Owner.UserRole.Name, '
				+ fields
				+ ' FROM ' + filterCriteria.getVersion()
				+ ' WHERE (NOT RecordType.Developername LIKE \'%Dummy%\') ';
		
		if ( String.isNotEmpty( filterCriteria.getFiliale() ) ) {
			query += ' AND Name LIKE \'%' + filterCriteria.getFiliale() + '%\' ';
		}
		if ( String.isNotEmpty( filterCriteria.getAstName() ) ) {
			query += ' AND ASt_Name__c LIKE \'%' + filterCriteria.getAstName() + '%\' ';
		}
		if ( String.isNotEmpty( filterCriteria.getFilialart() ) ) {
			query += ' AND Filialtyp_OZ__c LIKE \'%' + filterCriteria.getFilialart() + '%\' ';
		}
		if ( String.isNotEmpty( filterCriteria.getNlBrief() ) ) {
			query += ' AND NL_Brief__c LIKE \'%' + filterCriteria.getNlBrief() + '%\' ';
		}
		
		query = addPostalCode( query );
		
		if ( String.isNotEmpty( filterCriteria.getInhaber() ) ) {
			query += ' AND Owner.Name LIKE \'%' + filterCriteria.getInhaber() + '%\' ';
		}
		if ( !filterCriteria.getShowAll() ) {
			query += ' AND OwnerId = :currentUserId ';
		}
		else {
			query += ' AND (GL__r.Name = :currentUserOrgedp OR OwnerId = :currentUserId) ';
		}
		query += addSorting();
		data = Database.query( query );
		for ( SObject sobj : data ) {
			String address = sobj.get( 'ShippingStreet' ) + ', ' + sobj.get( 'ShippingPostalCode' ) + ', ' + sobj.get( 'ShippingCity' );
			sobj.put( 'ShippingStreet', address );
		}
	}
	
	private User loadCurrentUser () {
		return [
				SELECT
						Id,
						OrgE_DP__c
				FROM User
				WHERE Id = :UserInfo.getUserId()
				LIMIT 1
		];
	}
	
	private String addPostalCode ( String query ) {
		if ( String.isNotEmpty( filterCriteria.getStrasse() ) ) {
			if ( !filterCriteria.getStrasse().contains( ',' ) ) {
				query += addWhereClauses( filterCriteria.getStrasse() );
			}
			else {
				for ( String filter : filterCriteria.getStrasse().split( ',' ) ) {
					if ( String.isNotEmpty( filter ) ) {
						query += addWhereClauses( filter );
					}
				}
			}
		}
		return query;
	}
	
	private String addWhereClauses ( String filter ) {
		String whereClause = ' AND ( ShippingPostalCode LIKE \'' + filter + '%\' ';
		whereClause += ' OR ShippingStreet LIKE \'%' + filter + '%\' ';
		whereClause += ' OR ShippingCity LIKE \'%' + filter + '%\' )';
		return whereClause;
	}
	
	private String addSorting () {
		return ' ORDER BY ' + filterCriteria.getSortBy() + ' ' + filterCriteria.getSortDirection()
				+ ' NULLS LAST LIMIT ' + filterCriteria.getMaxRecords();
	}
	
	private class Column implements Comparable {
		public String label { get; set; }
		public String fieldName { get; set; }
		public String type { get; set; }
		public String fieldLabel { get; set; }
		public Boolean allowSort { get; set; }
		public Decimal position { get; set; }
		public Boolean isEditable { get; set; }
		public String style { get; set; }
		
		public Integer compareTo ( Object obj ) {
			Column column = ( Column ) ( obj );
			if ( this.position > column.position ) {
				return 1;
			}
			if ( this.position == column.position ) {
				return 0;
			}
			return -1;
		}
	}
}