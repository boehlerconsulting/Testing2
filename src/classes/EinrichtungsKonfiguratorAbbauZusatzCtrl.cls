/**
 *@author       Mats Böhler
 *@created      20.04.2021
 *
 *
 *@description  EinrichtungsKonfiguratorAbbauZusatzCtrl
 *
 *
 *@changelog    20.04.2021 Mats Böhler  - Created
 *              
 * 
 */
public with sharing class EinrichtungsKonfiguratorAbbauZusatzCtrl extends EinrichtungsKonfiguratorBaseCtrl {
	
	@AuraEnabled
	public static String init ( String accountId ) {
		
		EinrichtungsKonfiguratorAbbauZusatzCtrl instance = new EinrichtungsKonfiguratorAbbauZusatzCtrl();
		
		try {
			instance.accountId = accountId;
			instance.loadPicturesByProductIds();
			instance.loadExistingAusstattung();
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
		EinrichtungsKonfiguratorAbbauZusatzCtrl instance = new EinrichtungsKonfiguratorAbbauZusatzCtrl();
		
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
		EinrichtungsKonfiguratorAbbauZusatzCtrl instance = new EinrichtungsKonfiguratorAbbauZusatzCtrl();
		
		try {
			instance.accountId = accountId;
			instance.saveOptionQuantityAbbauZusatz( optionString );
		}
		catch ( Exception e ) {
			Database.rollback( savepoint );
			throw new AuraHandledException( e.getMessage() );
		}
	}
	
	private void saveOptionQuantityAbbauZusatz ( String optionString ) {
		
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
		saveOptionQuantityAbbauZusatz( new List<Option> {
				option
		} );
		update filialausstattungByOptionIds.values();
	}
	
	private void saveOptionQuantityAbbauZusatz ( List<Option> options ) {
		
		for ( Option option : options ) {
			if ( filialausstattungByOptionIds.containsKey( option.product.Id ) ) {
				filialausstattungByOptionIds.get( option.product.Id ).Menge__c = option.quantityAbbau;
				filialausstattungByOptionIds.get( option.product.Id ).Menge_Abbau__c = option.quantityAbbau;
				filialausstattungByOptionIds.get( option.product.Id ).Menge_Wiedereinsatzfaehig__c = option.quantityWiedereinsatzfaehig;
			}
			saveOptionQuantityAbbauZusatz( option.options );
		}
	}
	
	@AuraEnabled
	public static void saveOptionWiedereinsatzfaehig ( String accountId, String optionString ) {
		Savepoint savepoint = Database.setSavepoint();
		EinrichtungsKonfiguratorAbbauZusatzCtrl instance = new EinrichtungsKonfiguratorAbbauZusatzCtrl();
		
		try {
			instance.accountId = accountId;
			instance.saveOption( optionString );
		}
		catch ( Exception e ) {
			Database.rollback( savepoint );
			throw new AuraHandledException( e.getMessage() );
		}
	}
	
	private void createNewFilialausstattungen ( List<Option> selectedOptions ) {
		Set<Id> productOptionIds = new Set<Id>();
		for ( Filialausstattung__c filialausstattung : [
				SELECT
						Produktoption__c
				FROM Filialausstattung__c
				WHERE Filiale__c = :accountId
				AND Vorgemerkt__c = :getVorgemerktValue()
		] ) {
			
			productOptionIds.add( filialausstattung.Produktoption__c );
		}
		List<Option> selectedChildOptions = new List<Option>();
		for ( Option option : selectedOptions ) {
			if ( !productOptionIds.contains( option.product.Id ) ) {
				Filialausstattung__c filialausstattung = new Filialausstattung__c(
						Name = NameFieldLimiter.getValue(option.product.Option__r.Name),
						Filiale__c = accountId,
						Produkt__c = option.product.Option__c,
						Produktoption__c = option.product.Id,
						Menge__c = option.quantityAbbau,
						Menge_Abbau__c = option.quantityAbbau,
						Menge_Wiedereinsatzfaehig__c = option.quantityWiedereinsatzfaehig,
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
				AND Product__r.Family = 'Vorgängerfiliale'
				AND Product__r.IsActive = TRUE
				ORDER BY Nummerierung__c ASC NULLS LAST
		];
	}
	
	private void loadCategories () {
		Map<String, List<Produktoption__c>> produktoptionenByCategories = new Map<String, List<Produktoption__c>>();
		Map<String, Produktoption__c> productOptionByOptionId = new Map<String, Produktoption__c>();
		for ( Produktoption__c option : loadFirstLevelOptions() ) {
			
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
						produktoption,
						getMengeAbbau( produktoption ),
						getMengeWiedereinsatzfaehig( produktoption )
				);
				category.products.add(
						option
				);
				response.optionByIds.put( produktoption.Id, option );
			}
			categories.add( category );
		}
	}
	
	private Decimal getMengeWiedereinsatzfaehig ( Produktoption__c produktoption ) {
		return ausstattungByProductoptionIds.containsKey( produktoption.Id )
				? ausstattungByProductoptionIds.get( produktoption.Id ).Menge_Wiedereinsatzfaehig__c
				: null ;
	}
	
	private Decimal getMengeAbbau ( Produktoption__c produktoption ) {
		return ausstattungByProductoptionIds.containsKey( produktoption.Id )
				? ausstattungByProductoptionIds.get( produktoption.Id ).Menge_Abbau__c
				: null ;
	}
	
	private Boolean isSelectedTopLevel ( Produktoption__c produktoption ) {
		
		return ausstattungByProductoptionIds.containsKey( produktoption.Id );
	}
	
	protected override void buildProductStructure ( List<Option> options ) {
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
	
	private void loadProductStructure ( Map<String, Produktoption__c> productOptionByOptionId ) {
		
		Boolean keepLoading = true;
		Integer productLevel = 1;
		Set<String> productBundleOptionIds = productOptionByOptionId.keySet();
		while ( keepLoading ) {
			
			Map<String, List<Produktoption__c>> produktoptionenByParentProductOptionId = loadOptionsByParentProductOptionIds( productBundleOptionIds );
			productBundleOptionIds = new Set<String>();
			for ( String parentProductOptionId : produktoptionenByParentProductOptionId.keySet() ) {
				
				for ( Produktoption__c produktoption : produktoptionenByParentProductOptionId.get( parentProductOptionId ) ) {
					Option option = new Option(
							parentProductOptionId,
							getPictureId( produktoption.Option__c ),
							true,
							getQuantity( produktoption ),
							produktoption,
							getMengeAbbau( produktoption ),
							getMengeWiedereinsatzfaehig( produktoption )
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
		return 'in Abbau zusätzlich';
	}
}