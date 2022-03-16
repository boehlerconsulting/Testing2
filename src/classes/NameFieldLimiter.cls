/**
 *@author       Mats Böhler
 *@created      10.05.2021
 *
 *
 *@description  NameFieldLimiter
 *
 *
 *@changelog    10.05.2021 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class NameFieldLimiter {

	public static String getValue(String value){
		return value.length() > 80
				? value.left( 77 ) + '...'
				: value;
	}
}