public inherited sharing class PropertySelector {
  public static List<Property__c> getPropertyById(Id propertyId) {
    return [
      SELECT Id, Room_Count__c, Total_Expenses__c
      FROM Property__c
      WHERE Id = :propertyId
    ];
  }
}
