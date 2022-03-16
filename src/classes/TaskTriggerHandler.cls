/**
 *@author       Mats Böhler
 *@created      12.09.2019
 *@version      1.0
 *@since        45.0
 *
 *
 *@description  TaskTriggerHandler
 *
 *
 *@changelog    12.09.2019 Mats Böhler  - Created
 *              
 * 
 */

public without sharing class TaskTriggerHandler extends TriggerHandler {
	
	private List<Task> newTasks = null;
	private Map<Id, Task> newTasksMap = null;
	private Map<Id, Task> oldTasksMap = null;
	private Map<Id, Account> accountsById = new Map<Id, Account>();
	private Map<Id, Filialnetzaenderung__c> filialnetzaenderungImmobiliensucheByIds = new Map<Id, Filialnetzaenderung__c>();
	private Map<Id, Lead> leadsById = null;
	private Set<Id> leadIds = new Set<Id>();
	private Map<String, AufgabenStandardbeschreibungen__mdt> standardDescriptionByTaskType
			= new Map<String, AufgabenStandardbeschreibungen__mdt>();
	private List<Task> ekAstVlVkTasks = new List<Task>();
	private List<Task> zentraleEinheitTasks = new List<Task>();
	private List<Task> forderungsmgmtAndBesicherungswerteTasks = new List<Task>();
	private List<Task> dPShopTasks = new List<Task>();
	private Set<String> orgEDPNames = new Set<String>();
	private Map<String, OrgE_DP__c> orgEPDsByName = new Map<String, OrgE_DP__c>();
	private List<Task> followUptasks = new List<Task>();
	private List<Aufgabendetail1__c> aufgabendetail1s = new List<Aufgabendetail1__c>();
	private Map<Id, String> orgedpByUserId = new Map<Id, String>();
	@TestVisible
	private static Set<Id> processedIds = new Set<Id>();
	@TestVisible
	private static Set<Id> processedBeforeUpdateIds = new Set<Id>();
	
	private static final GlobaleEinstellung__mdt globalSetting = [
			SELECT
					PostfachSchwellenwert__c
			FROM GlobaleEinstellung__mdt
			LIMIT 1
	];
	
	private static final User HW_USER = InterfaceUser.getInstance().getUser();
	
	private static final Id AKQUISE_RT = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
			.get( 'Akquiseauftrag' ).getRecordTypeId();
	private static final Id AKQUISEAUFTRAG_PACKSTATION_RT = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
			.get( 'AkquiseauftragPackstation' ).getRecordTypeId();
	
	public TaskTriggerHandler () {
		
		this.newTasks = ( List<Task> ) Trigger.new;
		this.newTasksMap = ( Map<Id, Task> ) Trigger.newMap;
		this.oldTasksMap = ( Map<Id, Task> ) Trigger.oldMap;
	}
	
	public override void beforeInsert () {
		
		processBefore();
	}
	
	public override void afterInsert () {
		
		processAfter();
	}
	
	public override void beforeUpdate () {
		
		processBefore();
	}
	
	public override void afterUpdate () {
		
		processAfter();
	}
	
	public override void afterDelete () {
		
		deleteAufgabendetails();
	}
	
	private void loadAdditionalBeforeData () {
		leadIds = new Set<Id>();
		Set<Id> accountIds = new Set<Id>();
		Set<String> taskTypes = new Set<String>();
		Set<Id> oldOwnerIds = new Set<Id>();
		for ( Task task : newTasks ) {
			if ( task.WhatId != null
					&& task.WhatId.getSobjectType().getDescribe().getName() == 'Account' ) {
				accountIds.add( task.WhatId );
			}
			if ( task.WhoId != null
					&& task.WhoId.getSobjectType().getDescribe().getName() == 'Lead' ) {
				leadIds.add( task.WhoId );
			}
			if ( Trigger.isInsert
					&& task.Aufgabenart__c != 'Kapazitätsabfrage Paketausgabe und -annahme + Detail' ) {
				taskTypes.add( task.Aufgabenart__c );
			}
			if ( Trigger.isUpdate ) {
				oldOwnerIds.add( oldTasksMap.get( task.Id ).OwnerId );
			}
		}
		accountIds.remove( null );
		leadIds.remove( null );
		taskTypes.remove( null );
		loadAccountsById( accountIds );
		loadLeadsById( leadIds );
		loadOrgEDPByUserId( oldOwnerIds );
		loadStandardDescriptions( taskTypes );
	}
	
	private void processBefore () {
		loadAdditionalBeforeData();
		ekAstVlVkTasks = new List<Task>();
		zentraleEinheitTasks = new List<Task>();
		forderungsmgmtAndBesicherungswerteTasks = new List<Task>();
		dPShopTasks = new List<Task>();
		orgEDPNames = new Set<String>();
		TaskDefiner taskDefiner = new TaskDefiner( standardDescriptionByTaskType, accountsById );
		
		for ( Task task : newTasks ) {
			setNLBrief( task );
			copyType( task );
			copyTaskType( task );
			copyAccountValues( task );
			copyKundenrelevanzklasseFromAccount( task );
			taskDefiner.setDescription( task );
			if ( !leadIds.isEmpty() ) {
				setLeadSpecificFields( task );
			}
			setOwner( task );
			copyValuesToAufgabendetail( task );
		}
		update aufgabendetail1s;
		loadOrgEDPsByName( orgEDPNames );
		setOwnerForEkAstVlVkTasks( ekAstVlVkTasks );
		setOwnerForZentraleEinheitTasks( zentraleEinheitTasks );
		setOwnerForForderungsmgmtAndBesicherungswerteTasks( forderungsmgmtAndBesicherungswerteTasks );
		setOwnerForDPShopTasks( dPShopTasks );
		setOldOrgEDP();
	}
	
	private void setOwner ( Task task ) {
		String initialOwnerId = task.OwnerId;
		if ( isAuftragnehmerInhaberLead( task ) ) {
			task.OwnerId = leadsById.get( task.WhoId ).OwnerId;
		}
		else if ( isAuftragnehmerVertriebskoordinator( task ) ) {
			task.OwnerId = leadsById.get( task.WhoId ).VL__r.OwnerId;
		}
		else if ( isAuftragnehmerVertriebsleiter( task ) ) {
			task.OwnerId = leadsById.get( task.WhoId ).Filialnetzaenderung__r.NL_Brief__r.Leiter__c;
		}
		else if ( isArbeitnehmerInhaberLeadNoLeadAssigned( task ) ) {
			task.OwnerId = accountsById.containsKey( task.WhatId )
					? accountsById.get( task.WhatId ).OwnerId
					: null;
		}
		else if ( isFilialeDHLPaketshop( task ) ) {
			task.OwnerId = accountsById.get( task.WhatId ).OwnerId;
		}
		else if ( isVertragsbetreuendeEinheit( task ) ) {
			task.OwnerId = accountsById.get( task.WhatId ).Vertragsbetreuende_Einheit__r.Koordinator__c;
		}
		else if ( isEKAStVLVK( task ) ) {
			ekAstVlVkTasks.add( task );
			orgEDPNames.add( task.NL_Brief__c );
			orgEDPNames.add( substring( accountsById.get( task.WhatId ).Owner.OrgE_DP__c, 8 ) );
		}
		else if ( isZentraleEinheit( task ) ) {
			zentraleEinheitTasks.add( task );
			orgEDPNames.add( task.Auftragnehmer__c );
		}
		else if ( is3600ForderungsmgmtAndBesicherungswerte( task ) ) {
			forderungsmgmtAndBesicherungswerteTasks.add( task );
			orgEDPNames.add( task.Auftragnehmer__c );
		}
		else if ( is3540DPShop( task ) ) {
			dPShopTasks.add( task );
			orgEDPNames.add( task.Auftragnehmer__c );
		}
		else if ( Trigger.isInsert ) {
			setOwnerOnInsert( task, initialOwnerId );
		}
		else {
			//Sonarqube --> do nothing
		}
		setOwnerIfStillNull( task, initialOwnerId );
	}
	
	private void setOwnerOnInsert ( Task task, String initialOwnerId ) {
		task.OwnerId = task.OwnerId == null ? HW_USER.Id : initialOwnerId;
	}
	
	private void setOwnerIfStillNull ( Task task, String initialOwnerId ) {
		task.OwnerId = task.OwnerId == null ? initialOwnerId : task.OwnerId;
	}
	
	private void loadAdditionalAfterData () {
		Set<Id> accountIds = new Set<Id>();
		Set<Id> fnaeIds = new Set<Id>();
		
		for ( Task task : newTasks ) {
			if ( task.WhatId != null
					&& task.WhatId.getSobjectType().getDescribe().getName() == 'Account' ) {
				accountIds.add( task.WhatId );
			}
			if ( task.Aufgabenart__c == 'DP Shop Immobiliensuche' ) {
				
				fnaeIds.add( task.Filialnetzaenderung__c );
			}
		}
		fnaeIds.remove( null );
		accountIds.remove( null );
		loadAccountsById( accountIds );
		loadFilialnetzaenderungById( fnaeIds );
	}
	
	private void processAfter () {
		loadAdditionalAfterData();
		TaskMaker taskMaker = new TaskMaker();
		for ( Task task : newTasks ) {
			if ( processedIds.contains( task.Id ) ) {
				continue;
			}
			else if ( Trigger.isUpdate ) {
				processedIds.add( task.Id );
			}
			else {
				//Sonarqube --> do nothing
			}
			if ( Trigger.isInsert
					&& isErmittlungPostfachsendungsmenge( task ) ) {
				
				addErmittlungPostfachsendungsmengeTask( task );
			}
			if ( Trigger.isUpdate
					&& isErmittlungPostfachsendungsmenge( task )
					&& !isErmittlungPostfachsendungsmenge( oldTasksMap.get( task.Id ) ) ) {
				
				addErmittlungPostfachsendungsmengeTask( task );
			}
			addFollowUpTasks( task );
			taskMaker.copyValuesToFNAE( task );
			addEmailKuendigungsrueckgewinnung( task );
			addEmailAenderungZielFachanzahlAkquise(task);
		}
		insert followUptasks;
		taskMaker.updateFnaes();
		sendEmails();
	}
	
	private void addEmailAenderungZielFachanzahlAkquise ( Task task ) {
		if ( Trigger.isUpdate
				&& task.ZielFachanzahl__c != oldTasksMap.get( task.Id ).ZielFachanzahl__c
				&& task.WhoId != null
				&& task.WhoId.getSobjectType().getDescribe().getName() == 'Lead'
				&& task.RecordTypeId == AKQUISEAUFTRAG_PACKSTATION_RT ) {
			
			addRequest( task, 'AenderungZielFachanzahlAkquise_MYPM_863' );
		}
	}
	
	private void setOldOrgEDP () {
		for ( Task task : newTasks ) {
			if ( processedBeforeUpdateIds.contains( task.Id ) ) {
				continue;
			}
			else if ( Trigger.isUpdate ) {
				processedBeforeUpdateIds.add( task.Id );
			}
			else {
				//Sonarqube --> do nothing
			}
			if ( Trigger.isUpdate
					&& task.OwnerId != oldTasksMap.get( task.Id ).OwnerId ) {
				task.OrgE_alter_Inhaber__c = orgedpByUserId.get( oldTasksMap.get( task.Id ).OwnerId );
			}
			if ( String.isBlank( task.OrgE_alter_Inhaber__c ) ) {
				task.OrgE_alter_Inhaber__c = orgedpByUserId.get( UserInfo.getUserId() );
			}
		}
	}
	
	private Boolean isErmittlungPostfachsendungsmenge ( Task task ) {
		return accountsById.containsKey( task.WhatId )
				&& task.RecordTypeId == AKQUISE_RT
				&& ( returnEmptyIfNull( task.Aufgabenart__c ).startsWith( 'Akquiseauftrag' )
				|| returnEmptyIfNull( task.Aufgabenart__c ).startsWith( 'Integration Postfachanlage' ) )
				&& returnEmptyIfNull( task.Auftrag_zur_PfA_Akquisition__c ).startsWith( 'mit' )
				&& accountsById.get( task.WhatId ).Postfach_Betreiber__c == 'Partner'
				&& accountsById.get( task.WhatId ).Abrechnung__r.size() == 1
				&& accountsById.get( task.WhatId ).Abrechnung__r[ 0 ].Postfach__c > globalSetting.PostfachSchwellenwert__c;
	}
	
	private void addErmittlungPostfachsendungsmengeTask ( Task task ) {
		followUptasks.add(
				new Task(
						ActivityDate = Date.today(),
						Aufgabenart__c = 'Ermittlung Postfachsendungsmengen + Detail',
						Auftraggeber__c = '3500 Betriebssteuerung',
						Auftragnehmer__c = 'Vertriebsmanager',
						Description = 'Die Zählung der Postfachsendungsmengen bezieht sich auf folgenden ' +
								'Akquiseauftrag mit PfA: https://mypm.lightning.force.com/' + task.Id,
						Erledigung_bis_zum__c = Date.today().addDays( 60 ) > task.Erledigung_bis_zum__c.addDays( -14 )
								? task.Erledigung_bis_zum__c.addDays( -14 ) < Date.today()
										? Date.today()
										: task.Erledigung_bis_zum__c.addDays( -14 )
								: Date.today().addDays( 60 ),
						Filialnetzaenderung__c = task.Filialnetzaenderung__c,
						FNAE_Id__c = task.FNAE_Id__c,
						Priority = 'Hoch',
						RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
								.get( 'Aufgaben_zu_FNAE' ).getRecordTypeId(),
						Status = 'Nich begonnen',
						Typc__c = 'Besuch',
						Type = 'Beusch',
						WhatId = task.WhatId
				)
		);
	}
	
	private void copyType ( Task task ) {
		if ( Trigger.isInsert && task.Typc__c != null ) {
			task.TypInitial__c = task.Typc__c;
			task.Type = task.Typc__c;
		}
	}
	
	private void copyTaskType ( Task task ) {
		
		if ( Trigger.isInsert
				&& task.Aufgabenart__c != null
				&& task.Subject == 'Aufgabe' ) {
			
			task.Subject = task.Aufgabenart__c;
		}
	}
	
	private void copyAccountValues ( Task task ) {
		if ( Trigger.isInsert
				&& task.WhatId != null
				&& task.WhatId.getSobjectType().getDescribe().getName() == 'Account'
				&& accountsById.containsKey( task.WhatId ) ) {
			
			Account account = accountsById.get( task.WhatId );
			task.ASt_Nummer__c = account.ASt_Nummer__c;
			task.Ast_Id__c = account.ASt_ID__c;
			task.Ast_Name__c = account.ASt_Name__c;
			task.Debitor__c = account.Debitor__c;
			task.Filialart_OZ__c = account.Filialart__c + '/' + account.Filialtyp_OZ__c;
			task.Strasse_Filialanschrift__c = account.ShippingStreet;
			task.Telefon__c = account.Phone;
			task.VG__c = account.GL_Name__c;
			task.Vertriebssegment_Filiale__c = account.Vertriebssegment__c;
		}
	}
	
	private void copyKundenrelevanzklasseFromAccount ( Task task ) {
		if ( task.WhatId != null
				&& task.WhatId.getSobjectType().getDescribe().getName() == 'Account'
				&& accountsById.containsKey( task.WhatId ) ) {
			
			Account account = accountsById.get( task.WhatId );
			task.Kundenrelevanz_Klasse__c = account.Kundenrelevanz_Klasse__c;
		}
	}
	
	private void setOwnerForEkAstVlVkTasks ( List<Task> ekAstVlVkTasks ) {
		for ( Task task : ekAstVlVkTasks ) {
			OrgE_DP__c orgEDP = getOrgEDP( task );
			if ( task.Auftragnehmer__c == '3920/30 Aussenstelle' ) {
				task.OwnerId = getOwner( orgEDP, 'Aussenstellen_Ma__c' );
			}
			if ( task.Auftragnehmer__c == 'Vertriebskoordinator VL' || task.Auftragnehmer__c == 'Vertriebskoordinator VGL' ) {
				task.OwnerId = getOwner( orgEDP, 'Koordinator__c' );
			}
			if ( task.Auftragnehmer__c == 'Vertriebsleiter' ) {
				task.OwnerId = getOwner( orgEDP, 'Leiter__c' );
			}
			task.OwnerId = getOwner( task, 'OwnerId' );
		}
	}
	
	private Id getOwner ( SObject record, String fieldName ) {
		return record == null || record.get( fieldName ) == null ? HW_USER.Id : ( Id ) record.get( fieldName );
	}
	
	private OrgE_DP__c getOrgEDP ( Task task ) {
		OrgE_DP__c orgEDP = new OrgE_DP__c();
		if ( task.NL_Brief__c != null && task.NL_Brief__c != 'n.a.' ) {
			
			orgEDP = orgEPDsByName.containsKey( task.NL_Brief__c )
					? orgEPDsByName.get( task.NL_Brief__c )
					: null;
		}
		else {
			orgEDP = orgEPDsByName.containsKey( substring( accountsById.get( task.WhatId ).Owner.OrgE_DP__c, 8 ) )
					? orgEPDsByName.get( substring( accountsById.get( task.WhatId ).Owner.OrgE_DP__c, 8 ) )
					: null;
		}
		return orgEDP;
	}
	
	private void setOwnerForZentraleEinheitTasks ( List<Task> zentraleEinheitTasks ) {
		for ( Task task : zentraleEinheitTasks ) {
			String originalOwnerId = task.OwnerId;
			OrgE_DP__c orgEDP = orgEPDsByName.containsKey( task.Auftragnehmer__c )
					? orgEPDsByName.get( task.Auftragnehmer__c )
					: null;
			if ( task.Auftragnehmer__c == '3330/40 Aussenstelle' ) {
				task.OwnerId = HW_USER.Id;
			}
			else {
				task.OwnerId = orgEDP == null || orgEDP.Koordinator__c == null ? HW_USER.Id : orgEDP.Koordinator__c;
			}
			task.OwnerId = task.OwnerId == null ? originalOwnerId : task.OwnerId;
		}
	}
	
	private void setOwnerForForderungsmgmtAndBesicherungswerteTasks ( List<Task> forderungsmgmtAndBesicherungswerteTasks ) {
		for ( Task task : forderungsmgmtAndBesicherungswerteTasks ) {
			String originalOwnerId = task.OwnerId;
			OrgE_DP__c orgEDP = orgEPDsByName.containsKey( task.Auftragnehmer__c )
					? orgEPDsByName.get( task.Auftragnehmer__c )
					: null;
			task.OwnerId = orgEDP == null || orgEDP.Koordinator__c == null ? HW_USER.Id : orgEDP.Koordinator__c;
			task.OwnerId = task.OwnerId == null ? originalOwnerId : task.OwnerId;
		}
	}
	
	private void setOwnerForDPShopTasks ( List<Task> dPShopTasks ) {
		for ( Task task : dPShopTasks ) {
			String originalOwnerId = task.OwnerId;
			OrgE_DP__c orgEDP = orgEPDsByName.containsKey( task.Auftragnehmer__c )
					? orgEPDsByName.get( task.Auftragnehmer__c )
					: null;
			task.OwnerId = orgEDP == null || orgEDP.Koordinator__c == null ? HW_USER.Id : orgEDP.Koordinator__c;
			task.OwnerId = task.OwnerId == null ? originalOwnerId : task.OwnerId;
		}
	}
	
	private void loadOrgEDPsByName ( Set<String> orgEDPNames ) {
		if ( orgEDPNames.isEmpty() ) {
			return;
		}
		orgEDPNames.remove( null );
		for ( OrgE_DP__c orgEDP : [
				SELECT
						Id,
						OrgE_DP_Name__c,
						MA_ASt_PuDS__c,
						Aussenstellen_Ma__c,
						Koordinator__c,
						Leiter__c
				FROM OrgE_DP__c
				WHERE OrgE_DP_Name__c IN :orgEDPNames
		] ) {
			
			orgEPDsByName.put( orgEDP.OrgE_DP_Name__c, orgEDP );
		}
	}
	
	private Boolean isAuftragnehmerInhaberLead ( Task task ) {
		
		if ( task.WhoId == null
				|| task.WhoId.getSobjectType().getDescribe().getName() != 'Lead' ) {
			return false;
		}
		
		return task.Auftragnehmer__c == 'Inhaber des Leads'
				&& TaskEvaluator.isChanged( task, 'Auftragnehmer__c' );
	}
	
	private Boolean isAuftragnehmerVertriebskoordinator ( Task task ) {
		
		if ( task.WhoId == null
				|| task.WhoId.getSobjectType().getDescribe().getName() != 'Lead' ) {
			return false;
		}
		
		return task.Auftragnehmer__c == 'Vertriebskoordinator VGL'
				&& TaskEvaluator.isChanged( task, 'Auftragnehmer__c' );
	}
	
	private Boolean isAuftragnehmerVertriebsleiter ( Task task ) {
		
		if ( task.WhoId == null
				|| task.WhoId.getSobjectType().getDescribe().getName() != 'Lead' ) {
			return false;
		}
		
		return task.Auftragnehmer__c == 'Vertriebsleiter'
				&& TaskEvaluator.isChanged( task, 'Auftragnehmer__c' );
	}
	
	private Boolean isArbeitnehmerInhaberLeadNoLeadAssigned ( Task task ) {
		
		if ( task.WhoId == null
				|| task.WhoId.getSobjectType().getDescribe().getName() != 'Lead' ) {
			
			return task.Auftragnehmer__c == 'Inhaber des Leads'
					&& TaskEvaluator.isChanged( task, 'Auftragnehmer__c' );
		}
		return false;
	}
	
	private Boolean isFilialeDHLPaketshop ( Task task ) {
		if ( task.WhatId == null
				|| task.WhatId.getSobjectType().getDescribe().getName() != 'Account' ) {
			return false;
		}
		return task.Auftragnehmer__c == 'Vertriebsmanager'
				&& TaskEvaluator.isChanged( task, 'Auftragnehmer__c' )
				&& accountsById.get( task.WhatId ).Owner.IsActive;
	}
	
	private Boolean isVertragsbetreuendeEinheit ( Task task ) {
		if ( task.WhatId == null
				|| task.WhatId.getSobjectType().getDescribe().getName() != 'Account' ) {
			return false;
		}
		return task.Auftragnehmer__c == 'Vertragsbetreuende Einheit'
				&& TaskEvaluator.isChanged( task, 'Auftragnehmer__c' )
				&& accountsById.get( task.WhatId ).Vertragsbetreuende_Einheit__c != null
				&& accountsById.get( task.WhatId ).Vertragsbetreuende_Einheit__r.Koordinator__c != null
				&& accountsById.get( task.WhatId ).Vertragsbetreuende_Einheit__r.Koordinator__r.IsActive;
	}
	
	private Boolean isEKAStVLVK ( Task task ) {
		if ( ( task.WhatId == null
				|| task.WhatId.getSobjectType().getDescribe().getName() != 'Account' )
				|| task.Aufgabenart__c == 'Akquiseauftrag Packstation zu FNÄ' ) {
			return false;
		}
		return ( task.Auftragnehmer__c == '3920/30 Aussenstelle'
				|| task.Auftragnehmer__c == 'Vertriebsleiter'
				|| task.Auftragnehmer__c == 'Vertriebskoordinator VGL'
				|| task.Auftragnehmer__c == 'Vertriebskoordinator VL'
				|| task.Auftragnehmer__c == 'Vertriebskoordinator' )
				&& ( TaskEvaluator.isChanged( task, 'Auftragnehmer__c' ) || TaskEvaluator.isChanged( task, 'NL_Brief__c' ) )
				&& task.Auftragnehmer__c != null;
	}
	
	private Boolean isZentraleEinheit ( Task task ) {
		return (
				( task.Auftragnehmer__c == '3600 Forderungsmgmt Partner'
						&& task.Aufgabenart__c != 'Besicherungswerte zu Akquiseauftrag Filiale ermitteln' )
						|| task.Auftragnehmer__c == 'Support Center Filialen'
						|| task.Auftragnehmer__c == '3110 Warenwirtschaft'
						|| task.Auftragnehmer__c == '3210 Kassenwesen'
						|| task.Auftragnehmer__c == '3500 Betriebssteuerung'
						|| task.Auftragnehmer__c == '3510 Reporting Partner'
						|| task.Auftragnehmer__c == '3540 DP Shop'
						|| task.Auftragnehmer__c == '4200 ZG Geldwäscheprävention'
						|| task.Auftragnehmer__c == '5640 Team PoPS'
						|| task.Auftragnehmer__c == '3900 Netz-Servicemgmt'
						|| task.Auftragnehmer__c == '3220 Sicherheit'
						|| task.Auftragnehmer__c == '3700 Vertragsmgmt'
						|| task.Auftragnehmer__c == '3800 Qualität'
						|| task.Auftragnehmer__c == '3910 Immo/Instandh/Automation'
						|| task.Auftragnehmer__c == '3320 Immo/Instandhaltung Automation'
						|| task.Auftragnehmer__c == '5640 Team DHL Paketshop'
						|| task.Auftragnehmer__c == '5640 Team PoPS'
						|| task.Auftragnehmer__c == 'interServ Team DHL Paketshop' )
				&& TaskEvaluator.isChanged( task, 'Auftragnehmer__c' )
				&& ( task.Auftraggeber__c != task.Auftragnehmer__c
				|| (
				task.Auftraggeber__c == task.Auftragnehmer__c
						&& task.CreatedById == InterfaceUser.getInstance().getId() ) );
	}
	
	private Boolean is3600ForderungsmgmtAndBesicherungswerte ( Task task ) {
		return ( task.Auftragnehmer__c == '3600 Forderungsmgmt Partner'
				&& task.Aufgabenart__c == 'Besicherungswerte zu Akquiseauftrag Filiale ermitteln' )
				&& TaskEvaluator.isChanged( task, 'Auftragnehmer__c' );
	}
	
	private Boolean is3540DPShop ( Task task ) {
		return task.Auftragnehmer__c == '3540 DP Shop'
				&& TaskEvaluator.isChanged( task, 'Auftragnehmer__c' )
				&& (
				task.Auftraggeber__c != task.Auftragnehmer__c
						|| (
						task.Auftraggeber__c == task.Auftragnehmer__c
								&& (
								task.Aufgabenart__c == 'DP Shop Personalsuche im lfd. Betrieb - Mitarbeiter'
										|| task.Aufgabenart__c == 'DP Shop Personalsuche im lfd. Betrieb - Vertreter' ) ) );
	}
	
	private void loadAccountsById ( Set<Id> accountIds ) {
		if ( accountIds.isEmpty() ) {
			return;
		}
		accountsById = new Map<Id, Account>( [
				SELECT
						Id,
						OwnerId,
						Owner.IsActive,
						Owner.OrgE_DP__c,
						Vertragsbetreuende_Einheit__c,
						Vertragsbetreuende_Einheit__r.Koordinator__c,
						Vertragsbetreuende_Einheit__r.Koordinator__r.IsActive,
						NL_Brief__c,
						ASt_Nummer__c,
						ASt_ID__c,
						ASt_Name__c,
						Debitor__c,
						Filialart__c,
						Filialtyp_OZ__c,
						ShippingStreet,
						Phone,
						GL_Name__c,
						Vertriebssegment__c,
						Paketausgabe__c,
						Kapazitaet_Paketannahme__c,
						Kapazitaet_Paketausgabe__c,
						GL__r.OrgE_DP_Name__c,
						NL_Brief_Lookup__r.Name,
						Kundenrelevanz_Klasse__c,
						Postfach_Betreiber__c, (
						SELECT
								Postfach__c
						FROM Abrechnung__r
						ORDER BY SAP_Buchungsdatum__c DESC NULLS LAST
						LIMIT 1
				)
				FROM Account
				WHERE Id IN :accountIds
		] );
	}
	
	private void loadFilialnetzaenderungById ( Set<Id> fnaeIds ) {
		
		if ( fnaeIds.isEmpty() ) {
			return;
		}
		filialnetzaenderungImmobiliensucheByIds = new Map<Id, Filialnetzaenderung__c>( [
				SELECT
						Id,
						Filiale_Filialpartner__r.Filialart__c,
						Grund__c
				FROM Filialnetzaenderung__c
				WHERE Id IN :fnaeIds
		] );
	}
	
	private void loadLeadsById ( Set<Id> leadIds ) {
		if ( leadIds.isEmpty() ) {
			return;
		}
		leadsById = new Map<Id, Lead>( [
				SELECT
						Id,
						OwnerId,
						VL__r.OwnerId,
						NL_Brief__c,
						VL_Name__c,
						Filialnetzaenderung__r.NL_Brief__r.Leiter__c
				FROM Lead
				WHERE Id IN :leadIds
		] );
	}
	
	private void loadOrgEDPByUserId ( Set<Id> oldOwnerIds ) {
		if ( oldOwnerIds.isEmpty() ) {
			return;
		}
		for ( User user : [
				SELECT
						Id,
						OrgE_DP__c
				FROM User
				WHERE Id IN :oldOwnerIds
				OR Id = :UserInfo.getUserId()
		] ) {
			orgedpByUserId.put( user.Id, user.OrgE_DP__c );
		}
	}
	
	private void loadStandardDescriptions ( Set<String> taskTypes ) {
		if ( taskTypes.isEmpty() ) {
			return;
		}
		standardDescriptionByTaskType = new Map<String, AufgabenStandardbeschreibungen__mdt>();
		for ( AufgabenStandardbeschreibungen__mdt standardbeschreibung : [
				SELECT
						Aufgabenart__c,
						Standardbeschreibung__c
				FROM AufgabenStandardbeschreibungen__mdt
				WHERE Aufgabenart__c IN :taskTypes
		] ) {
			
			standardDescriptionByTaskType.put( standardbeschreibung.Aufgabenart__c, standardbeschreibung );
		}
	}
	
	private void addFollowUpTasks ( Task task ) {
		if ( Trigger.isInsert
				&& task.Aufgabenart__c == 'Einbruch/Überfall Filiale'
				&& task.Status != 'Erledigt' ) {
			
			addBegleiteterSIV( task );
			addBeauftragungAndBegleitungInventurTeilinventur( task );
		}
		if ( Trigger.isInsert
				&& task.Aufgabenart__c == 'Akquiseauftrag Filiale + Detail' ) {
			
			addBesicherungswerteErmitteln( task );
		}
		
		if ( task.Aufgabenart__c == 'DP Shop Immobiliensuche'
				&& task.IsClosed
				&& task.Wiedervorlage_am__c != null
				&& TaskEvaluator.isChanged( task, 'IsClosed' ) ) {
			
			Filialnetzaenderung__c filialnetzaenderung = filialnetzaenderungImmobiliensucheByIds.containsKey( task.Filialnetzaenderung__c )
					? filialnetzaenderungImmobiliensucheByIds.get( task.Filialnetzaenderung__c ) : null;
			
			if ( filialnetzaenderung.Filiale_Filialpartner__r.Filialart__c != null
					&& filialnetzaenderung.Filiale_Filialpartner__r.Filialart__c.startsWith( 'DPS' )
					&& filialnetzaenderung.Grund__c == 'Umzug der Filiale' ) {
				
				addBegleitungUmzugUndUebernahmeFiliale( task );
			}
		}
	}
	
	private void addBegleiteterSIV ( Task task ) {
		String filialart = accountsById.containsKey( task.WhatId ) ? accountsById.get( task.WhatId ).Filialart__c : '';
		followUptasks.add(
				new Task(
						ActivityDate = Date.today(),
						Aufgabenart__c = returnEmptyIfNull( filialart ).contains( 'DPS' )
								? 'DP Shop Unvermutete Kassenprüfung + Detail'
								: 'Begleiteter S-I-V + Detail',
						Auftraggeber__c = returnEmptyIfNull( filialart ).contains( 'DPS' )
								? '3540 DP Shop'
								: 'Vertriebsleiter',
						Auftragnehmer__c = 'Vertriebsmanager',
						Description = 'Diese Aufgaben basiert auf der Aufgabe \'Einbruch/Überfall Filiale\': ' +
								'https://mypm.lightning.force.com/' + task.Id,
						Erledigung_bis_zum__c = Date.today().addDays( 1 ),
						Priority = 'Hoch',
						RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
								.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId(),
						Status = 'Nicht begonnen',
						Typc__c = 'Besuch',
						WhatId = task.AccountId
				)
		);
	}
	
	private void addBeauftragungAndBegleitungInventurTeilinventur ( Task task ) {
		
		followUptasks.add(
				new Task(
						ActivityDate = Date.today(),
						Aufgabenart__c = 'Beauftragung und Begleitung Inventur/Teilinventur + Detail',
						Auftraggeber__c = returnEmptyIfNull( task.Filialart_OZ__c ).contains( 'DPS' )
								? '3540 DP Shop'
								: 'Vertriebsleiter',
						Auftragnehmer__c = 'Vertriebsmanager',
						Description = 'Diese Aufgaben basiert auf der Aufgabe \'Einbruch/Überfall Filiale\': ' +
								'https://mypm.lightning.force.com/' + task.Id,
						Erledigung_bis_zum__c = Date.today().addDays( 1 ),
						Priority = 'Hoch',
						RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
								.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId(),
						Status = 'Nicht begonnen',
						Typc__c = 'Besuch',
						WhatId = task.AccountId
				)
		);
	}
	
	private void addBesicherungswerteErmitteln ( Task task ) {
		
		followUptasks.add(
				new Task(
						ActivityDate = Date.today(),
						Aufgabenart__c = 'Besicherungswerte zu Akquiseauftrag Filiale ermitteln',
						Auftrag_zur_PartnerAkquise__c = task.Auftrag_zur_PartnerAkquise__c,
						Auftraggeber__c = '3600 Forderungsmgmt Partner',
						Auftragnehmer__c = returnEmptyIfNull( task.Auftrag_zur_PartnerAkquise__c ).contains( '79' )
								|| returnEmptyIfNull( task.Auftrag_zur_PartnerAkquise__c ).contains( '84' )
								? 'Vertriebskoordinator VL'
								: '3600 Forderungsmgmt Partner',
						Description = String.format( 'Für Erstgespräch! Vorläufiger pauschaler Durchschnittswert ' +
								'auf OZ/VL-Ebene. Abweichungen nach oben können sich insb. bei ' +
								'haftungsbeschränkterer Rechtsform (UG, GmbH), schlechter Bonität bzw. bei Partnern ' +
								'mit mehreren Standorten ergeben. Für finales Partnergespräch BGP unter Angabe des ' +
								'konkreten Partners und der Referenzfiliale anfordern. {0}; Link zum Akquiseauftrag: ' +
								'https://mypm.lightning.force.com/{1}', new List<String> {
								task.Aenderungsgrund_Standort__c,
								task.Id
						} ),
						Erledigt_am__c = returnEmptyIfNull( task.Auftrag_zur_PartnerAkquise__c ).contains( '79' )
								|| returnEmptyIfNull( task.Auftrag_zur_PartnerAkquise__c ).contains( '84' )
								? Date.today()
								: task.Erledigt_am__c,
						Erledigung_bis_zum__c = returnEmptyIfNull( task.Auftrag_zur_PartnerAkquise__c ).contains( '79' )
								|| returnEmptyIfNull( task.Auftrag_zur_PartnerAkquise__c ).contains( '84' )
								? Date.today()
								: Date.today().addDays( 7 ),
						Erledigungsvermerk__c = getErledigungsvermerk( task ),
						FNAE_Id__c = task.FNAE_Name__c,
						Filialnetzaenderung__c = task.Filialnetzaenderung__c,
						Priority = 'Mittel',
						RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
								.get( 'Aufgaben_zu_FNAE' ).getRecordTypeId(),
						Status = returnEmptyIfNull( task.Auftrag_zur_PartnerAkquise__c ).contains( '79' )
								|| returnEmptyIfNull( task.Auftrag_zur_PartnerAkquise__c ).contains( '84' )
								? 'Erledigt'
								: 'Nicht begonnen',
						Typc__c = 'Intern',
						WhatId = task.AccountId
				)
		);
	}
	
	private void addBegleitungUmzugUndUebernahmeFiliale ( Task task ) {
		
		followUptasks.add(
				new Task(
						ActivityDate = Date.today(),
						Aufgabenart__c = 'Begleitung Umzug und Übernahme der Filiale + Detail',
						Auftrag_zur_PartnerAkquise__c = task.Auftrag_zur_PartnerAkquise__c,
						Auftraggeber__c = '3500 Betriebssteuerung',
						Auftragnehmer__c = 'Vertriebsmanager',
						Erledigung_bis_zum__c = Date.valueOf( task.Wiedervorlage_am__c ).addDays( 1 ),
						FNAE_Id__c = task.FNAE_Name__c,
						Filialnetzaenderung__c = task.Filialnetzaenderung__c,
						Priority = 'Hoch',
						RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
								.get( 'Aufgaben_zu_FNAE' ).getRecordTypeId(),
						Status = 'Nicht begonnen',
						Typc__c = 'Besuch',
						WhatId = task.AccountId,
						Description = 'Umzugstermin: ' + Date.valueOf( task.Wiedervorlage_am__c ).format()
								+ '; Vorab-Information der DPS Mitarbeiter - Wohin? / Wann?, Abstimmung ' +
								'Umzugsplanung mit Einrichtungskoordinator der ASt und DPS Mitarbeiter, ' +
								'Begleitung Umzug am Umzugstag (ggf. vorübergehende Änderung der Öffnungszeiten) ' +
								'sowie Durchführung Arbeits- und Brandschutzbelehrung für den neuen Standort'
				)
		);
	}
	
	private String getBesicherungswert ( Task task, String value84, String value79 ) {
		return returnEmptyIfNull( task.Auftrag_zur_PartnerAkquise__c ).contains( '84' )
				? value84
				: returnEmptyIfNull( task.Auftrag_zur_PartnerAkquise__c ).contains( '79' )
						? value79
						: '';
	}
	
	private String getErledigungsvermerk ( Task task ) {
		String orgEDP = accountsById.containsKey( task.WhatId ) ? accountsById.get( task.WhatId ).GL__r.OrgE_DP_Name__c : '';
		String erledigungsvermerk = '';
		switch on orgEDP {
			when 'Würzburg', 'Kassel', 'Leipzig' {
				erledigungsvermerk = getBesicherungswert( task, '7.000 €', '15.000 €' );
			}
			when 'München', 'Frankfurt', 'Stuttgart' {
				erledigungsvermerk = getBesicherungswert( task, '9.000 €', '17.000 €' );
			}
			when 'Berlin' {
				erledigungsvermerk = getBesicherungswert( task, '9.000 €', '16.000 €' );
			}
			when 'Mainz' {
				erledigungsvermerk = getBesicherungswert( task, '8.000 €', '16.000 €' );
			}
			when 'Freiburg', 'Nürnberg' {
				erledigungsvermerk = getBesicherungswert( task, '8.000 €', '15.000 €' );
			}
			when 'Hannover', 'Hamburg' {
				erledigungsvermerk = getBesicherungswert( task, '8.000 €', '18.000 €' );
			}
			when 'Münster' {
				erledigungsvermerk = getBesicherungswert( task, '9.000 €', '18.000 €' );
			}
			when 'Dortmund' {
				erledigungsvermerk = getBesicherungswert( task, '10.000 €', '19.000 €' );
			}
			when 'Köln' {
				erledigungsvermerk = getBesicherungswert( task, '11.000 €', '19.000 €' );
			}
			when else {
				erledigungsvermerk = 'Wert konnte nicht ermittelt werden, bitte an 3600 wenden';
			}
		}
		erledigungsvermerk += returnEmptyIfNull( task.Auftrag_zur_PartnerAkquise__c ).contains( '84' )
				|| returnEmptyIfNull( task.Auftrag_zur_PartnerAkquise__c ).contains( '79' )
				? ' als vorläufiger Orientierungswert, verbindlicher Besicherungswert folgt mit BGP. ' +
						'Bitte Kommentar s.o. beachten.' : '';
		
		return erledigungsvermerk;
	}
	
	private String returnEmptyIfNull ( String value ) {
		return value == null ? '' : value;
	}
	
	private void copyValuesToAufgabendetail ( Task task ) {
		if ( task.Aufgabendetail__c != null ) {
			String name = returnEmptyIfNull( task.Ast_Name__c ) + ' / ' + returnEmptyIfNull( task.Aufgabenart__c );
			name = NameFieldLimiter.getValue( name );
			aufgabendetail1s.add(
					new Aufgabendetail1__c(
							Id = task.Aufgabendetail__c,
							Ablehnungsgrund__c = task.Ablehnungsgrund__c,
							Aktivitaets_ID_Eindeutig__c = task.Aktivitaets_ID_Eindeutig__c,
							Aufgabenart__c = task.Aufgabenart__c,
							Auftraggeber__c = task.Auftraggeber__c,
							Auftragnehmer__c = task.Auftragnehmer__c,
							Erledigt_am__c = task.Erledigt_am__c,
							Erledigung_bis_zum__c = task.Erledigung_bis_zum__c,
							FNAEM_ID__c = task.FNAEM_ID__c,
							Faelligkeitsdatum__c = task.ActivityDate,
							Name = name,
							Name__c = task.WhoId,
							Prioritaet__c = task.Priority,
							Referenz_ID_Fachseitensystem__c = task.Referenz_ID_Fachseitensystem__c,
							Status__c = task.Status,
							Typ__c = task.Typc__c,
							Zugeordnet_zu__c = task.OwnerId,
							PoPS_Aktion__c = task.Aufgabenart__c == 'PoPS Aktivierungsaktion Neukunden + Detail'
									|| task.Aufgabenart__c == 'PoPS Outboundcall + Detail'
									? task.PoPS_Aktion__c
									: null
					)
			);
		}
	}
	
	private String substring ( String value, Integer count ) {
		return value.length() < count ? value : value.substring( count );
	}
	
	private void setNLBrief ( Task task ) {
		if ( ( task.WhatId == null
				|| task.WhatId.getSobjectType().getDescribe().getName() != 'Account' ) || task.NL_Brief__c != null ) {
			return;
		}
		if ( Trigger.isInsert ) {
			String nlBrief = accountsById.containsKey( task.WhatId )
					? accountsById.get( task.WhatId ).NL_Brief_Lookup__r.Name
					: 'n.a.';
			task.NL_Brief__c = String.isBlank( nlBrief ) ? 'n.a.' : nlBrief;
		}
	}
	
	private void setLeadSpecificFields ( Task task ) {
		if ( leadsById.containsKey( task.WhoId ) ) {
			Lead lead = leadsById.get( task.WhoId );
			task.VG__c = lead.VL_Name__c;
			task.NL_Brief__c = lead.NL_Brief__c;
		}
	}
	
	private void deleteAufgabendetails () {
		delete [
				SELECT
						Id
				FROM Aufgabendetail1__c
				WHERE Aktivitaets_Id__c IN :oldTasksMap.keySet()
		];
	}
	
	private void addEmailKuendigungsrueckgewinnung ( Task task ) {
		if ( isEmailKuendigungsrueckgewinnung( task ) ) {
			addRequest(task,  'KuendigungsrueckgewinnungPackPoststation');
		}
	}
	
	private void addRequest(Task task, String emailSettingName){
		EmailSettingService.Request request = new EmailSettingService.Request();
		request.recordId = task.Id;
		if (task.AccountId != null ) {
			request.accountId = task.AccountId;
			request.emailTemplateRecordId = task.AccountId;
		}
		if (task.WhoId != null ) {
			request.leadId = task.WhoId;
			request.emailTemplateRecordId = task.WhoId;
		}
		request.fnaeId = task.Filialnetzaenderung__c;
		request.emailSettingName = emailSettingName;
		EmailSettingService.getInstance().requests.add( request );
	}
	
	private Boolean isEmailKuendigungsrueckgewinnung ( Task task ) {
		return task.Aufgabenart__c == 'Kündigungsrückgewinnung Pack-/Poststation'
				&& task.Status == 'Erfolgreich'
				&& isChanged( task.Id, 'Status' );
	}
	
	private void sendEmails () {
		EmailSettingService.getInstance().sendBulk();
	}
}