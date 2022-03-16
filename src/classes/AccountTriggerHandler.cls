/**
* @author           Oliver Preuschl
*                   H&W Consult GmbH
*                   Bahnhofstr. 3
*                   21244 Buchholz i.d.N.
*                   http://www.hundw.com
*
* @description      Account Trigger Handler
*
* date              24.03.2016
*
* Timeline:
* Name              DateTime                Version        Description
* Oliver Preuschl   24.03.2016              *1.0*          Created
* Mats Böhler       06.04.2020              *1.1*          MYPM-88
*/

public without sharing class AccountTriggerHandler extends AccountBaseHandler {
	
	private List<Account> filialen = new List<Account>();
	private List<Account> filialpartners = new List<Account>();
	private List<Account> paketshops = new List<Account>();
	private List<Account> packstations = new List<Account>();
	
	public AccountTriggerHandler () {
		handlerState.resetSets();
		resetRecordTypeHandlers();
	}
	
	protected override void beforeInsert () {
		processBeforeInsert();
	}
	
	protected override void afterInsert () {
		processAfterInsert();
	}
	
	protected override void beforeUpdate () {
		processBeforeUpdate();
	}
	
	protected override void afterUpdate () {
		processAfterUpdate();
	}
	
	protected override void afterDelete () {
		processAfterDelete();
	}
	
	private void processBeforeInsert () {
		loadAccountsByDebitorIds();
		for ( Account account : newAccounts ) {
			setRecordTypeHandlers( account );
			emptySalutationFields( account );
			setLookups( account );
		}
		executeRecordTypeHandlers();
	}
	
	private void processAfterInsert () {
		for ( Account account : newAccounts ) {
			setRecordTypeHandlers( account );
		}
		executeRecordTypeHandlers();
		processAfter();
	}
	
	private void processBeforeUpdate () {
		loadAccountsWithRelatedInformation();
		loadAccountsByDebitorIds();
		for ( Account account : newAccountMap.values() ) {
			setRecordTypeHandlers( account );
			emptySalutationFields( account );
			setLookups( account );
		}
		executeRecordTypeHandlers();
	}
	
	private void processAfterUpdate () {
		for ( Account account : newAccounts ) {
			if ( wasAlreadyProcessedInAfterUpdateContext( account.Id ) ) {
				continue;
			}
			else if ( Trigger.isUpdate ) {
				processedIds.add( account.Id );
				processedIds.remove( null );
			}
			else {
				//Sonarqube --> do nothing
			}
			setRecordTypeHandlers( account );
		}
		executeRecordTypeHandlers();
		processAfter();
	}
	
	private void processAfterDelete () {
		for ( Account account : oldAccountMap.values() ) {
			setRecordTypeHandlers( account );
		}
		executeRecordTypeHandlers();
	}
	
	private void emptySalutationFields ( Account account ) {
		account.Anrede__c = null;
		account.Geschlecht__c = null;
		account.X1_Ansprechpartner_Anrede__c = null;
		account.X2_Ansprechpartner_Anrede__c = null;
	}
	
	private void setRecordTypeHandlers ( Account account ) {
		if ( account.RecordTypeId == RecordTypeState.FILIALE ) {
			filialen.add( account );
		}
		else if ( account.RecordTypeId == RecordTypeState.FILIALPARTNER ) {
			
			filialpartners.add( account );
		}
		else if ( account.RecordTypeId == RecordTypeState.DHL_PAKETSHOP ) {
			
			paketshops.add( account );
		}
		else if ( account.RecordTypeId == RecordTypeState.PACKSTATION ) {
			
			packstations.add( account );
		}
		else {
			// Sonarqube -> do nothing
		}
	}
	
	private void resetRecordTypeHandlers () {
		filialen = new List<Account>();
		filialpartners = new List<Account>();
		paketshops = new List<Account>();
		packstations = new List<Account>();
	}
	
	private void executeRecordTypeHandlers () {
		new FilialeTriggerHandler( filialen ).run();
		new FilialpartnerTriggerHandler( filialpartners ).run();
		new PaketshopTriggerHandler( paketshops ).run();
		new PackstationTriggerHandler( packstations ).run();
	}
}