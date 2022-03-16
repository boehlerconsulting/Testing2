/**
 *@author       Mats Böhler
 *@created      07.08.2020
 *
 *
 *@description  TaskWorkerTest
 *
 *
 *@changelog    07.08.2020 Mats Böhler  - Created
 *              
 * 
 */
@IsTest
private class TaskWorkerTest {
	@IsTest
	static void testBehavior () {

		System.runAs( TestUser.create( TestUser.UserType.ADMIN ) ) {
			Task task = ( Task ) TestFactory.createSObject(
					new Task(
							Status = 'Nicht begonnen'
					),
					true
			);
			Test.startTest();
			TaskWorker uow = TaskWorker.getInstance();
			uow.get(task);
			uow.exists(task);
			uow.add(task);
			uow.process(true);
			uow.add(task);
			uow.process(false);
			Test.stopTest();
		}
	}
}