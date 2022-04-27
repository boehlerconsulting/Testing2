/**
 *@author       Mats Böhler
 *@created      04.05.2021
 *
 *
 *@description  OeffnungszeitService
 *
 *
 *@changelog    04.05.2021 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class OeffnungszeitService {

	public static Map<String,List<Oeffnungszeiten__c>> createDefinitions(Id accountId, List<String> categories) {
		Account account = loadAccount( accountId );
		return createDefinitions(account,categories);
	}

	public static Map<String,List<Oeffnungszeiten__c>> createDefinitions(Account account, List<String> categories) {

		Map<String, List<Oeffnungszeiten__c>> oefByCat = new Map<String, List<Oeffnungszeiten__c>>();

		for (String cat : categories) {

			oefByCat.put(
					cat,
					new List<Oeffnungszeiten__c>{
					createMonday(account, cat),
					createTuesday(account, cat),
					createWednesday(account, cat),
					createThursday(account, cat),
					createFriday(account, cat),
					createSaturday(account, cat),
					createSunday(account, cat)
				}
			);
		}
		return oefByCat;
	}
	
	public static List<Oeffnungszeiten__c> getDefinitionsByAccountId ( Id accountId ) {
		Account account = loadAccount( accountId );
		String category = 'Filialöffnungszeiten';
		return new List<Oeffnungszeiten__c> {
				createMonday( account, category),
				createTuesday( account, category ),
				createWednesday( account, category ),
				createThursday( account, category ),
				createFriday( account, category ),
				createSaturday( account, category ),
				createSunday( account, category )
		};
	}
	
	public static List<Oeffnungszeiten__c> createDefinitions ( Id accountId, String category, Boolean useGzFields ) {
		Account account = loadAccount( accountId );
		if (useGzFields ) {
			return new List<Oeffnungszeiten__c> {
					createMondayGz( account, category),
					createTuesdayGz( account, category ),
					createWednesdayGz( account, category ),
					createThursdayGz( account, category ),
					createFridayGz( account, category ),
					createSaturdayGz( account, category ),
					createSundayGz( account, category )
			};
		}
		else{
			return new List<Oeffnungszeiten__c> {
					createMonday( account, category),
					createTuesday( account, category ),
					createWednesday( account, category ),
					createThursday( account, category ),
					createFriday( account, category ),
					createSaturday( account, category ),
					createSunday( account, category )
			};
		}
	}
	
	private static Account loadAccount ( Id accountId ) {
		return [
				SELECT
						Id,
						Mo_vm_von__c,
						Mo_vm_bis__c,
						Mo_nm_von__c,
						Mo_nm_bis__c,
						Di_vm_von__c,
						Di_vm_bis__c,
						Di_nm_von__c,
						Di_nm_bis__c,
						Mi_vm_von__c,
						Mi_vm_bis__c,
						Mi_nm_von__c,
						Mi_nm_bis__c,
						Do_vm_von__c,
						Do_vm_bis__c,
						Do_nm_von__c,
						Do_nm_bis__c,
						Fr_vm_von__c,
						Fr_vm_bis__c,
						Fr_nm_von__c,
						Fr_nm_bis__c,
						Sa_vm_von__c,
						Sa_vm_bis__c,
						Sa_nm_von__c,
						Sa_nm_bis__c,
						So_vm_von__c,
						So_vm_bis__c,
						So_nm_von__c,
						So_nm_bis__c,
						Gz_Mo_vm_von__c,
						Gz_Mo_vm_bis__c,
						Gz_Mo_nm_von__c,
						Gz_Mo_nm_bis__c,
						Gz_Di_vm_von__c,
						Gz_Di_vm_bis__c,
						Gz_Di_nm_von__c,
						Gz_Di_nm_bis__c,
						Gz_Mi_vm_von__c,
						Gz_Mi_vm_bis__c,
						Gz_Mi_nm_von__c,
						Gz_Mi_nm_bis__c,
						Gz_Do_vm_von__c,
						Gz_Do_vm_bis__c,
						Gz_Do_nm_von__c,
						Gz_Do_nm_bis__c,
						Gz_Fr_vm_von__c,
						Gz_Fr_vm_bis__c,
						Gz_Fr_nm_von__c,
						Gz_Fr_nm_bis__c,
						Gz_Sa_vm_von__c,
						Gz_Sa_vm_bis__c,
						Gz_Sa_nm_von__c,
						Gz_Sa_nm_bis__c,
						Gz_So_vm_von__c,
						Gz_So_vm_bis__c,
						Gz_So_nm_von__c,
						Gz_So_nm_bis__c
				FROM Account
				WHERE Id = :accountId
		];
	}
	
	private static Oeffnungszeiten__c createMonday ( Account account, String category ) {
		return new Oeffnungszeiten__c(
				Kategorie__c = category,
				Wochentag__c = 'Montag',
				vm_von__c = account.Mo_vm_von__c,
				vm_bis__c = account.Mo_vm_bis__c,
				nm_von__c = account.Mo_nm_von__c,
				nm_bis__c = account.Mo_nm_bis__c,
				Account__c = account.Id,
				Prozess__c = HW_Stammdatensammler_LC.mainProcess
		);
	}
	
	private static Oeffnungszeiten__c createMondayGz ( Account account, String category ) {
		return new Oeffnungszeiten__c(
				Kategorie__c = category,
				Wochentag__c = 'Montag',
				vm_von__c = account.Gz_Mo_vm_von__c,
				vm_bis__c = account.Gz_Mo_vm_bis__c,
				nm_von__c = account.Gz_Mo_nm_von__c,
				nm_bis__c = account.Gz_Mo_nm_bis__c,
				Account__c = account.Id,
				Prozess__c = HW_Stammdatensammler_LC.mainProcess
		);
	}
	
	private static Oeffnungszeiten__c createTuesday ( Account account, String category  ) {
		return new Oeffnungszeiten__c(
				Kategorie__c = category,
				Wochentag__c = 'Dienstag',
				vm_von__c = account.Di_vm_von__c,
				vm_bis__c = account.Di_vm_bis__c,
				nm_von__c = account.Di_nm_von__c,
				nm_bis__c = account.Di_nm_bis__c,
				Account__c = account.Id,
				Prozess__c = HW_Stammdatensammler_LC.mainProcess
		);
	}
	
	private static Oeffnungszeiten__c createTuesdayGz ( Account account, String category  ) {
		return new Oeffnungszeiten__c(
				Kategorie__c = category,
				Wochentag__c = 'Dienstag',
				vm_von__c = account.Gz_Di_vm_von__c,
				vm_bis__c = account.Gz_Di_vm_bis__c,
				nm_von__c = account.Gz_Di_nm_von__c,
				nm_bis__c = account.Gz_Di_nm_bis__c,
				Account__c = account.Id,
				Prozess__c = HW_Stammdatensammler_LC.mainProcess
		);
	}
	
	private static Oeffnungszeiten__c createWednesday ( Account account, String category  ) {
		return new Oeffnungszeiten__c(
				Kategorie__c = category,
				Wochentag__c = 'Mittwoch',
				vm_von__c = account.Mi_vm_von__c,
				vm_bis__c = account.Mi_vm_bis__c,
				nm_von__c = account.Mi_nm_von__c,
				nm_bis__c = account.Mi_nm_bis__c,
				Account__c = account.Id,
				Prozess__c = HW_Stammdatensammler_LC.mainProcess
		);
	}
	
	private static Oeffnungszeiten__c createWednesdayGz ( Account account, String category  ) {
		return new Oeffnungszeiten__c(
				Kategorie__c = category,
				Wochentag__c = 'Mittwoch',
				vm_von__c = account.Gz_Mi_vm_von__c,
				vm_bis__c = account.Gz_Mi_vm_bis__c,
				nm_von__c = account.Gz_Mi_nm_von__c,
				nm_bis__c = account.Gz_Mi_nm_bis__c,
				Account__c = account.Id,
				Prozess__c = HW_Stammdatensammler_LC.mainProcess
		);
	}
	
	private static Oeffnungszeiten__c createThursday ( Account account, String category  ) {
		return new Oeffnungszeiten__c(
				Kategorie__c = category,
				Wochentag__c = 'Donnerstag',
				vm_von__c = account.Do_vm_von__c,
				vm_bis__c = account.Do_vm_bis__c,
				nm_von__c = account.Do_nm_von__c,
				nm_bis__c = account.Do_nm_bis__c,
				Account__c = account.Id,
				Prozess__c = HW_Stammdatensammler_LC.mainProcess
		);
	}
	
	private static Oeffnungszeiten__c createThursdayGz ( Account account, String category  ) {
		return new Oeffnungszeiten__c(
				Kategorie__c = category,
				Wochentag__c = 'Donnerstag',
				vm_von__c = account.Gz_Do_vm_von__c,
				vm_bis__c = account.Gz_Do_vm_bis__c,
				nm_von__c = account.Gz_Do_nm_von__c,
				nm_bis__c = account.Gz_Do_nm_bis__c,
				Account__c = account.Id,
				Prozess__c = HW_Stammdatensammler_LC.mainProcess
		);
	}
	
	private static Oeffnungszeiten__c createFriday ( Account account, String category  ) {
		return new Oeffnungszeiten__c(
				Kategorie__c = category,
				Wochentag__c = 'Freitag',
				vm_von__c = account.Fr_vm_von__c,
				vm_bis__c = account.Fr_vm_bis__c,
				nm_von__c = account.Fr_nm_von__c,
				nm_bis__c = account.Fr_nm_bis__c,
				Account__c = account.Id,
				Prozess__c = HW_Stammdatensammler_LC.mainProcess
		);
	}
	
	private static Oeffnungszeiten__c createFridayGz ( Account account, String category  ) {
		return new Oeffnungszeiten__c(
				Kategorie__c = category,
				Wochentag__c = 'Freitag',
				vm_von__c = account.Gz_Fr_vm_von__c,
				vm_bis__c = account.Gz_Fr_vm_bis__c,
				nm_von__c = account.Gz_Fr_nm_von__c,
				nm_bis__c = account.Gz_Fr_nm_bis__c,
				Account__c = account.Id,
				Prozess__c = HW_Stammdatensammler_LC.mainProcess
		);
	}
	
	private static Oeffnungszeiten__c createSaturday ( Account account, String category  ) {
		return new Oeffnungszeiten__c(
				Kategorie__c = category,
				Wochentag__c = 'Samstag',
				vm_von__c = account.Sa_vm_von__c,
				vm_bis__c = account.Sa_vm_bis__c,
				nm_von__c = account.Sa_nm_von__c,
				nm_bis__c = account.Sa_nm_bis__c,
				Account__c = account.Id,
				Prozess__c = HW_Stammdatensammler_LC.mainProcess
		);
	}
	
	private static Oeffnungszeiten__c createSaturdayGz ( Account account, String category  ) {
		return new Oeffnungszeiten__c(
				Kategorie__c = category,
				Wochentag__c = 'Samstag',
				vm_von__c = account.Gz_Sa_vm_von__c,
				vm_bis__c = account.Gz_Sa_vm_bis__c,
				nm_von__c = account.Gz_Sa_nm_von__c,
				nm_bis__c = account.Gz_Sa_nm_bis__c,
				Account__c = account.Id,
				Prozess__c = HW_Stammdatensammler_LC.mainProcess
		);
	}
	
	private static Oeffnungszeiten__c createSunday ( Account account, String category  ) {
		return new Oeffnungszeiten__c(
				Kategorie__c = category,
				Wochentag__c = 'Sonntag',
				vm_von__c = account.So_vm_von__c,
				vm_bis__c = account.So_vm_bis__c,
				nm_von__c = account.So_nm_von__c,
				nm_bis__c = account.So_nm_bis__c,
				Account__c = account.Id,
				Prozess__c = HW_Stammdatensammler_LC.mainProcess
		);
	}
	
	private static Oeffnungszeiten__c createSundayGz ( Account account, String category  ) {
		return new Oeffnungszeiten__c(
				Kategorie__c = category,
				Wochentag__c = 'Sonntag',
				vm_von__c = account.Gz_So_vm_von__c,
				vm_bis__c = account.Gz_So_vm_bis__c,
				nm_von__c = account.Gz_So_nm_von__c,
				nm_bis__c = account.Gz_So_nm_bis__c,
				Account__c = account.Id,
				Prozess__c = HW_Stammdatensammler_LC.mainProcess
		);
	}
}