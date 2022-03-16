/**
 *@author       Mats Böhler
 *@created      18.02.2021
 *
 *
 *@description  AuftragVerEntsorgungBriefPaketCtrl
 *
 *
 *@changelog    18.02.2021 Mats Böhler  - Created
 *              
 * 
 */
public with sharing class AuftragVerEntsorgungBriefPaketCtrl extends EinrichtungsDokumentBase{
	
	private List<Oeffnungszeiten__c> filialOeffnungszeiten = new List<Oeffnungszeiten__c>();
	
	public AuftragVerEntsorgungBriefPaketCtrl () {
		currentPage = ApexPages.currentPage();
		initialize();
		createOeffnungszeiten();
	}
	
	public AuftragVerEntsorgungBriefPaketCtrl ( PageReference page ) {
		currentPage = page;
		initialize();
		createOeffnungszeiten();
	}

	protected override String getFileName () {
		return 'Auftrag Ver- und Entsorgung Brief und Paket '
				+ einrichtungsprozess.Filiale__r.ASt_Name__c;
	}
	
	public Oeffnungszeiten__c getMontag(){
		return filialOeffnungszeiten[0];
	}
	
	public Oeffnungszeiten__c getDienstag(){
		return filialOeffnungszeiten[1];
	}
	
	public Oeffnungszeiten__c getMittwoch(){
		return filialOeffnungszeiten[2];
	}
	
	public Oeffnungszeiten__c getDonnerstag(){
		return filialOeffnungszeiten[3];
	}
	
	public Oeffnungszeiten__c getFreitag(){
		return filialOeffnungszeiten[4];
	}
	
	public Oeffnungszeiten__c getSamstag(){
		return filialOeffnungszeiten[5];
	}
	
	public Oeffnungszeiten__c getSonntag(){
		return filialOeffnungszeiten[6];
	}
	
	private void createOeffnungszeiten () {
		filialOeffnungszeiten = [
				SELECT
						Name,
						Id,
						Kategorie__c,
						Wochentag__c,
						vm_von__c,
						vm_bis__c,
						nm_von__c,
						nm_bis__c,
						Account__c
				FROM Oeffnungszeiten__c
				WHERE Account__c = :einrichtungsprozess.Filiale__c
				AND Kategorie__c = 'Filialöffnungszeiten'
				ORDER BY Name ASC NULLS LAST
		];
		if ( filialOeffnungszeiten.size() == 0 ) {
			filialOeffnungszeiten = OeffnungszeitService.getDefinitionsByAccountId( einrichtungsprozess.Filiale__c );
			insert filialOeffnungszeiten;
		}
		else if ( filialOeffnungszeiten.size() > 0 && !einrichtungsprozess.Filiale__r.FehlendeFactsOez__c ) {
			filialOeffnungszeiten = OeffnungszeitService.getDefinitionsByAccountId( einrichtungsprozess.Filiale__c );
		}
		else{
			//Sonarqube --> do nothing
		}
	}
}