/**
 *@author       Mats Böhler
 *@created      17.03.2021
 *
 *
 *@description  LeitregionMapper
 *
 *
 *@changelog    17.03.2021 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class LeitregionMapper {
	
	private Map<String, Id> vertriebskoordinatorIdByLeitregion = new Map<String, Id>();
	
	private static LeitregionMapper instance = null;
	
	public static LeitregionMapper getInstance () {
		if ( instance == null ) {
			instance = new LeitregionMapper();
			instance.loadData();
		}
		return instance;
	}
	
	public String getKoordinatorForPostalCode ( String postalCode ) {
		if ( postalCode == null ) {
			return null;
		}
		String leitregion = postalCode.left( 2 );
		return vertriebskoordinatorIdByLeitregion.containsKey( leitregion )
				? vertriebskoordinatorIdByLeitregion.get( leitregion )
				: null;
	}
	
	private void loadData () {
		for ( OrgE_DP__c orgEDP : [
				SELECT
						Leitregion__c,
						Koordinator__c
				FROM OrgE_DP__c
				WHERE RecordType.DeveloperName = 'NL_Brief'
		] ) {
			
			if ( orgEDP.Leitregion__c != null ) {
				for ( String leitregion : orgEDP.Leitregion__c.split( ',' ) ) {
					
					vertriebskoordinatorIdByLeitregion.put( leitregion, orgEDP.Koordinator__c );
				}
			}
		}
	}
}