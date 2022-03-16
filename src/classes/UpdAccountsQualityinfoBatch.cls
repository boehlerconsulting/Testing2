/**
 * Batch for updating every account with a Qualityinformation__c record
 * MYPM-672
 * @author Sabrina Wortmann (DPDHL IT Services)
 * @since 02.09.2020
 */
public class UpdAccountsQualityinfoBatch implements Database.Batchable<sObject> {
    public final String query;
    public final String recordTypeNameQuali;
    public String recordTypeIdQuali;
	
    public UpdAccountsQualityinfoBatch(String recordTypeAccount, String recordTypeQuali) {
      this.query = 'SELECT Id FROM Account WHERE RecordType.Name = \'' + recordTypeAccount 
            + '\' AND Id NOT IN (SELECT Filiale__c FROM Qualityinformation__c WHERE RecordType.Name = \'' + recordTypeQuali + '\')';
      this.recordTypeNameQuali = recordTypeQuali;  
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Account> scope) {
        try {
            this.recordTypeIdQuali = Schema.SObjectType.Qualityinformation__c.getRecordTypeInfosByDeveloperName()
            .get( recordTypeNameQuali ).getRecordTypeId();
            // for every Account, create a Qualityinformation__c
        	List<Qualityinformation__c> newQualis = new List<Qualityinformation__c>();
        	for (Account account : scope) {
            	Qualityinformation__c accountQuali = new Qualityinformation__c(Filiale__c = account.Id, RecordTypeId = recordTypeIdQuali);
            	newQualis.add(accountQuali);
        	}
        	insert newQualis;
        } catch ( Exception e) {
            new HW_ErrorLogging().logException(
                e, 
                new Map<Id, Account>( scope ).keySet(), 
                'Update Filialen mit Qualitätsinformationen');
        }
        
    }
    
    public void finish(Database.BatchableContext bc) {
	    //Sonarqube -> does nothing
    }
}