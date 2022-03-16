/**
 * MYPM-534 Test
 * @author Sabrina Wortmann (DPDHL IT Services)
 * @since 11.09.2020
 */
@isTest
public class AutoTaskServicezertifikatScheduleTest {
	
    @isTest
    static void testScheduleRun() {
        String cron = '0 0 0 1 4 ? 2022';
        
        Test.startTest();
        AutoTaskServicezertifikatSchedule.heute = Date.newInstance(2020, 4, 19);
        String jobId = System.schedule(
            'KPI Auswertung Servicezertifikat Schedule Test', 
            cron, 
            new AutoTaskServicezertifikatSchedule()
        );
        Test.stopTest();
        
        // Check schedulable is in the job list
    	List<AsyncApexJob> jobsScheduled = [select Id, ApexClassID, ApexClass.Name, Status, JobType from AsyncApexJob where JobType = 'ScheduledApex'];
    	System.assertEquals(1, jobsScheduled.size(), 'expecting one scheduled job');
    	System.assertEquals('AutoTaskServicezertifikatSchedule', jobsScheduled[0].ApexClass.Name, 'expecting specific scheduled job');
        
        // check apex batch is in the job list
    	List<AsyncApexJob> jobsApexBatch = [select Id, ApexClassID, ApexClass.Name, Status, JobType from AsyncApexJob where JobType = 'BatchApex'];
    	System.assertEquals(1, jobsApexBatch.size(), 'expecting one apex batch job');
    	System.assertEquals('AutoTaskServicezertifikatBatch', jobsApexBatch[0].ApexClass.Name, 'expecting specific batch job');
    }
    
    @isTest
    static void testScheduleNoRun() {
        String cron = '0 0 0 2 4 ? 2022';
        
        Test.startTest();
        AutoTaskServicezertifikatSchedule.heute = Date.newInstance(2020, 4, 2);
        String jobId = System.schedule(
            'KPI Auswertung Servicezertifikat Schedule Test', 
            cron, 
            new AutoTaskServicezertifikatSchedule()
        );
        Test.stopTest();
        
        // Check schedulable is in the job list
    	List<AsyncApexJob> jobsScheduled = [select Id, ApexClassID, ApexClass.Name, Status, JobType from AsyncApexJob where JobType = 'ScheduledApex'];
    	System.assertEquals(1, jobsScheduled.size(), 'expecting one scheduled job');
    	System.assertEquals('AutoTaskServicezertifikatSchedule', jobsScheduled[0].ApexClass.Name, 'expecting specific scheduled job');
        
        // check apex batch is not in the job list
    	List<AsyncApexJob> jobsApexBatch = [select Id, ApexClassID, ApexClass.Name, Status, JobType from AsyncApexJob where JobType = 'BatchApex'];
    	System.assertEquals(0, jobsApexBatch.size(), 'expecting no apex batch jobs!');
    }
    
    @isTest
    static void testScheduleFail() {
        String cron = '0 0 0 1 4 ? 2022';
        
        Test.startTest();
        AutoTaskServicezertifikatSchedule.heute = Date.newInstance(2020, 4, 1);
        AutoTaskServicezertifikatSchedule.testException = true;
        String jobId = System.schedule(
            'KPI Auswertung Servicezertifikat Schedule Test', 
            cron, 
            new AutoTaskServicezertifikatSchedule()
        );
        Test.stopTest();
        
        System.assertEquals( 1, [ SELECT Id FROM Logbuch__c ].size(), 'Logbuch sollte einen Fehlereintrag haben!' );
    }
}