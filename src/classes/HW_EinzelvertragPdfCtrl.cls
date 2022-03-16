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
public without sharing class HW_EinzelvertragPdfCtrl {

    //### ATTRIBUTES ###

    public Decimal calculated_stromkosten {get; private set;}
    public final Decimal calculated_mietkosten {get; private set;}
    public final Decimal calculated_gesamtverguetung {get; private set;}

    private AnschriftCSG__mdt anschriftCSG = new AnschriftCSG__mdt();
    private Stromverbrauch__mdt stromverbrauch = new Stromverbrauch__mdt();
	private AccountContactRelation vertragspartner = new AccountContactRelation();
    public EVAddress address {get; private set;}

    private final Lead currentLead;

    //### CLASS METHODS ###

    /**
     * @description Default contructor
     *              get lead and related objects
     **/
    public HW_EinzelvertragPdfCtrl() {

        this.currentLead = HW_SharedVertragsUtils.getLead(ApexPages.currentPage().getParameters().get('id'));

        calculated_stromkosten = Decimal.valueOf(ApexPages.currentPage().getParameters().get('sp'))
		        .setScale(2,System.RoundingMode.HALF_UP);
        calculated_mietkosten  = Decimal.valueOf(ApexPages.currentPage().getParameters().get('mk'))
		        .setScale(2,System.RoundingMode.HALF_UP);

        stromverbrauch = HW_SharedVertragsUtils.getStromverbrauch(this.currentLead);

        //MYPM-1297
        if((currentLead.ADM_Typ__c == 'LPS Flex' || currentLead.ADM_Typ__c == 'LPS Klassik')
		        && currentLead.Stromanschluss__c == 'Solar (nur LPS)' ) {
	
	        calculated_stromkosten = 0;
	        stromverbrauch.Stromverbrauch__c = 0;
        }

        calculated_gesamtverguetung = (calculated_mietkosten + calculated_stromkosten).setScale(2,System.RoundingMode.HALF_UP);
	    loadVertragspartner();
        address = new EVAddress(this);

        for ( AnschriftCSG__mdt anschrift : [
                SELECT
                        Id,
                        Region__c,
                        Strasse__c,
                        Postleitzahl__c,
                        Ort__c,
                        Bezeichnung__c,
                        EmailAdresse__c,
                        TeamManager__c,
                        TeamManagerEmailAdresse__c,
                        Leitregionen__c
                FROM AnschriftCSG__mdt
        ] ) {
            if ( currentLead.PostalCode != null
                    && anschrift.Leitregionen__c.contains( currentLead.PostalCode.left( 2 ) ) ) {

                anschriftCSG = anschrift;
            }
        }
    }
	
	public String getCalculatedMietkosten(){
		return CurrencyFormatter.format(calculated_mietkosten, '€');
	}
	
	public String getFormattedStromverbrauch(){
		return CurrencyFormatter.format(getStromverbrauch(), '');
	}
	
	public String getCalculatedStromkosten(){
		return CurrencyFormatter.format(calculated_stromkosten, '€');
	}
	
	public String getCalculatedGesamtverguetung(){
		return CurrencyFormatter.format(calculated_gesamtverguetung, '€');
	}
	
	public String getBezeichnung(){
		return anschriftCSG.Bezeichnung__c;
	}
	
	public String getStrasse(){
		return anschriftCSG.Strasse__c;
	}
	
	public String getPostleitzahl(){
		return anschriftCSG.Postleitzahl__c;
	}
	
	public String getOrt(){
		return anschriftCSG.Ort__c;
	}
	
	public Decimal getStromverbrauch(){
		return stromverbrauch.Stromverbrauch__c;
	}

    /**
     * @return the class var lead
     **/
        public Lead getCurrentLead() {
            return currentLead;
        }
	
	private void loadVertragspartner(){
		List<AccountContactRelation> accountContactRelations = [
				SELECT
						Id,
						Contact.Firmenbezeichnung__c,
						Contact.FirstName,
						Contact.LastName,
						Contact.MailingStreet,
						Contact.MailingPostalCode,
						Contact.MailingCity
				FROM AccountContactRelation
				WHERE AccountId = :currentLead.Packstation__c
				AND Contact.RecordType.DeveloperName = 'Packstation'
				AND Roles INCLUDES ('Vertragspartner')
				LIMIT 1 ];
		vertragspartner = ( accountContactRelations.size() == 1 )
				? accountContactRelations.get( 0 )
				: new AccountContactRelation();
	}

    public class EVAddress {
        public String name {get;set;}
        public String street {get;set;}
        public String zip {get;set;}
        public String city {get;set;}
        public String firma {get;set;}
        
        public EVAddress(HW_EinzelvertragPdfCtrl instance) {
	        Lead lead = instance.currentLead;
	        AccountContactRelation vertragspartner = instance.vertragspartner;
            if(
                (
                    (vertragspartner.Contact.FirstName == null && vertragspartner.Contact.LastName == null)
                    || vertragspartner.Contact.Firmenbezeichnung__c == null
                ) && (
		                vertragspartner.Contact.MailingCity == null
                    || vertragspartner.Contact.MailingPostalCode == null
                    || vertragspartner.Contact.MailingStreet == null
                )
            ) {

                this.name = lead.Company;
                this.street = lead.Street;
                this.zip = lead.PostalCode;
                this.city = lead.City;

            } else {
                
                if(vertragspartner.Contact.Firmenbezeichnung__c == null){
                    this.name = vertragspartner.Contact.FirstName + ' ' + vertragspartner.Contact.LastName;
                }else{
                    this.name = vertragspartner.Contact.Firmenbezeichnung__c;
                }
                this.street = vertragspartner.Contact.MailingStreet;
                this.zip = vertragspartner.Contact.MailingPostalCode;
                this.city = vertragspartner.Contact.MailingCity;
            }
        }
    }
}