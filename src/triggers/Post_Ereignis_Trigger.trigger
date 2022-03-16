/**
* @author           Oliver Preuschl
*                   H&W Consult GmbH
*                   Bahnhofstr. 3
*                   21244 Buchholz i.d.N.
*                   http://www.hundw.com
*
* @description      Ereignis-Trigger
*
* date             29.02.2016
*
* Timeline:
* Name              DateTime                Version        Description
* Oliver Preuschl   29.02.2016              *1.0*          Created
*/

trigger Post_Ereignis_Trigger on Event ( before delete ) {
	
	if ( TriggerService.isActive( 'Post_Ereignis_Trigger' ) ) {
		if( Trigger.isBefore ){
			if( Trigger.isDelete ){
				Post_EventTriggerHandler.pruefeLoeschung( Trigger.oldMap );
			}
		}
	}
}