/**
 *@author       Mats Böhler
 *@created      14.04.2021
 *
 *
 *@description  EinrichtungsKonfiguratorAbbauCtrl
 *
 *
 *@changelog    14.04.2021 Mats Böhler  - Created
 *              
 * 
 */
public with sharing class EinrichtungsKonfiguratorAbbauCtrl {
	
	private InitializationResponse response = new InitializationResponse();
	private List<Category> categories = new List<Category>();
	private String accountId = '';
	private Map<Id, Id> contentDocumentIdByProductIds = new Map<Id, Id>();
	private Map<String, List<Option>> optionsByParentProductOptionId = new Map<String, List<Option>>();
	private Integer highestProductStructureLevel = 0;
	private List<Filialausstattung__c> newFilialausstattungen = new List<Filialausstattung__c>();
	
	@AuraEnabled
	public static String init ( String accountId ) {
		
		EinrichtungsKonfiguratorAbbauCtrl instance = new EinrichtungsKonfiguratorAbbauCtrl();
		
		try {
			instance.accountId = accountId;
			instance.loadPicturesByProductIds();
			instance.loadCategories();
			instance.response.categories = instance.categories;
		}
		catch ( Exception e ) {
			
			throw new AuraHandledException( e.getMessage() );
		}
		return JSON.serialize( instance.response );
	}
	
	@AuraEnabled
	public static void saveOptionsState ( String accountId, String selectedOptionsString, String deselectedOptionsString ) {
		Savepoint savepoint = Database.setSavepoint();
		EinrichtungsKonfiguratorAbbauCtrl instance = new EinrichtungsKonfiguratorAbbauCtrl();
		
		try {
			
			instance.accountId = accountId;
			instance.updateNewFilialausstattungen(
					( List<Option> ) JSON.deserialize( selectedOptionsString, List<Option>.class )
			);
			
			instance.updateNewFilialausstattungenDeselected(
					( List<Option> ) JSON.deserialize( deselectedOptionsString, List<Option>.class )
			);
			update instance.newFilialausstattungen;
		}
		catch ( Exception e ) {
			Database.rollback( savepoint );
			throw new AuraHandledException( e.getMessage() );
		}
	}
	
	@AuraEnabled
	public static void saveOptionQuantity ( String accountId, String optionString ) {
		Savepoint savepoint = Database.setSavepoint();
		EinrichtungsKonfiguratorAbbauCtrl instance = new EinrichtungsKonfiguratorAbbauCtrl();
		
		try {
			instance.accountId = accountId;
			instance.saveOption( optionString );
		}
		catch ( Exception e ) {
			Database.rollback( savepoint );
			throw new AuraHandledException( e.getMessage() );
		}
	}
	
	private void saveOption ( String optionString ) {
		
		Option option = ( Option ) JSON.deserialize( optionString, Option.class );
		saveOption( new List<Option> {
				option
		} );
		update newFilialausstattungen;
	}
	
	private void saveOption ( List<Option> options ) {

		for ( Option option : options ) {
			
			newFilialausstattungen.add(
					new Filialausstattung__c(
							Id = option.product.Id,
							Menge__c = option.quantity,
							Menge_Abbau__c = option.quantityAbbau,
							Menge_Wiedereinsatzfaehig__c = option.quantityWiedereinsatzfaehig
					)
			);
			saveOption( option.options );
		}
	}
	
	private void updateNewFilialausstattungen ( List<Option> selectedOptions ) {
		
		List<Option> selectedChildOptions = new List<Option>();
		for ( Option option : selectedOptions ) {
			Filialausstattung__c filialausstattung = new Filialausstattung__c(
					Id = option.product.Id,
					Vorgemerkt__c = getVorgemerktValue(),
					Menge_Abbau__c = option.quantityAbbau
			);
			
			newFilialausstattungen.add( filialausstattung );
			for ( Option childOption : option.options ) {
				if ( childOption.isSelected ) {
					selectedChildOptions.add( childOption );
				}
			}
		}
		if ( !selectedChildOptions.isEmpty() ) {
			updateNewFilialausstattungen( selectedChildOptions );
		}
	}
	
	private void updateNewFilialausstattungenDeselected ( List<Option> selectedOptions ) {
		
		List<Option> selectedChildOptions = new List<Option>();
		for ( Option option : selectedOptions ) {
			Filialausstattung__c filialausstattung = new Filialausstattung__c(
					Id = option.product.Id,
					Vorgemerkt__c = ''
			);
			
			newFilialausstattungen.add( filialausstattung );
			for ( Option childOption : option.options ) {
				if ( childOption.isSelected ) {
					selectedChildOptions.add( childOption );
				}
			}
		}
		if ( !selectedChildOptions.isEmpty() ) {
			updateNewFilialausstattungenDeselected( selectedChildOptions );
		}
	}
	
	private List<Filialausstattung__c> loadFirstLevelOptions () {
		return [
				SELECT
						Id,
						Name,
						Produktoption__r.Option__c,
						Produktoption__r.Option__r.Family,
						Produktoption__r.Option__r.Description,
						Produktoption__r.Option__r.Zusatzinformationen__c,
						Produktoption__r.Option__r.GetBotKategorie__c,
						Produktoption__r.Option__r.ProductCode,
						Produktoption__r.Option__r.Lieferant__c,
						Produktoption__r.Nummerierung__c,
						Produktoption__r.Option__r.Name,
						Produktoption__r.Standard__c,
						Menge__c,
						Produktoption__r.Menge_editierbar__c,
						Produktoption__r.Product__c,
						Produktoption__r.Auswahl_editierbar__c,
						Produktbuendeloption__c,
						Produktoption__r.Option__r.Lagerprodukt__c,
						Produktoption__r.mitPostfach__c,
						Produktoption__r.mitPaketausgabe__c,
						Produktoption__r.Zusatzinformationen__c,
						Vorgemerkt__c,
						Produktoption__c,
						Produktbuendel__c,
						Menge_Abbau__c,
						Menge_Wiedereinsatzfaehig__c
				FROM Filialausstattung__c
				WHERE Produktbuendeloption__c = NULL
				AND Filiale__c = :accountId
				AND ( Vorgemerkt__c = :getVorgemerktValue() OR Vorgemerkt__c = NULL)
				ORDER BY Produktoption__r.Nummerierung__c ASC NULLS LAST
		];
	}
	
	private void loadCategories () {
		Map<String, List<Filialausstattung__c>> produktoptionenByCategories = new Map<String, List<Filialausstattung__c>>();
		Map<String, Filialausstattung__c> productOptionByOptionId = new Map<String, Filialausstattung__c>();
		
		for ( Filialausstattung__c option : loadFirstLevelOptions() ) {
			
			if ( produktoptionenByCategories.containsKey( option.Produktoption__r.Option__r.Family ) ) {
				produktoptionenByCategories.get( option.Produktoption__r.Option__r.Family ).add( option );
			}
			else {
				produktoptionenByCategories.put( option.Produktoption__r.Option__r.Family, new List<Filialausstattung__c> {
						option
				} );
			}
			productOptionByOptionId.put( option.Id, option );
		}
		buildCategories( produktoptionenByCategories );
		loadProductStructure( productOptionByOptionId );
		for ( Category category : categories ) {
			buildProductStructure( category.products );
		}
	}
	
	private void buildCategories ( Map<String, List<Filialausstattung__c>> produktoptionenByCategories ) {
		for ( String categoryTitle : produktoptionenByCategories.keySet() ) {
			Category category = new Category( categoryTitle );
			
			for ( Filialausstattung__c produktoption : produktoptionenByCategories.get( categoryTitle ) ) {
				Option option = new Option(
						produktoption.Produktoption__r.Product__c,
						getPictureId( produktoption.Produktoption__r.Option__c ),
						produktoption.Vorgemerkt__c == getVorgemerktValue(),
						produktoption.Menge__c,
						produktoption
				);
				
				category.products.add(
						option
				);
				response.optionByIds.put( produktoption.Id, option );
			}
			categories.add( category );
		}
	}
	
	private String getPictureId ( Id productId ) {
		return contentDocumentIdByProductIds.containsKey( productId )
				? contentDocumentIdByProductIds.get( productId )
				: null;
	}
	
	private void buildProductStructure ( List<Option> options ) {
		for ( Option option : options ) {
			if ( optionsByParentProductOptionId.containsKey( option.product.Id ) ) {
				
				option.options.addAll( optionsByParentProductOptionId.get( option.product.Id ) );
				if ( option.options.size() > 0 ) {
					
					option.hasOptions = false;
					buildProductStructure( option.options );
				}
			}
		}
	}
	
	private void loadProductStructure ( Map<String, Filialausstattung__c> productOptionByOptionId ) {
		
		Boolean keepLoading = true;
		Integer productLevel = 1;
		Set<String> productBundleOptionIds = productOptionByOptionId.keySet();
		while ( keepLoading ) {
			
			Map<String, List<Filialausstattung__c>> produktoptionenByParentProductOptionId
					= loadOptionsByParentProductOptionIds( productBundleOptionIds );
			
			productBundleOptionIds = new Set<String>();
			for ( String parentProductOptionId : produktoptionenByParentProductOptionId.keySet() ) {
				
				for ( Filialausstattung__c produktoption : produktoptionenByParentProductOptionId.get( parentProductOptionId ) ) {
					Option option = new Option(
							parentProductOptionId,
							getPictureId( produktoption.Produktoption__r.Option__c ),
							true,
							produktoption.Menge__c,
							produktoption
					);
					
					response.optionByIds.put( produktoption.Id, option );
					if ( optionsByParentProductOptionId.containsKey( parentProductOptionId ) ) {
						optionsByParentProductOptionId.get( parentProductOptionId ).add( option );
					}
					else {
						optionsByParentProductOptionId.put( parentProductOptionId, new List<Option> {
								option
						} );
					}
					productBundleOptionIds.add( produktoption.Id );
				}
			}
			highestProductStructureLevel = productLevel;
			keepLoading = produktoptionenByParentProductOptionId.keySet().size() > 0;
			productLevel++;
		}
	}
	
	private Map<String, List<Filialausstattung__c>> loadOptionsByParentProductOptionIds ( Set<String> productBundleOptionIds ) {
		Map<String, List<Filialausstattung__c>> optionsByParentProductOptionId = new Map<String, List<Filialausstattung__c>>();
		
		for ( Filialausstattung__c option : [
				SELECT
						Id,
						Name,
						Produktoption__r.Option__c,
						Produktoption__r.Option__r.Family,
						Produktoption__r.Option__r.Description,
						Produktoption__r.Option__r.Zusatzinformationen__c,
						Produktoption__r.Option__r.GetBotKategorie__c,
						Produktoption__r.Option__r.ProductCode,
						Produktoption__r.Option__r.Lieferant__c,
						Produktoption__r.Nummerierung__c,
						Produktoption__r.Option__r.Name,
						Produktoption__r.Standard__c,
						Menge__c,
						Produktoption__r.Menge_editierbar__c,
						Produktoption__r.Product__c,
						Produktoption__r.Auswahl_editierbar__c,
						Produktbuendeloption__c,
						Produktoption__r.Option__r.Lagerprodukt__c,
						Produktoption__r.mitPostfach__c,
						Produktoption__r.mitPaketausgabe__c,
						Produktoption__r.Zusatzinformationen__c,
						Vorgemerkt__c,
						Produktoption__c,
						Produktbuendel__c,
						Menge_Abbau__c,
						Menge_Wiedereinsatzfaehig__c
				FROM Filialausstattung__c
				WHERE Produktbuendel__c IN :productBundleOptionIds
				ORDER BY Produktoption__r.Nummerierung__c ASC NULLS LAST
		] ) {
			
			if ( optionsByParentProductOptionId.containsKey( option.Produktbuendel__c ) ) {
				optionsByParentProductOptionId.get( option.Produktbuendel__c ).add( option );
			}
			else {
				optionsByParentProductOptionId.put( option.Produktbuendel__c, new List<Filialausstattung__c> {
						option
				} );
			}
		}
		
		return optionsByParentProductOptionId;
	}
	
	private void loadPicturesByProductIds () {
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
	
	private String getVorgemerktValue () {
		return 'in Abbau';
	}
	
	@TestVisible
	private class InitializationResponse {
		@TestVisible
		private List<Category> categories = new List<Category>();
		private Map<String, Option> optionByIds = new Map<String, Option>();
		private Boolean isEinrichtungskoordinator = FeatureManagement.checkPermission( 'Einrichtungskoordinator' );
	}
	
	private class Category {
		private String title;
		public List<Option> products = new List<Option>();
		
		public Category ( String title ) {
			this.title = title;
		}
	}
	
	@TestVisible
	private class Option {
		private String parentProductId;
		private Filialausstattung__c product;
		private String pictureId;
		private Boolean isSelected = false;
		private Boolean hasPicture = false;
		private Boolean hasOptions = false;
		private Boolean hasAdditionalInformation = false;
		private Boolean showConfiguration = false;
		private Boolean isSelectionDisabled = false;
		private Decimal quantity = 0;
		private Decimal originalQuantity = 0;
		private Decimal quantityAbbau = 0;
		private Decimal originalQuantityAbbau = 0;
		private Decimal quantityWiedereinsatzfaehig = 0;
		private Decimal originalQuantityWiedereinsatzfaehig = 0;
		private Boolean quantityDisabled = false;
		private List<Option> options = new List<Option>();
		private String name;
		private String zusatzinformationen;
		
		public Option ( String parentProductId, String pictureId, Boolean isSelected, Decimal quantity, Filialausstattung__c product ) {
			this.parentProductId = parentProductId;
			this.pictureId = pictureId;
			this.hasPicture = String.isNotBlank( pictureId );
			this.isSelected = isSelected;
			this.quantity = quantity;
			this.originalQuantity = product.Menge__c;
			this.quantityAbbau = product.Menge_Abbau__c;
			this.originalQuantityAbbau = product.Menge_Abbau__c;
			this.quantityWiedereinsatzfaehig = product.Menge_Wiedereinsatzfaehig__c;
			this.originalQuantityWiedereinsatzfaehig = product.Menge_Wiedereinsatzfaehig__c;
			this.quantityDisabled = false;
			this.product = product;
			this.hasAdditionalInformation = product.Produktoption__r.Zusatzinformationen__c != null;
			this.showConfiguration = this.hasPicture || this.hasAdditionalInformation;
			this.isSelectionDisabled = product.Produktbuendel__c != null;
			this.name = product.Produktoption__r.Option__r.Lagerprodukt__c
					? 'Lager: ' + product.Produktoption__r.Option__r.Name
					: product.Produktoption__r.Option__r.Name;
			this.zusatzinformationen = product.Produktoption__r.Zusatzinformationen__c;
		}
	}
}