@isTest
private class MaintenanceTaskEventPublisherTest {
  @isTest
  static void publishTaskMoved_publishesEventSuccessfully() {
    Test.startTest();
    Database.SaveResult result = MaintenanceTaskEventPublisher.publishTaskMoved(
      'a06000000000001AAA',
      'In Progress'
    );
    Test.stopTest();

    System.assertEquals(
      true,
      result.isSuccess(),
      'La publicación del Platform Event debería ser exitosa'
    );
  }
}
