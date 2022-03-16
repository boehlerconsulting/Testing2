/**
 *@author       Mats Böhler
 *@created      30.08.2021
 *
 *
 *@description  ProductTriggerHandler
 *
 *
 *@changelog    30.08.2021 Mats Böhler  - Created
 *              
 * 
 */
public without sharing class ProductTriggerHandler extends TriggerHandler{
	
	private List<Product2> oldProducts = null;
	
	public ProductTriggerHandler () {
		
		this.oldProducts = ( List<Product2> ) Trigger.old;
	}
	
	public override void beforeDelete () {
		
		for ( Product2 product : oldProducts ) {
			product.addError('Produkte dürfen nicht gelöscht werden.');
		}
	}
}