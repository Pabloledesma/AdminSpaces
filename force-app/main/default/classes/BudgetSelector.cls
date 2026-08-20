public inherited sharing class BudgetSelector {
  /**
   * Presupuestos de una propiedad, del más reciente al más viejo.
   */
  public static List<Budget__c> getByPropertyId(Id propertyId) {
    if (propertyId == null) {
      return new List<Budget__c>();
    }

    return [
      SELECT Id, Name, Start_Date__c, End_Date__c, Projected_Income__c
      FROM Budget__c
      WHERE Property__c = :propertyId
      WITH USER_MODE
      ORDER BY Start_Date__c DESC
    ];
  }
}
