/**
 *@author       Mats Böhler
 *@created      28.04.2021
 *
 *
 *@description  InterfaceUser
 *
 *
 *@changelog    28.04.2021 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class InterfaceUser {
	
	private User user = new User();
	
	private static InterfaceUser instance = null;
	
	public static InterfaceUser getInstance () {
		if ( instance == null ) {
			instance = new InterfaceUser();
			instance.loadUser();
		}
		return instance;
	}
	
	public User getUser(){
		return user;
	}
	
	public Id getId(){
		return user.Id;
	}
	
	private void loadUser(){
		user = [
				SELECT
						Id
				FROM User
				WHERE IstSchnittstellenbenutzer__c = TRUE
				LIMIT 1
		];
	}
}