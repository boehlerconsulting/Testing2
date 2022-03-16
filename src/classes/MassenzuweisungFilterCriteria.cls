/**
 *@author       Mats Böhler
 *@created      18.09.2020
 *
 *
 *@description  MassenzuweisungFilterCriteria
 *
 *
 *@changelog    18.09.2020 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class MassenzuweisungFilterCriteria {
	
	private String zugeordnetZu;
	private String aufgabenart;
	private String astName;
	private String debitor;
	private String erledigungBisZum;
	
	private String filiale;
	private String filialart;
	private String nlBrief;
	private String strasse;
	private String inhaber;
	
	private Boolean showAll;
	private String sortBy;
	private String sortDirection;
	private Integer maxRecords;
	private String version;
	
	public MassenzuweisungFilterCriteria ( String [] filterCriteria ) {
		this.version = filterCriteria[ 0 ];
		if ( this.version == 'Task' ) {
			this.zugeordnetZu = filterCriteria[ 1 ];
			this.aufgabenart = filterCriteria[ 2 ];
			this.astName = filterCriteria[ 3 ];
			this.debitor = filterCriteria[ 4 ];
			this.erledigungBisZum = filterCriteria[ 5 ] == null ? null : filterCriteria[ 5 ].removeEnd( ' 00:00:00' );
			this.showAll = Boolean.valueOf( filterCriteria[ 6 ] );
			this.sortBy = filterCriteria[ 7 ];
			this.sortDirection = filterCriteria[ 8 ];
			this.maxRecords = Integer.valueOf( filterCriteria[ 9 ] );
		}
		else if ( this.version == 'Account' ) {
			this.filiale = filterCriteria[ 1 ];
			this.astName = filterCriteria[ 2 ];
			this.filialart = filterCriteria[ 3 ];
			this.nlBrief = filterCriteria[ 4 ];
			this.strasse = filterCriteria[ 5 ];
			this.inhaber = filterCriteria[ 6 ];
			this.showAll = Boolean.valueOf( filterCriteria[ 7 ] );
			this.sortBy = filterCriteria[ 8 ];
			this.sortDirection = filterCriteria[ 9 ];
			this.maxRecords = Integer.valueOf( filterCriteria[ 10 ] );
		}
		else {
			//Sonarqube --> do nothing
		}
	}
	
	public String getFiliale () {
		return String.escapeSingleQuotes( this.filiale );
	}
	
	public String getFilialart () {
		return String.escapeSingleQuotes( this.filialart );
	}
	
	public String getNlBrief () {
		return String.escapeSingleQuotes( this.nlBrief );
	}
	
	public String getStrasse () {
		return String.escapeSingleQuotes( this.strasse );
	}
	
	public String getInhaber () {
		return String.escapeSingleQuotes( this.inhaber );
	}
	
	public String getZugeordnetZu () {
		return String.escapeSingleQuotes( this.zugeordnetZu );
	}
	
	public String getAufgabenart () {
		return String.escapeSingleQuotes( this.aufgabenart );
	}
	
	public String getAstName () {
		return String.escapeSingleQuotes( this.astName );
	}
	
	public String getDebitor () {
		return String.escapeSingleQuotes( this.debitor );
	}
	
	public String getErledigungBisZum () {
		return String.escapeSingleQuotes( this.erledigungBisZum );
	}
	
	public Boolean getShowAll () {
		return this.showAll;
	}
	
	public String getSortBy () {
		return String.escapeSingleQuotes( this.sortBy );
	}
	
	public String getSortDirection () {
		return String.escapeSingleQuotes( this.sortDirection );
	}
	
	public Integer getMaxRecords () {
		return this.maxRecords;
	}
	
	public String getVersion () {
		return String.escapeSingleQuotes( this.version );
	}
}