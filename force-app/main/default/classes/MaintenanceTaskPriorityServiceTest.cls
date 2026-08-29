@isTest
private class MaintenanceTaskPriorityServiceTest {
  @isTest
  static void isValidPriority_valoresDelPicklist_sonValidos() {
    for (
      String value : MaintenanceTaskPriorityService.getValidPriorityValues()
    ) {
      System.assertEquals(
        true,
        MaintenanceTaskPriorityService.isValidPriority(value)
      );
    }
  }

  @isTest
  static void isValidPriority_valorInexistente_esInvalido() {
    System.assertEquals(
      false,
      MaintenanceTaskPriorityService.isValidPriority('Catastrófico')
    );
  }
}
