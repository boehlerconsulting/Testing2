/**
* @author           Oliver Preuschl
*                   H&W Consult GmbH
*                   Bahnhofstr. 3
*                   21244 Buchholz i.d.N.
*                   http://www.hundw.com
*
* @description      Ereigniss-Übersicht für die Startseite und die Filialansicht
*
* date              02.11.2015
*
* Timeline:
* Name              DateTime                Version        Description
* Oliver Preuschl   02.11.2015              *1.0*          Created
*/

public with sharing class Post_EreignisUebersicht {

//Die AccountId, falls die Themenliste in der Registerkartenansicht des Accounts angezeigt wird
	public Id accountIdAttribute { get; set; }

//Der aktuelle Nutzer
	public User currentUserAttribute {
		get {
			if ( currentUserAttribute == null ) {
				currentUserAttribute = [ SELECT Id, OrgE_DP__c, Profile.Name FROM User WHERE Id = :UserInfo.getUserId() ];
			}
			return currentUserAttribute;
		}
		set;
	}
	
	//Die aktuelle Zeit
	public DateTime currentTime {
		get {
			currentTime = DateTime.now();
			return currentTime;
		}
		set;
	}

//Benutzerdefinierte Einstellungen
	public AufgabenEreignisAnsicht__c ereignisAnsicht {
		get {
			if ( ereignisAnsicht == null ) {
				ereignisAnsicht = AufgabenEreignisAnsicht__c.getInstance();
			}
			return ereignisAnsicht;
		}
		set;
	}

//Das Feld ach dem sortiert wird
	public String ereignisSortierungsFeld {
		get;
		set {
			ereignisSortierungsFeldName = value;
			String newValue = getSortierungsFeld( value );
			if ( value == ereignisSortierungsFeld ) {
				if ( ereignisSortierungsRichtung == 'ASC' ) {
					ereignisSortierungsRichtung = 'DESC';
				}
				else {
					ereignisSortierungsRichtung = 'ASC';
				}
			}
			else {
				if ( isSortable( value ) ) {
					ereignisSortierungsRichtung = 'ASC';
					ereignisSortierungsFeld = newValue;
				}
			}
		}
	}
	
	//Das Feld nach dem sortiert wird
	public String ereignisSortierungsFeldName {
		get {
			if ( ereignisSortierungsFeldName == null ) {
				ereignisSortierungsFeldName = '';
			}
			return ereignisSortierungsFeldName;
		}
		set;
	}
	
	//Die Sortier-Richtung
	public String ereignisSortierungsRichtung {
		get {
			if ( ereignisSortierungsRichtung == null ) {
				ereignisSortierungsRichtung = 'ASC';
			}
			return ereignisSortierungsRichtung;
		}
		set;
	}

//Das Icon, welches in der UI für die Sortier-Richtung
	public String ereignisSortierungsRichtungIcon {
		get {
			if ( ereignisSortierungsRichtung == 'ASC' ) {
				ereignisSortierungsRichtungIcon = '↑';
			}
			else if ( ereignisSortierungsRichtung == 'DESC' ) {
				ereignisSortierungsRichtungIcon = '↓';
			}
			else {
				ereignisSortierungsRichtungIcon = '';
			}
			return ereignisSortierungsRichtungIcon;
		}
		set;
	}

//Der zusamenngesetzte Sortier-String (wird für die Abfrage der Ereignis verwendet)
	public String ereignisSortierung {
		get {
			if ( ereignisSortierungsFeld == null ) {
				ereignisSortierung = ' ORDER BY StartDateTime ASC';
			}
			else {
				ereignisSortierung = ' ORDER BY ' + ereignisSortierungsFeld + ' ' + ereignisSortierungsRichtung;
			}
			return ereignisSortierung;
		}
		set;
	}

//Die maximale Anzahl der Ereignis (wird aus den benutzerdefinierten Einstellungen übernommen)
	private Integer ereignisLimit {
		get {
			if ( ereignisLimit == null ) {
				if ( ereignisAnsicht != null ) {
					if ( ereignisAnsicht.EreignisseProSeite__c != null ) {
						ereignisLimit = Integer.valueOf( ereignisAnsicht.EreignisseProSeite__c );
					}
					else {
						ereignisLimit = 100;
					}
				}
				else {
					ereignisLimit = 100;
				}
			}
			return ereignisLimit;
		}
		set;
	}

//Die aktuell angezeigte Seite
	public Integer ereignisOffset {
		get {
			ereignisOffset = Integer.valueOf( ereignisOffsetString );
			return ereignisOffset;
		}
		set;
	}

//Die aktuell angezeigt Seite (String)
	public String ereignisOffsetString {
		get {
			if ( ereignisOffsetString == null ) {
				ereignisOffsetString = '0';
			}
			return ereignisOffsetString;
		}
		set;
	}

//Die verfügbaren Seiten
	public List< SelectOption > ereignisSeiten {
		get {
			if ( ereignisSeiten == null ) {
				ereignisSeiten = new List< SelectOption >();
				Integer ereignisSeitenAnzahl = ereignisAnzahl / ereignisLimit;
				for ( Integer i = 0; i <= ereignisSeitenAnzahl; i++ ) {
					Integer ereignisSeitenStart = ( i * ereignisLimit ) + 1;
					Integer ereignisSeitenEnde = ( i * ereignisLimit ) + ereignisLimit;
					if ( ereignisSeitenEnde > ereignisAnzahl ) {
						ereignisSeitenEnde = ereignisAnzahl;
					}
					ereignisSeiten.add(
							new SelectOption(
									String.valueOf( ereignisSeitenStart - 1 ),
									String.valueOf( ereignisSeitenStart ) + ' - ' + String.valueOf( ereignisSeitenEnde )
							)
					);
				}
			}
			return ereignisSeiten;
		}
		set;
	}

//Die Anzahl der Datensätze
	public Integer ereignisAnzahl {
		get {
			if ( ereignisAnzahl == null ) {
				String ereignisAnzahlAbfrage = 'SELECT COUNT(ID) EreignisAnzahl FROM Event ' + ereignisAbfrageFilter;
				List< AggregateResult > ereignisAnzahlAggregate = Database.query( ereignisAnzahlAbfrage );
				ereignisAnzahl = ( Integer ) ereignisAnzahlAggregate.get( 0 ).get( 'EreignisAnzahl' );
			}
			return ereignisAnzahl;
		}
		set;
	}

//Alle verfügbaren Filter
	public enum EreignisFilterEnum {
		Meine, OrgE, Filiale
	}

//Der aktuelle Datensatz-Filter
	public String ereignisFilter {
		get {
			if ( ereignisFilter == null ) {
				if ( accountIdAttribute == null ) {
					if ( currentUserAttribute.Profile.Name == 'Vertrieb' ) {
						ereignisFilter = String.valueOf( EreignisFilterEnum.Meine );
					}
					else {
						ereignisFilter = String.valueOf( EreignisFilterEnum.OrgE );
					}
				}
				else {
					ereignisFilter = String.valueOf( EreignisFilterEnum.Filiale );
				}
			}
			return ereignisFilter;
		}
		set;
	}

//Alle verfügbaren Filter für die aktuelle Ansicht
	public List< SelectOption > ereignisFilterOptions {
		get {
			if ( ereignisFilterOptions == null ) {
				ereignisFilterOptions = new List< SelectOption >();
				ereignisFilterOptions.add( new SelectOption( 'Meine', 'Meine offenen Ereignisse' ) );
				if ( accountIdAttribute == null ) {
					ereignisFilterOptions.add( new SelectOption( 'OrgE', 'Ereignis ' + currentUserAttribute.OrgE_DP__c ) );
				}
				else {
					ereignisFilterOptions.add( new SelectOption( 'Filiale', 'Offene Ereignisse' ) );
				}
			}
			return ereignisFilterOptions;
		}
		set;
	}
	
	//Die anzuzeigenden Felder (aus den benutzerdefinierten Einstellungen)
	private List< Schema.FieldSetMember > ereignisFelder {
		get {
			if ( ereignisFelder == null ) {
				ereignisFelder = SObjectType.Event.FieldSets.EreignisAnsicht.getFields();
			}
			return ereignisFelder;
		}
		set;
	}
	
	//Die anzuzeigenden Felder (aus dem FieldSet)
	public Map< String, String > ereignisFelderIds {
		get {
			if ( ereignisFelderIds == null ) {
				ereignisFelderIds = new Map< String, String >();
				for ( Schema.FieldSetMember feld : ereignisFelder ) {
					String feldId = feld.getFieldPath();
					if ( feldId.endsWithIgnoreCase( '__c' ) ) {
						feldId = feldId.removeEndIgnoreCase( '__c' ) + '_c';
					}
					ereignisFelderIds.put( feld.getFieldPath(), feldId );
				}
			}
			return ereignisFelderIds;
		}
		set;
	}
	
	//Der komplette Filter für die SOQL-Abfrage
	public String ereignisAbfrageFilter {
		get {
			if ( ereignisAbfrageFilter == null ) {
				ereignisAbfrageFilter = ' WHERE IsRecurrence = false';
				if ( ereignisFilter == String.valueOf( EreignisFilterEnum.Meine ) ) {
					ereignisAbfrageFilter += ' AND StartDateTime >= :currentTime AND OwnerId = \'' + UserInfo.getUserId() + '\'';
					if ( accountIdAttribute != null ) {
						ereignisAbfrageFilter += ' AND AccountId = :accountIdAttribute';
					}
				}
				else if ( ereignisFilter == String.valueOf( EreignisFilterEnum.OrgE ) ) {
					ereignisAbfrageFilter += ' AND StartDateTime >= :currentTime AND OwnerId IN ( SELECT Id FROM User WHERE OrgE_DP__c = \''
							+ currentUserAttribute.OrgE_DP__c + '\' )';
				}
				else if ( ereignisFilter == String.valueOf( EreignisFilterEnum.Filiale ) ) {
					ereignisAbfrageFilter += ' AND StartDateTime >= :currentTime AND AccountId = :accountIdAttribute';
				}
				else {
					//Sonarqube --> do nothing
				}
			}
			return ereignisAbfrageFilter;
		}
		set;
	}
	
	//Die komplette SOQL-Abfrage
	private String ereignisAbfrage {
		get {
			if ( ereignisAbfrage == null ) {
				ereignisAbfrage = 'SELECT ';
				for ( Schema.FieldSetMember ereignisField : this.ereignisFelder ) {
					ereignisAbfrage += ereignisField.getFieldPath() + ', ';
				}
				ereignisAbfrage += 'Id FROM Event ' + ereignisAbfrageFilter
						+ ereignisSortierung + ' LIMIT :ereignisLimit OFFSET :ereignisOffset ';
			}
			return ereignisAbfrage;
		}
		set;
	}

//Die ermittelten Ereignis
	public List< Event > events {
		get {
			if ( events == null ) {
				events = Database.query( ereignisAbfrage );
			}
			return events;
		}
		set;
	}
	
	//Prüft, ob das angegebene Feld sortierbar ist
	private Boolean isSortable ( String feldName ) {
		return Schema.SObjectType.Event.fields.getMap().get( feldName ).getDescribe().isSortable();
	}
	
	//Ermittelt den Typ des Feldes
	private Schema.Displaytype getType ( String feldName ) {
		return Schema.SObjectType.Event.fields.getMap().get( feldName ).getDescribe().getType();
	}
	
	//Ermittele das Sortierungsfeld
	private String getSortierungsFeld ( String feldName ) {
		String sortField = '';
		if ( getType( feldName ) != Schema.Displaytype.Reference ) {
			sortField = feldName;
		}
		else {
			sortField = feldName;
			if ( sortField.toLowerCase().endsWith( '__c' ) ) {
				sortField = sortField.removeEndIgnoreCase( '__c' ) + '__r.name';
			}
			else if ( sortField.toLowerCase().endsWith( 'id' ) ) {
				sortField = sortField.removeEndIgnoreCase( 'id' ) + '.name';
			}
			else {
				//Sonarqube --> do nothing
			}
		}
		return sortField;
	}
	
	//Aktualisierung der Ereignis
	public void refreshEreignis () {
		ereignisAbfrageFilter = null;
		ereignisAbfrage = null;
		ereignisAnzahl = null;
		ereignisSeiten = null;
		events = null;
	}
	
	//Aktualisierung der Aufgaben
	public void refreshEreignisUndPaginierung () {
		refreshEreignis();
		ereignisLimit = null;
		ereignisOffset = null;
		ereignisOffsetString = null;
	}
}