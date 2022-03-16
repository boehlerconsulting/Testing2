/**
* @author: Copyright (c) 2015 Daniel Hoechst, https://github.com/dhoechst/Salesforce-Test-Factory/blob/master/LICENSE.md
*/
@IsTest
public  class TestFactoryDefaults{
	
	// To specify defaults for objects, use the naming convention [ObjectName]Defaults.
	// For custom objects, omit the __c from the Object Name
	
	public class AccountDefaults implements TestFactory.FieldDefaults {
		public Map<Schema.SObjectField, Object> getFieldDefaults() {
			return new Map<Schema.SObjectField, Object> {
					Account.Name => 'Test Account',
					Account.RecordTypeId => Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
					.get( 'Filiale' ).getRecordTypeId(),
					Account.Filialart__c => 'DHL-Paketshop',
					Account.Eroeffnungsdatum__c => Date.today().addYears(-1),
					Account.NL_Brief__c => 'NL Dresden'
					
			};
		}
	}
	
	public class DummyFilialeDefaults implements TestFactory.FieldDefaults {
		public Map<Schema.SObjectField, Object> getFieldDefaults() {
			return new Map<Schema.SObjectField, Object> {
					Account.Name => 'Dummy Filiale Test',
					Account.RecordTypeId => Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
							.get( 'Filiale_Dummy' ).getRecordTypeId()
			};
		}
	}
	
	public class PriohilfeAufgabenverwaltungDefaults implements TestFactory.FieldDefaults {
		public Map<Schema.SObjectField, Object> getFieldDefaults() {
			return new Map<Schema.SObjectField, Object> {
					PriohilfeAufgabenverwaltung__c.Version__c => 'ohne Akquise',
					PriohilfeAufgabenverwaltung__c.AmpelAktiviert__c => true
			};
		}
	}
	
	public class TaskDefaults implements TestFactory.FieldDefaults {
		public Map<Schema.SObjectField, Object> getFieldDefaults() {
			return new Map<Schema.SObjectField, Object> {
					Task.Verfallsdatum__c => Date.today().addDays( 28 ),
					Task.Status => 'Nicht begonnen',
					Task.Aufgabenart__c => 'Individuelle Aufgabe (Sonstiges)',
					Task.Auftragnehmer__c => 'Vertriebsleiter',
					Task.Auftraggeber__c => '1T1 Field Sales',
					Task.Erledigung_bis_zum__c => Date.today().addDays( 14 ),
					Task.RecordTypeId => Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
							.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId()
			};
		}
	}
	
	public class ContactDefaults implements TestFactory.FieldDefaults {
		public Map<Schema.SObjectField, Object> getFieldDefaults() {
			return new Map<Schema.SObjectField, Object> {
					Contact.FirstName => 'First',
					Contact.LastName => 'Last'
			};
		}
	}
	
	public class OpportunityDefaults implements TestFactory.FieldDefaults {
		public Map<Schema.SObjectField, Object> getFieldDefaults() {
			return new Map<Schema.SObjectField, Object> {
					Opportunity.Name => 'Test Opportunity',
					Opportunity.StageName => 'Closed Won',
					Opportunity.CloseDate => System.today()
			};
		}
	}
	
	public class CaseDefaults implements TestFactory.FieldDefaults {
		public Map<Schema.SObjectField, Object> getFieldDefaults() {
			return new Map<Schema.SObjectField, Object> {
					Case.Subject => 'Test Case'
			};
		}
	}
	
	public class LeadDefaults implements TestFactory.FieldDefaults {
		public Map<Schema.SObjectField, Object> getFieldDefaults() {
			return new Map<Schema.SObjectField, Object> {
					Lead.LastName => 'Test',
					Lead.PostalCode => '64653',
					Lead.STOG_Gesellschaft__c => 'REWE',
					Lead.Company => 'TestCompany'
			};
		}
	}
	
	public class OrgE_DPDefaults implements TestFactory.FieldDefaults {
		public Map<Schema.SObjectField, Object> getFieldDefaults() {
			return new Map<Schema.SObjectField, Object> {
					OrgE_DP__c.Name => 'Test OrgE_DP',
					OrgE_DP__c.Koordinator__c => UserInfo.getUserId()
			
			};
		}
	}
	
	public class EmailVersandDefaults implements TestFactory.FieldDefaults {
		public Map<Schema.SObjectField, Object> getFieldDefaults() {
			return new Map<Schema.SObjectField, Object> {
					EmailVersand__c.Email_von__c => 'von@mail.com',
					EmailVersand__c.Email_an__c => 'an@mail.com',
					EmailVersand__c.Email_CC__c => 'cc@mail.com',
					EmailVersand__c.Email_Betreff__c => 'Test Subject',
					EmailVersand__c.Email_Nachricht__c => 'Test Body'
			};
		}
	}
	
	public class FilterCriteria {
		public Boolean isClosed { get; set; }
		public Decimal months { get; set; }
		public Id recordId { get; set; }
		public String sObjectType { get; set; }
		public String version { get; set; }
		public String sortBy { get; set; }
		public String sortDirection { get; set; }
		public String aufgabenstatusValue { get; set; }
		public String selectedTaskIds { get; set; }
		public String changedTaskIds { get; set; }
		public String nlBrief { get; set; }
		
		public FilterCriteria (
				Boolean isClosed,
				Decimal months,
				Id recordId,
				String sObjectType,
				String version,
				String sortBy,
				String sortDirection,
				String aufgabenstatusValue,
				String nlBrief ) {
			
			this.isClosed = isClosed;
			this.months = months;
			this.recordId = recordId;
			this.sObjectType = sObjectType;
			this.version = version;
			this.sortBy = sortBy;
			this.sortDirection = sortDirection;
			this.aufgabenstatusValue = aufgabenstatusValue;
			this.nlBrief = nlBrief;
		}
		
		public FilterCriteria (
				Id recordId,
				String sObjectType ) {
			
			this.recordId = recordId;
			this.sObjectType = sObjectType;
		}
	}
}