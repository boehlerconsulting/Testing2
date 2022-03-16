/**
 *@author       Mats Böhler
 *@created      27.11.2020
 *
 *
 *@description  PackstationLeaduebernahmeCtrl
 *
 *
 *@changelog    27.11.2020 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class PackstationLeaduebernahmeCtrl {
	
	@AuraEnabled
	public static void init ( String leadId ) {
		PackstationLeaduebernahmeCtrl instance = new PackstationLeaduebernahmeCtrl();
		try {
			if ( instance.isAllowedOperation() ) {
				update new Lead(
						Id = leadId,
						OwnerId = UserInfo.getUserId()
				);
			}
			else {
				throw new PackstationLeaduebernahmeCtrlException( 'Sie sind nicht berechtigt den Lead zu übernehmen!' );
			}
		}
		catch ( Exception e ) {
			throw new AuraHandledException( e.getMessage() );
		}
	}
	
	private Boolean isAllowedOperation () {
		User currentUser = CurrentUser.getInstance().getUser();
		return currentUser.Profile.Name.contains( 'myPM Vertrieb (V' )
				|| currentUser.Profile.Name.contains( 'myPM Packstation Vertrieb' );
	}
	
	public class PackstationLeaduebernahmeCtrlException extends Exception {
	}
}