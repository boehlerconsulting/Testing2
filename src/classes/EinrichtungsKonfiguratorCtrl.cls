/**
 *@author       Mats Böhler
 *@created      22.02.2021
 *
 *
 *@description  EinrichtungsKonfiguratorCtrl
 *
 *
 *@changelog    22.02.2021 Mats Böhler  - Created
 *              
 * 
 */
public with sharing class EinrichtungsKonfiguratorCtrl extends EinrichtungsKonfiguratorBaseCtrl {
	
	private Einrichtungsprozess__c einrichtungsprozess = new Einrichtungsprozess__c();
	
	@AuraEnabled
	public static String init (
			String oz,
			String vertriebssegment,
			String anzahlSchalter,
			String variant,
			String accountId,
			String process ) {
		
		EinrichtungsKonfiguratorCtrl instance = new EinrichtungsKonfiguratorCtrl();
		
		try {
			instance.oz = oz;
			instance.accountId = accountId;
			instance.vertriebssegment = vertriebssegment;
			instance.anzahlSchalter = anzahlSchalter.isNumeric() ? Decimal.valueOf( anzahlSchalter ) : null;
			instance.variant = variant;
			instance.process = process;
			instance.loadEinrichtungsprozess();
			instance.setResponseVariables();
			instance.loadPicturesByProductIds();
			instance.loadExistingAusstattung();
			instance.loadCategories();
			insert instance.newFilialausstattungen;
			instance.setParentRelationships();
			instance.response.categories = instance.categories;
			if ( process == 'Neubestellung' ) {
				instance.einrichtungsprozess.initialisiert__c = true;
				update instance.einrichtungsprozess;
			}
		}
		catch ( Exception e ) {
			throw new AuraHandledException( e.getMessage() );
		}
		return JSON.serialize( instance.response );
	}
	
	@AuraEnabled
	public static String initWithNewVariant (
			String oz,
			String vertriebssegment,
			String anzahlSchalter,
			String variant,
			String accountId,
			String einrichtungsprozessId,
			String process ) {
		
		Savepoint savepoint = Database.setSavepoint();
		EinrichtungsKonfiguratorCtrl instance = new EinrichtungsKonfiguratorCtrl();
		
		try {
			instance.oz = oz;
			instance.accountId = accountId;
			instance.vertriebssegment = vertriebssegment;
			instance.anzahlSchalter = Decimal.valueOf( anzahlSchalter );
			instance.variant = variant;
			instance.einrichtungsprozessId = einrichtungsprozessId;
			instance.process = process;
			instance.setResponseVariables();
			instance.saveVariant();
			instance.deleteLegacyFilialausstattung();
			instance.loadPicturesByProductIds();
			instance.loadExistingAusstattung();
			instance.loadCategories();
			insert instance.newFilialausstattungen;
			instance.setParentRelationships();
			instance.response.categories = instance.categories;
		}
		catch ( Exception e ) {
			Database.rollback( savepoint );
			throw new AuraHandledException( e.getMessage() );
		}
		return JSON.serialize( instance.response );
	}
	
	@AuraEnabled
	public static void saveOptionsState (
			String accountId,
			String selectedOptionsString,
			String deselectedOptionsString,
			String process ) {
		
		Savepoint savepoint = Database.setSavepoint();
		EinrichtungsKonfiguratorCtrl instance = new EinrichtungsKonfiguratorCtrl();
		
		try {
			instance.accountId = accountId;
			instance.process = process;
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
		EinrichtungsKonfiguratorCtrl instance = new EinrichtungsKonfiguratorCtrl();
		
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
				AND Vorgemerkt__c = NULL
		] ) {
			
			productOptionIds.add( filialausstattung.Produktoption__c );
		}
		List<Option> selectedChildOptions = new List<Option>();
		for ( Option option : selectedOptions ) {
			if ( !productOptionIds.contains( option.product.Id ) ) {
				Filialausstattung__c filialausstattung = new Filialausstattung__c(
						Name = NameFieldLimiter.getValue( option.product.Option__r.Name ),
						Filiale__c = accountId,
						Produkt__c = option.product.Option__c,
						Produktoption__c = option.product.Id,
						Menge__c = option.quantity,
						Produktbuendeloption__c = option.product.Produktbuendeloption__c,
						BestandVorgaengerfiliale__c = process == 'Vorgängerfiliale'
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
				AND
				( (
						Product__r.Family = :process
						AND OZ__c = :oz
						AND Vertriebssegment__c = :vertriebssegment
						AND AnzahlSchalter__c = :anzahlSchalter
						AND ( Variante__c = NULL OR Variante__c = :variant)
				)
				OR ( mitPostfach__c = TRUE OR mitPaketausgabe__c = TRUE)
				)
				AND Product__r.IsActive = TRUE
				AND IstUnsichtbarNeubestellung__c = FALSE
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
				category.products.add(
						option
				);
				response.optionByIds.put( produktoption.Id, option );
				
				if ( !ausstattungByProductoptionIds.containsKey( produktoption.Id )
						&& produktoption.Standard__c
						&& !einrichtungsprozess.initialisiert__c ) {
					Filialausstattung__c filialausstattung = new Filialausstattung__c(
							Name = NameFieldLimiter.getValue( produktoption.Option__r.Name ),
							Filiale__c = accountId,
							Produkt__c = produktoption.Option__c,
							Produktoption__c = produktoption.Id,
							Menge__c = getQuantity( produktoption ),
							BestandVorgaengerfiliale__c = process == 'Vorgängerfiliale'
					);
					
					newFilialausstattungen.add( filialausstattung );
					filialausstattungByOptionIds.put( produktoption.Id, filialausstattung );
				}
			}
			categories.add( category );
		}
	}
	
	private Boolean isSelectedTopLevel ( Produktoption__c produktoption ) {
		
		return ausstattungByProductoptionIds.containsKey( produktoption.Id )
				|| ( produktoption.Standard__c && !einrichtungsprozess.initialisiert__c );
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
					addAusstattung( produktoption, parentProductOptionId, productBundleOptionIds );
				}
			}
			highestProductStructureLevel = productLevel;
			keepLoading = produktoptionenByParentProductOptionId.keySet().size() > 0;
			productLevel++;
		}
	}
	
	private void addAusstattung ( Produktoption__c produktoption, String parentProductOptionId, Set<String> productBundleOptionIds ) {
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
		
		if ( !ausstattungByProductoptionIds.containsKey( produktoption.Id )
				&& produktoption.Standard__c
				&& !einrichtungsprozess.initialisiert__c
				&& ( filialausstattungByOptionIds.containsKey( parentProductOptionId )
				|| ausstattungByProductoptionIds.containsKey( parentProductOptionId ) ) ) {
			
			Filialausstattung__c filialausstattung = new Filialausstattung__c(
					Name = NameFieldLimiter.getValue( produktoption.Option__r.Name ),
					Filiale__c = accountId,
					Produkt__c = produktoption.Option__c,
					Produktoption__c = produktoption.Id,
					Menge__c = getQuantity( produktoption ),
					Produktbuendeloption__c = parentProductOptionId,
					BestandVorgaengerfiliale__c = process == 'Vorgängerfiliale'
			);
			newFilialausstattungen.add( filialausstattung );
			filialausstattungByOptionIds.put( produktoption.Id, filialausstattung );
		}
	}
	
	private void loadEinrichtungsprozess () {
		einrichtungsprozess = [
				SELECT
						Id,
						initialisiert__c
				FROM Einrichtungsprozess__c
				WHERE Filiale__c = :accountId
				LIMIT 1
		];
	}
	
	private void deleteLegacyFilialausstattung () {
		
		Map<Id, Produktoption__c> produktoptionByIds = new Map<Id, Produktoption__c>( [
				SELECT
						Id
				FROM Produktoption__c
				WHERE OZ__c = :oz
				AND Vertriebssegment__c = :vertriebssegment
				AND AnzahlSchalter__c = :anzahlSchalter
				AND Variante__c != :variant
				AND Variante__c != NULL
		] );
		
		flagExistingFilialausstattungForDeletion( produktoptionByIds.keySet() );
		if ( !existingFilialausstattungsForDeletion.isEmpty() ) {
			delete existingFilialausstattungsForDeletion;
			Database.emptyRecycleBin( existingFilialausstattungsForDeletion );
		}
	}
	
	private void flagExistingFilialausstattungForDeletion ( Set<Id> optionIds ) {
		
		Set<Id> childOptionIds = new Set<Id>();
		for ( Filialausstattung__c filialausstattung : [
				SELECT
						Id, (
						SELECT
								Produktoption__c
						FROM Produktoptionen__r
				)
				FROM Filialausstattung__c
				WHERE Filiale__c = :accountId
				AND Produktoption__c IN :optionIds
				AND Vorgemerkt__c = NULL
		] ) {
			existingFilialausstattungsForDeletion.add( filialausstattung );
			for ( Filialausstattung__c childAusstattung : filialausstattung.Produktoptionen__r ) {
				childOptionIds.add( childAusstattung.Produktoption__c );
			}
		}
		if ( !childOptionIds.isEmpty() ) {
			flagExistingFilialausstattungForDeletion( childOptionIds );
		}
	}
	
	private void saveVariant () {
		
		update new Einrichtungsprozess__c(
				Id = einrichtungsprozessId,
				Variante__c = variant
		);
	}
}