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
 * 06.01.21      Stefan Richter  Initial release.
 **/
public with sharing class AnschreibenCSGCtrl {
	
	private User vkUser;
	private SenderAddress senderAddress;
	
	private final Lead currentLead;
	
	private Map<String, String> documentIdByDeveloperName = new Map<String, String>();
	private String folderId = '';
	
	private AnschriftCSG__mdt anschriftCSG = new AnschriftCSG__mdt();
	
	//### CLASS METHODS ###
	
	/**
	 * @description Default contructor
	 *              get lead and related objects
	 **/
	public AnschreibenCSGCtrl () {
		
		try {
			//getting aditional params --> ApexPages.currentPage().getParameters().get('p1');
			
			String param_Id = ApexPages.currentPage().getParameters().get( 'id' );
			
			this.currentLead = HW_SharedVertragsUtils.getLead( param_Id );
			loadAddress();
			loadLogos();
			findLeitregion();
		}
		catch ( Exception e ) {
			throw new DmlException( 'Can not generate pdf: ' + e.getMessage() );
		}
	}
	
	/**
	 * @description all dml can be hooked her if it is forbidden to
	 *              call it from constructor, this is hooked to
	 *              the action parameter of the page
	 * @return a empty page reference
	 **/
	public PageReference dmlExecHook () {
		return null;
	}
	
	/**
	 * @return the class var lead
	 **/
	public Lead getCurrentLead () {
		return currentLead;
	}
	
	/**
	 * @return the class var vk user
	 **/
	public User getVkUser () {
		return vkUser;
	}
	
	/**
	 * @return the class var senderAddress user
	 **/
	public SenderAddress getSenderAddress () {
		return senderAddress;
	}
	
	/**
	 * @return returns the logo url for Logo_Post
	 **/
	public String getPostLogo () {
		return getLogo( 'Logo_Post' );
	}
	
	/**
	 * @return returns the logo url for Logo_DHL
	 **/
	public String getDHLLogo () {
		return getLogo( 'Logo_DHL' );
	}
	
	/**
	 * @return field getter Bezeichnung__c
	 **/
	public String getBezeichnungCSG () {
		return anschriftCSG.Bezeichnung__c;
	}
	
	/**
	 * @return field getter Strasse__c
	 **/
	public String getStrasseCSG () {
		return anschriftCSG.Strasse__c;
	}
	
	/**
	 * @return field getter Postleitzahl__c
	 **/
	public String getPostleitzahlCSG () {
		return anschriftCSG.Postleitzahl__c;
	}
	
	/**
	 * @return field getter Ort__c
	 **/
	public String getOrtCSG () {
		return anschriftCSG.Ort__c;
	}
	
	/**
	 * @return field getter Ort__c
	 **/
	public String getAnsprechpartnerCSG () {
		return anschriftCSG.Ort__c;
	}
	
	/**
	 * @description get all Documents for a specific folder
	 *              and put it to documentIdByDeveloperName
	 **/
	private void loadLogos () {
		if ( !documentIdByDeveloperName.isEmpty() ) {
			return;
		}
		for ( Document document : [
				SELECT
						Id,
						DeveloperName
				FROM Document
				WHERE FolderId = :getFolderId()
		] ) {
			
			documentIdByDeveloperName.put( document.DeveloperName, document.Id );
		}
	}
	
	/**
	 * @description generates the document url for the given filename
	 * @param documentName the name if the requested document
	 * @return the url that leads to the document
	 **/
	private String getLogo ( String documentName ) {
		return Url.getSalesforceBaseUrl().toExternalForm().replace( 'visualforce.com', 'documentforce.com' )
				+ '/servlet/servlet.ImageServer?id='
				+ documentIdByDeveloperName.get( documentName )
				+ '&oid='
				+ UserInfo.getOrganizationId();
	}
	
	/**
	 * @description staticly returns the folder Id for Logos_Allgemein
	 * @return the folder id for Logos_Allgemein
	 **/
	private String getFolderId () {
		if ( folderId == '' ) {
			folderId = [
					SELECT
							Id
					FROM Folder
					WHERE DeveloperName = 'Logos_Allgemein'
					LIMIT 1
			].Id;
		}
		return folderId;
	}
	
	/**
	 * @description loads vl and vk user for the current user
	 * @param userId the user id vl and vk shold be loaded for
	 **/
	private void loadAddress () {
		try {
			User user = [ SELECT Id,Profile.Name FROM User WHERE Id = :UserInfo.getUserId() ];
			String profileName = user.Profile.Name;
			
			if ( profileName.contains( 'VL' )
					|| profileName.contains( 'VK' )
					|| profileName.contains( 'VM' ) ) {
				this.senderAddress = new SenderAddress(
						currentLead.VL__r.ShippingStreet,
						currentLead.VL__r.ShippingPostalCode,
						currentLead.VL__r.ShippingCity
				);
			}
			else {
				this.senderAddress = new SenderAddress(
						currentLead.VL__r.GL__r.RVU_Team__r.Strasse__c,
						currentLead.VL__r.GL__r.RVU_Team__r.PLZ__c,
						currentLead.VL__r.GL__r.RVU_Team__r.Ort__c
				);
			}
			
			OrgE_DP__c orgEDP = [
					SELECT
							Koordinator__c,
							Koordinator__r.Email,
							Koordinator__r.Phone,
							Koordinator__r.FirstName,
							Koordinator__r.LastName
					FROM OrgE_DP__c
					WHERE Name = :currentLead.NL_Brief__c
			];
			this.vkuser = new User(
					Email = orgEDP.Koordinator__r.Email,
					Phone = orgEDP.Koordinator__r.Phone,
					FirstName = orgEDP.Koordinator__r.FirstName,
					LastName = orgEDP.Koordinator__r.LastName
			);
		
		}
		catch ( Exception ex ) {
			throw new DmlException( 'Die OrgE DP, VL, NL Brief oder der Koordinator sind nicht korrekt eingereichtet.' );
		}
	}
	
	/**
	 * @description sets the anschriftCSG from the AnschriftCSG__mdt
	 *              via Leitregionen__c
	 **/
	private void findLeitregion () {
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
	
	//AURA DISPATCHER METHODS
	
	/**
 * @description generates a contentDocument pdf from a visulaforce page
 *              and and link it to the lead
 * @param leadId the lead where the pdf is attached to
 **/
	@AuraEnabled
	public static void saveAnschreibenCSG ( Id leadId ) {
		try {
			if ( HW_SharedVertragsUtils.canGenAnschreibenCSG( leadId ) ) {
				
				String docTitle = 'Anschreiben CSG';
				
				//check if docs exist
				List<ContentDocumentLink> existingDocuments = [
						SELECT Id, ContentDocumentId
						FROM ContentDocumentLink
						WHERE ContentDocument.Title = :docTitle
						AND LinkedEntityId = :leadId
				];
				
				//delete existing
				if ( !existingDocuments.isEmpty() ) {
					delete existingDocuments;
					Database.emptyRecycleBin( existingDocuments );
				}
				
				//create new
				PageReference pdfPage = Page.AnschreibenCSG;
				pdfPage.getParameters().put( 'Id', leadId );
				
				Blob pdfContent;
				if ( !Test.isRunningTest() ) {
					try {
						pdfContent = pdfPage.getContent();
					}
					catch ( Exception e ) {
						throw new AuraHandledException( 'pdf rendering failed: ' + e.getMessage() );
					}
				}
				else {
					pdfContent = Blob.valueOf( 'Test' );
				}
				
				ContentVersion pdfAttachment = new ContentVersion();
				pdfAttachment.VersionData = pdfContent;
				pdfAttachment.Title = docTitle;
				pdfAttachment.ContentLocation = 's';
				pdfAttachment.PathOnClient = docTitle.replaceAll( ' ', '_' ) + '.pdf';
				
				insert pdfAttachment;
				
				Id conDoc = [ SELECT ContentDocumentId FROM ContentVersion WHERE Id = :pdfAttachment.Id ].ContentDocumentId;
				ContentDocumentLink pdfLink = new ContentDocumentLink();
				pdfLink.ContentDocumentId = conDoc;
				pdfLink.LinkedEntityId = leadId;
				pdfLink.ShareType = 'I';
				pdfLink.Visibility = 'AllUsers';
				insert pdfLink;
			}
			else {
				NoAccessException naEx = new NoAccessException();
				naEx.setMessage( 'Sie haben keine Berechtigung um das Anschreiben zu erstellen.' );
				throw naEx;
			}
		}
		catch ( Exception e ) {
			throw new AuraHandledException( 'Anschreiben CSG kommte nicht erstellt werden. ' + e.getMessage() );
		}
	}
	
	public class SenderAddress {
		
		public String ShippingStreet { get; set; }
		public String ShippingPostalCode { get; set; }
		public String ShippingCity { get; set; }
		
		public SenderAddress ( String street, String postalCode, String city ) {
			this.ShippingCity = city;
			this.ShippingPostalCode = postalCode;
			this.ShippingStreet = street;
		}
	}
}