/**
 *@author       Mats Böhler
 *@created      01.07.2021
 *
 *
 *@description  AktivitaetsDetailCtrlTest
 *
 *
 *@changelog    01.07.2021 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class AktivitaetsDetailCtrlTest {
	
	@IsTest
	static void testInit () {
		
		Post_TestTools.erzeugeRechteEinstellungenAdmin( UserInfo.getProfileId() );
		Account filiale = createFiliale();
		Task aufgabe = createAufgabe( filiale );
		createAufgabendetails( filiale, aufgabe );
		
		Test.startTest();
		AktivitaetsDetailCtrl.init( aufgabe.Id );
		Test.stopTest();
	}
	
	private static Account createFiliale () {
		OrgE_DP__c LO_OrgE = new OrgE_DP__c(
				Name = 'Gebiet 1',
				Koordinator__c = UserInfo.getUserId()
		);
		insert( LO_OrgE );
		Account LO_Filiale = new Account(
				Name = 'Filiale 1',
				ASt_ID__c = '12345',
				GL__c = LO_OrgE.Id
		);
		insert LO_Filiale;
		
		return LO_Filiale;
	}
	
	private static Task createAufgabe ( Account PO_Filiale ) {
		Task LO_Aufgabe = new Task(
				WhatId = PO_Filiale.Id,
				Subject = 'Subject'
		);
		insert LO_Aufgabe;
		
		return LO_Aufgabe;
	}
	
	private static List< Aufgabendetail1__c > createAufgabendetails ( Account PO_Filiale, Task PO_Aufgabe ) {
		List< Aufgabendetail1__c > LL_Aufgabendetails = new List< Aufgabendetail1__c >();
		
		Aufgabendetail1__c LO_Aufgabendetail = new Aufgabendetail1__c(
				Aktivitaets_Id__c = PO_Aufgabe.Id,
				Bezug_zu__c = PO_Filiale.Id,
				Flow__c = 'Flow1',
				Name = 'Name 1',
				Feldart__c = 'Datum',
				Antwort_Datum__c = Date.today(),
				Sortierung__c = 1
		);
		LL_Aufgabendetails.add( LO_Aufgabendetail );
		LO_Aufgabendetail = new Aufgabendetail1__c(
				Aktivitaets_Id__c = PO_Aufgabe.Id,
				Bezug_zu__c = PO_Filiale.Id,
				Flow__c = 'Flow1',
				Name = 'Name 1',
				Feldart__c = 'Euro/Cent',
				Antwort_Euro_Cent__c = 100,
				Sortierung__c = 1
		);
		LL_Aufgabendetails.add( LO_Aufgabendetail );
		LO_Aufgabendetail = new Aufgabendetail1__c(
				Aktivitaets_Id__c = PO_Aufgabe.Id,
				Bezug_zu__c = PO_Filiale.Id,
				Flow__c = 'Flow1',
				Name = 'Name 1',
				Feldart__c = 'Kontrollkästchen',
				Antwort_Kontrollkaestchen__c = true,
				Sortierung__c = 1
		);
		LL_Aufgabendetails.add( LO_Aufgabendetail );
		LO_Aufgabendetail = new Aufgabendetail1__c(
				Aktivitaets_Id__c = PO_Aufgabe.Id,
				Bezug_zu__c = PO_Filiale.Id,
				Flow__c = 'Flow1',
				Name = 'Name 1',
				Feldart__c = 'Text',
				Antwort_Text_Auswahlliste__c = 'Wert 1',
				Sortierung__c = 1
		);
		LL_Aufgabendetails.add( LO_Aufgabendetail );
		LO_Aufgabendetail = new Aufgabendetail1__c(
				Aktivitaets_Id__c = PO_Aufgabe.Id,
				Bezug_zu__c = PO_Filiale.Id,
				Flow__c = 'Flow1',
				Name = 'Name 1',
				Feldart__c = 'Zahl',
				Antwort_Zahl__c = 10,
				Sortierung__c = 1
		);
		LL_Aufgabendetails.add( LO_Aufgabendetail );
		
		insert( LL_Aufgabendetails );
		
		return LL_Aufgabendetails;
	}
}