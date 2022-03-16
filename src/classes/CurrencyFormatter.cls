/**
 *@author       Mats Böhler
 *@created      20.01.2022
 *
 *
 *@description  CurrencyFormatter
 *
 *
 *@changelog    20.01.2022 Mats Böhler  - Created
 *              
 * 
 */
public with sharing class CurrencyFormatter {
	
	public static String format ( Decimal value, String symbol ) {
		if ( value == null ) {
			return '';
		}
		String stringValue = String.valueOf( value );
		if ( value.scale() == 1 ) {
			stringValue += '0';
		}
		stringValue += stringValue.contains( '.' ) ? ' ' + symbol : ',00 ' + symbol;
		stringValue = stringValue.replace( '.', ',' );
		return stringValue;
	}
}