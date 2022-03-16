/**
 *@author       Mats Böhler
 *@created      13.07.2020
 *
 *
 *@description  AccountMoverServiceTest
 *
 *
 *@changelog    13.07.2020 Mats Böhler  - Created
 *              Process Builder - Aufgabe - Verschiebung Erledigung bei Verschiebung Eröffnung/Schließung
 *              
 * 
 */
@IsTest
private class AccountMoverServiceTest {
	
	@TestSetup static void setupRequiredOrgEDPs () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			List<String> orgEdpNames = new List<String> {
					'3920/30 Aussenstelle',
					'Vertriebsmanager',
					'3910 Immo/Instandh/Automation',
					'3540 DP Shop'
			};
			List<OrgE_DP__c> orgEDPS = new List<OrgE_DP__c>();
			for ( String name : orgEdpNames ) {
				orgEDPS.add(
						new OrgE_DP__c(
								Aussenstellen_Ma__c = UserInfo.getUserId(),
								Koordinator__c = UserInfo.getUserId(),
								OrgE_DP_Name__c = name
						)
				);
			}
			insert orgEDPS;
		}
	}
	
	@IsTest
	static void test_EO_verschoben () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			Account account = createAccount();
			createTasks( account.Id, new List<String> {
					'Vorbereitung Filialeinrichtung',
					'Einrichtungsgespräch Partner-Filiale (ASt)',
					'Begleitung Eröffnung + Detail',
					'Ersteinweisung Filiale',
					'DHL Paketshop Terminabstimmung Ersteinweisung',
					'DHL Paketshop Ersteinweisung',
					'DP Shop Übernahme der Räume (ASt)',
					'DP Shop Gefahren- und Belastungsanalyse bei Neueinrichtung (ASt)',
					'DP Shop Filialübergabe (ASt+Ma DPS)',
					'DP Shop Erstunterweisung Arbeits-/Brandschutz/Gefahrgut',
					'DP Shop Bestellung Bargelderstausstattung (SCF)',
					'Vorbereitung Leistungsanpassung',
					'Vorbereitung Up-/Downgrade Filialeinrichtung (Formatwechsel)',
					'Bargeldentsorgung beauftragen',
					'Bargeld bestellen',
					'Aktualisierung Besicherungswerte aufgrund Up-/Downgrade',
					'OZ 95 - Besonderheiten bei der Einrichtung/Eröffnung',
					'Veranlassung SAP Stammdatenpflege (NUR Partner-Filialen)'
			} );
			
			System.assertEquals( 18, [
					SELECT
							Id
					FROM Task
					WHERE AccountId = :account.Id
			].size() );
			
			Test.startTest();
			Integer daysToAdd = 2;
			account.Eroeffnungsdatum__c = Date.today().addDays( daysToAdd );
			update account;
			Test.stopTest();
			
			for ( Task task : [
					SELECT
							Id,
							Aufgabenart__c,
							ActivityDate,
							Description,
							Erledigung_bis_zum__c
					FROM Task
					WHERE AccountId = :account.Id
			] ) {
				System.assertEquals( Date.today().addDays( daysToAdd ), task.ActivityDate );
				System.assertEquals( Date.today().addDays( daysToAdd + 1 ), task.Erledigung_bis_zum__c );
			}
		}
	}
	
	@IsTest
	static void test_SD_verschoben () {
		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			Account account = createAccount();
			createTasks( account.Id, new List<String> {
					'Vorbereitung_Filialschliessung',
					'Filialschließung + Detail',
					'Beräumung Filiale',
					'Begleitung Schließung',
					'DP Shop Kündigung Mietvertrag',
					'Veranlassung SAP Stammdatenpflege (NUR Partner-Filialen)'
			} );
			
			System.assertEquals( 6, [
					SELECT
							Id
					FROM Task
					WHERE AccountId = :account.Id
			].size() );
			
			Test.startTest();
			Integer daysToAdd = 2;
			account.Schliessung_zum__c = Date.today().addDays( daysToAdd + 14 );
			update account;
			Test.stopTest();
			
			for ( Task task : [
					SELECT
							Id,
							Aufgabenart__c,
							ActivityDate,
							Description,
							Erledigung_bis_zum__c
					FROM Task
					WHERE AccountId = :account.Id
			] ) {
				System.assertEquals( String.format(
						'Verschiebung Schließung auf den {0}; Verschiebung um {1} Tage!',
						new List<Object> {
								String.valueOf( account.Schliessung_zum__c ),
								2
						} ) + ' Test', task.Description );
			}
		}
	}
	
	private static void createTasks ( Id accountId, List<String> taskTypes ) {
		List<Task> tasks = new List<Task>();
		for ( String taskType : taskTypes ) {
			tasks.add( ( Task ) TestFactory.createSObject(
					new Task(
							Aufgabenart__c = taskType,
							ActivityDate = Date.today(),
							Erledigung_bis_zum__c = Date.today().addDays( 1 ),
							Auftragnehmer__c = '3540 DP Shop',
							WhatId = accountId,
							RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
									.get( 'A_Aufgaben_automatische_Anlage' ).getRecordTypeId(),
							Description = 'Test'
					),
					false
			) );
		}
		insert tasks;
	}
	
	private static Account createAccount () {
		
		Account account = ( Account ) TestFactory.createSObject(
				new Account(
						Eroeffnungsdatum__c = Date.today(),
						Schliessung_zum__c = Date.today().addDays( 14 )
				),
				true
		);
		return account;
	}
}