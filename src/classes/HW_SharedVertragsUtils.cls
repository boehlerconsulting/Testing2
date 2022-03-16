/**
 * @author      Stefan Richter (stefan.richter@hundw.de)
 *              H+W CONSULT GmbH
 *              Bahnhofstr. 3
 *              21244 Buchholz i. d. Nordheide
 *              Germany
 *              https://www.hundw.de
 *
 * @description class for <insert-description-here>
 *
 * TIMELINE
 * 13.11.20      Stefan Richter  Initial release.
 **/
public without sharing class HW_SharedVertragsUtils {
	
	/**
	 * @param ld the lead to get the partner record for
	 *
	 * @return a single matching partner record
	 **/
	public static StrategischerPartner__mdt getStrategischePartner ( Lead ld ) {
		
		Boolean solarPanel = ld.Solarpanel__c == 'Ja';
		List<StrategischerPartner__mdt> partners = [
				SELECT Id,
						MasterLabel,
						ModuleVon__c,
						ModuleBis__c,
						Packstationstyp__c,
						ArtDerMiete__c,
						ArtDerStromkosten__c,
						DeveloperName,
						Label,
						MietkostensatzInEuro__c,
						StromkostensatzInEuro__c,
						OrderTextbaustein__c,
						exklusiveSteuerschrank__c
				FROM StrategischerPartner__mdt
				WHERE Packstationstyp__c = :ld.ADM_Typ__c
				AND Solarpanel__c = :solarPanel
				AND MasterLabel = :ld.ZuordnungZuRahmenvertrag__c
		];
		StrategischerPartner__mdt p;
		
		for ( StrategischerPartner__mdt lp : partners ) {
			
			if ( ( lp.ArtDerMiete__c.equals( 'Spanne' ) && ld.Summe_aller_Module__c >= lp.ModuleVon__c && ld.Summe_aller_Module__c <= lp.ModuleBis__c )
					|| lp.ArtDerMiete__c.equals( 'Modul' ) || lp.ArtDerMiete__c.equals( 'Pauschale' ) ) {
				p = lp;
				break;
			}
		}
		return p;
	}
	
	/**
	 * @param ld the lead to get the partner record for
	 *
	 * @return a single matching partner record
	 **/
	public static Stromverbrauch__mdt getStromverbrauch ( Lead ld ) {
		List<Stromverbrauch__mdt> svList = [
				SELECT Id,
						MasterLabel,
						Stromverbrauch__c,
						Packstationstyp__c
				FROM Stromverbrauch__mdt
				WHERE Packstationstyp__c = :ld.ADM_Typ__c
				AND Hersteller__c = :ld.ADM_Hersteller__c
				AND BetriebStromanschluss__c = :ld.Stromanschluss__c
		];
		if ( svList != null && !svList.isEmpty() ) {
			return svList.get( 0 );
		}
		return new Stromverbrauch__mdt();
	}
	
	public static Filialnetzaenderung__c getFnae ( Id fnaeId ) {
		return [
				SELECT
						Id,
						VGL__c,
						Filiale_Filialpartner__c,
						Filiale_Filialpartner__r.ASt_Name__c,
						Filiale_Filialpartner__r.Filialart__c,
						Filiale_Filialpartner__r.Filialtyp_OZ__c,
						Filiale_Filialpartner__r.E_Mail_Vertragspartner__c,
						Filiale_Filialpartner__r.Phone,
						Filiale_Filialpartner__r.Fax,
						Filiale_Filialpartner__r.Betreiber__c,
						Filiale_Filialpartner__r.Telefon_Vertragspartner__c,
						Filiale_Filialpartner__r.Name,
						Filiale_Filialpartner__r.GL__c,
						//Filiale_Filialpartner__r.GL__r.Leiter__c,
						Filiale_Filialpartner__r.ShippingAddress,
						Filiale_Filialpartner__r.ShippingCity,
						Filiale_Filialpartner__r.ShippingStreet,
						Filiale_Filialpartner__r.ShippingPostalCode,
						Filiale_Filialpartner__r.ShippingCountry,
						Filiale_Filialpartner__r.Filiale_Hausnummer__c,
						Filiale_Filialpartner__r.Ortsteil_Postanschrift__c,
						Filiale_Filialpartner__r.Rechtsform__c,
						Filiale_Filialpartner__r.Juristischer_Name_Gewerbeanmeldung__c,
						Filiale_Filialpartner__r.Juristischer_Name_Gewerbeanmeldung_1__c,
						Filiale_Filialpartner__r.Juristischer_Name_Gewerbeanmeldung_2__c,
						Filiale_Filialpartner__r.Juristischer_Name_Gewerbeanmeldung_3__c,
						Filiale_Filialpartner__r.X1_Ansprechpartner_Vorname__c,
						Grund__c,
						Erledigungsdatum_FNAE__c,
						Netzentscheidung__c,
						Schliessung_avisiert_fuer__c
				FROM Filialnetzaenderung__c
				WHERE Id = :fnaeId
		];
	}
	
	public static Lead getLead ( Id leadId ) {
		return [
				SELECT Id,
						Name,
						FirstName,
						LastName,
						Company,
						Street,
						PostalCode,
						City,
						PODID_Lookup__r.Wert__c,
						NL_Brief__c,
						VL__c,
						VL_Name__c,
						VL__r.Name,
						VL__r.ShippingStreet,
						VL__r.ShippingPostalCode,
						VL__r.ShippingCity,
						VL__r.GL__c,
						VL__r.GL__r.RVU_Team__c,
						VL__r.GL__r.RVU_Team__r.Strasse__c,
						VL__r.GL__r.RVU_Team__r.PLZ__c,
						VL__r.GL__r.RVU_Team__r.Ort__c,
						ADM_Typ__c,
						Bewertung_Zentrale__c,
						ZuordnungZuRahmenvertrag__c,
						DokumentationDurchRTFreigebenDatum__c,
						Summe_aller_Module__c,
						Solarpanel__c,
						Stromversorgung__c,
						Stromanschluss__c,
						Screening__c,
						STOG_Gesellschaft__c,
						VP_Firma__c,
						VP_Vorname__c,
						VP_Name__c,
						VP_Ort__c,
						VP_PLZ__c,
						VP_Hausnummer__c,
						VP_Strasse__c,
						Uebergabetermin__c,
						IBAN__c,
						Bank__c,
						BIC__c,
						Packstation__c,
						ADM_Hersteller__c
				FROM Lead
				WHERE Id = :leadId
		];
	}
	
	public static OrgE_DP__c getOrgE_DP ( Id userId ) {
		String orgeName = getUserOrgeDpName( userId );
		return getOrgeDpByName( orgeName );
	}
	
	public static OrgE_DP__c getOrgeDpByName ( String orgeName ) {
		OrgE_DP__c orgEDP = [
				SELECT
						Id,
						Name,
						Leiter__c,
						Koordinator__c,
						OrgE_DP_Name__c,
						RVU_Team__c
				FROM OrgE_DP__c
				WHERE OrgE_Leiter__c = :orgeName
		].get( 0 );
		return orgEDP;
	}
	
	public static String getUserOrgeDpName ( Id userId ) {
		User u = [ SELECT OrgE_DP__c FROM User WHERE Id = :userId ].get( 0 );
		return u.OrgE_DP__c;
	}
	
	public static Id getUserOrgeDpDummyAccountId ( String vgl ) {
		Id orgeDpDummyAccountId;
		
		if ( String.isNotBlank( vgl ) ) {
			for ( Account orgedp : [
					SELECT Id, Name, RecordType.DeveloperName
					FROM Account
					WHERE RecordType.DeveloperName = 'OrgE_Dummy'
					AND Name = :vgl
					LIMIT 1
			] ) {
				orgeDpDummyAccountId = orgedp.Id;
			}
		}
		
		return orgeDpDummyAccountId;
	}
	
	public static Boolean canGenAnschreibenCSG ( Id leadId ) {
		
		Lead lead = HW_SharedVertragsUtils.getLead( leadId );
		
		String roleDevName = [ SELECT Id, Name, DeveloperName FROM UserRole WHERE Id = :UserInfo.getUserRoleId() ].DeveloperName;
		Boolean isOrgeDpMatch = false;
		
		if ( lead.VL__c != null && lead.VL__r.Name != null ) {
			String vlName = '%' + lead.VL__r.Name + '%';
			List<User> userorgeDP = [ SELECT OrgE_DP__c FROM User WHERE Id = :UserInfo.getUserId() AND OrgE_DP__c LIKE :vlName ];
			
			if ( userorgeDP != null && userorgeDP.size() > 0 ) {
				isOrgeDpMatch = true;
			}
		}
		
		if ( roleDevName == 'Regionale_Vertriebsunterstuetzung' || isOrgeDpMatch ) {
			return true;
		}
		
		return false;
	}
	
	public static List<String> getAllObjFieldsByObjectName ( String objName ) {
		List<String> fieldNames = new List<String>();
		Schema.SObjectType targetType = Schema.getGlobalDescribe().get( objName );
		Map<String, Schema.SObjectField> fieldMap = targetType.getDescribe().fields.getMap();
		for ( Schema.SObjectField field : fieldMap.values() ) {
			fieldNames.add( field.getDescribe().getName() );
		}
		return fieldNames;
	}
	
	public static SObject queryAllFields ( String objName, Id recordId, String filterField ) {
		String allfields = HW_SharedVertragsUtils.concatStrings( HW_SharedVertragsUtils.getAllObjFieldsByObjectName( objName ), ', ' );
		List<SObject> result = Database.query( 'SELECT ' + allfields + ' FROM ' + objName + ' WHERE '
				+ filterField + ' = \'' + recordId + '\' LIMIT 1' );
		return result != null && !result.isEmpty() ? result.get( 0 ) : null;
	}
	
	public static SObject queryAllFields ( String objName, Id recordId, String filterField, String additionalFields ) {
		String allfields = HW_SharedVertragsUtils.concatStrings( HW_SharedVertragsUtils.getAllObjFieldsByObjectName( objName ), ', ' );
		if ( String.isNotBlank( additionalFields ) ) {
			allfields = allfields + ',' + additionalFields;
		}
		return Database.query( 'SELECT ' + allfields + ' FROM ' + objName + ' WHERE '
				+ filterField + ' = \'' + recordId + '\' LIMIT 1' );
	}
	
	public static String concatStrings ( List<String> sValues, String seperator ) {
		
		String result = '';
		for ( String str : sValues ) result = result + str + seperator;
		return result.removeEnd( seperator );
	}
}