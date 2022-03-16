/**
* @author           Oliver Preuschl
*                   H&W Consult GmbH
*                   Bahnhofstr. 3
*                   21244 Buchholz i.d.N.
*                   http://www.hundw.com
*
* @description      Aufgaben-Übersicht für die Startseite und die Filialansicht
*
* date              02.11.2015
*
* Timeline:
* Name              DateTime                Version        Description
* Oliver Preuschl   02.11.2015              *1.0*          Created
*/

public with sharing class Post_AufgabenUebersicht {
	
	//Die AccountId, falls die Themenliste in der Registerkartenansicht des Accounts angezeigt wird
	public Id accountIdAttribute {
		get;
		set;
	}
	
	//Der Typ der Ansicht
	public String userTypAttribute { get; set; }
	
	//Der aktuelle Nutzer
	public User currentUser {
		get {
			if ( currentUser == null ) {
				currentUser = [ SELECT Id, OrgE_DP__c, Profile.Name FROM User WHERE Id = :UserInfo.getUserId() ];
			}
			return currentUser;
		}
		set;
	}
	
	//Der Name des aktuellen FeldSets
	public String feldSetName {
		get {
			if ( feldSetName == null ) {
				if ( accountIdAttribute != null ) {
					feldSetName = 'Aufgabenuebersicht_Filiale';
				}
				else {
					if ( userTypAttribute == 'AG' ) {
						feldSetName = 'Aufgabenuebersicht_Startseite_AG';
					}
					else {
						feldSetName = 'Aufgabenuebersicht_Startseite_AN';
					}
				}
			}
			return feldSetName;
		}
		set;
	}
	
	//Benutzerdefinierte Einstellungen
	public AufgabenEreignisAnsicht__c aufgabenAnsicht {
		get {
			if ( aufgabenAnsicht == null ) {
				aufgabenAnsicht = AufgabenEreignisAnsicht__c.getInstance();
			}
			return aufgabenAnsicht;
		}
		set;
	}
	
	//Das Feld nach dem sortiert wird
	public String aufgabenSortierungsFeld {
		get;
		set {
			aufgabenSortierungsFeldName = value;
			String newValue = getSortierungsFeld( value );
			if ( newValue == aufgabenSortierungsFeld ) {
				if ( aufgabenSortierungsRichtung == 'ASC' ) {
					aufgabenSortierungsRichtung = 'DESC';
				}
				else {
					aufgabenSortierungsRichtung = 'ASC';
				}
			}
			else {
				if ( isSortable( value ) ) {
					aufgabenSortierungsRichtung = 'ASC';
					aufgabenSortierungsFeld = newValue;
				}
			}
		}
	}
	
	//Das Feld nach dem sortiert wird
	public String aufgabenSortierungsFeldName {
		get {
			if ( aufgabenSortierungsFeldName == null ) {
				aufgabenSortierungsFeldName = '';
			}
			return aufgabenSortierungsFeldName;
		}
		set;
	}
	
	//Die Sortier-Richtung
	public String aufgabenSortierungsRichtung {
		get {
			if ( aufgabenSortierungsRichtung == null ) {
				aufgabenSortierungsRichtung = 'ASC';
			}
			return aufgabenSortierungsRichtung;
		}
		set;
	}
	
	//Das Icon, welches in der UI für die Sortier-Richtung
	public String aufgabenSortierungsRichtungIcon {
		get {
			if ( aufgabenSortierungsRichtung == 'ASC' ) {
				aufgabenSortierungsRichtungIcon = '↑';
			}
			else if ( aufgabenSortierungsRichtung == 'DESC' ) {
				aufgabenSortierungsRichtungIcon = '↓';
			}
			else {
				aufgabenSortierungsRichtungIcon = '';
			}
			return aufgabenSortierungsRichtungIcon;
		}
		set;
	}
	
	//Der zusamenngesetzte Sortier-String (wird für die Abfrage der Aufgaben verwendet)
	public String aufgabenSortierung {
		get {
			if ( aufgabenSortierungsFeld == null ) {
				if ( accountIdAttribute == null && userTypAttribute == 'AG' ) {
					aufgabenSortierung = ' ORDER BY Erledigung_bis_zum__c,Priority ASC';
				}
				else {
					aufgabenSortierung = ' ORDER BY ActivityDate,Priority,Erledigung_bis_zum__c ASC';
				}
			}
			else {
				aufgabenSortierung = ' ORDER BY ' + aufgabenSortierungsFeld + ' ' + aufgabenSortierungsRichtung;
			}
			return aufgabenSortierung;
		}
		set;
	}
	
	//Die maximale Anzahl der Aufgaben (wird aus den benutzerdefinierten Einstellungen übernommen)
	private Integer aufgabenLimit {
		get {
			if ( aufgabenLimit == null ) {
				if ( aufgabenAnsicht != null ) {
					if ( aufgabenAnsicht.AufgabenProSeite__c != null ) {
						aufgabenLimit = Integer.valueOf( aufgabenAnsicht.AufgabenProSeite__c );
					}
					else {
						aufgabenLimit = 100;
					}
				}
				else {
					aufgabenLimit = 100;
				}
			}
			return aufgabenLimit;
		}
		set;
	}
	
	//Die aktuell angezeigte Seite
	public Integer aufgabenOffset {
		get {
			aufgabenOffset = Integer.valueOf( aufgabenOffsetString );
			return aufgabenOffset;
		}
		set;
	}
	
	//Die aktuell angezeigt Seite (String)
	public String aufgabenOffsetString {
		get {
			if ( aufgabenOffsetString == null ) {
				aufgabenOffsetString = '0';
			}
			return aufgabenOffsetString;
		}
		set;
	}
	
	//Die verfügbaren Seiten
	public List< SelectOption > aufgabenSeiten {
		get {
			if ( aufgabenSeiten == null ) {
				aufgabenSeiten = new List< SelectOption >();
				Integer aufgabenSeitenAnzahl = taskCount / aufgabenLimit;
				for ( Integer i = 0; i <= aufgabenSeitenAnzahl; i++ ) {
					Integer aufgabenSeitenStart = ( i * aufgabenLimit ) + 1;
					Integer aufgabenSeitenEnde = ( i * aufgabenLimit ) + aufgabenLimit;
					if ( aufgabenSeitenEnde > taskCount ) {
						aufgabenSeitenEnde = taskCount;
					}
					aufgabenSeiten.add(
							new SelectOption(
									String.valueOf( aufgabenSeitenStart - 1 ),
									String.valueOf( aufgabenSeitenStart ) + ' - '
											+ String.valueOf( aufgabenSeitenEnde )
							)
					);
				}
			}
			return aufgabenSeiten;
		}
		set;
	}
	
	//Die Anzahl der Datensätze
	public Integer taskCount {
		get {
			if ( taskCount == null ) {
				String aufgabenAnzahlAbfrage = 'SELECT COUNT(ID) AufgabenAnzahl FROM Task ' + aufgabenAbfrageFilter;
				List< AggregateResult > aufgabenAnzahl = Database.query( aufgabenAnzahlAbfrage );
				taskCount = ( Integer ) aufgabenAnzahl.get( 0 ).get( 'AufgabenAnzahl' );
			}
			return taskCount;
		}
		set;
	}
	
	//Alle verfügbaren Filter
	public enum AufgabenFilterEnum {
		Meine, OrgE, Filiale
	}
	
	//Der aktuelle Datensatz-Filter
	public String taskFilter {
		get {
			if ( taskFilter == null ) {
				if ( accountIdAttribute == null ) {
					if ( currentUser.Profile.Name == 'STF Vertrieb (VM/VK)' || currentUser.Profile.Name == 'STF Vertrieb (VD/VGL)' ||
							currentUser.Profile.Name == 'STF Training Vertrieb (VM/VK)'
							|| currentUser.Profile.Name == 'STF Training Vertrieb (VD/VGL)' ) {
						taskFilter = String.valueOf( AufgabenFilterEnum.Meine );
					}
					else {
						taskFilter = String.valueOf( AufgabenFilterEnum.OrgE );
					}
				}
				else {
					taskFilter = String.valueOf( AufgabenFilterEnum.Filiale );
				}
			
			}
			return taskFilter;
		}
		set;
	}
	
	//Alle verfügbaren Filter für die aktuelle Ansicht
	public List< SelectOption > aufgabenFilter {
		get {
			if ( aufgabenFilter == null ) {
				aufgabenFilter = new List< SelectOption >();
				if ( userTypAttribute != 'AG' ) {
					aufgabenFilter.add( new SelectOption( 'Meine', 'Meine offenen Aufgaben' ) );
				}
				if ( accountIdAttribute == null ) {
					aufgabenFilter.add( new SelectOption( 'OrgE', 'Aufgaben ' + currentUser.OrgE_DP__c ) );
				}
				else {
					aufgabenFilter.add( new SelectOption( 'Filiale', 'Offene Aufgaben' ) );
				}
			}
			return aufgabenFilter;
		}
		set;
	}
	
	//Die anzuzeigenden Felder (aus dem FieldSet)
	public List< Schema.FieldSetMember > aufgabenFelder {
		get {
			if ( aufgabenFelder == null ) {
				aufgabenFelder = SObjectType.Task.fieldSets.getMap().get( feldSetName ).getFields();
			}
			return aufgabenFelder;
		}
		set;
	}
	
	//Die anzuzeigenden Felder (aus dem FieldSet)
	public Map< String, String > aufgabenFelderIds {
		get {
			if ( aufgabenFelderIds == null ) {
				aufgabenFelderIds = new Map< String, String >();
				for ( Schema.FieldSetMember feld : aufgabenFelder ) {
					String feldId = feld.getFieldPath();
					if ( feldId.endsWithIgnoreCase( '__c' ) ) {
						feldId = feldId.removeEndIgnoreCase( '__c' ) + '_c';
					}
					aufgabenFelderIds.put( feld.getFieldPath(), feldId );
				}
			}
			return aufgabenFelderIds;
		}
		set;
	}
	
	Date maximalesAktivitaetsdatum = Date.newInstance( Date.today().year(), 12, 31 );
	
	//Der komplette Filter für die SOQL-Abfrage
	public String aufgabenAbfrageFilter {
		get {
			if ( aufgabenAbfrageFilter == null ) {
				aufgabenAbfrageFilter = ' WHERE IsRecurrence = false';
				if ( taskFilter == String.valueOf( AufgabenFilterEnum.Meine ) ) {
					aufgabenAbfrageFilter += ' AND isClosed = false AND OwnerId = \'' + UserInfo.getUserId() + '\'';
					if ( accountIdAttribute != null ) {
						aufgabenAbfrageFilter += ' AND AccountId = :accountIdAttribute';
					}
					else {
						aufgabenAbfrageFilter += ' AND ActivityDate <= :maximalesAktivitaetsdatum';
					}
				}
				else if ( taskFilter == String.valueOf( AufgabenFilterEnum.OrgE ) ) {
					if ( userTypAttribute == 'AG' ) {
						aufgabenAbfrageFilter += ' AND isClosed = false AND Auftraggeber__c LIKE \'%' + currentUser.OrgE_DP__c + '%\'';
					}
					else {
						aufgabenAbfrageFilter += ' AND isClosed = false AND OwnerId IN ( SELECT Id FROM User WHERE OrgE_DP__c LIKE \'%'
								+ currentUser.OrgE_DP__c + '%\' )';
					}
					aufgabenAbfrageFilter += ' AND ActivityDate <= :maximalesAktivitaetsdatum';
				}
				else if ( taskFilter == String.valueOf( AufgabenFilterEnum.Filiale ) ) {
					aufgabenAbfrageFilter += ' AND isClosed = false AND AccountId = :accountIdAttribute';
				}
				else {
					//Sonarqube --> do nothing
				}
			}
			return aufgabenAbfrageFilter;
		}
		set;
	}
	
	//Die komplette SOQL-Abfrage
	private String aufgabenAbfrage {
		get {
			if ( aufgabenAbfrage == null ) {
				aufgabenAbfrage = 'SELECT ';
				for ( Schema.FieldSetMember aufgabenField : this.aufgabenFelder ) {
					aufgabenAbfrage += aufgabenField.getFieldPath() + ', ';
				}
				aufgabenAbfrage += 'Id, Account.Name FROM Task ' + aufgabenAbfrageFilter
						+ aufgabenSortierung + ' LIMIT :aufgabenLimit OFFSET :aufgabenOffset ';
			}
			return aufgabenAbfrage;
		}
		set;
	}
	
	//Die ermittelten Aufgaben
	public List< Task > tasks {
		get {
			if ( tasks == null ) {
				tasks = Database.query( aufgabenAbfrage );
			}
			return tasks;
		}
		set;
	}
	
	//Prüft, ob das angegebene Feld sortierbar ist
	private Boolean isSortable ( String feldName ) {
		return Schema.getGlobalDescribe().get( 'Task' ).getDescribe().fields.getMap().get( feldName ).getDescribe().isSortable();
	}
	
	//Ermittelt den Typ des Feldes
	private Schema.DisplayType getType ( String feldName ) {
		return Schema.getGlobalDescribe().get( 'Task' ).getDescribe().fields.getMap().get( feldName ).getDescribe().getType();
	}
	
	//Ermittele das Sortierungsfeld
	private String getSortierungsFeld ( String feldName ) {
		String sortierungsfeld = '';
		if ( getType( feldName ) != Schema.DisplayType.REFERENCE ) {
			sortierungsfeld = feldName;
		}
		else {
			sortierungsfeld = feldName;
			if ( sortierungsfeld.toLowerCase().endsWith( '__c' ) ) {
				sortierungsfeld = sortierungsfeld.removeEndIgnoreCase( '__c' ) + '__r.name';
			}
			else if ( sortierungsfeld.toLowerCase().endsWith( 'id' ) ) {
				sortierungsfeld = sortierungsfeld.removeEndIgnoreCase( 'id' ) + '.name';
			}
			else {
				//Sonarqube --> do nothing
			}
		}
		return sortierungsfeld;
	}
	
	//Die ReturnURL
	public String returnURL {
		get {
			if ( returnURL == null ) {
				if ( accountIdAttribute == null ) {
					returnURL = '/home/home.jsp';
				}
				else {
					returnURL = '/' + accountIdAttribute;
				}
			}
			return returnURL;
		}
		set;
	}
	
	//Aktualisierung der Aufgaben
	public void refreshAufgaben () {
		aufgabenAbfrageFilter = null;
		aufgabenAbfrage = null;
		taskCount = null;
		aufgabenSeiten = null;
		tasks = null;
	}
	
	//Aktualisierung der Aufgaben
	public void refreshAufgabenundPaginierung () {
		refreshAufgaben();
		aufgabenLimit = null;
		aufgabenOffset = null;
		aufgabenOffsetString = null;
	}
}