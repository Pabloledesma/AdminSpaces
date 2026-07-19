public with sharing class TestDataFactory {
  public static Property__c createProperty() {
    return new Property__c(Is_Demo__c = true);
  }

  public static Room__c createRoom(Id propertyId) {
    return new Room__c(
      Property__c = propertyId,
      Room_Type__c = 'Single',
      Is_Demo__c = true
    );
  }

  public static Room__c createRoomWithRate(Id propertyId, Decimal rate) {
    return new Room__c(
      Property__c = propertyId,
      Room_Type__c = 'Single',
      Is_Demo__c = true,
      Nightly_Rate__c = rate
    );
  }

  public static Reservation__c buildReservation(
    Id roomId,
    Date checkIn,
    Date checkOut
  ) {
    return buildReservation(roomId, checkIn, checkOut, 'Confirmed');
  }

  public static Reservation__c buildReservation(
    Id roomId,
    Date checkIn,
    Date checkOut,
    String status
  ) {
    return new Reservation__c(
      Room__c = roomId,
      Check_In_Date__c = checkIn,
      Check_Out_Date__c = checkOut,
      Status__c = status,
      Is_Demo__c = true
    );
  }
}
