/**
 *@author       Mats Böhler
 *@created      30.06.2020
 *
 *
 *@description  PackstationAktivatorCtrl
 *
 *
 *@changelog    30.06.2020 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class PackstationAktivatorCtrl {
	
	private Lead lead = null;
	private Boolean activated = false;
	
	@AuraEnabled
	public static Boolean init ( String leadId ) {
		PackstationAktivatorCtrl instance = new PackstationAktivatorCtrl();
		try {
			instance.loadLead( leadId );
			if ( instance.isAllowedOperation() ) {
				if ( instance.isActive() ) {
					instance.deactivateLead();
				} else if( instance.isInactive()){
					instance.activateLead();
				}
				else{
					instance.activateLead();
				}
				update instance.lead;
			}
			else {
				throw new PackstationAktivatorCtrlException( 'Sie sind nicht berechtigt den Lead zu aktivieren / deaktivieren!' );
			}
		}
		catch ( Exception e ) {
			throw new AuraHandledException( e.getMessage() );
		}
		return instance.activated;
	}
	
	private Boolean isAllowedOperation () {
		return lead.OwnerId == UserInfo.getUserId()
				|| FeatureManagement.checkPermission( 'PackstationLeadAktivierenDeaktivieren' );
	}
	
	private void loadLead ( String leadId ) {
		lead = [
				SELECT
						Id,
						Aktivitaetsstatus__c,
						OwnerId
				FROM Lead
				WHERE Id = :leadId
				LIMIT 1
		];
		lead.Aktivitaetsstatus__c = lead.Aktivitaetsstatus__c == null
				? ''
				: lead.Aktivitaetsstatus__c;
	}
	
	private Boolean isActive () {
		return lead.Aktivitaetsstatus__c.startsWith( 'aktiv' );
	}
	
	private Boolean isInactive () {
		return lead.Aktivitaetsstatus__c.startsWith( 'inaktiv' );
	}
	
	private void activateLead () {
		lead.Aktivitaetsstatus__c = 'aktiv';
		activated = true;
	}
	
	private void deactivateLead () {
		lead.Aktivitaetsstatus__c = 'inaktiv';
		activated = false;
	}
	
	public class PackstationAktivatorCtrlException extends Exception {
	}
}