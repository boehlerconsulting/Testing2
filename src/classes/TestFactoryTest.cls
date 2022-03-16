/**
* @author: Copyright (c) 2015 Daniel Hoechst, https://github.com/dhoechst/Salesforce-Test-Factory/blob/master/LICENSE.md
*/
@IsTest
private class TestFactoryTest{
	
	@IsTest
	static void when_objectIsCreated_expect_defaultFieldsArePopulated(){
		//when
		Account a = (Account)TestFactory.createSObject(new Account());
		//then
		System.assertEquals('Test Account', a.Name, 'Expecting Default field value is set to specific value');
	}
	
	@IsTest
	static void when_objectIsInserted_expect_defaultFieldsArePopulated(){
		//when
		Account a = (Account)TestFactory.createSObject(new Account(),true);
		//then
		a = [SELECT Name FROM Account WHERE Id = :a.Id];
		System.assertEquals('Test Account', a.Name, 'Expecting Default field value is set to specific value');
	}
	
	@IsTest
	static void when_objectIsCreatedWithSpecificDefaultsSet_expect_defaultFieldsArePopulated(){
		//when
		Account a = (Account)TestFactory.createSObject(new Account(), 'TestFactoryDefaults.DummyFilialeDefaults');
		//then
		System.assertEquals('Dummy Filiale Test', a.Name, 'Expecting Default field value is set to specific value');
	}
	
	@IsTest
	static void when_objectIsInsertedWithSpecificDefaultsSet_expect_defaultFieldsArePopulated(){
		//when
		Account a = (Account)TestFactory.createSObject(new Account(), 'TestFactoryDefaults.DummyFilialeDefaults', true);
		//then
		System.assertEquals('Dummy Filiale Test', a.Name, 'Expecting Default field value is set to specific value');
	}
	
	@IsTest
	static void when_ListOfObjectsIsCreated_expect_defaultFieldsArePopulated(){
		//when
		Account[] aList = (Account[])TestFactory.createSObjectList(new Account(), 2);
		//then
		for(Account a : aList){
			System.assert(a.Name.startsWith('Test Account'), 'Expecting Default field value is set to specific value');
		}
	}
	
	@IsTest
	static void when_ListOfObjectIsInserted_expect_defaultFieldsArePopulated(){
		//when
		Account[] aList = (Account[])TestFactory.createSObjectList(new Account(), 2, true);
		//then
		aList = [SELECT Name FROM Account WHERE Id IN :aList ORDER BY Name];
		for(Account a : aList){
			System.assert(a.Name.startsWith('Test Account'), 'Expecting Default field value is set to specific value');
		}
	}
	
	@IsTest
	static void when_ListOfObjectsIsCreatedWithSpecificDefaultsSet_expect_defaultFieldsArePopulated(){
		//when
		Account[] aList = (Account[])TestFactory.createSObjectList(new Account(), 2, 'TestFactoryDefaults.DummyFilialeDefaults');
		//then
		for(Account a : aList){
			System.assert(a.Name.startsWith('Dummy Filiale Test'), 'Expecting Default field value is set to specific value');
		}
	}
	
	@IsTest
	static void when_ListOfObjectsIsInsertedWithSpecificDefaultsSet_expect_defaultFieldsArePopulated(){
		//when
		Account[] aList = (Account[])TestFactory.createSObjectList(new Account(), 2, 'TestFactoryDefaults.DummyFilialeDefaults', true);
		//then
		aList = [SELECT Name FROM Account WHERE Id IN :aList ORDER BY Name];
		for(Account a : aList){
			System.assert(a.Name.startsWith('Dummy Filiale Test'), 'Expecting Default field value is set to specific value');
		}
	}

}