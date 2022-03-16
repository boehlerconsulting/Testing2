/**
 *@author       Mats Böhler
 *@created      28.03.2020
 *
 *
 *@description  PriorizationHelpBase
 *
 *
 *@changelog    28.03.2020 Mats Böhler  - Created
 *              
 * 
 */
public without sharing virtual class PriorizationHelpBase {
	
	protected List<PriohilfeUebersicht__mdt> columnDefinitions = new List<PriohilfeUebersicht__mdt>();
	protected PriorizationHelpSetting setting = new PriorizationHelpSetting();
	@TestVisible
	protected List<Column> columns = new List<Column>();
	protected Map<String, PriohilfeAmpelKonfiguration__mdt> ampelKonfigurationsByName =
			new Map<String, PriohilfeAmpelKonfiguration__mdt>();
	
	
	protected virtual void createColumns () {
		Set<String> queryFields = new Set<String>();
		for ( PriohilfeUebersicht__mdt columnDefinition : columnDefinitions ) {
			Column column = new Column();
			column.label = columnDefinition.LabelSpalte__c;
			column.fieldName = columnDefinition.Feldname__c;
			column.type = columnDefinition.Feldtyp__c;
			column.fieldLabel = columnDefinition.Feldlabel__c;
			column.allowSort = columnDefinition.Sortierbar__c;
			column.position = columnDefinition.Nummerierung__c;
			columns.add( column );
			queryFields.add( columnDefinition.Feldlabel__c );
			queryFields.add( columnDefinition.Feldname__c );
		}
		for ( String queryField : queryFields ) {
			setting.fields += queryField + ',';
		}
		columns.sort();
		setting.fields = setting.fields.removeEnd( ',' );
	}
	
	protected void loadColumnDefinitions () {
		columnDefinitions = [
				SELECT
						Id,
						LabelSpalte__c,
						Feldlabel__c,
						Feldname__c,
						Feldtyp__c,
						Sortierbar__c,
						Nummerierung__c
				FROM PriohilfeUebersicht__mdt
				WHERE Objekt__c = :setting.sObjectType
				AND Rolle__c = :setting.role
				AND Herkunft__c = :setting.origin
				ORDER BY Nummerierung__c ASC NULLS LAST
		];
	}
	
	protected String getTrafficLight ( String color ) {
		return String.format(
				'<img border="0" alt="status color" src="/img/samples/light_{0}.gif">',
				new List<Object> {
						color
				}
		);
	}
	
	protected String addFieldIfMissing ( String fieldName ) {
		if ( !setting.fields.contains( fieldName ) ) {
			setting.fields += ',' + fieldName;
		}
		return setting.fields;
	}
	
	public class Column implements Comparable {
		public String label { get; set; }
		public String fieldName { get; set; }
		public String type { get; set; }
		public String fieldLabel { get; set; }
		public Boolean allowSort { get; set; }
		public Decimal position { get; set; }
		
		public Integer compareTo ( Object obj ) {
			Column column = ( Column ) ( obj );
			if ( this.position > column.position ) {
				return 1;
			}
			if ( this.position == column.position ) {
				return 0;
			}
			return -1;
		}
	}
}