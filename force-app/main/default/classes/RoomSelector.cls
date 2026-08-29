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

  /**
   * Habitaciones cuyo código (Name) está en el conjunto dado, para resolver
   * en bloque todas las habitaciones que mencionan N requests de una acción
   * de Agentforce (Historia 6) con una sola query.
   *
   * Alcanza con Name, sin filtrar por Property__c: Room__c.Name es un
   * AutoNumber global al objeto (R-{0000} no se reinicia por propiedad,
   * verificado contra el org), así que un código de habitación identifica
   * como máximo un registro en todo el org. El caller es quien tiene que
   * confirmar que la habitación encontrada pertenece a la propiedad
   * esperada — esta query no lo garantiza.
   */

  public static List<Room__c> getByNames(Set<String> roomNames) {
    if (roomNames.isEmpty()) {
      return new List<Room__c>();
    }
    return [
      SELECT Id, Name, Property__c
      FROM Room__c
      WHERE Name IN :roomNames
      WITH USER_MODE
    ];
  }
}
