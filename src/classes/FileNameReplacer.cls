/**
 *@author       Mats Böhler
 *@created      29.10.2020
 *
 *
 *@description  FileNameReplacer
 *
 *
 *@changelog    29.10.2020 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class FileNameReplacer {
	
	private static Map<String, String> replacementByCharacter = new Map<String, String>();
	
	public static String replace ( String fileName ) {
		
		loadSettings();
		for ( String key : replacementByCharacter.keySet() ) {
			if ( fileName.contains( key ) ) {
				fileName = fileName.replace( key, replacementByCharacter.get( key ) );
			}
		}
		return fileName;
	}
	
	private static void loadSettings () {
		if ( replacementByCharacter.isEmpty() ) {
			for ( SDS_Uebersetzungseintrag__mdt setting : [
					SELECT
							Id,
							Zeichen__c,
							Ersetzungszeichen__c
					FROM SDS_Uebersetzungseintrag__mdt
			] ) {
				
				replacementByCharacter.put( setting.Zeichen__c, setting.Ersetzungszeichen__c );
			}
		}
	}
}