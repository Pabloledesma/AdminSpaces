@isTest
private class MaintenanceTaskSelectorTest {
  @TestSetup
  static void makeData() {
    Property__c property = TestDataFactory.createProperty();
    insert property;

    insert new List<Maintenance_Task__c>{
      new Maintenance_Task__c(
        Property__c = property.Id,
        Status__c = 'Pending',
        Description__c = 'Tarea 1'
      ),
      new Maintenance_Task__c(
        Property__c = property.Id,
        Status__c = 'In Progress',
        Description__c = 'Tarea 2'
      ),
      new Maintenance_Task__c(
        Property__c = property.Id,
        Status__c = 'Done',
        Description__c = 'Tarea 3'
      )
    };
  }

  @isTest
  static void getByPropertyId_returnsAllStatusesForThatProperty() {
    Property__c property = [SELECT Id FROM Property__c LIMIT 1];

    Test.startTest();
    List<Maintenance_Task__c> tasks = MaintenanceTaskSelector.getByPropertyId(
      property.Id
    );
    Test.stopTest();

    System.assertEquals(
      3,
      tasks.size(),
      'Debería traer las 3 tareas sin importar el estado'
    );
  }

  @isTest
  static void getByPropertyId_returnsEmptyForNullPropertyId() {
    System.assertEquals(
      0,
      MaintenanceTaskSelector.getByPropertyId(null).size()
    );
  }
}
