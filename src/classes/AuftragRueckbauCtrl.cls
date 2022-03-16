/**
 *@author       Mats Böhler
 *@created      26.04.2021
 *
 *
 *@description  AuftragRueckbauCtrl
 *
 *
 *@changelog    26.04.2021 Mats Böhler  - Created
 *              
 * 
 */
public with sharing class AuftragRueckbauCtrl extends EinrichtungsDokumentBase {
	
	public Boolean hasMissingValues = false;
	
	public AuftragRueckbauCtrl () {
		currentPage = ApexPages.currentPage();
		initialize();
	}
	
	public AuftragRueckbauCtrl ( PageReference page ) {
		currentPage = page;
		initialize();
	}
	
	protected override void initialize () {
		
		loadData();
		process = currentPage.getParameters().get( 'process' );
		loadCategories();
	}
	
	protected override String getFileName () {
		switch on process {
			when 'Teilabbau' {
				return 'Auftrag_Teilabbau_'
						+ einrichtungsprozess.Filiale__r.ASt_Name__c;
			}
			when 'Filialschließung' {
				return 'Auftrag_Rückbau_'
						+ einrichtungsprozess.Filiale__r.ASt_Name__c;
			}
			when else {
				//Sonarqube --> do nothing
			}
		}
		return '';
	}
	
	private void loadCategories () {
		
		categories = new List<Category>();
		
		for ( Filialausstattung__c option : loadFirstLevelProducts( buildTopLevelQuery() ) ) {
			
			if ( option.Menge_Wiedereinsatzfaehig__c == null ) {
				hasMissingValues = true;
			}
			addOption( option );
		}
		
		for ( String categoryTitle : produktoptionenByCategories.keySet() ) {
			Category category = new Category( categoryTitle );
			
			for ( Filialausstattung__c produktoption : produktoptionenByCategories.get( categoryTitle ) ) {
				Option option = new Option(
						produktoption
				);
				category.products.add(
						option
				);
			}
			categories.add( category );
		}
	}
	
	private String buildTopLevelQuery () {
		String query = 'SELECT ' + QUERY_FIELDS + ' ' +
				'FROM Filialausstattung__c ' +
				'WHERE Filiale__c = :accountId ' +
				'AND Produktoption__r.Produktbuendeloption__c = NULL ' +
				'AND (Vorgemerkt__c = \'in Abbau\' OR Vorgemerkt__c = \'in Abbau zusätzlich\')';
		
		query += 'ORDER BY Produktoption__r.Nummerierung__c ASC NULLS LAST';
		return query;
	}
}