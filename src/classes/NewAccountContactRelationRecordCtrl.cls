/**
 *@author       Mats Böhler
 *@created      08.09.2021
 *
 *
 *@description  NewAccountContactRelationRecordCtrl
 *
 *
 *@changelog    08.09.2021 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class NewAccountContactRelationRecordCtrl {
	
	@AuraEnabled
	public static void createNewContactWithAccountContactRelation ( String contactString, String accountId, List<String> selectedRoles ) {
		if ( selectedRoles.contains( 'Vertragspartner' )
				&& vertragspartnerAlreadyExists( accountId ) ) {
			
			throw new DmlException( 'Es existiert bereits ein Vertragspartner zu dieser Packstation.' );
		}
		Savepoint savepoint = Database.setSavepoint();
		try {
			Contact contact = ( Contact ) JSON.deserialize( contactString, Contact.class );
			contact.AccountId = accountId;
			contact.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName()
					.get( 'Packstation' ).getRecordTypeId();
			insert contact;
			
			AccountContactRelation accountContactRelation = [
					SELECT
							Id
					FROM AccountContactRelation
					WHERE AccountId = :accountId
					AND ContactId = :contact.Id
					LIMIT 1
			];
			accountContactRelation.Roles = getRoles( selectedRoles );
			update accountContactRelation;
		}
		catch ( Exception e ) {
			Database.rollback( savepoint );
			throw new AuraHandledException( e.getMessage() );
		}
	}
	
	@AuraEnabled
	public static void createNewAccountContactRelation ( String contactId, String accountId, List<String> selectedRoles ) {
		if ( selectedRoles.contains( 'Vertragspartner' )
				&& vertragspartnerAlreadyExists( accountId ) ) {
			
			throw new DmlException( 'Es existiert bereits ein Vertragspartner zu dieser Packstation.' );
		}
		Savepoint savepoint = Database.setSavepoint();
		try {
			insert new AccountContactRelation(
					Roles = getRoles( selectedRoles ),
					AccountId = accountId,
					ContactId = contactId
			);
		}
		catch ( Exception e ) {
			Database.rollback( savepoint );
			throw new AuraHandledException( e.getMessage() );
		}
	}
	
	private static String getRoles ( List<String> roles ) {
		String selectedRoles = '';
		for ( String role : roles ) {
			selectedRoles += role + ';';
		}
		return selectedRoles.removeEnd( ';' );
	}
	
	@AuraEnabled(Cacheable=true)
	public static List<LookupSearchResult> searchContacts ( String searchTerm, List<String> selectedIds ) {
		
		List<LookupSearchResult> results = new List<LookupSearchResult>();
		searchTerm = '%' + DynamicQuery.removeRestrictedCharacters(searchTerm) + '%';
		for ( Contact contact : [
				SELECT
						Id,
						Name,
						Account.Name
				FROM Contact
				WHERE RecordType.DeveloperName = 'Packstation'
		] ) {
			results.add(
					new LookupSearchResult(
							contact.Id,
							'Contact',
							'standard:contact',
							contact.Name,
							contact.Account.Name
					)
			);
		}
		results.sort();
		return results;
	}
	
	private static Boolean vertragspartnerAlreadyExists ( String accountId ) {
		for ( AccountContactRelation accountContactRelation : [
				SELECT
						Id
				FROM AccountContactRelation
				WHERE AccountId = :accountId
				AND Roles INCLUDES ('Vertragspartner')
		] ) {
			return true;
		}
		return false;
	}
}