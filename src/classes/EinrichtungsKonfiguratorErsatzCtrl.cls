/**
 *@author       Mats Böhler
 *@created      05.04.2021
 *
 *
 *@description  EinrichtungsprozessErsatzCtrl
 *
 *
 *@changelog    05.04.2021 Mats Böhler  - Created
 *              
 * 
 */
public with sharing class EinrichtungsKonfiguratorErsatzCtrl extends EinrichtungsKonfiguratorBaseCtrl {
	
	@AuraEnabled
	public static String init (
			String oz,
			String vertriebssegment,
			String anzahlSchalter,
			String variant,
			String accountId ) {
		
		EinrichtungsKonfiguratorErsatzCtrl instance = new EinrichtungsKonfiguratorErsatzCtrl();
		
		try {
			instance.oz = oz;
			instance.accountId = accountId;
			instance.vertriebssegment = vertriebssegment;
			instance.anzahlSchalter = anzahlSchalter.isNumeric() ? Decimal.valueOf( anzahlSchalter ) : null;
			instance.variant = variant;
			instance.process = 'Neubestellung';
			instance.setResponseVariables();
			instance.loadPicturesByProductIds();
			instance.loadExistingAusstattung();
			instance.loadCategories();
			insert instance.newFilialausstattungen;
			instance.setParentRelationships();
			instance.response.categories = instance.categories;
		}
		catch ( Exception e ) {
			throw new AuraHandledException( e.getMessage() );
		}
		return JSON.serialize( instance.response );
	}
	
	@AuraEnabled(Cacheable=true)
	public static List<LookupSearchResult> searchProducts ( String searchTerm, List<String> selectedIds, String categoryTitle ) {
		
		List<LookupSearchResult> results = new List<LookupSearchResult>();
		searchTerm = '%' + DynamicQuery.removeRestrictedCharacters(searchTerm) + '%';
		for ( Produktoption__c product : [
				SELECT
						Option__c,
						Option__r.Name,
						Option__r.Family
				FROM Produktoption__c
				WHERE Option__r.Name LIKE :searchTerm
				AND Geloescht__c = FALSE
				AND Product__r.Family = 'Vorgängerfiliale'
				AND Kategorie__c = :categoryTitle
		] ) {
			results.add(
					new LookupSearchResult(
							product.Option__c,
							'Product2',
							'standard:product',
							product.Option__r.Name,
							product.Option__r.Family
					)
			);
		}
		results.sort();
		return results;
	}
	
	@AuraEnabled
	public static void saveReplacement ( String accountId, String optionId, String productId ) {
		
		EinrichtungsKonfiguratorErsatzCtrl instance = new EinrichtungsKonfiguratorErsatzCtrl();
		
		try {
			instance.accountId = accountId;
			instance.saveReplacementProduct( optionId, productId );
		}
		catch ( Exception e ) {
			
			throw new AuraHandledException( e.getMessage() );
		}
	}
	
	@AuraEnabled
	public static void saveOptionsState ( String accountId, String selectedOptionsString, String deselectedOptionsString ) {
		
		Savepoint savepoint = Database.setSavepoint();
		EinrichtungsKonfiguratorErsatzCtrl instance = new EinrichtungsKonfiguratorErsatzCtrl();
		
		try {
			instance.accountId = accountId;
			instance.createNewFilialausstattungen(
					( List<Option> ) JSON.deserialize( selectedOptionsString, List<Option>.class )
			);
			insert instance.newFilialausstattungen;
			instance.setParentRelationships();
			
			instance.findOptionIdsForDeletion(
					( List<Option> ) JSON.deserialize( deselectedOptionsString, List<Option>.class )
			);
			instance.deleteExistingFilialausstattungen();
		}
		catch ( Exception e ) {
			Database.rollback( savepoint );
			throw new AuraHandledException( e.getMessage() );
		}
	}
	
	@AuraEnabled
	public static void saveOptionQuantity ( String accountId, String optionString ) {
		Savepoint savepoint = Database.setSavepoint();
		EinrichtungsKonfiguratorErsatzCtrl instance = new EinrichtungsKonfiguratorErsatzCtrl();
		
		try {
			instance.accountId = accountId;
			instance.saveOption( optionString );
		}
		catch ( Exception e ) {
			Database.rollback( savepoint );
			throw new AuraHandledException( e.getMessage() );
		}
	}
	
	private void saveReplacementProduct ( String optionId, String productId ) {
		Filialausstattung__c filialausstattung = [
				SELECT
						Id
				FROM Filialausstattung__c
				WHERE Filiale__c = :accountId
				AND Produktoption__c = :optionId
				AND Vorgemerkt__c = :getVorgemerktValue()
		];
		
		filialausstattung.ErsatzFuer__c = productId;
		update filialausstattung;
	}
	
	private void createNewFilialausstattungen ( List<Option> selectedOptions ) {
		
		List<Option> selectedChildOptions = new List<Option>();
		for ( Option option : selectedOptions ) {
			Filialausstattung__c filialausstattung = new Filialausstattung__c(
					Name = NameFieldLimiter.getValue( option.product.Option__r.Name ),
					Filiale__c = accountId,
					Produkt__c = option.product.Option__c,
					Produktoption__c = option.product.Id,
					Menge__c = option.quantity,
					Produktbuendeloption__c = option.product.Produktbuendeloption__c,
					Vorgemerkt__c = getVorgemerktValue()
			);
			
			newFilialausstattungen.add( filialausstattung );
			filialausstattungByOptionIds.put( option.product.Id, filialausstattung );
			for ( Option childOption : option.options ) {
				if ( childOption.isSelected ) {
					selectedChildOptions.add( childOption );
				}
			}
		}
		if ( !selectedChildOptions.isEmpty() ) {
			createNewFilialausstattungen( selectedChildOptions );
		}
	}
	
	private List<Produktoption__c> loadFirstLevelOptions () {
		return [
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
						Option__r.Lagerprodukt__c,
						mitPostfach__c,
						mitPaketausgabe__c,
						Zusatzinformationen__c
				FROM Produktoption__c
				WHERE Option__r.IsActive = TRUE
				AND Geloescht__c = FALSE
				AND istErsatz__c = TRUE
				AND
				( (
						Product__r.Family = :process
						AND OZ__c = :oz
						AND Vertriebssegment__c = :vertriebssegment
						AND AnzahlSchalter__c = :anzahlSchalter
				)
				OR ( mitPostfach__c = TRUE OR mitPaketausgabe__c = TRUE)
				)
				AND Product__r.IsActive = TRUE
				ORDER BY Nummerierung__c ASC NULLS LAST
		];
	}
	
	private void loadCategories () {
		Map<String, List<Produktoption__c>> produktoptionenByCategories = new Map<String, List<Produktoption__c>>();
		Map<String, Produktoption__c> productOptionByOptionId = new Map<String, Produktoption__c>();
		for ( Produktoption__c option : loadFirstLevelOptions() ) {
			
			if ( option.mitPostfach__c && !response.mitPostfach ) {
				continue;
			}
			if ( option.mitPaketausgabe__c && !response.mitPaketausgabe ) {
				continue;
			}
			if ( produktoptionenByCategories.containsKey( option.Option__r.Family ) ) {
				produktoptionenByCategories.get( option.Option__r.Family ).add( option );
			}
			else {
				produktoptionenByCategories.put( option.Option__r.Family, new List<Produktoption__c> {
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
	
	private void buildCategories ( Map<String, List<Produktoption__c>> produktoptionenByCategories ) {
		for ( String categoryTitle : produktoptionenByCategories.keySet() ) {
			Category category = new Category( categoryTitle );
			
			for ( Produktoption__c produktoption : produktoptionenByCategories.get( categoryTitle ) ) {
				Option option = new Option(
						produktoption.Product__c,
						getPictureId( produktoption.Option__c ),
						isSelectedTopLevel( produktoption ),
						getQuantity( produktoption ),
						produktoption
				);
				option.quantityDisabled = false;
				if ( ausstattungByProductoptionIds.containsKey( produktoption.Id ) ) {
					option.replacementId = ausstattungByProductoptionIds.get( produktoption.Id ).ErsatzFuer__c;
					option.replacementTitle = ausstattungByProductoptionIds.get( produktoption.Id ).ErsatzFuer__r.Name;
					option.replacementSubtitle = ausstattungByProductoptionIds.get( produktoption.Id ).ErsatzFuer__r.Family;
				}
				category.products.add(
						option
				);
				response.optionByIds.put( produktoption.Id, option );
			}
			categories.add( category );
		}
	}
	
	private Boolean isSelectedTopLevel ( Produktoption__c produktoption ) {
		
		return ausstattungByProductoptionIds.containsKey( produktoption.Id );
	}
	
	private void loadProductStructure ( Map<String, Produktoption__c> productOptionByOptionId ) {
		
		Boolean keepLoading = true;
		Integer productLevel = 1;
		Set<String> productBundleOptionIds = productOptionByOptionId.keySet();
		while ( keepLoading ) {
			
			Map<String, List<Produktoption__c>> produktoptionenByParentProductOptionId
					= loadOptionsByParentProductOptionIds( productBundleOptionIds );
			productBundleOptionIds = new Set<String>();
			for ( String parentProductOptionId : produktoptionenByParentProductOptionId.keySet() ) {
				
				for ( Produktoption__c produktoption : produktoptionenByParentProductOptionId.get( parentProductOptionId ) ) {
					Option option = new Option(
							parentProductOptionId,
							getPictureId( produktoption.Option__c ),
							isSelected( produktoption ),
							getQuantity( produktoption ),
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
	
	protected override String getVorgemerktValue () {
		return 'in Ersatzbestellung';
	}
}