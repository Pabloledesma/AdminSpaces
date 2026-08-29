public inherited sharing class PropertySelector {
  /**
   * `WITH USER_MODE` por el mismo criterio que ExpenseSelector: el selector es
   * `inherited sharing`, así que el sharing ya lo aporta el caller; esto agrega
   * la validación de permisos de objeto y FLS que faltaba.
   */
  public static List<Property__c> getAllProperties() {
    return [
      SELECT Id, Name, Total_Expenses__c
      FROM Property__c
      WITH USER_MODE
      ORDER BY Name
    ];
  }

  public static List<Property__c> getPropertyById(Id propertyId) {
    return [
      SELECT Id, Room_Count__c, Total_Expenses__c
      FROM Property__c
      WHERE Id = :propertyId
    ];
  }

  public static List<Property__c> getPropertyByRoomCount(Integer roomCount) {
    return [SELECT Id FROM Property__c WHERE Room_Count__c = :roomCount];
  }

  /**
   * Todas las propiedades con los campos que necesita la búsqueda del agente
   * (Historia 6). Sin WHERE, igual que `getAllProperties()`: a esta escala
   * (decenas de propiedades) es más simple traer todo y filtrar en Apex por
   * request que armar SOQL dinámico para un término de búsqueda libre —
   * mismo criterio que ya usa `getAllProperties()` para el combobox de
   * Finanzas. Campos y orden distintos porque el consumidor es distinto:
   * acá importa Address__c/City__c/Room_Count__c, no Name.
   */
  public static List<Property__c> getForSearch() {
    return [
      SELECT Id, Address__c, City__c, Room_Count__c
      FROM Property__c
      WITH USER_MODE
      ORDER BY Address__c
    ];
  }
}
