public with sharing class MaintenanceTaskBoardController {
  @AuraEnabled(cacheable=true)
  public static List<Maintenance_Task__c> getTasksForProperty(Id propertyId) {
    return MaintenanceTaskSelector.getByPropertyId(propertyId);
  }

  @AuraEnabled(cacheable=true)
  public static List<MaintenanceTaskStatusService.StatusOption> getTaskStatusOptions() {
    return MaintenanceTaskStatusService.getActiveStatusOptions();
  }

  @AuraEnabled
  public static void updateTaskStatus(Id taskId, String newStatus) {
    if (!MaintenanceTaskStatusService.isValidStatus(newStatus)) {
      throw AuraExceptionUtil.create(
        String.format(
          System.Label.Maintenance_Invalid_Status,
          new List<String>{ newStatus }
        )
      );
    }

    try {
      update new Maintenance_Task__c(Id = taskId, Status__c = newStatus);
    } catch (DmlException e) {
      throw AuraExceptionUtil.create(e.getDmlMessage(0));
    }
  }
}
