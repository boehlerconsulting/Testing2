/**
 *@author       Mats Böhler
 *@created      20.08.2020
 *
 *
 *@description  WartezeitrisikoDataCtrl
 *
 *
 *@changelog    20.08.2020 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class WartezeitrisikoDataCtrl {
	
	@TestVisible
	private Dataset dataset = new Dataset();
	private Map<Decimal, String> colorByYear = new Map<Decimal, String>();
	private Id recordId;
	private Integer kwVon;
	private Integer kwBis;
	private Integer startingYear;
	
	@AuraEnabled
	public static String loadData ( Id recordId, Integer kwVon, Integer kwBis, Integer startingYear ) {
		
		WartezeitrisikoDataCtrl instance = new WartezeitrisikoDataCtrl();
		try {
			instance.recordId = recordId;
			instance.kwVon = kwVon;
			instance.kwBis = kwBis;
			instance.startingYear = startingYear;
			instance.loadData();
		}
		catch ( Exception e ) {
			
			throw new AuraHandledException( e.getMessage() );
		}
		return JSON.serialize( instance.dataset );
	}
	
	private void loadData () {
		
		dataset.labels = '[';
		Map<String, Data> dataByYear = new Map<String, Data>();
		
		Map<String, String> riskByYearAndCalendarweek = new Map<String, String>();
		for ( Wartezeitrisiko__c wartezeitrisiko : [
				SELECT
						Id,
						Calendarweek__c,
						Year__c,
						Risiko__c
				FROM Wartezeitrisiko__c
				WHERE Qualitaetsinformation__c = :recordId
				AND Year__c >= :startingYear
				AND Calendarweek__c >= :kwVon
				AND Calendarweek__c <= :kwBis
				ORDER BY Year__c DESC, Calendarweek__c ASC NULLS LAST
		] ) {
			
			riskByYearAndCalendarweek.put(
					String.valueOf( wartezeitrisiko.Year__c )
							+ String.valueOf( wartezeitrisiko.Calendarweek__c ),
					String.valueOf( wartezeitrisiko.Risiko__c )
			);
		}
		
		for ( Integer year = startingYear; year <= Date.today().year(); year++ ) {
			for ( Integer calendarWeek = kwVon; calendarWeek <= kwBis; calendarWeek++ ) {
				
				dataset.labels += dataset.labels.contains( String.valueOf( calendarWeek ) )
						? ''
						: '"' + String.valueOf( calendarWeek ) + '",';
				
				String key = String.valueOf( year ) + String.valueOf( calendarWeek );
				String riskValue = riskByYearAndCalendarweek.containsKey( key )
						? riskByYearAndCalendarweek.get( key )
						: 'null';
				
				if ( dataByYear.containsKey( String.valueOf( year ) ) ) {
					Data existingData = dataByYear.get( String.valueOf( year ) );
					existingData.detail += '"' + riskValue + '",';
				}
				else {
					Data newData = new Data();
					newData.label = String.valueOf( year );
					newData.backgroundColor = getColor( year );
					newData.borderColor = getColor( year );
					newData.detail = '["' + riskValue + '",';
					dataByYear.put( String.valueOf( year ), newData );
				}
			}
		}
		
		dataset.labels = dataset.labels.removeEnd( ',' );
		dataset.labels += ']';
		for ( String year : dataByYear.keySet() ) {
			Data existingData = dataByYear.get( year );
			existingData.detail = existingData.detail.removeEnd( ',' ) + ']';
		}
		dataset.datas = dataByYear.values();
	}
	
	private String getColor ( Decimal year ) {
		if ( colorByYear.isEmpty() ) {
			colorByYear.put( Date.today().year(), 'rgba(255,204,0)' );
			colorByYear.put( Date.today().year() - 1, 'rgba(0,0,255)' );
			colorByYear.put( Date.today().year() - 2, 'rgba(0,255,0)' );
		}
		return colorByYear.containsKey( year ) ? colorByYear.get( year ) : 'rgba(255,204,0)';
	}
	
	@TestVisible
	private class Dataset {
		public String labels { get; set; }
		public List<Data> datas { get; set; }
	}
	
	private class Data {
		
		public String label { get; set; }
		public String detail { get; set; }
		public String backgroundColor { get; set; }
		public String borderColor { get; set; }
	
	}
}