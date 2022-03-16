/**
 *@author       Karsten Maaß
 *@created      27.06.2019
 *@version      1.0
 *@since        45.0
 *
 *
 *@description  Testclass for the Document Controller
 *
 *
 *@changelog    27.06.2019 Karsten Maaß - Created
 * 
 */

@isTest
public class HW_Document_C_T {
    @IsTest
    public static void testPage_HW_FACTS_Stammdatenbeleg() {
        HW_Document_C controller = testDocumentController(Page.HW_FACTS_Stammdatenbeleg, 'HTML', 'FACTS Stammdatenbeleg für Test');
        System.assert(controller.getFACTS().size() > 0);
    }
    
    @IsTest
    public static void testPage_HW_MAEF() {
        testDocumentController(Page.HW_MAEF, 'excel', 'MAEF 12345 Test, OZ 95, Eröffnung zum 21.06.2019.xls');
    }
    
    @IsTest
    public static void testPage_HW_Postbankanfrage() {
        testDocumentController(Page.HW_Postbankanfrage, 'excel', 'Postbankanfrage für Filiale Test.xls');
    }
    
    @IsTest
    public static void testPage_HW_SAP_Debitoren_beantragen() {
        testDocumentController(Page.HW_SAP_Debitoren_beantragen, 'excel', 'SAP166 für Test.xls');
    }
    
    @IsTest
    public static void testPage_HW_SAP_Neuanlage() {
        testDocumentController(Page.HW_SAP_Neuanlage, 'excel', 'SAP165 Neuanlage für Test.xls');
    }
    
    @IsTest
    public static void testPage_HW_Selbstauskunft() {
        initDocument('Logo_855x186');
        HW_Document_C controller = testDocumentController(Page.HW_Selbstauskunft, 'pdf', 'Partner Selbstauskunft für Test.pdf');

        controller.getLogoSelbstauskunft();
        //        System.assertNotEquals('', controller.getLogoSelbstauskunft(), 'Logo for Selbstauskunft not found.');
    }
    
    @IsTest
    public static void testPage_HW_Vertragsdokument() {
        testDocumentController(Page.HW_Vertragsdokument, 'ini', 'Vertragsdokument für Test.ini');
    }
    
    @IsTest
    public static void testPage_HW_Zusatzinfo_Material() {
        initDocument('Logo_855x186');
//        HW_Document_C controller = testDocumentController(Page.HW_Zusatzinfo_Material, 'excel', 'Matwi_Stamm_Filialname_Test.xls');

//        controller.getLogoZusatzinfoMaterial();
        //        System.assertNotEquals('', controller.getLogoZusatzinfoMaterial(), 'Logo for ZusatzinfoMaterial not found.');
    }
	
	@IsTest
	public static void testRest() {

		Test.startTest();
		initDocument('Logo_855x186');
		HW_Document_C controller = testDocumentController(Page.HW_Selbstauskunft, 'pdf', 'Partner Selbstauskunft für Test.pdf');
		controller.getSheetName();
		controller.getErrorMessage();
		controller.getContentAsIni();
		controller.getFilialoeffnungszeiten();
		controller.getOeffnungszeitenHauptgeschaeft();
		controller.getZugangszeitenSB();
		controller.getSortierzeiten();
		controller.getZugangszeiten();
		controller.getAusgabezeiten();
		Test.stopTest();
		
	}
    
    //
    // Helper
    //
    private static HW_Document_C testDocumentController(PageReference pageRef, String output, String fileName) {
        initTestData(pageRef, output);
        
        HW_Document_C controller = new HW_Document_C();
        controller.controllerActions();
        
        System.assert(controller.getFeld().size() > 0);
        
        validateRenderAs(controller, output);
        validateContentType(controller, output, fileName);
        
        return controller;
    }
    
    private static void validateRenderAs(HW_Document_C controller, String output) {
        String renderAsString = controller.getRenderAs();
        
        if (output.toUpperCase() == 'PDF')
            System.assertEquals('PDF',  renderAsString);
        else if (output.toUpperCase() == 'HTML')
            System.assertEquals('HTML',  renderAsString);
        else
            System.assertEquals('',  renderAsString);
    }
    
    private static void validateContentType(HW_Document_C controller, String output, String fileName) {
        String contentTypeString = controller.getContentType();
        
        switch on output.toUpperCase() {
            when 'EXCEL' {
                System.assert(contentTypeString.contains('application/vnd.ms-excel#'));
            }
            when 'WORD' {
	            System.assert(contentTypeString.contains('application/vnd.msword#'));
            }
            when 'CSV' {
	            System.assert(contentTypeString.contains('text/csv#'));
            }
            when 'INI' {
	            System.assert(contentTypeString.contains('text#'));
            }
        }
    }
    
    private static void initTestData(PageReference pageRef, String output) {
        // Create Lead
        Lead testLead = createTestLead();
        
        // Start SDS Process to create Account, Contract
        HW_Stammdatensammler_LC.loadData( testLead.Id, false );
        HW_Stammdatensammler_LC.loadData( testLead.Id, false );
        
        // Update Fields
        Contract testContract = initContract(testLead.Id);
        Account testAccount = initAccount(testLead.Id);
        
        Test.setCurrentPage(pageRef);
        
        ApexPages.currentPage().getParameters().put('output', output);
        ApexPages.currentPage().getParameters().put('id', testAccount.Id);
        ApexPages.currentPage().getParameters().put('save', 'true');
    }
    
    private static Lead createTestLead() {
        Lead testLead = new Lead(
		        LastName = 'Test',
		        Company = 'Test',
		        PostalCode = '12345',
		        RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
				        .get('Interessent').getRecordTypeId()
        );
        insert testLead;
        
        return testLead;
    }
    
    private static Contract initContract(ID testLeadId) {
        Contract testContract = [ SELECT DebitorderschliessendeFiliale__c, Filialtyp__c FROM Contract WHERE Lead__c = :testLeadId LIMIT 1 ];
        testContract.DebitorderschliessendeFiliale__c = '12345';
        testContract.Filialtyp__c = '95';
        upsert testContract;
        return testContract;
    }
    
    private static Account initAccount(ID testLeadId) {
        Account testAccount = [ SELECT ShippingPostalCode FROM Account WHERE Lead__c = :testLeadId LIMIT 1 ];
        
        testAccount.ShippingPostalCode = '12345';
        testAccount.Eroeffnungsdatum__c = Date.newInstance(2019, 06, 21);
        
        upsert testAccount;
        
        return testAccount;
    }
    
    private static void initDocument(String documentName) {
        Document doc = new Document(Name = documentName,
                                    DeveloperName = documentName);
        
        //insert doc;
    }
}