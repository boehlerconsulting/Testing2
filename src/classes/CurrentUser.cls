/**
 *@author       Mats Böhler
 *@created      17.11.2021
 *
 *
 *@description  CurrentUser
 *
 *
 *@changelog    17.11.2021 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class CurrentUser {
	
	private User user = new User();
	private Profile profile = new Profile();
	
	private static CurrentUser instance = null;
	
	public static CurrentUser getInstance () {
		if ( instance == null ) {
			instance = new CurrentUser();
			instance.loadUser();
			instance.loadProfile();
		}
		return instance;
	}
	
	public User getUser () {
		return user;
	}
	
	public Profile getProfile () {
		return profile;
	}
	
	public Id getId () {
		return user.Id;
	}
	
	private void loadUser () {
		user = [
				SELECT
						Id,
						Email,
						OrgE_DP__c,
						Profile.Name
				FROM User
				WHERE Id = :UserInfo.getUserId()
				LIMIT 1
		];
	}
	
	private void loadProfile () {
		profile = [
				SELECT
						Id,
						Name
				FROM Profile
				WHERE Id = :UserInfo.getProfileId()
				LIMIT 1
		];
	}
}