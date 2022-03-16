/**
 * 
 * @author Sabrina Wortmann
 * @since 04.09.2020
 */
@isTest
private class UpdAccountsQualityinfoBatchTest {
    
    @testSetup
    static void setup() {
        List<Account> newAccounts = createAccounts(200, 'Filiale');
        
        TriggerHandler.bypass( 'AccountTriggerHandler' );
		insert newAccounts;
		TriggerHandler.clearBypass( 'AccountTriggerHandler' );
    }
	
    @isTest
    static void testBatch() {
        
        Test.startTest();
        ID batchProcessId = Database.executeBatch(new UpdAccountsQualityinfoBatch( 'Filiale', 'Wartezeitrisiko' ) );
        Test.stopTest();
        
        // Assert: now 200 Qualis with recType Wartezeitrisiko
        System.assertEquals(200, [SELECT Id FROM Qualityinformation__c WHERE RecordType.Name = 'Wartezeitrisiko'].size(), 'Falsche Anzahl an Wartezeitrisiken vorhanden!');
        
    }
    
    @isTest
    static void testBatchFail() {
        
        Test.startTest();
        ID batchProcessId = Database.executeBatch(new UpdAccountsQualityinfoBatch( 'Filiale', 'Wartezeitriiko' ) );
        Test.stopTest();
        
        System.assertEquals(
            1, 
            [SELECT Id FROM Logbuch__c].size(), 
            'Es muss ein Logbucheintrag vorhanden sein!');
    }
    
    private static List<Account> createAccounts ( Integer quantity, String recordType ) {
		String recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
			.get( recordType ).getRecordTypeId();
		return ( List<Account> ) TestFactory.createSObjectList(
				new Account(
                    RecordTypeId = recordTypeId
				),
				quantity,
				false
		);
	}
}