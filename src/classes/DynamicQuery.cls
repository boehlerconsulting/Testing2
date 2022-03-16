/**
 *@author       Mats Böhler
 *@created      18.11.2021
 *
 *
 *@description  DynamicQuery
 *
 *
 *@changelog    18.11.2021 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class DynamicQuery {

	public static String removeRestrictedCharacters(String searchTerm){
		return searchTerm.remove( '%' ).remove( '_' );
	}
}