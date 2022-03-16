/**
 * MYPM-534 Test
 * @author Sabrina Wortmann (DPDHL IT Services)
 * @since 11.09.2020
 */
@isTest
public class AutoTaskServicezertifikatBatchTest {
    
    @testSetup
    static void setup() {
        TriggerHandler.bypass( 'AccountTriggerHandler' );
        createAccounts(5, 'Filiale');
        TriggerHandler.clearBypass( 'AccountTriggerHandler' );
    }
    
    @isTest
    static void testBatchPositiveTasks() {
        List<Account> newAccounts = [SELECT Id FROM Account];
        createQualis(newAccounts, 'Servicezertifikat', 4.8);
        List<TaskServicezertifikatSetting__mdt> settings = getMetadata();
        
        Test.startTest();
        Database.executeBatch(new AutoTaskServicezertifikatBatch(settings));
        Test.stopTest();
    }
    
    private static List<Account> createAccounts (Integer quantity, String recordType) {
        String recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
			.get( recordType ).getRecordTypeId();
		return ( List<Account> ) TestFactory.createSObjectList(
				new Account(
                    RecordTypeId = recordTypeId,
						Filialart__c = 'McPaper'
				),
				quantity,
				true
		);
    }
    
    private static List<Qualityinformation__c> createQualis (List<Account> accounts, String recordType, Decimal durchschnittsBewertung) {
        String recordTypeId = Schema.SObjectType.Qualityinformation__c.getRecordTypeInfosByDeveloperName()
			.get( recordType ).getRecordTypeId();
        List<Qualityinformation__c> newQualis = new List<Qualityinformation__c>();
        for (Account account : accounts) {
            Qualityinformation__c newQuali = new Qualityinformation__c(
            	RecordTypeId = recordTypeId,
                Filiale__c = account.id,
                AnzahlGoogleBewertungen__c = 10,
                DurchschnittGoogleBewertungen__c = durchschnittsBewertung,
                AnzahlStandortfinderBewertungen__c = 0,
                DurchschnittFreundlichkeit__c = 0,
                DurchschnittKompetenz__c = 0,
                DurchschnittWartezeit__c = 0
            );
            newQualis.add(newQuali);
        }
        insert newQualis;
        return newQualis;
    }
    
    private static List<TaskServicezertifikatSetting__mdt> getMetadata () {
       List<TaskServicezertifikatSetting__mdt> settings = [
            SELECT
            	Id,
            	DeveloperName,
            	Aufgabenart__c,
            	AvgRatings__c,
            	AvgRatingsOperator__c,
            	Comment__c,
            	NumberOfRatings__c,
            	NumberOfRatingsOperator__c,
            	Stichtag__c
            FROM TaskServicezertifikatSetting__mdt
        ];
        
        List<TaskServicezertifikatSetting__mdt> filtered = new List<TaskServicezertifikatSetting__mdt>();
        
        for (TaskServicezertifikatSetting__mdt setting : settings) {
            if(setting.Stichtag__c.month() == 4) {
                filtered.add(setting);
            }
        }
        
        return filtered;
    }

}