/**
 * @author      Stefan Richter (stefan.richter@hundw.de)
 *              H+W CONSULT GmbH
 *              Bahnhofstr. 3
 *              21244 Buchholz i. d. Nordheide
 *              Germany
 *              https://www.hundw.de
 *
 * @description class for <insert-description-here>
 *
 * TIMELINE
 * 28.09.21      Stefan Richter  Initial release.
 **/
@IsTest
private class ZusaetzlicheEinrichtungCtrlTest {
	
	@IsTest
	static void testTaskCreation () {
		
		User u = TestUser.create( TestUser.UserType.ADMIN );
		u.OrgE_DP__c = 'Extern';
		update u;
		
		System.runAs( u ) {
			
			OrgE_DP__c orge = new OrgE_DP__c( Leiter__c = u.Id, Koordinator__c = u.Id, OrgE_DP_Name__c = 'Extern', Name = 'Extern' );
			orge.RecordTypeId = Schema.SObjectType.OrgE_DP__c.getRecordTypeInfosByDeveloperName().get( 'NL_Brief' ).getRecordTypeId();
			insert orge;
			
			Account acco = ( Account ) TestFactory.createSObject(
					new Account(
							Name = 'Ada',
							RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
									.get( 'Filialpartner' ).getRecordTypeId()
					),
					true
			);
			
			Filialnetzaenderung__c fnae = ( Filialnetzaenderung__c ) TestFactory.createSObject(
					new Filialnetzaenderung__c(
							Filiale_Filialpartner__c = acco.Id,
							Schliessung_avisiert_fuer__c = Date.today() + 5,
							RecordTypeId = Schema.SObjectType.Filialnetzaenderung__c.getRecordTypeInfosByDeveloperName()
									.get( 'Filiale' ).getRecordTypeId(),
							NL_Brief__c = orge.Id
					),
					true
			);
			
			String jsonTask = JSON.serialize( new Task() );
			
			Test.startTest();
			
			ZusaetzlicheEinrichtungCtrl.init();
			ZusaetzlicheEinrichtungCtrl.createTask( fnae.Id, jsonTask );
			
			Test.stopTest();
			
			System.assertEquals(acco.Id,
					[SELECT Filialnetzaenderung__r.Filiale_Filialpartner__c
					FROM Task
					WHERE Filialnetzaenderung__c =: fnae.Id]
							.Filialnetzaenderung__r.Filiale_Filialpartner__c);
		}
	}
}