public inherited sharing class MaintenanceTaskSelector {
  private static final Set<String> OPEN_STATUSES = new Set<String>{
    'Pending',
    'In Progress'
  };

  /**
   * Cuenta las tareas de mantenimiento no terminadas (Pending o In progress) de una propiedad
   * @param propertyId Id de la Property__c
   * @return Cantidad de Maintenance_Task__c abiertas para esa propiedad
   *
   */
  public static Integer getPendingCountForProperty(Id propertyId) {
    if (propertyId == null) {
      return 0;
    }

    return [
      SELECT COUNT()
      FROM Maintenance_Task__c
      WHERE Property__c = :propertyId AND Status__c IN :OPEN_STATUSES
    ];
  }

  public static List<Maintenance_Task__c> getPendingByPropertyId(
    Id propertyId
  ) {
    return [
      SELECT Id, Status__c, Description__c
      FROM Maintenance_Task__c
      WHERE
        Property__c = :propertyId
        AND Status__c IN ('Pending', 'In Progress')
    ];
  }
}
