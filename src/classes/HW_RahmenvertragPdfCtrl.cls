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
 * 14.10.20      Stefan Richter  Initial release.
 **/
public without sharing class HW_RahmenvertragPdfCtrl {
	
	//### ATTRIBUTES ###
	
	public List<RenderedText> orderedVertragsTexte { get; private set; }
	
	private final Lead currentLead;
	private Map<String, Vertragsbaustein__mdt> bausteinDefByDevName = new Map<String, Vertragsbaustein__mdt>();
	private List<Integer> orderNumbers;
	private StrategischerPartner__mdt partner {
		get {
			
			if ( partner == null ) {
				partner = HW_SharedVertragsUtils.getStrategischePartner( this.currentLead );
			}
			return partner;
		}
		set;
	}
	
	//### CLASS METHODS ###
	
	/**
	 * @description Default contructor
	 *              get lead and related objects
	 **/
	public HW_RahmenvertragPdfCtrl () {
		this.currentLead = HW_SharedVertragsUtils.getLead( ApexPages.currentPage().getParameters().get( 'id' ) );
		orderNumbers = parseOrderNumber( partner?.OrderTextbaustein__c );
	}
	
	//the method called from the page action
	
	public PageReference dmlExecHook () {
		
		List<EmailTemplate> vertragsTemplates = getOrderedTemplates();
		
		this.orderedVertragsTexte = renderTemplates( vertragsTemplates, currentLead.Id );
		
		return null;
	}
	
	/**
	 * @return the class var lead
	 **/
	public Lead getCurrentLead () {
		return currentLead;
	}
	
	/**
	 * @return all emailtemplates
	 **/
	private List<EmailTemplate> getOrderedTemplates () {
		
		List<EmailTemplate> templates = new List<EmailTemplate>();
		
		for ( Vertragsbaustein__mdt vb : [
				SELECT
						Id,
						DeveloperName,
						OrderNumber__c
				FROM Vertragsbaustein__mdt
				WHERE OrderNumber__c IN :orderNumbers
		] ) {
			bausteinDefByDevName.put( vb.DeveloperName, vb );
		}
		templates = [ SELECT Id, DeveloperName FROM EmailTemplate WHERE DeveloperName IN :bausteinDefByDevName.keySet() ];
		return templates;
	}
	
	/**
	 * @param templates email templates to render
	 * @param whoId object id for values to pass in
	 *
	 * @return the rendered text wrapper containing texts
	 **/
	private List<RenderedText> renderTemplates ( List<EmailTemplate> templates, Id whoId ) {
		List<RenderedText> renderedTemplates = new List<RenderedText>();
		
		Vertragsformeln__c vformula = new Vertragsformeln__c();
		
		vformula.StromkostenInEuro__c = getStrompreis( currentLead, partner );
		vformula.MietkostenInEuro__c = getMietpreis( currentLead, partner );
		
		insert vformula;
		
		for ( EmailTemplate emailTemplate : templates ) {
			Messaging.SingleEmailMessage renderResult = Messaging.renderStoredEmailTemplate( emailTemplate.Id, whoId, vformula.Id );
			
			RenderedText tx = new RenderedText();
			
			tx.heading = renderResult.subject;
			tx.body = renderResult.htmlBody;
			
			for ( String str : bausteinDefByDevName.keySet() ) {
				Vertragsbaustein__mdt vertragsbaustein = bausteinDefByDevName.get( str );
				if ( vertragsbaustein.DeveloperName.equals( emailTemplate.DeveloperName ) ) {
					tx.orderNumber = vertragsbaustein.OrderNumber__c;
				}
			}
			
			renderedTemplates.add( tx );
		}
		
		delete vformula;
		
		renderedTemplates = sortByOrderNumber( renderedTemplates, orderNumbers );
		return renderedTemplates;
	}
	
	//### STATIC HELPER METHODS ###
	
	/**
	 * @param unorderedTexts list of text to sort
	 * @param newOrder sortorder as list
	 * @description thsi sorts the templates and will add a '§' running number in front of the heading
	 *
	 * @return sorted list of rendered text
	 **/
	private static List<RenderedText> sortByOrderNumber ( List<RenderedText> unorderedTexts, List<Integer> newOrder ) {
		
		List<RenderedText> orderedTexts = new List<RenderedText>();
		
		for ( Integer i : newOrder ) {
			Integer paragrahNumber = 1;
			for ( RenderedText renderedText : unorderedTexts ) {
				if ( renderedText.orderNumber == i ) {
					renderedText.heading = '§' + paragrahNumber + ' ' + renderedText.heading;
					orderedTexts.add( renderedText );
				}
			}
		}
		return orderedTexts;
	}
	
	/**
	 * @param ld lead to calculate mietpreis for
	 * @param lp partner with mietpreis values
	 *
	 * @return the calculated mietpreis
	 **/
	public static Double getMietpreis ( Lead ld, StrategischerPartner__mdt lp ) {
		Double calculated_mietpreis;
		if ( lp == null || lp.ArtDerMiete__c == null ) {
			return calculated_mietpreis;
		}
		if ( lp.ArtDerMiete__c.equals( 'Spanne' ) || lp.ArtDerMiete__c.equals( 'Pauschale' ) ) {
			calculated_mietpreis = lp.MietkostensatzInEuro__c;
		}
		else if ( lp.ArtDerMiete__c.equals( 'Modul' ) ) {
			calculated_mietpreis = lp.MietkostensatzInEuro__c * ( ld.Summe_aller_Module__c - ( lp.exklusiveSteuerschrank__c == true ? 1 : 0 ) );
		}
		else {
			//Sonarqube --> do nothing
		}
		return calculated_mietpreis;
	}
	
	/**
	 * @param ld lead to calculate strompreis for
	 * @param lp partner with strompreis values
	 *
	 * @return the calculated strompreis
	 **/
	public static Double getStrompreis ( Lead ld, StrategischerPartner__mdt lp ) {
		Double calculated_strompreis;
		if ( lp == null || lp.ArtDerStromkosten__c == null ) {
			return calculated_strompreis;
		}
		if ( lp.ArtDerStromkosten__c.equals( 'Spanne' ) || lp.ArtDerStromkosten__c.equals( 'Pauschale' ) ) {
			calculated_strompreis = lp.StromkostensatzInEuro__c;
		}
		return calculated_strompreis;
	}
	
	/**
	 * @param orderTextbausteine ;-seperated list of integer in a string
	 *
	 * @return parsed list of integer in an object
	 **/
	private static List<Integer> parseOrderNumber ( String orderTextbausteine ) {
		List<Integer> orderNumbers = new List<Integer>();
		
		if ( String.isNotBlank( orderTextbausteine ) ) {
			for ( String s : orderTextbausteine.trim().split( ';' ) ) {
				orderNumbers.add( Integer.valueOf( s ) );
			}
		}
		return orderNumbers;
	}
	
	/**
	 * @description TextWrapper to contain all values needed in PDF
	 **/
	private class RenderedText {
		public Decimal orderNumber { get; set; }
		public String heading { get; set; }
		public String body {
			get {
				return body.remove( 'p{margin-top:0px; margin-bottom:0px;}' );
			}
			set;
		}
	
	}
}