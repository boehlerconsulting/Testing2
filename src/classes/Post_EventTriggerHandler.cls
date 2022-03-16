/**
* @author           Oliver Preuschl
*                   H&W Consult GmbH
*                   Bahnhofstr. 3
*                   21244 Buchholz i.d.N.
*                   http://www.hundw.com
*
* @description      Ereignis Trigger-Handler
*
* date             29.02.2016
*
* Timeline:
* Name              DateTime                Version        Description
* Oliver Preuschl   29.02.2016              *1.0*          Created
*/

public with sharing class Post_EventTriggerHandler {
	
	public static void pruefeLoeschung ( Map< Id, Event > ereignisse ) {
		Rechte__c rechte = Rechte__c.getInstance();
		Set< Id > ereignisIds = ereignisse.keySet();
		if ( !rechte.Alle_Ereignisse_loeschen__c && String.isNotBlank( rechte.Nicht_loeschbare_Ereignisse__c ) ) {
			DateTime LV_NOW = DateTime.now();
			String query = 'SELECT Id FROM Event WHERE ( Id IN :ereignisIds ) AND ( ' + rechte.Nicht_loeschbare_Ereignisse__c + ' )';
			List< Event > nichtLoeschbareEreignisse = Database.query( query );
			for ( Event nichtLoeschbaresEreignis : nichtLoeschbareEreignisse ) {
				ereignisse.get( nichtLoeschbaresEreignis.Id ).addError( '<p style="font-weight: bold; color: red;">'
						+ Label.EreignisLoeschenKeineBerechtigung + '</p>', false );
			}
		}
	}
}