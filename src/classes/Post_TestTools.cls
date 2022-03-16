/**
* @author           Oliver Preuschl
*                   H&W Consult GmbH
*                   Bahnhofstr. 3
*                   21244 Buchholz i.d.N.
*                   http://www.hundw.com
*
* @description      Hilfs-Methoden für die Testklassen
*
* date             03.03.2016
*
* Timeline:
* Name              DateTime                Version        Description
* Oliver Preuschl   03.03.2016              *1.0*          Created
*/

public with sharing class Post_TestTools {
	
	public static User createUser ( String profileName ) {
		Id profileId = null;
		if ( profileNames2ProfileIds.containsKey( profileName ) ) {
			profileId = profileNames2ProfileIds.get( profileName );
		}
		User newUser = new User(
				Username = UserInfo.getOrganizationId() + System.now().millisecond() + 'test@hundw.com',
				Alias = 'standt',
				email = 'activation@hundw.com',
				emailencodingkey = 'UTF-8',
				LastName = 'TestUser',
				LanguageLocaleKey = 'de',
				LocaleSidKey = 'de_DE',
				ProfileId = profileId,
				TimeZoneSidKey = 'Europe/Berlin'
		);
		insert( newUser );
		return newUser;
	}
	
	public static User createUser ( String profileName, String roleName ) {
		Id profileId = null;
		if ( profileNames2ProfileIds.containsKey( profileName ) ) {
			profileId = profileNames2ProfileIds.get( profileName );
		}
		User newUser = new User(
				Username = UserInfo.getOrganizationId() + System.now().millisecond() + 'test@hundw.com',
				Alias = 'standt',
				email = 'activation@hundw.com',
				emailencodingkey = 'UTF-8',
				LastName = 'TestUser',
				LanguageLocaleKey = 'de',
				LocaleSidKey = 'de_DE',
				ProfileId = profileId,
				TimeZoneSidKey = 'Europe/Berlin',
				UserRoleId = userRoleIdByDeveloperName.containsKey( roleName )
						? userRoleIdByDeveloperName.get( roleName )
						: null
		);
		insert( newUser );
		return newUser;
	}
	
	public static Map< String, Id > profileNames2ProfileIds {
		get {
			if ( profileNames2ProfileIds == null ) {
				profileNames2ProfileIds = new Map< String, Id >();
				for ( Profile profile : [ SELECT Id, Name FROM Profile ] ) {
					profileNames2ProfileIds.put( profile.Name, profile.Id );
				}
			}
			return profileNames2ProfileIds;
		}
		set;
	}
	
	public static Map< String, Id > userRoleIdByDeveloperName {
		get {
			if ( userRoleIdByDeveloperName == null ) {
				userRoleIdByDeveloperName = new Map< String, Id >();
				for ( UserRole role : [ SELECT Id, DeveloperName FROM UserRole ] ) {
					userRoleIdByDeveloperName.put( role.DeveloperName, role.Id );
				}
			}
			return userRoleIdByDeveloperName;
		}
		set;
	}
	
	public static void erzeugeRechteEinstellungenAdmin ( Id userId ) {
		Rechte__c rechte = new Rechte__c(
				SetupOwnerId = userId,
				Account_Name_aendern__c = true,
				Alle_Ereignisse_loeschen__c = true,
				Aufgaben_loeschen__c = true,
				darf_Filialinhaber_aendern__c = true,
				darf_Inhaber_aller_Filialen_aendern__c = true,
				darf_Partnerinhaber_aendern__c = true,
				Nicht_loeschbare_Ereignisse__c = '( ActivityDateTime < :LV_Now ) AND ( RecordType.DeveloperName = \'Filialkontakt\' )'
		);
		insert( rechte );
	}
	
	public static void erzeugeRechteEinstellungenVertrieb ( Id userId ) {
		Rechte__c rechte = new Rechte__c(
				SetupOwnerId = userId,
				Account_Name_aendern__c = false,
				Alle_Ereignisse_loeschen__c = false,
				Aufgaben_loeschen__c = false,
				darf_Filialinhaber_aendern__c = true,
				darf_Inhaber_aller_Filialen_aendern__c = false,
				darf_Partnerinhaber_aendern__c = true,
				Nicht_loeschbare_Ereignisse__c = '( ActivityDateTime < :LV_Now ) AND ( RecordType.DeveloperName = \'Filialkontakt\' )'
		);
		insert( rechte );
	}
	
	public static List< Event > erzeugeEreignisse ( Integer anzahl, Id whatId, Id whoId ) {
		List< Event > events = new List< Event >();
		for ( Integer i = 1; i <= anzahl; i++ ) {
			Event event = new Event(
					RecordTypeId = Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName()
							.get( 'Filialkontakt' ).getRecordTypeId(),
					WhatId = whatId,
					WhoId = whoId,
					Subject = 'Test Ereignis ' + i,
					StartDateTime = DateTime.now() - 60,
					DurationInMinutes = 60
			);
			events.add( event );
		}
		insert( events );
		return events;
	}
}