/**
 * MYPM-534
 * @author Sabrina Wortmann (DPDHL IT Services)
 * @since 10.09.2020
 */
public class AutoTaskServicezertifikatBatch implements Database.Batchable<sObject> {
    
    private List<TaskServicezertifikatSetting__mdt> settings;
    
    
    public AutoTaskServicezertifikatBatch(List<TaskServicezertifikatSetting__mdt> settingsToUse) {
        this.settings = settingsToUse;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
       return Database.getQueryLocator([
           SELECT
           		Id
           FROM Qualityinformation__c
           WHERE RecordType.Name = 'Servicezertifikat'
           AND (Filiale__r.Filialart__c = 'Partner-Filiale' OR Filiale__r.Filialart__c = 'McPaper')
       ]);
    }
    
    public void execute(Database.BatchableContext bc, List<Qualityinformation__c> scope) {
        try {
            for (TaskServicezertifikatSetting__mdt setting : this.settings) {
                    processSetting(setting, scope);
                }
        } catch (Exception e) {
           new HW_ErrorLogging().logException(
               e,
               new Map<Id, Qualityinformation__c> ( scope ).keySet(),
               'KPI Auswertung Servicezertifikat Batch');
        }
    }
    
    public void finish(Database.BatchableContext bc) {
        //Sonarqube -> does nothing
    }
    
    private void processSetting(TaskServicezertifikatSetting__mdt setting, List<Qualityinformation__c> scope) {
        String operatorAnz = setting.NumberOfRatingsOperator__c;
        Decimal valueAnz = setting.NumberOfRatings__c;
        
        String operatorAvg = setting.AvgRatingsOperator__c;
        Decimal valueAvg = setting.AvgRatings__c;
        
        String query = 'SELECT Id, Filiale__c, DurchschnittlicheKundenbewertung__c ' +
		        'FROM Qualityinformation__c ' +
		        'WHERE AnzahlKundenbewertungen__c ' + operatorAnz +
            ':valueAnz AND DurchschnittlicheKundenbewertung__c ' + operatorAvg +
            ':valueAvg AND Id IN :scope';
        
        List<Qualityinformation__c> qualis = Database.query(query);
        
        if (!qualis.isEmpty()) {
            List<Task> newTasks = new List<Task>();
            
            String delimiter = '|Var|';
            String firstSplit = setting.Comment__c.substringBefore(delimiter);
            String secondSplit = setting.Comment__c.substringAfter(delimiter);
            
            Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Aufgaben_Qualitaet').getRecordTypeId();
        
        	for (Qualityinformation__c quali : qualis) {
                String comment = firstSplit + quali.DurchschnittlicheKundenbewertung__c.format() + secondSplit;
            	Task newTask = new Task(
      				Auftraggeber__c = '1L1 Bereichsentwicklung',
                	Auftragnehmer__c = 'Vertriebsmanager',
                	ActivityDate = Date.today(),
                	Status = 'Nicht begonnen',
                	Priority = 'Mittel',
                	RecordTypeId = recordTypeId,
                	Aufgabenart__c = setting.Aufgabenart__c,
                	Description = comment,
                	WhatId = quali.Filiale__c,
                	Erledigung_bis_zum__c = Date.today().addDays(28)
            	);
                
                newTasks.add(newTask);
        	}
            
            insert newTasks;
        } else {
            return;
        }
    }
    

}