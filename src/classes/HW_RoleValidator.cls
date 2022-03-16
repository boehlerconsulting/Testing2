/**
 *@author       Mats Böhler
 *@created      11.10.2019
 *@version      1.0
 *@since        45.0
 *
 *
 *@description  HW_RoleValidator
 *              DPSA-878
 *
 *
 *@changelog    11.10.2019 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class HW_RoleValidator {
	
	private String role = '';
	private String profile = '';
	
	public String getPriorisierungshilfeRole () {
		loadUserInfo();
		
		if ( isVertriebsleiter() ) {
			return 'VL';
		}
		else if ( isVertriebskoordinator() ) {
			return 'VK';
		}
		else if ( isVertriebsmanager() ) {
			return 'VM';
		}
		else if ( isSystemAdministrator() ) {
			return 'VL';
		}
		else {
			return 'VM';
		}
	}
	
	private void loadUserInfo () {
		User currentUser = [
				SELECT
						Id,
						UserRole.DeveloperName,
						Profile.Name
				FROM User
				WHERE Id = :UserInfo.getUserId()
				LIMIT 1
		];
		role = currentUser.UserRole.DeveloperName;
		profile = currentUser.Profile.Name;
	}
	
	private Boolean isVertriebsleiter () {
		if (role == null ) {
			return false;
		}
		return role.contains( 'Vertriebsleiter_koordinator' ) && profile.contains('myPM Vertrieb (VL');
	}
	
	private Boolean isVertriebskoordinator () {
		if (role == null ) {
			return false;
		}
		return role.contains( 'Vertriebsleiter_koordinator' ) && profile.contains('myPM Vertrieb (VK');
	}
	
	private Boolean isVertriebsmanager () {
		if (role == null ) {
			return false;
		}
		return role.contains( 'Vertriebsmanager' );
	}
	
	private Boolean isSystemAdministrator () {
		return profile.containsIgnoreCase('admin');
	}
}