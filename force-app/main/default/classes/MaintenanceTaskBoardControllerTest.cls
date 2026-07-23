@isTest
private class MaintenanceTaskBoardControllerTest {
  @TestSetup
  static void makeData() {
    Property__c property = TestDataFactory.createProperty();
    insert property;

    insert new Maintenance_Task__c(
      Property__c = property.Id,
      Status__c = 'Pending',
      Description__c = 'Cambiar filtro de aire'
    );
  }

  @isTest
  static void getTasksForProperty_returnsTasksOfThatProperty() {
    Property__c property = [SELECT Id FROM Property__c LIMIT 1];

    Test.startTest();
    List<Maintenance_Task__c> tasks = MaintenanceTaskBoardController.getTasksForProperty(
      property.Id
    );
    Test.stopTest();

    System.assertEquals(1, tasks.size());
  }

  @isTest
  static void getTaskStatusOptions_delegatesToStatusService() {
    List<MaintenanceTaskStatusService.StatusOption> expected = MaintenanceTaskStatusService.getActiveStatusOptions();

    Test.startTest();
    List<MaintenanceTaskStatusService.StatusOption> actual = MaintenanceTaskBoardController.getTaskStatusOptions();
    Test.stopTest();

    System.assertEquals(expected.size(), actual.size());
    for (Integer i = 0; i < expected.size(); i++) {
      System.assertEquals(expected[i].value, actual[i].value);
      System.assertEquals(expected[i].label, actual[i].label);
    }
  }

  @isTest
  static void updateTaskStatus_movesTaskToNewStatus() {
    Maintenance_Task__c task = [SELECT Id FROM Maintenance_Task__c LIMIT 1];

    Test.startTest();
    MaintenanceTaskBoardController.updateTaskStatus(task.Id, 'In Progress');
    Test.stopTest();

    Maintenance_Task__c updated = [
      SELECT Status__c
      FROM Maintenance_Task__c
      WHERE Id = :task.Id
    ];
    System.assertEquals('In Progress', updated.Status__c);
  }

  @isTest
  static void updateTaskStatus_rejectsValueNotInPicklist() {
    Maintenance_Task__c task = [SELECT Id FROM Maintenance_Task__c LIMIT 1];

    try {
      MaintenanceTaskBoardController.updateTaskStatus(task.Id, 'Cancelled');
      System.assert(
        false,
        'Debería haber rechazado un estado que no existe en el picklist'
      );
    } catch (AuraHandledException e) {
      System.assertEquals('Estado inválido: Cancelled', e.getMessage());
    }
  }

  @isTest
  static void updateTaskStatus_wrapsDmlExceptionWithRealMessage() {
    Maintenance_Task__c task = [SELECT Id FROM Maintenance_Task__c LIMIT 1];
    delete task;

    try {
      MaintenanceTaskBoardController.updateTaskStatus(task.Id, 'In Progress');
      System.assert(
        false,
        'Debería haber tirado una excepción: el registro ya no existe'
      );
    } catch (AuraHandledException e) {
      System.assertNotEquals(
        'Script-thrown exception',
        e.getMessage(),
        'El mensaje real del DML debería sobrevivir, no el genérico de AuraHandledException'
      );
    }
  }
}
