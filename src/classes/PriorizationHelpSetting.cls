/**
 *@author       Mats Böhler
 *@created      30.03.2020
 *
 *
 *@description  PriorizationHelpSetting
 *
 *
 *@changelog    30.03.2020 Mats Böhler  - Created
 *              
 * 
 */
public with sharing class PriorizationHelpSetting {
	
	public Boolean isClosed = false;
	public Boolean isFiliale = false;
	public Integer months = 0;
	public Id recordId;
	public String sObjectType = '';
	public String version = '';
	public String sortBy = '';
	public String sortDirection = '';
	public String aufgabenstatusValue = '';
	public Boolean isScheduled = false;
	public Boolean isTerminNotTerminiert = false;
	public Date terminZum;
	public String fields = '';
	public String role = '';
	public String origin = '';
	public User vertriebsmanager;
	public String nlBrief;
	public Decimal defaultFilter = 5;
	public String zeige = '';
	
	public void setInstanceVariables ( String filterCriteria ) {
		
		Map<String, Object> filterCriteriaByName =
				( Map<String, Object> )
						JSON.deserializeUntyped( filterCriteria );
		origin = getOrigin();
		role = new HW_RoleValidator().getPriorisierungshilfeRole();
		setIsClosed( filterCriteriaByName );
		setMonths( filterCriteriaByName );
		setRecordId( filterCriteriaByName );
		setSObjectType( filterCriteriaByName );
		setVersion( filterCriteriaByName );
		setSortBy( filterCriteriaByName );
		setSortDirection( filterCriteriaByName );
		setAufgabenstatusValue( filterCriteriaByName );
		setIsScheduled( filterCriteriaByName );
		setIsTerminNotTerminiert( filterCriteriaByName );
		setTerminZum( filterCriteriaByName );
		setIsFiliale( filterCriteriaByName );
		setVertriebsmanager();
		setNlbrief( filterCriteriaByName );
		setZeige( filterCriteriaByName );
	}
	
	private void setVertriebsmanager () {
		List<User> users = [
				SELECT
						Id,
						OrgE_DP__c,
						AnzeigeDatensaetzePriohilfe__c
				FROM User
				WHERE Id = :UserInfo.getUserId()
				LIMIT 1
		];
		defaultFilter = ( users.size() == 1 ) ? users.get( 0 ).AnzeigeDatensaetzePriohilfe__c : 5;
		if ( role == 'VM' ) {
			vertriebsmanager = ( users.size() == 1 ) ? users.get( 0 ) : null;
		}
	}
	
	private String getOrigin () {
		if ( version == 'mit Akquise' ) {
			return 'Startseite';
		}
		return recordId == null
				? 'Startseite'
				: String.valueOf( recordId.getSobjectType() );
	}
	
	private void setIsClosed ( Map<String, Object> filterCriteriaByName ) {
		if ( filterCriteriaByName.containsKey( 'isClosed' ) ) {
			isClosed = ( Boolean ) filterCriteriaByName.get( 'isClosed' );
		}
	}
	
	private void setMonths ( Map<String, Object> filterCriteriaByName ) {
		if ( filterCriteriaByName.containsKey( 'months' ) ) {
			months = ( Integer ) filterCriteriaByName.get( 'months' );
		}
	}
	
	private void setRecordId ( Map<String, Object> filterCriteriaByName ) {
		if ( filterCriteriaByName.containsKey( 'recordId' ) ) {
			recordId = ( Id ) filterCriteriaByName.get( 'recordId' );
		}
	}
	
	private void setSObjectType ( Map<String, Object> filterCriteriaByName ) {
		if ( filterCriteriaByName.containsKey( 'sObjectType' ) ) {
			sObjectType = String.escapeSingleQuotes( returnEmptyIfNull ( ( String ) filterCriteriaByName.get( 'sObjectType' ) ) );
		}
	}
	
	private void setVersion ( Map<String, Object> filterCriteriaByName ) {
		if ( filterCriteriaByName.containsKey( 'version' ) ) {
			version = String.escapeSingleQuotes( returnEmptyIfNull ( ( String ) filterCriteriaByName.get( 'version' ) ) );
		}
	}
	
	private void setSortBy ( Map<String, Object> filterCriteriaByName ) {
		if ( filterCriteriaByName.containsKey( 'sortBy' ) ) {
			sortBy = String.escapeSingleQuotes( returnEmptyIfNull ( ( String ) filterCriteriaByName.get( 'sortBy' ) ) );
		}
	}
	
	private void setSortDirection ( Map<String, Object> filterCriteriaByName ) {
		if ( filterCriteriaByName.containsKey( 'sortDirection' ) ) {
			sortDirection = String.escapeSingleQuotes ( returnEmptyIfNull ( ( String ) filterCriteriaByName.get( 'sortDirection' ) ) );
		}
	}
	
	private void setAufgabenstatusValue ( Map<String, Object> filterCriteriaByName ) {
		if ( filterCriteriaByName.containsKey( 'aufgabenstatusValue' ) ) {
			aufgabenstatusValue = String.escapeSingleQuotes( returnEmptyIfNull ( ( String ) filterCriteriaByName.get( 'aufgabenstatusValue' ) ) );
		}
	}
	
	private void setIsScheduled ( Map<String, Object> filterCriteriaByName ) {
		if ( filterCriteriaByName.containsKey( 'isScheduled' ) ) {
			isScheduled = ( Boolean ) filterCriteriaByName.get( 'isScheduled' );
		}
	}
	
	private void setIsTerminNotTerminiert ( Map<String, Object> filterCriteriaByName ) {
		if ( filterCriteriaByName.containsKey( 'isTerminNotTerminiert' ) ) {
			isTerminNotTerminiert = ( Boolean ) filterCriteriaByName.get( 'isTerminNotTerminiert' );
		}
	}
	
	private void setTerminZum ( Map<String, Object> filterCriteriaByName ) {
		if ( filterCriteriaByName.containsKey( 'terminZum' ) ) {
			terminZum = filterCriteriaByName.get ( 'terminZum' ) == null
					? null
					: Date.valueOf ( ( String ) filterCriteriaByName.get ( 'terminZum' ) );
		}
	}
	
	private void setIsFiliale ( Map<String, Object> filterCriteriaByName ) {
		if ( filterCriteriaByName.containsKey( 'isFiliale' ) ) {
			isFiliale = ( Boolean ) filterCriteriaByName.get( 'isFiliale' );
		}
	}
	
	private void setNlbrief ( Map<String, Object> filterCriteriaByName ) {
		if ( filterCriteriaByName.containsKey( 'nlBrief' ) ) {
			nlBrief = String.escapeSingleQuotes( returnEmptyIfNull ( ( String ) filterCriteriaByName.get( 'nlBrief' ) ) );
		}
	}
	
	private void setZeige ( Map<String, Object> filterCriteriaByName ) {
		if ( filterCriteriaByName.containsKey( 'zeige' ) ) {
			zeige = String.escapeSingleQuotes( returnEmptyIfNull( ( String ) filterCriteriaByName.get( 'zeige' ) ) );
		}
	}
	
	private String returnEmptyIfNull ( String value ) {
		return value == null ? '' : value;
	}
}