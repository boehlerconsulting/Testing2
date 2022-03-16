/**
 *@author       Mats Böhler
 *@created      22.05.2020
 *
 *
 *@description  TestUser
 *
 *
 *@changelog    22.05.2020 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
public class TestUser {
	
	public static User create ( UserType type ) {
		if ( type == UserType.ADMIN ) {
			return createAdminUser();
		}
		if ( type == UserType.VL2001 ) {
			return createVL2001User();
		}
		if ( type == UserType.AO ) {
			return createAOUser();
		}
		return new User();
	}
	
	private static User createAdminUser () {
		User adminUser = new User(
				Username = UserInfo.getOrganizationId() + System.now().millisecond() + 'test@dpdhl.com',
				Alias = 'standt',
				Email = 'test@dpdhl.com',
				EmailEncodingKey = 'UTF-8',
				LastName = 'TestUser',
				LanguageLocaleKey = 'de',
				LocaleSidKey = 'de_DE',
				ProfileId = [
						SELECT
								Name
						FROM Profile
						WHERE ( UserType = 'Standard' AND PermissionsPrivacyDataAccess = TRUE)
						ORDER BY CreatedDate ASC
						LIMIT 1
				].Id,
				TimeZoneSidKey = 'Europe/Berlin',
				UserRoleId = [
						SELECT
								Id,
								DeveloperName
						FROM UserRole
						WHERE DeveloperName = 'Sicht_alle_Filialen_ohne_Beschr_nkung'
						LIMIT 1
				].Id,
				OrgE_DP__c = 'VL 2001 Köln'
		);
		insert adminUser;
		addPermissionSet( adminUser.Id, 'ZusammenlegungLeadmanagement1' );
		addPermissionSet( adminUser.Id, 'Anlagennummer' );
		return adminUser;
	}
	
	private static User createVL2001User () {
		User vl2001User = new User(
				Username = UserInfo.getOrganizationId() + System.now().millisecond() + 'test@dpdhl.com',
				Alias = 'standt',
				Email = 'test@dpdhl.com',
				EmailEncodingKey = 'UTF-8',
				LastName = 'TestUser',
				LanguageLocaleKey = 'de',
				LocaleSidKey = 'de_DE',
				ProfileId = [
						SELECT
								Name
						FROM Profile
						WHERE ( UserType = 'Standard' AND PermissionsPrivacyDataAccess = TRUE)
						ORDER BY CreatedDate ASC
						LIMIT 1
				].Id,
				TimeZoneSidKey = 'Europe/Berlin',
				UserRoleId = [
						SELECT
								Id,
								DeveloperName
						FROM UserRole
						WHERE DeveloperName = 'Sicht_alle_Filialen_ohne_Beschr_nkung'
						LIMIT 1
				].Id,
				OrgE_DP__c = 'VL 2001 Köln'
		);
		insert vl2001User;
		addPermissionSet( vl2001User.Id, 'ZusammenlegungLeadmanagement1' );
		addPermissionSet( vl2001User.Id, 'Anlagennummer' );
		return vl2001User;
	}
	
	private static User createAOUser () {
		User user = new User(
				Username = UserInfo.getOrganizationId() + System.now().millisecond() + 'test@dpdhl.com',
				Alias = 'ao',
				Email = 'test@dpdhl.com',
				EmailEncodingKey = 'UTF-8',
				LastName = 'TestUser',
				LanguageLocaleKey = 'de',
				LocaleSidKey = 'de_DE',
				ProfileId = [
						SELECT
								Name
						FROM Profile
						WHERE Name = 'myPM Vertrieb (VM) - MFA'
						ORDER BY CreatedDate ASC
						LIMIT 1
				].Id,
				TimeZoneSidKey = 'Europe/Berlin',
				UserRoleId = [
						SELECT
								Id,
								DeveloperName
						FROM UserRole
						WHERE DeveloperName = 'Sicht_alle_Filialen_ohne_Beschr_nkung'
						LIMIT 1
				].Id,
				OrgE_DP__c = 'VL 2001 Köln'
		);
		insert user;
		addPermissionSet( user.Id, 'ZusammenlegungLeadmanagement1' );
		addPermissionSet( user.Id, 'Anlagennummer' );
		return user;
	}
	
	private static void addPermissionSet ( Id userId, String name ) {
		insert new PermissionSetAssignment(
				AssigneeId = userId,
				PermissionSetId = [
						SELECT
								Id
						FROM PermissionSet
						WHERE Name = :name
						LIMIT 1
				].Id
		);
	}
	
	public enum UserType {
		ADMIN, VL2001, AO
	}
}