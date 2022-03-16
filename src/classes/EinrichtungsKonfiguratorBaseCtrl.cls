/**
 *@author       Mats Böhler
 *@created      05.05.2021
 *
 *
 *@description  EinrichtungsKonfiguratorBaseCtrl
 *
 *
 *@changelog    05.05.2021 Mats Böhler  - Created
 *              
 * 
 */
public with sharing virtual class EinrichtungsKonfiguratorBaseCtrl {
	
	@TestVisible
	protected InitializationResponse response = new InitializationResponse();
	protected String oz = '';
	protected String vertriebssegment = '';
	protected Decimal anzahlSchalter = 0;
	protected String variant = '';
	protected String einrichtungsprozessId = '';
	protected String process = '';
	protected String accountId = '';
	protected List<Category> categories = new List<Category>();
	protected Map<Id, Filialausstattung__c> ausstattungByProductoptionIds = new Map<Id, Filialausstattung__c>();
	protected Map<Id, Id> contentDocumentIdByProductIds = new Map<Id, Id>();
	protected Map<String, List<Option>> optionsByParentProductOptionId = new Map<String, List<Option>>();
	protected Integer highestProductStructureLevel = 0;
	protected List<Filialausstattung__c> newFilialausstattungen = new List<Filialausstattung__c>();
	protected Map<Id, Filialausstattung__c> filialausstattungByOptionIds = new Map<Id, Filialausstattung__c>();
	protected List<Filialausstattung__c> existingFilialausstattungsForDeletion = new List<Filialausstattung__c>();
	protected Set<Id> optionIdsForDeletion = new Set<Id>();
	
	protected void setResponseVariables () {
		if ( process == 'Vorgängerfiliale' ) {
			return;
		}
		Account account = [
				SELECT
						Id,
						PostfachanlageCheckbox__c,
						Paketausgabe__c,
						Postfach_Betreiber__c,
						ASt_ID__c,
						Lead__c,
						Lead__r.Filialnetzaenderung__c,
						Lead__r.Filialnetzaenderung__r.mit_Postfachanlage__c,
						Lead__r.Filialnetzaenderung__r.Netzentscheidung__c
				FROM Account
				WHERE Id = :accountId
		];
		
		List<Filialnetzaenderung__c> filialnetzaenderungs = [
				SELECT
						Netzentscheidung__c
				FROM Filialnetzaenderung__c
				WHERE Filiale_Filialpartner__r.ASt_ID__c = :account.ASt_ID__c
				ORDER BY CreatedDate DESC
				LIMIT 1
		];
		Filialnetzaenderung__c latestFnaeOfAccount = ( filialnetzaenderungs.size() == 1 ) ? filialnetzaenderungs.get( 0 ) : null;
		
		if ( String.isNotBlank( account.Postfach_Betreiber__c ) ) {
			response.mitPostfach = account.Postfach_Betreiber__c == 'Partner';
		}
		else if ( latestFnaeOfAccount != null && account.Lead__r.Filialnetzaenderung__c != null ) {
			response.mitPostfach = account.Lead__r.Filialnetzaenderung__r.mit_Postfachanlage__c == 'mit Postfach'
					|| latestFnaeOfAccount.Netzentscheidung__c == 'Integration Postfachanlage';
		}
		else if ( account.Lead__r.Filialnetzaenderung__c != null ) {
			response.mitPostfach = account.Lead__r.Filialnetzaenderung__r.mit_Postfachanlage__c == 'mit Postfach';
		}
		else if ( latestFnaeOfAccount != null ) {
			response.mitPostfach = latestFnaeOfAccount.Netzentscheidung__c == 'Integration Postfachanlage';
		}
		else {
			response.mitPostfach = false;
		}
		response.mitPaketausgabe = account.Paketausgabe__c;
	}
	
	protected void loadPicturesByProductIds () {
		Map<Id, Product2> productByIds = new Map<Id, Product2>( [
				SELECT
						Id
				FROM Product2
				WHERE Family != 'Dummy'
				AND IsActive = TRUE
		] );
		if ( !productByIds.keySet().isEmpty() ) {
			for ( ContentDocumentLink contentDocumentLink : [
					SELECT
							Id,
							LinkedEntityId,
							ContentDocumentId
					FROM ContentDocumentLink
					WHERE LinkedEntityId IN :productByIds.keySet()
			] ) {
				
				contentDocumentIdByProductIds.put( contentDocumentLink.LinkedEntityId, contentDocumentLink.ContentDocumentId );
			}
		}
	}
	
	protected void loadExistingAusstattung () {
		
		for ( Filialausstattung__c filialausstattung : [
				SELECT
						Id,
						Produktoption__c,
						Menge__c,
						Produktbuendeloption__c,
						Produkt__r.Family,
						BestandVorgaengerfiliale__c,
						ErsatzFuer__c,
						ErsatzFuer__r.Name,
						ErsatzFuer__r.Family,
						Menge_Wiedereinsatzfaehig__c,
						Menge_Abbau__c
				FROM Filialausstattung__c
				WHERE Filiale__c = :accountId
				AND Vorgemerkt__c = :getVorgemerktValue()
		] ) {
			
			ausstattungByProductoptionIds.put( filialausstattung.Produktoption__c, filialausstattung );
			if ( filialausstattung.BestandVorgaengerfiliale__c ) {
				if ( response.existingFilialausstattungByCategoryTitle.containsKey( filialausstattung.Produkt__r.Family ) ) {
					response.existingFilialausstattungByCategoryTitle.get( filialausstattung.Produkt__r.Family ).add( filialausstattung );
				}
				else {
					response.existingFilialausstattungByCategoryTitle.put( filialausstattung.Produkt__r.Family, new List<Filialausstattung__c> {
							filialausstattung
					} );
				}
			}
		}
	}
	
	protected virtual String getVorgemerktValue () {
		return null;
	}
	
	protected void setParentRelationships () {
		for ( Filialausstattung__c filialausstattung : newFilialausstattungen ) {
			filialausstattung.Produktbuendel__c = filialausstattungByOptionIds.containsKey( filialausstattung.Produktbuendeloption__c )
					? filialausstattungByOptionIds.get( filialausstattung.Produktbuendeloption__c ).Id
					: ausstattungByProductoptionIds.containsKey( filialausstattung.Produktbuendeloption__c )
							? ausstattungByProductoptionIds.get( filialausstattung.Produktbuendeloption__c ).Id
							: null;
		}
		update newFilialausstattungen;
	}
	
	protected void saveOption ( String optionString ) {
		
		for ( Filialausstattung__c filialausstattung : [
				SELECT
						Id,
						Produktoption__c
				FROM Filialausstattung__c
				WHERE Filiale__c = :accountId
				AND Vorgemerkt__c = :getVorgemerktValue()
		] ) {
			
			filialausstattungByOptionIds.put( filialausstattung.Produktoption__c, filialausstattung );
		}
		
		Option option = ( Option ) JSON.deserialize( optionString, Option.class );
		saveOption( new List<Option> {
				option
		} );
		update filialausstattungByOptionIds.values();
	}
	
	private void saveOption ( List<Option> options ) {
		
		for ( Option option : options ) {
			if ( filialausstattungByOptionIds.containsKey( option.product.Id ) ) {
				filialausstattungByOptionIds.get( option.product.Id ).Menge__c = option.quantity;
				filialausstattungByOptionIds.get( option.product.Id ).Menge_Abbau__c = option.quantityAbbau;
				filialausstattungByOptionIds.get( option.product.Id ).Menge_Wiedereinsatzfaehig__c = option.quantityWiedereinsatzfaehig;
			}
			saveOption( option.options );
		}
	}
	
	protected void findOptionIdsForDeletion ( List<Option> deselectedOptions ) {
		
		List<Option> deselectedChildOptions = new List<Option>();
		for ( Option option : deselectedOptions ) {
			optionIdsForDeletion.add( option.product.Id );
			for ( Option childOption : option.options ) {
				if ( childOption.isSelected ) {
					deselectedChildOptions.add( childOption );
				}
			}
		}
		if ( !deselectedChildOptions.isEmpty() ) {
			findOptionIdsForDeletion( deselectedChildOptions );
		}
	}
	
	protected void deleteExistingFilialausstattungen () {
		
		for ( Filialausstattung__c filialausstattung : [
				SELECT
						Id
				FROM Filialausstattung__c
				WHERE Filiale__c = :accountId
				AND Produktoption__c IN :optionIdsForDeletion
				AND Vorgemerkt__c = :getVorgemerktValue()
		] ) {
			
			existingFilialausstattungsForDeletion.add( filialausstattung );
		}
		
		if ( !existingFilialausstattungsForDeletion.isEmpty() ) {
			delete existingFilialausstattungsForDeletion;
			Database.emptyRecycleBin( existingFilialausstattungsForDeletion );
		}
	}
	
	protected virtual void buildProductStructure ( List<Option> options ) {
		for ( Option option : options ) {
			
			if ( optionsByParentProductOptionId.containsKey( option.product.Id ) ) {
				
				option.options.addAll( optionsByParentProductOptionId.get( option.product.Id ) );
				if ( option.options.size() > 0 ) {
					option.hasOptions = true;
					option.showConfiguration = true;
					buildProductStructure( option.options );
				}
			}
		}
	}
	
	protected Boolean isSelected ( Produktoption__c produktoption ) {
		
		return ausstattungByProductoptionIds.containsKey( produktoption.Id ) || produktoption.Standard__c;
	}
	
	protected Decimal getQuantity ( Produktoption__c produktoption ) {
		return ausstattungByProductoptionIds.containsKey( produktoption.Id )
				? ausstattungByProductoptionIds.get( produktoption.Id ).Menge__c
				: produktoption.Menge__c ;
	}
	
	protected String getPictureId ( Id productId ) {
		return contentDocumentIdByProductIds.containsKey( productId )
				? contentDocumentIdByProductIds.get( productId )
				: null;
	}
	
	protected Map<String, List<Produktoption__c>> loadOptionsByParentProductOptionIds ( Set<String> productBundleOptionIds ) {
		Map<String, List<Produktoption__c>> optionsByParentProductOptionId = new Map<String, List<Produktoption__c>>();
		
		for ( Produktoption__c option : [
				SELECT
						Id,
						Name,
						Option__c,
						Option__r.Family,
						Option__r.Description,
						Option__r.Zusatzinformationen__c,
						Option__r.GetBotKategorie__c,
						Option__r.ProductCode,
						Option__r.Lieferant__c,
						Nummerierung__c,
						Option__r.Name,
						Standard__c,
						Menge__c,
						Menge_editierbar__c,
						Product__c,
						Auswahl_editierbar__c,
						Produktbuendeloption__c,
						Product__r.Family,
						Option__r.Lagerprodukt__c,
						Zusatzinformationen__c
				FROM Produktoption__c
				WHERE Option__r.IsActive = TRUE
				AND Geloescht__c = FALSE
				AND Produktbuendeloption__c IN :productBundleOptionIds
				ORDER BY Nummerierung__c ASC NULLS LAST
		] ) {
			
			if ( optionsByParentProductOptionId.containsKey( option.Produktbuendeloption__c ) ) {
				optionsByParentProductOptionId.get( option.Produktbuendeloption__c ).add( option );
			}
			else {
				optionsByParentProductOptionId.put( option.Produktbuendeloption__c, new List<Produktoption__c> {
						option
				} );
			}
		}
		
		return optionsByParentProductOptionId;
	}
	
	public class InitializationResponse {
		public List<Category> categories = new List<Category>();
		public Map<String, Option> optionByIds = new Map<String, Option>();
		public Map<String, List<Filialausstattung__c>> existingFilialausstattungByCategoryTitle = new Map<String, List<Filialausstattung__c>>();
		public Boolean isEinrichtungskoordinator = FeatureManagement.checkPermission( 'Einrichtungskoordinator' );
		public Boolean mitPostfach = false;
		public Boolean mitPaketausgabe = false;
	}
	
	public class Category {
		public String title;
		public Boolean hide = false;
		public List<Option> products = new List<Option>();
		
		public Category ( String title ) {
			this.title = title;
		}
	}
	
	public class Option {
		public String parentProductId;
		public Produktoption__c product;
		public String pictureId;
		public Boolean isSelected = false;
		public Boolean hasPicture = false;
		public Boolean hasOptions = false;
		public Boolean hasAdditionalInformation = false;
		public Boolean showConfiguration = false;
		public Boolean isSelectionDisabled = false;
		public Decimal quantity = 0;
		public Decimal originalQuantity = 0;
		public Decimal quantityAbbau = null;
		public Decimal quantityWiedereinsatzfaehig = null;
		public Boolean quantityDisabled = false;
		public List<Option> options = new List<Option>();
		public String name;
		public String replacementId;
		public String replacementTitle;
		public String replacementSubtitle;
		public String zusatzinformationen;
		
		public Option (
				String parentProductId,
				String pictureId,
				Boolean isSelected,
				Decimal quantity,
				Produktoption__c product ) {
			this.parentProductId = parentProductId;
			this.pictureId = pictureId;
			this.hasPicture = String.isNotBlank( pictureId );
			this.isSelected = isSelected;
			this.quantity = quantity;
			this.originalQuantity = product.Menge__c;
			this.quantityDisabled = !product.Menge_editierbar__c;
			this.product = product;
			this.hasAdditionalInformation = product.Zusatzinformationen__c != null;
			this.showConfiguration = this.hasPicture || this.hasOptions || this.hasAdditionalInformation;
			this.isSelectionDisabled = !product.Auswahl_editierbar__c
					|| ( product.Option__r.Lagerprodukt__c
					&& !FeatureManagement.checkPermission( 'Einrichtungskoordinator' ) ) ;
			this.name = product.Option__r.Lagerprodukt__c ? 'Lager: ' + product.Option__r.Name : product.Option__r.Name;
		}
		
		public Option (
				String parentProductId,
				String pictureId,
				Boolean isSelected,
				Decimal quantity,
				Produktoption__c product,
				Decimal quantityAbbau,
				Decimal quantityWiedereinsatzfaehig ) {
			
			this.parentProductId = parentProductId;
			this.pictureId = pictureId;
			this.hasPicture = String.isNotBlank( pictureId );
			this.isSelected = isSelected;
			this.quantity = quantity;
			this.originalQuantity = product.Menge__c;
			this.quantityAbbau = quantityAbbau;
			this.quantityWiedereinsatzfaehig = quantityWiedereinsatzfaehig;
			this.quantityDisabled = !product.Menge_editierbar__c;
			this.product = product;
			this.hasAdditionalInformation = product.Zusatzinformationen__c != null;
			this.showConfiguration = this.hasPicture || this.hasAdditionalInformation;
			this.isSelectionDisabled = !product.Auswahl_editierbar__c
					|| ( product.Option__r.Lagerprodukt__c
					&& !FeatureManagement.checkPermission( 'Einrichtungskoordinator' ) ) ;
			this.name = product.Option__r.Lagerprodukt__c ? 'Lager: ' + product.Option__r.Name : product.Option__r.Name;
			this.zusatzinformationen = product.Zusatzinformationen__c;
		}
	}
}