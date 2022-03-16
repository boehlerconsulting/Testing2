/**
 *@author       Mats Böhler
 *@created      23.11.2021
 *
 *
 *@description  RecordType
 *
 *
 *@changelog    23.11.2021 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class RecordTypeState {
	
	public static final String FILIALE = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
			.get( 'Filiale' ).getRecordTypeId();
	public static final String DHL_PAKETSHOP = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
			.get( 'DHL_Paketshop' ).getRecordTypeId();
	public static final String FILIALPARTNER = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
			.get( 'Filialpartner' ).getRecordTypeId();
	public static final String PACKSTATION = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
			.get( 'Packstation' ).getRecordTypeId();
}