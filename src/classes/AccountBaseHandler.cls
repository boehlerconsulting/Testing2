/**
 *@author       Mats Böhler
 *@created      23.11.2021
 *
 *
 *@description  AccountBaseHandler
 *
 *
 *@changelog    23.11.2021 Mats Böhler  - Created
 *              
 * 
 */
public without sharing virtual class AccountBaseHandler extends TriggerHandler {
	
	protected List<Account> newAccounts;
	protected Map<Id, Account> newAccountMap;
	protected Map<Id, Account> oldAccountMap;
	protected Map<Id, Account> accountsWithRelatedInformationById;
	protected AccountHandlerState handlerState;
	protected Map<Id, Filialnetzaenderung__c> filialnetzaenderungByIds = new Map<Id, Filialnetzaenderung__c>();
	protected Map< String, Map< String, Account > > debitorIdField2DebitorId2Account;
	
	public static Set<Id> processedIds = new Set<Id>();
	public static Map< String, String > debitorIdField2LookupField = new Map< String, String > {
			'VertragspartnerId__c' => 'Betreiber__c',
			'ImmobiliengeberId__c' => 'Immobiliengeber__c',
			'Lieferant1Id__c' => 'Lieferant_1__c',
			'Lieferant2Id__c' => 'Lieferant_2__c',
			'FranchisegeberId__c' => 'Franchisegeber__c',
			'Gesellschafter1Id__c' => 'Gesellschafter_1__c',
			'Gesellschafter2Id__c' => 'Gesellschafter_2__c',
			'VermittlerId__c' => 'Vermittler__c'
	};
	
	public AccountBaseHandler () {
		handlerState = AccountHandlerState.getInstance();
		this.newAccounts = ( List<Account> ) Trigger.new;
		this.newAccountMap = ( Map<Id, Account> ) Trigger.newMap;
		this.oldAccountMap = ( Map<Id, Account> ) Trigger.oldMap;
	}
	
	protected void setVertragsbetreuendeEinheit ( Account account ) {
		if ( account.Betreiber__c != null
				&& account.BetreiberVertragsbetreuendeEinheit__c != null
				&& isChanged( account.Id, 'Betreiber__c' ) ) {
			
			account.Vertragsbetreuende_Einheit__c = account.BetreiberVertragsbetreuendeEinheit__c;
		}
		else if ( account.Vertragsbetreuende_Einheit__c == null
				&& account.GL__c != null ) {
			
			account.Vertragsbetreuende_Einheit__c = account.GL__c;
		}
		else {
			//Sonarqube --> do nothing
		}
	}
	
	protected void setKundenrelevanzklasse ( Account account ) {
		if ( ( Trigger.isInsert || account.Kundenrelevanz_Klasse__c == oldAccountMap.get( account.Id ).Kundenrelevanz_Klasse__c )
				&& ( account.Vorgaengerfiliale__c != null
				&& account.Kundenrelevanz_Klasse_Vorgaengerfiliale__c != null
				&& account.Kundenrelevanz_Klasse__c == null ) ) {
			account.Kundenrelevanz_Klasse__c = account.Kundenrelevanz_Klasse_Vorgaengerfiliale__c;
		}
	}
	
	protected void loadAccountsWithRelatedInformation () {
		accountsWithRelatedInformationById = new Map<Id, Account>( [
				SELECT
						Id,
						Vertragsbetreuende_Einheit__r.Koordinator__c,
						GL__r.Koordinator__c,
						Vorgaengerfiliale__c,
						Vorgaengerfiliale__r.EOE_Datum_Partnerjubilaeum__c,
						Vorgaengerfiliale__r.Kundenrelevanz_Klasse__c
				FROM Account
				WHERE Id IN :newAccountMap.keySet()
		] );
	}
	
	protected String returnEmptyIfNull ( String value ) {
		return value == null ? '' : value;
	}
	
	protected void trackVertriebsleitungChanged ( Account account ) {
		if ( ( account.GL__c != oldAccountMap.get( account.Id ).GL__c
				|| account.RecordTypeId != oldAccountMap.get( account.Id ).RecordTypeId )
				&& account.GL__c != null ) {
			
			String newOwnerId = accountsWithRelatedInformationById.get( account.Id ).GL__r.Koordinator__c;
			account.OwnerId = newOwnerId == null ? account.OwnerId : newOwnerId;
		}
	}
	
	protected Boolean wasAlreadyProcessedInAfterUpdateContext ( Id accountId ) {
		return Trigger.isUpdate
				&& processedIds.contains( accountId );
	}
	
	protected void addDebitor ( Account account ) {
		handlerState.accountIdByDebitor.put(
				account.Debitor__c == null
						? '9999999999'
						: account.Debitor__c,
				account.Id );
	}
	
	protected Boolean isPriorValueNull ( Id accountId, String fieldName ) {
		if ( Trigger.isInsert ) {
			return true;
		}
		return Trigger.oldMap.get( accountId ).get( fieldName ) == null;
	}
	
	protected void trackIsDebitorAdded ( Account account ) {
		if ( ( Trigger.isInsert
				&& account.Debitor__c != null )
				|| ( Trigger.isUpdate
				&& account.Debitor__c != null
				&& account.RecordTypeId != oldAccountMap.get( account.Id ).RecordTypeId ) ) {
			
			handlerState.accountIdByDebitor.put( account.Debitor__c, account.Id );
		}
	}
	
	protected void setNewFilialeInFilialnetzaenderung ( Map<String, String> accountIdByDebitor ) {
		if ( accountIdByDebitor.keySet().isEmpty() ) {
			return;
		}
		for ( Filialnetzaenderung__c filialnetzaenderung : [
				SELECT
						Id,
						Zu_erwartender_Debitor__c
				FROM Filialnetzaenderung__c
				WHERE Erledigungsdatum_FNAE__c = NULL
				AND Zu_erwartender_Debitor__c IN :accountIdByDebitor.keySet()
		] ) {
			Filialnetzaenderung__c existingFilialnetzaenderung =
					filialnetzaenderungByIds.containsKey( filialnetzaenderung.Id )
							? filialnetzaenderungByIds.get( filialnetzaenderung.Id )
							: filialnetzaenderung;
			existingFilialnetzaenderung.Neue_Filiale_neuer_Filialpartner__c =
					accountIdByDebitor.containsKey( existingFilialnetzaenderung.Zu_erwartender_Debitor__c )
							? accountIdByDebitor.get( existingFilialnetzaenderung.Zu_erwartender_Debitor__c )
							: null;
			filialnetzaenderungByIds.put( existingFilialnetzaenderung.Id, existingFilialnetzaenderung );
		}
	}
	
	protected void upsertFilialnetzaenderungen () {
		if ( !filialnetzaenderungByIds.values().isEmpty()
				&& !System.isQueueable()
				&& !System.isFuture()
				&& !System.isBatch()
				&& isEnqueueable()
				&& TriggerService.processAsynchronously( 'Post_AccountTrigger' ) ) {
			
			System.enqueueJob(
					new FilialnetzaenderungUpsertQueueable(
							'FilialnetzänderungUpsert',
							filialnetzaenderungByIds.values()
					)
			);
		}
		else {
			upsert filialnetzaenderungByIds.values();
		}
	}
	
	protected Boolean isSchliessungRemoved ( Account account ) {
		return Trigger.isUpdate
				&& account.Schliessung_zum__c == null
				&& isChanged( account.Id, 'Schliessung_zum__c' );
	}
	
	protected Boolean isSchliessungEqualEroeffnung ( Account account ) {
		return Trigger.isUpdate
				&& account.Schliessung_zum__c != null
				&& account.Schliessung_zum__c == account.Eroeffnungsdatum__c
				&& ( isChanged( account.Id, 'Schliessung_zum__c' )
				|| isChanged( account.Id, 'Eroeffnungsdatum__c' ) );
	}
	
	protected Boolean isSchliessungBiggerEroeffnung ( Account account ) {
		return Trigger.isUpdate
				&& account.Schliessung_zum__c != null
				&& account.Schliessung_zum__c > account.Eroeffnungsdatum__c
				&& ( isChanged( account.Id, 'Schliessung_zum__c' )
				|| isChanged( account.Id, 'Eroeffnungsdatum__c' ) );
	}
	
	protected Boolean isVertragsbetreuendeEinheitChanged ( Account account ) {
		return Trigger.isUpdate
				&& account.Vertragsbetreuende_Einheit__c != null
				&& isChanged( account.Id, 'Vertragsbetreuende_Einheit__c' );
	}
	
	protected Boolean isFilialinhaberwechsel ( Account account ) {
		return Trigger.isUpdate
				&& isChanged( account.Id, 'OwnerId' );
	}
	
	protected Boolean isSchliessungChanged ( Account account ) {
		return Trigger.isUpdate
				&& account.Schliessung_zum__c != null
				&& oldAccountMap.get( account.Id ).Schliessung_zum__c != null
				&& account.Schliessung_zum__c != oldAccountMap.get( account.Id ).Schliessung_zum__c;
	}
	
	protected Boolean isEroeffnungChanged ( Account account ) {
		return Trigger.isUpdate
				&& account.Eroeffnungsdatum__c != null
				&& oldAccountMap.get( account.Id ).Eroeffnungsdatum__c != null
				&& account.Eroeffnungsdatum__c != oldAccountMap.get( account.Id ).Eroeffnungsdatum__c;
	}
	
	protected void resetTasks ( Set<Id> accountIdsSchliessungRemovedChanged ) {
		if ( accountIdsSchliessungRemovedChanged.isEmpty() ) {
			return;
		}
		TaskWorker uow = TaskWorker.getInstance();
		for ( Task task : [
				SELECT
						Id,
						AccountId,
						ActivityDate,
						Erledigung_bis_zum__c,
						Auftragnehmer__c,
						Aufgabenart__c,
						WhatId
				FROM Task
				WHERE AccountId IN :accountIdsSchliessungRemovedChanged
				AND Erledigung_bis_zum__c > TODAY
				AND Erledigungsvermerk__c LIKE '%nach Schließung fällig%'
				AND Status = 'Zurückgezogen (Nur AG)'
		] ) {
			Task existingTask = uow.exists( task ) ? uow.get( task ) : task;
			existingTask.Erledigt_am__c = null;
			existingTask.Erledigungsvermerk__c = null;
			existingTask.Status = 'Nicht begonnen';
			uow.add( existingTask );
		}
		for ( Task task : [
				SELECT
						Id
				FROM Task
				WHERE AccountId IN :accountIdsSchliessungRemovedChanged
				AND IsClosed = FALSE
				AND (
						Kommentar_Kopie__c LIKE '%Schließungsdatum:%'
						OR Zieltermin__c != NULL
						OR Aufgabenart__c = 'Besicherungswerte zu Akquiseauftrag Filiale ermitteln' )
		] ) {
			Task existingTask = uow.exists( task ) ? uow.get( task ) : task;
			existingTask.Erledigungsvermerk__c = 'Filiale bleibt am Netz';
			existingTask.Status = 'Zurückgezogen (Nur AG)';
			uow.add( existingTask );
		}
		resetFilialnetzaenderungs( accountIdsSchliessungRemovedChanged );
	}
	
	protected void moveTasksExcludingAkquisen ( Set<Id> accountIdsSchliessungBiggerEroeffnungChanged ) {
		if ( accountIdsSchliessungBiggerEroeffnungChanged.isEmpty() ) {
			return;
		}
		TaskWorker uow = TaskWorker.getInstance();
		for ( Task task : [
				SELECT
						Id,
						AccountId,
						ActivityDate,
						Erledigung_bis_zum__c,
						Auftragnehmer__c,
						Aufgabenart__c,
						WhatId
				FROM Task
				WHERE AccountId IN :accountIdsSchliessungBiggerEroeffnungChanged
				AND IsClosed = FALSE
				AND RecordType.DeveloperName != 'Akquiseauftrag'
		] ) {
			Task existingTask = uow.exists( task ) ? uow.get( task ) : task;
			if ( existingTask.ActivityDate >= newAccountMap.get( existingTask.AccountId ).Schliessung_zum__c
					|| existingTask.Auftragnehmer__c == '5640 Team PoPS' ) {
				
				existingTask.Erledigungsvermerk__c = '"Die Aufgabe ist erst nach Schließung fällig bzw. die Filiale wird nicht eröffnet."';
				existingTask.Status = 'Zurückgezogen (Nur AG)';
				uow.add( existingTask );
			}
		}
	}
	
	protected void moveAllTasks ( Set<Id> accountIdsSchliessungEqualsEroeffnungChanged ) {
		if ( accountIdsSchliessungEqualsEroeffnungChanged.isEmpty() ) {
			return;
		}
		TaskWorker uow = TaskWorker.getInstance();
		Date startDate = Date.newInstance( 2016, 1, 1 );
		for ( Task task : [
				SELECT
						Id,
						AccountId,
						ActivityDate,
						Erledigung_bis_zum__c,
						Auftragnehmer__c,
						Aufgabenart__c,
						WhatId
				FROM Task
				WHERE AccountId IN :accountIdsSchliessungEqualsEroeffnungChanged
				AND IsClosed = FALSE
				AND ActivityDate > :startDate
				AND RecordType.DeveloperName != 'Akquiseauftrag'
		] ) {
			Task existingTask = uow.exists( task ) ? uow.get( task ) : task;
			existingTask.Erledigungsvermerk__c = '"Die Aufgabe ist erst nach Schließung fällig bzw. die Filiale wird nicht eröffnet."';
			existingTask.Status = 'Zurückgezogen (Nur AG)';
			uow.add( existingTask );
		}
	}
	
	protected void setNewVertragsbetreuendeEinheitForVertragspartner ( Set<Id> accountIdsVertragsbetreuendeEinheitChanged ) {
		if ( accountIdsVertragsbetreuendeEinheitChanged.isEmpty() ) {
			return;
		}
		List<Account> accounts = new List<Account>();
		for ( Account account : [
				SELECT
						Id,
						Betreiber__c
				FROM Account
				WHERE Betreiber__c IN :accountIdsVertragsbetreuendeEinheitChanged
		] ) {
			
			account.Vertragsbetreuende_Einheit__c = newAccountMap.get( account.Betreiber__c ).Vertragsbetreuende_Einheit__c;
			accounts.add( account );
		}
		TriggerHandler.bypass( 'AccountTriggerHandler' );
		update accounts;
		TriggerHandler.clearBypass( 'AccountTriggerHandler' );
	}
	
	protected void setNewOwnerForContactsAndTasks ( Set<Id> accountIdsOwnerChanged ) {
		if ( accountIdsOwnerChanged.isEmpty() ) {
			return;
		}
		TaskWorker uow = TaskWorker.getInstance();
		for ( Task task : [
				SELECT
						Id,
						AccountId,
						ActivityDate,
						Erledigung_bis_zum__c,
						Auftragnehmer__c,
						Aufgabenart__c,
						WhatId
				FROM Task
				WHERE AccountId IN :accountIdsOwnerChanged
				AND Auftragnehmer__c = 'Vertriebsmanager'
				AND Status = 'Nicht begonnen'
		] ) {
			Task existingTask = uow.exists( task ) ? uow.get( task ) : task;
			existingTask.OwnerId = newAccountMap.get( existingTask.AccountId ).OwnerId;
			uow.add( existingTask );
		}
		List<Contact> contacts = new List<Contact>();
		for ( Contact contact : [
				SELECT
						Id,
						Filiale_Partnermitarbeiter__c
				FROM Contact
				WHERE Filiale_Partnermitarbeiter__c IN :accountIdsOwnerChanged
		] ) {
			contact.OwnerId = newAccountMap.get( contact.Filiale_Partnermitarbeiter__c ).OwnerId;
			contacts.add( contact );
		}
		update contacts;
	}
	
	protected void processAfter () {
		executeFilialService();
		new AccountMoverService()
				.execute( AccountMoverService.Type.EROEFFNUNG )
				.setAccountIds( handlerState.accountIdsEroeffnungChanged )
				.moveTasks();
		new AccountMoverService()
				.execute( AccountMoverService.Type.SCHLIESSUNG )
				.setAccountIds( handlerState.accountIdsSchliessungChanged )
				.moveTasks();
		setNewOwnerForContactsAndTasks( handlerState.accountIdsOwnerChanged );
		moveTasksExcludingAkquisen( handlerState.accountIdsSchliessungBiggerEroeffnungChanged );
		moveAllTasks( handlerState.accountIdsSchliessungEqualsEroeffnungChanged );
		resetTasks( handlerState.accountIdsSchliessungRemovedChanged );
		TaskWorker uow = TaskWorker.getInstance();
		uow.process( TriggerService.processAsynchronously( 'Post_AccountTrigger' ) );
		setNewFilialeInFilialnetzaenderung( handlerState.accountIdByDebitor );
		upsertFilialnetzaenderungen();
		EmailSettingService.getInstance().sendBulk();
	}
	
	private void executeFilialService () {
		FilialService.getInstance()
				.loadAccounts( handlerState.createdFilialenIds )
				.setProcess( 'Neuanlage' )
				.createTasksFor( 'Neue Partner-Filiale (exkl. DPS)', handlerState.newPartnerFilialeExcludingDPSIds )
				.createTasksFor( 'DPS Filiale', handlerState.newPartnerFilialeDPSIds )
				.createTasksFor( 'DHL Paketshop (toom)', handlerState.dhlPaketshopTOOMIds )
				.createTasksFor( 'DHL Paketshop (REWE)', handlerState.dhlPaketshopREWEIds )
				.createTasksFor( 'DHL Paketshop', handlerState.dhlPaketshopIds )
				.createTasksFor( '95 -> 79,76 Formatänderung', handlerState.conversion95To79Or76Ids )
				.createTasksFor( '79/76 -> 95 Formatänderung', handlerState.conversion79Or76To95Ids )
				.createTasksFor( '95 -> 84 Formatänderung', handlerState.conversion95To84Ids )
				.createTasksFor( '84 -> 95 Formatänderung', handlerState.conversion84To95Ids )
				.createTasksFor( '84 -> 79/76 Formatänderung', handlerState.conversion84To79Or76Ids )
				.createTasksFor( '79/76 -> 84 Formatänderung', handlerState.conversion79Or76To84Ids )
				.createTasksFor( 'OZ 95', handlerState.oz95Ids )
				.createTasksFor( 'OZ 76', handlerState.oz76Ids )
				.createTasksForNewDPSFiliale( handlerState.accountIdsEroeffnungDPS )
				.createTasksForWerbemedienFACTS( handlerState.accountIdsWerbemedienFACTS )
				.createTasksForAreYouHappyCall( handlerState.accountIdsAreYouHappyCall )
				.loadAccounts( handlerState.terminatedFilialenIds )
				.setProcess( 'Schliessung' )
				.createTasksFor( 'Nur Filialen (exkl. DPS)', handlerState.terminatedFilalenIdsExcludingDPS )
				.createTasksFor( 'DPS Filiale auf angemieteter Fläche SD>EÖ', handlerState.terminatedDPSInterimFilialenIds )
				.createTasksFor( 'DPS Filiale Klassik', handlerState.terminatedFilialenClassicIds )
				.createTasksFor( 'Filiale OZ 95 oder DPS 79', handlerState.terminatedOZ95OrDPS79Ids )
				.createTasksFor( 'DPS Filiale auf angemieteter Fläche SD=EÖ', handlerState.terminatedDPSInterimFilialenIdsSameDate )
				.createTasksFor( 'Verschiebung Schließdatum DPS', handlerState.terminatedDPSInterimFilialenIdsChangedDate )
				.loadAccounts( handlerState.laufendeFilialenIds )
				.setProcess( 'LaufenderBetrieb' )
				.createTasksFor( 'DHL Paketshop ohne PoPS eröffnet', handlerState.accountIdsLaufenderBetriebNoPops )
				.createTasksFor( 'Partnerjubiläum erreicht', handlerState.accountIdsLaufenderBetriebPartnerjubilaeum )
				.insertTasks();
	}
	
	private void resetFilialnetzaenderungs ( Set<Id> accountIdsSchliessungRemovedChanged ) {
		for ( Filialnetzaenderung__c filialnetzaenderung : [
				SELECT
						Id,
						Zu_erwartender_Debitor__c
				FROM Filialnetzaenderung__c
				WHERE Filiale_Filialpartner__c IN :accountIdsSchliessungRemovedChanged
				AND Erledigungsdatum_FNAE__c = NULL
		] ) {
			Filialnetzaenderung__c existingFilialnetzaenderung =
					filialnetzaenderungByIds.containsKey( filialnetzaenderung.Id )
							? filialnetzaenderungByIds.get( filialnetzaenderung.Id )
							: filialnetzaenderung;
			existingFilialnetzaenderung.Erledigungsdatum_FNAE__c = Date.today();
			existingFilialnetzaenderung.Erledigungsvermerk__c = 'Filiale bleibt am Netz';
			filialnetzaenderungByIds.put( existingFilialnetzaenderung.Id, existingFilialnetzaenderung );
		}
	}
	
	private Boolean isEnqueueable () {
		return Limits.getLimitQueueableJobs() - Limits.getQueueableJobs() > 0;
	}
	
	protected void setLookups ( Account account ) {
		for ( String debitorIdField : debitorIdField2LookupField.keySet() ) {
			String lookupField = debitorIdField2LookupField.get( debitorIdField );
			Map< String, Account > debitorId2Account = debitorIdField2DebitorId2Account.get( debitorIdField );
			setLookup( debitorId2Account, debitorIdField, lookupField, account );
		}
	}
	
	private void setLookup ( Map< String, Account > debitorId2Account, String debitorIdField, String lookupField, Account account ) {
		String debitorId = ( String ) account.get( debitorIdField );
		if ( ( debitorId2Account != null ) && debitorId2Account.containsKey( debitorId ) ) {
			Account relatedAccount = debitorId2Account.get( debitorId );
			if ( account.Id != relatedAccount.Id ) {
				account.put( lookupField, relatedAccount.Id );
			}
			else {
				account.put( lookupField, null );
			}
		}
		else {
			account.put( lookupField, null );
		}
	}
	
	protected void loadAccountsByDebitorIds ( ) {
		Map< String, Set< String > > debitorIdField2DebitorIds = new Map< String, Set< String > >();
		for ( Account account : newAccounts ) {
			for ( String debitorIdField : debitorIdField2LookupField.keySet() ) {
				if ( !debitorIdField2DebitorIds.containsKey( debitorIdField ) ) {
					debitorIdField2DebitorIds.put( debitorIdField, new Set< String >() );
				}
				String debitorId = ( String ) account.get( debitorIdField );
				if ( String.isNotBlank( debitorId ) ) {
					Set< String > debitorIds = debitorIdField2DebitorIds.get( debitorIdField );
					debitorIds.add( debitorId );
				}
			}
		}
		Set< String > allDebitorIds = new Set< String >();
		for ( Set< String > debitorIds : debitorIdField2DebitorIds.values() ) {
			allDebitorIds.addAll( debitorIds );
		}
		populateMap(allDebitorIds, debitorIdField2DebitorIds);
	}
	
	private void populateMap ( Set<String> allDebitorIds, Map<String, Set<String>> debitorIdField2DebitorIds ) {
		debitorIdField2DebitorId2Account = new Map< String, Map< String, Account > >();
		for ( Account account : [
				SELECT
						Id,
						Debitor__c
				FROM Account
				WHERE Debitor__c IN :allDebitorIds
				ORDER BY Eroeffnungsdatum__c ASC
		] ) {
			for ( String debitorIdField : debitorIdField2DebitorIds.keySet() ) {
				Set< String > debitorIds = debitorIdField2DebitorIds.get( debitorIdField );
				if ( debitorIds.contains( account.Debitor__c ) ) {
					if ( !debitorIdField2DebitorId2Account.containsKey( debitorIdField ) ) {
						debitorIdField2DebitorId2Account.put( debitorIdField, new Map< String, Account >() );
					}
					debitorIdField2DebitorId2Account.get( debitorIdField ).put( account.Debitor__c, account );
				}
			}
		}
	}
}