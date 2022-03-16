/**
 *@author       Mats Böhler
 *@created      16.05.2020
 *
 *
 *@description  EmailVersandTriggerHandlerTest
 *
 *
 *@changelog    16.05.2020 Mats Böhler  - Created
 *				14.08.2020 Sabrina Wortmann - Add methods to test SDS functionality
 *              
 * 
 */
@IsTest
private class EmailVersandTriggerHandlerTest {
	
	@IsTest
	static void testBulk () {
		
		Test.startTest();
		createEmailVersands( 1 );
		Test.stopTest();
		
		System.assertEquals( 1, [ SELECT Id FROM EmailVersand__c ].size() );
	}
	
	@IsTest
	static void testEmailHistoryCreation () {
		System.runAs( TestUser.create( TestUser.UserType.VL2001 ) ) {
			EmailVersand__c emailVersand = createCSGEmail(
					createLead()
			);
			
			Test.startTest();
			emailVersand.Status__c = 'versendet';
			update emailVersand;
			Test.stopTest();
			
			System.assertEquals( 'E-Mail versendet', [ SELECT Id, EMailStatus__c FROM Lead LIMIT 1 ].EMailStatus__c );
			System.assertEquals(1, [ SELECT Id, ActivityId FROM EmailMessage ].size());
		}
	}
    
    @isTest
    static void testSDSMailingHistoryCreation() {
        System.runAs( TestUser.create( TestUser.UserType.VL2001 ) ) {
			EmailVersand__c emailVersand = createSDSEmail(
				createAccount(),
				createLead()
			);
			
			Test.startTest();
			emailVersand.Status__c = 'versendet';
			update emailVersand;
			Test.stopTest();
			
			System.assertEquals(2, [ SELECT Id, ActivityId FROM EmailMessage WHERE ActivityId <> '' ].size(), 'Mehr als zwei Aktivitäten bzw. Maileinträge vorhanden!');
		}
    }
	
	private static void createEmailVersands ( Integer quantity ) {
		List<EmailVersand__c> emailVersands = new List<EmailVersand__c>();
		for ( Integer i = 0; i < quantity; i++ ) {
			emailVersands.add(
					( EmailVersand__c ) TestFactory.createSObject(
							new EmailVersand__c(
							
							),
							false
					)
			);
		}
		insert emailVersands;
	}
	
	private static EmailVersand__c createCSGEmail ( Lead lead ) {
		return ( EmailVersand__c ) TestFactory.createSObject(
				new EmailVersand__c(
						Dokument__c = 'Packstation - Mietvertrag',
						Lead__c = lead.Id,
						Status__c = 'offen'
				),
				true
		);
	}
    
    private static EmailVersand__c createSDSEmail (Account account) {
        return ( EmailVersand__c ) TestFactory.createSObject(
				new EmailVersand__c(
						Dokument__c = 'Debitoren_beantragen',
						Account__c = account.Id,
						Status__c = 'offen'
				),
				true
		);
    }
    
    private static EmailVersand__c createSDSEmail (Account account, Lead lead) {
        return ( EmailVersand__c ) TestFactory.createSObject(
				new EmailVersand__c(
						Dokument__c = 'Debitoren_beantragen',
						Account__c = account.Id,
                    	Lead__c = lead.Id,
						Status__c = 'offen'
				),
				true
		);
    }
	
	private static Lead createLead () {
		Lead lead = ( Lead ) TestFactory.createSObject(
				new Lead(
				),
				true
		);
		return lead;
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