/**
 *@author       Mats Böhler
 *@created      28.02.2022
 *
 *
 *@description  EmailSettingQuery
 *
 *
 *@changelog    28.02.2022 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class EmailSettingQuery {
	
	public static Database.QueryLocator getQueryLocator ( Set<Id> recordIds, String sObjectName ) {
		switch on sObjectName {
			when 'Lead' {
				return Database.getQueryLocator( [
						SELECT
								Id
						FROM Lead
						WHERE Id IN :recordIds
				] );
			}
			when 'Account' {
				return Database.getQueryLocator( [
						SELECT
								Id
						FROM Account
						WHERE Id IN :recordIds
				] );
			}
			when 'Task' {
				return Database.getQueryLocator( [
						SELECT
								Id,
								Filialnetzaenderung__c,
								WhoId,
								WhatId
						FROM Task
						WHERE Id IN :recordIds
				] );
			}
			when 'Filialnetzaenderung__c' {
				return Database.getQueryLocator( [
						SELECT
								Id
						FROM Filialnetzaenderung__c
						WHERE Id IN :recordIds
				] );
			}
			when 'Contract' {
				return Database.getQueryLocator( [
						SELECT
								Id,
								Lead__c,
								AccountId
						FROM Contract
						WHERE Id IN :recordIds
				] );
			}
			when else {
				throw new QueryException('SObject not supported: ' + sObjectName);
			}
		}
	}
}