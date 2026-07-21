public inherited sharing class RoomSelector {
  public static List<Room__c> getRoomsById(Set<Id> setId) {
    return [SELECT Id, Nightly_Rate__c FROM Room__c WHERE Id IN :setId];
  }

  public static Map<String, Integer> getRoomCountsByStatusForProperty(
    Id propertyId
  ) {
    Map<String, Integer> countsByStatus = new Map<String, Integer>();
    if (propertyId == null) {
      return countsByStatus;
    }

    for (AggregateResult result : [
      SELECT Status__c status, COUNT(Id) total
      FROM Room__c
      WHERE Property__c = :propertyId
      GROUP BY Status__c
    ]) {
      countsByStatus.put(
        (String) result.get('status'),
        (Integer) result.get('total')
      );
    }
    return countsByStatus;
  }

  public static List<Room__c> getRoomFromPropertyId(Id propertyId) {
    List<Room__c> lstRoom = new List<Room__c>();
    if (propertyId == null) {
      return lstRoom;
    }

    return [
      SELECT Id, Name, Room_Type__c, Capacity__c, Nightly_Rate__c, Status__c
      FROM Room__c
      WHERE Property__c = :propertyId
    ];
  }
}
