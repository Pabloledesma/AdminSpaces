public inherited sharing class MaintenanceTaskStatusService {
  public class StatusOption {
    @AuraEnabled
    public String value;
    @AuraEnabled
    public String label;
  }

  public static List<StatusOption> getActiveStatusOptions() {
    List<StatusOption> options = new List<StatusOption>();
    for (Schema.PicklistEntry entry : getStatusPicklistEntries()) {
      if (entry.isActive()) {
        StatusOption option = new StatusOption();
        option.value = entry.getValue();
        option.label = entry.getLabel();
        options.add(option);
      }
    }
    return options;
  }

  public static Boolean isValidStatus(String status) {
    return getValidStatusValues().contains(status);
  }

  private static List<Schema.PicklistEntry> getStatusPicklistEntries() {
    return Maintenance_Task__c.Status__c.getDescribe().getPicklistValues();
  }

  private static Set<String> getValidStatusValues() {
    Set<String> values = new Set<String>();
    for (Schema.PicklistEntry entry : getStatusPicklistEntries()) {
      if (entry.isActive()) {
        values.add(entry.getValue());
      }
    }
    return values;
  }
}
