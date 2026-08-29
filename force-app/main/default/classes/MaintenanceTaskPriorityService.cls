/**
 * Mismo criterio que MaintenanceTaskStatusService, pero para Priority__c: lee
 * los valores activos del picklist real en vez de hardcodear una lista, para
 * que la validación nunca quede desincronizada si alguien agrega o desactiva
 * un valor de prioridad en el objeto.
 */
public inherited sharing class MaintenanceTaskPriorityService {
  public static Boolean isValidPriority(String priority) {
    return getValidPriorityValues().contains(priority);
  }

  public static List<String> getValidPriorityValues() {
    List<String> values = new List<String>();
    for (
      Schema.PicklistEntry entry : Maintenance_Task__c.Priority__c.getDescribe()
        .getPicklistValues()
    ) {
      if (entry.isActive()) {
        values.add(entry.getValue());
      }
    }
    return values;
  }
}
