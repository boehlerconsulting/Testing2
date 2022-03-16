/**
 * MYPM-534
 * @author Sabrina Wortmann (DPDHL IT Services)
 * @since 10.09.2020
 */
public with sharing class AutoTaskServicezertifikatSchedule implements Schedulable {
    
    @testVisible
    private static Date heute = Date.today();
    
    @TestVisible
	private static Boolean testException = false;
    
    public void execute(SchedulableContext sc) {
        try {
            checkTime();
            if ( testException && Test.isRunningTest() ) {
                throw new AutoTaskServicezertifikatScheduleException('Test Exception');
            }
        } catch (Exception e) {
            new HW_ErrorLogging().logException(
					e,
					new Set<Id>(),
					'KPI Auswertung Servicezertifikat Scheduler'
			);
        }
    }
    
    private void checkTime() {
        List<TaskServicezertifikatSetting__mdt> settingsToUse = new List<TaskServicezertifikatSetting__mdt>();
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
        
        for (TaskServicezertifikatSetting__mdt setting : settings) {
            Date datum = setting.Stichtag__c;
            
            if ((datum.month() == heute.month()) && (datum.day() == heute.day())) {
                settingsToUse.add(setting);
            } 
        }
        
        if (!settingsToUse.isEmpty()) {
            AutoTaskServicezertifikatBatch batch = new AutoTaskServicezertifikatBatch(settingsToUse);
            database.executeBatch(batch);
        }
    }
    
    private class AutoTaskServicezertifikatScheduleException extends Exception  {
        
    }

}