/**
* @author           Oliver Preuschl
*                   H&W Consult GmbH
*                   Bahnhofstr. 3
*                   21244 Buchholz i.d.N.
*                   http://www.hundw.com
*
* @description      Account Trigger
*
* date             24.03.2016
*
* Timeline:
* Name              DateTime                Version        Description
* Oliver Preuschl   24.03.2016              *1.0*          Created
*/

trigger Post_AccountTrigger on Account ( before insert, before update, before delete, after insert, after update, after delete, after undelete ) {
	
	if ( TriggerService.isActive( 'Post_AccountTrigger' ) ) {
		new AccountTriggerHandler().run();
	}
}