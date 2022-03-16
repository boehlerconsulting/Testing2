/**
 *@author       Mats Böhler
 *@created      01.07.2021
 *
 *
 *@description  AktivitaetsDetailCtrl
 *
 *
 *@changelog    01.07.2021 Mats Böhler  - Created
 *              
 * 
 */
public with sharing class AktivitaetsDetailCtrl {
	
	private Id taskId;
	private Map<String, List<Aufgabendetail1__c>> detailsByFlowNames = new Map<String, List<Aufgabendetail1__c>>();
	private List<Detail> details = new List<Detail>();
	
	@AuraEnabled
	public static String init ( String taskId ) {
		
		AktivitaetsDetailCtrl instance = new AktivitaetsDetailCtrl();
		
		try {
			instance.taskId = taskId;
			instance.loadData();
			instance.buildDetails();
		}
		catch ( Exception e ) {
			
			throw new AuraHandledException( e.getMessage() );
		}
		return JSON.serialize( instance.details );
	}
	
	private void buildDetails () {
		
		for ( String flowName : detailsByFlowNames.keySet() ) {
			
			details.add(
					new Detail(
							flowName,
							detailsByFlowNames.get( flowName )
					)
			);
		}
	}
	
	private void loadData () {
		
		for ( Aufgabendetail1__c aufgabendetail1 : [
				SELECT
						Id,
						Flow__c,
						Name,
						Feldart__c,
						Antwort_Datum__c,
						Antwort_Euro_Cent__c,
						Antwort_Kontrollkaestchen__c,
						Antwort_Text_Auswahlliste__c,
						Antwort_Zahl__c
				FROM Aufgabendetail1__c
				WHERE ( Aktivitaets_Id__c = :String.valueOf( taskId ).left( 15 ) ) OR ( Aktivitaets_Id__c = :taskId )
				ORDER BY Sortierung__c ASC NULLS LAST , Flow__c ASC NULLS LAST
		] ) {
			if ( aufgabendetail1.Flow__c.toLowerCase() != 'master' ) {
				String flowName = '';
				if ( aufgabendetail1.Flow__c != null ) {
					flowName = aufgabendetail1.Flow__c.replace( ' ', '' )
							.replace( '-', '' )
							.replace( '(', '' )
							.replace( ')', '' )
							.replace( '.', '' );
				}
				if ( !detailsByFlowNames.containsKey( flowName ) ) {
					detailsByFlowNames.put( flowName, new List< Aufgabendetail1__c >() );
				}
				detailsByFlowNames.get( flowName ).add( aufgabendetail1 );
			}
		}
	}
	
	public class Detail {
		private String title = '';
		private List<Aufgabendetail1__c> details = new List<Aufgabendetail1__c>();
		
		public Detail ( String title, List<Aufgabendetail1__c> details ) {
			this.title = title;
			this.details = details;
		}
	}
}