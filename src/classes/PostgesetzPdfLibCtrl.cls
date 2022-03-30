/**
 *@author       Mats Böhler
 *@created      24.03.2022
 *
 *
 *@description  PostgesetzPdfLibCtrl
 *
 *
 *@changelog    24.03.2022 Mats Böhler  - Created
 *              
 * 
 */
public with sharing class PostgesetzPdfLibCtrl {
	
	private Id accountId;
	@TestVisible
	private Id recordId;
	private Id contractId;
	private String relateToRecordFieldName;
	
	@AuraEnabled
	public static String initialize ( Id accountId ) {
		PostgesetzPdfLibCtrl instance = new PostgesetzPdfLibCtrl();
		try {
			instance.accountId = accountId;
			instance.loadRecordId();
			return JSON.serialize( instance );
		}
		catch ( Exception e ) {
			throw new AuraHandledException( e.getMessage() );
		}
	}
	
	private void loadRecordId () {
		if ( contractExists() ) {
			recordId = contractId;
			relateToRecordFieldName = 'AccountId';
		}
		else {
			recordId = accountId;
			relateToRecordFieldName = 'Id';
		}
	}
	
	private Boolean contractExists () {
		List<Contract> contracts = [ SELECT Id FROM Contract WHERE AccountId = :accountId LIMIT 1 ];
		Contract contract = ( contracts.size() == 1 ) ? contracts.get( 0 ) : null;
		contractId = contract?.Id;
		return contract != null;
	}
}