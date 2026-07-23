@isTest
private class MaintenanceTaskStatusServiceTest {
  @isTest
  static void getActiveStatusOptions_mirrorsActivePicklistValuesInOrder() {
    List<Schema.PicklistEntry> entries = Maintenance_Task__c.Status__c.getDescribe()
      .getPicklistValues();

    Test.startTest();
    List<MaintenanceTaskStatusService.StatusOption> options = MaintenanceTaskStatusService.getActiveStatusOptions();
    Test.stopTest();

    Integer optionIndex = 0;
    for (Schema.PicklistEntry entry : entries) {
      if (entry.isActive()) {
        System.assertEquals(
          entry.getValue(),
          options[optionIndex].value,
          'El value en la posición ' +
            optionIndex +
            ' debería coincidir con el picklist'
        );
        System.assertEquals(entry.getLabel(), options[optionIndex].label);
        optionIndex++;
      }
    }
    System.assertEquals(
      optionIndex,
      options.size(),
      'No debería haber ni más ni menos opciones que valores activos en el picklist'
    );
  }

  @isTest
  static void isValidStatus_returnsTrueForActivePicklistValue() {
    System.assertEquals(
      true,
      MaintenanceTaskStatusService.isValidStatus('Pending')
    );
  }

  @isTest
  static void isValidStatus_returnsFalseForValueNotInPicklist() {
    System.assertEquals(
      false,
      MaintenanceTaskStatusService.isValidStatus('Cancelled')
    );
  }
}
