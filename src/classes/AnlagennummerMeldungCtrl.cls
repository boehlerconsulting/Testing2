/**
 *@author       Mats Böhler
 *@created      15.06.2020
 *
 *
 *@description  MeldungAnlagennummerCtrl
 *
 *
 *@changelog    15.06.2020 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class AnlagennummerMeldungCtrl {
	
	public List<MeldungWrapper> meldungWrappers {
		get {
			return AnlagennummerMeldungCtrl.getInstance().meldungWrappers;
		}
		set;
	}
	public List<AnlagennummerHistorie__c> anlagennummerHistories {
		get {
			return AnlagennummerMeldungCtrl.getInstance().anlagennummerHistories;
		}
		set;
	}
	
	private static AnlagennummerMeldungCtrl instance = null;
	
	private AnlagennummerLetzteMeldung__c lastNotification;
	private Map<Id, List<AnlagennummerHistorie__c>> historienByAnlagennummerId
			= new Map<Id, List<AnlagennummerHistorie__c>>();
	private Map<Id, List<AnlagennummerHistorie__c>> gemeldeteHistorieByAnlagennummerId
			= new Map<Id, List<AnlagennummerHistorie__c>>();
	
	public static AnlagennummerMeldungCtrl getInstance () {
		if ( instance == null ) {
			instance = new AnlagennummerMeldungCtrl();
			instance.getLatestNotificationDate();
			instance.identifyRelevantNotifications();
		}
		return instance;
	}
	
	public void identifyRelevantNotifications () {
		meldungWrappers = new List<MeldungWrapper>();
		anlagennummerHistories = new List<AnlagennummerHistorie__c>();
		loadHistorie();
		for ( Id anlagennummerId : historienByAnlagennummerId.keySet() ) {
			
			if ( neverGemeldet( anlagennummerId ) && wasAssignedSinceLastMeldung( anlagennummerId ) ) {
				
				createMeldung( historienByAnlagennummerId.get( anlagennummerId )[ 0 ], 'Angelegt' );
			}
			if ( gemeldet( anlagennummerId ) && wasRemovedSinceLastMeldung( anlagennummerId ) ) {
				
				createMeldung(
						historienByAnlagennummerId.get(
								anlagennummerId )[ 0 ],
						'Anlagennummer gesperrt und wird nicht weiterverwendet'
				);
			}
			if ( gemeldet( anlagennummerId ) && wasAssignedSinceLastMeldung( anlagennummerId ) ) {
				
				createMeldung( historienByAnlagennummerId.get( anlagennummerId )[ 0 ], 'Geändert' );
			}
		}
	}
	
	private void createMeldung ( AnlagennummerHistorie__c anlagennummerHistorie, String reason ) {
		MeldungWrapper meldungWrapper = new MeldungWrapper();
		meldungWrapper.anlagennummer = anlagennummerHistorie.Anlagennummer__r.Name;
		meldungWrapper.kostenstelle = anlagennummerHistorie.Lead__r.Kostenstelle__c;
		meldungWrapper.admTyp = anlagennummerHistorie.Lead__r.ADM_Typ__c;
		meldungWrapper.adresse = anlagennummerHistorie.Lead__r.PostalCode + ' '
				+ anlagennummerHistorie.Lead__r.City + ' '
				+ anlagennummerHistorie.Lead__r.Street;
		meldungWrapper.admHersteller = anlagennummerHistorie.Lead__r.ADM_Hersteller__c;
		meldungWrapper.podId = anlagennummerHistorie.Lead__r.PODID_Lookup__r.Wert__c;
		String netzmanager = anlagennummerHistorie.Lead__r.Owner.Name + ' ('
						+ anlagennummerHistorie.Lead__r.Owner.EMail + ')';
		meldungWrapper.ansprechpartner = 'Koordinator: ' + anlagennummerHistorie.Lead__r.VL__r.GL__r.RVU_Team__r.Koordinator__r.Name
				+ ' (' + anlagennummerHistorie.Lead__r.VL__r.GL__r.RVU_Team__r.Koordinator__r.Email
				+ ') <br></br> Netzmanager: ' + netzmanager;
		meldungWrapper.grund = reason;
		meldungWrapper.pspElement = anlagennummerHistorie.Lead__r.PSP_Element__c;
		meldungWrappers.add( meldungWrapper );
		anlagennummerHistorie.Gemeldet__c = true;
		anlagennummerHistories.add( anlagennummerHistorie );
		anlagennummerHistories.add(
				new AnlagennummerHistorie__c(
						Anlagennummer__c = anlagennummerHistorie.Anlagennummer__c,
						Aktion__c = 'Gemeldet',
						Nachricht__c = 'Die Anlagennummer wurde der Anlagenbuchhaltung gemeldet ("' + reason + '").'
				)
		);
	}
	
	private void loadHistorie () {
		for ( AnlagennummerHistorie__c anlagennummerHistorie : [
				SELECT
						Anlagennummer__c,
						Anlagennummer__r.Name,
						Anlagennummer__r.Status__c,
						Gemeldet__c,
						Aktion__c,
						Nachricht__c,
						CreatedDate,
						Lead__c,
						Lead__r.Kostenstelle__c,
						Lead__r.PSP_Element__c,
						Lead__r.ADM_Typ__c,
						Lead__r.Street,
						Lead__r.ADM_Hersteller__c,
						Lead__r.PODID_Lookup__r.Wert__c,
						Lead__r.Name_Ansprechpartner__c,
						Lead__r.PostalCode,
						Lead__r.City,
						Lead__r.VL__r.Owner.Name,
						Lead__r.VL__r.Owner.Email,
						Lead__r.Owner.Name,
						Lead__r.Owner.EMail,
						Lead__r.VL__r.GL__r.RVU_Team__r.Koordinator__r.Name,
						Lead__r.VL__r.GL__r.RVU_Team__r.Koordinator__r.Email
				FROM AnlagennummerHistorie__c
				WHERE ( ( CreatedDate >= :lastNotification.LetzteMeldungErfolgtAm__c
				AND Aktion__c != 'Erstellt'
				AND Aktion__c != 'Gesperrt'
				AND Aktion__c != 'Gemeldet'
				AND Aktion__c != 'Entsperrt')
				OR ( Gemeldet__c = TRUE
				AND CreatedDate < :lastNotification.LetzteMeldungErfolgtAm__c) )
				ORDER BY CreatedDate DESC NULLS LAST
		] ) {
			if ( !anlagennummerHistorie.Gemeldet__c ) {
				if ( historienByAnlagennummerId.containsKey( anlagennummerHistorie.Anlagennummer__c ) ) {
					historienByAnlagennummerId.get( anlagennummerHistorie.Anlagennummer__c ).add( anlagennummerHistorie );
				}
				else {
					historienByAnlagennummerId.put( anlagennummerHistorie.Anlagennummer__c, new List<AnlagennummerHistorie__c> {
							anlagennummerHistorie
					} );
				}
			}
			if ( anlagennummerHistorie.Gemeldet__c ) {
				if ( gemeldeteHistorieByAnlagennummerId.containsKey( anlagennummerHistorie.Anlagennummer__c ) ) {
					gemeldeteHistorieByAnlagennummerId.get( anlagennummerHistorie.Anlagennummer__c ).add( anlagennummerHistorie );
				}
				else {
					gemeldeteHistorieByAnlagennummerId.put( anlagennummerHistorie.Anlagennummer__c, new List<AnlagennummerHistorie__c> {
							anlagennummerHistorie
					} );
				}
			}
		}
	}
	
	private Boolean neverGemeldet ( Id anlagennummerId ) {
		return !gemeldeteHistorieByAnlagennummerId.containsKey( anlagennummerId );
	}
	
	private Boolean gemeldet ( Id anlagennummerId ) {
		return gemeldeteHistorieByAnlagennummerId.containsKey( anlagennummerId );
	}
	
	private Boolean wasAssignedSinceLastMeldung ( Id anlagennummerId ) {
		return historienByAnlagennummerId.get( anlagennummerId )[ 0 ].Aktion__c == 'Zugewiesen';
	}
	
	private Boolean wasRemovedSinceLastMeldung ( Id anlagennummerId ) {
		return historienByAnlagennummerId.get( anlagennummerId )[ 0 ].Aktion__c == 'Entfernt';
	}
	
	private void getLatestNotificationDate () {
		if ( AnlagennummerLetzteMeldung__c.getOrgDefaults().LetzteMeldungErfolgtAm__c == null ) {
			Database.insert( new AnlagennummerLetzteMeldung__c(), false );
		}
		lastNotification = AnlagennummerLetzteMeldung__c.getOrgDefaults();
	}
	
	public class MeldungWrapper {
		public String anlagennummer { get; set; }
		public String kostenstelle { get; set; }
		public String admTyp { get; set; }
		public String adresse { get; set; }
		public String admHersteller { get; set; }
		public String podId { get; set; }
		public String ansprechpartner { get; set; }
		public String grund { get; set; }
		public String pspElement { get; set; }
	}
}