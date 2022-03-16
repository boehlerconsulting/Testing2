/**
 *@author       Mats Böhler
 *@created      10.08.2020
 *
 *
 *@description  FilialnetzaenderungUpsertQueueableTest
 *
 *
 *@changelog    10.08.2020 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class FilialnetzaenderungUpsertQueueableTest {
	
	@IsTest
	static void testSuccess () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			Account account = createAccount();
			
			Test.startTest();
			System.enqueueJob(
					new FilialnetzaenderungUpsertQueueable(
							'Test',
							new List<Filialnetzaenderung__c> {
									createFilialnetzaenderung( account )
							}
					)
			);
			Test.stopTest();
			
			System.assertEquals( 1, [ SELECT Id FROM Filialnetzaenderung__c WHERE Filiale_Filialpartner__c = :account.Id ].size() );
		}
	}
	
	@IsTest
	static void testFailure () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			Account account = createAccount();
			Filialnetzaenderung__c filialnetzaenderung = createFilialnetzaenderung( account );
			
			Test.startTest();
			filialnetzaenderung.Filiale_Filialpartner__c = null;
			System.enqueueJob(
					new FilialnetzaenderungUpsertQueueable(
							'Test',
							new List<Filialnetzaenderung__c> {
									filialnetzaenderung
							}
					)
			);
			Test.stopTest();
			
			
			Logbuch__c logbuch = [
					SELECT
							Id,
							Job__c,
							Herkunft__c,
							Meldung__c,
							Type__c,
							Zeitpunkt__c
					FROM Logbuch__c
					LIMIT 1
			];
			System.assertEquals( 'Test', logbuch.Job__c );
			System.assertEquals( 'Filialnetzänderung ID: ' + filialnetzaenderung.Id, logbuch.Herkunft__c );
			System.assert( logbuch.Meldung__c.contains('Erforderliche Felder fehlen: [Filiale_Filialpartner__c]') );
			System.assertEquals( 'Filialnetzänderung ID: ' + filialnetzaenderung.Id, logbuch.Type__c );
		}
	}
	
	private static Filialnetzaenderung__c createFilialnetzaenderung ( Account account ) {
		
		Filialnetzaenderung__c filialnetzaenderung = new Filialnetzaenderung__c(
				Schliessung_avisiert_fuer__c = Date.today(),
				Filiale_Filialpartner__c = account.Id
		);
		insert filialnetzaenderung;
		return filialnetzaenderung;
	}
	
	private static Account createAccount () {
		
		Account account = ( Account ) TestFactory.createSObject(
				new Account(
				),
				true
		);
		return account;
	}
}