public with sharing class MaintenanceTaskEventPublisher {
  public static Database.SaveResult publishTaskMoved(
    Id propertyId,
    String newStatus
  ) {
    Maintenance_Task_Moved__e event = new Maintenance_Task_Moved__e(
      Property_Id__c = propertyId,
      New_Status__c = newStatus
    );

    return EventBus.publish(event);
  }
}
