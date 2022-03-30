/**
 *@author       Mats Böhler
 *@created      24.03.2022
 *
 *
 *@description  PostgesetzPdfLibCtrlTest
 *
 *
 *@changelog    24.03.2022 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class PostgesetzPdfLibCtrlTest {
	
	@IsTest
	static void testInitializeAccountWithoutContract () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Account account = (Account) TestFactory.createSObject(
					new Account(),
					true
			);
			
			Test.startTest();
			PostgesetzPdfLibCtrl instance = (PostgesetzPdfLibCtrl) JSON.deserialize( PostgesetzPdfLibCtrl.initialize( account.Id ), PostgesetzPdfLibCtrl.class ) ;
			Test.stopTest();
			
			System.assertEquals( account.Id, instance.recordId );
		}
	}
	
	@IsTest
	static void testInitializeAccountWithContract () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			
			Account account = (Account) TestFactory.createSObject(
					new Account(),
					true
			);
			
			Contract contract = (Contract) TestFactory.createSObject(
					new Contract(
							AccountId = account.Id
					),
					true
			);
			
			Test.startTest();
			PostgesetzPdfLibCtrl instance = (PostgesetzPdfLibCtrl) JSON.deserialize( PostgesetzPdfLibCtrl.initialize( account.Id ), PostgesetzPdfLibCtrl.class ) ;
			Test.stopTest();
			
			System.assertEquals( contract.Id, instance.recordId );
		}
	}
}