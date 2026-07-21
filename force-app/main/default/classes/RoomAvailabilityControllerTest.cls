@isTest
private class RoomAvailabilityControllerTest {
  @TestSetup
  static void makeData() {
    Property__c property = TestDataFactory.createProperty();
    insert property;

    Room__c room1 = TestDataFactory.createRoom(property.Id);
    Room__c room2 = TestDataFactory.createRoom(property.Id);
    insert new List<Room__c>{ room1, room2 };

    // Reserva confirmada en room1, para probar solapamiento real
    insert TestDataFactory.buildReservation(
      room1.Id,
      Date.today().addDays(10),
      Date.today().addDays(12)
    );

    // Reserva cancelada en room1, en fechas que SÍ se solaparían si no fuera Cancelled
    insert TestDataFactory.buildReservation(
      room1.Id,
      Date.today().addDays(20),
      Date.today().addDays(22),
      'Cancelled'
    );

    Property__c property2 = TestDataFactory.createProperty();
    insert property2;

    Room__c room3 = TestDataFactory.createRoom(property2.Id);
    insert room3;
  }

  @isTest
  static void checkAvailability_returnsTrueWhenNoOverlap() {
    Room__c room1 = [SELECT Id FROM Room__c LIMIT 1];
    // fechas que no chocan con la reserva confirmada (10-12)
    Boolean available = RoomAvailabilityController.checkAvailability(
      room1.Id,
      Date.today().addDays(30),
      Date.today().addDays(32)
    );
    System.assertEquals(
      true,
      available,
      'Debería estar disponible en fechas sin conflicto'
    );
  }

  @isTest
  static void checkAvailability_returnsFalseWhenOverlaps() {
    Room__c room1 = [SELECT Id FROM Room__c LIMIT 1];
    // se solapa con la reserva confirmada (10-12)
    Boolean available = RoomAvailabilityController.checkAvailability(
      room1.Id,
      Date.today().addDays(11),
      Date.today().addDays(13)
    );
    System.assertEquals(
      false,
      available,
      'No debería estar disponible si se solapa con una reserva activa'
    );
  }

  @isTest
  static void checkAvailability_ignoresCancelledReservations() {
    Room__c room1 = [SELECT Id FROM Room__c LIMIT 1];
    // mismas fechas que la reserva Cancelled (20-22) — no debería bloquear
    Boolean available = RoomAvailabilityController.checkAvailability(
      room1.Id,
      Date.today().addDays(20),
      Date.today().addDays(22)
    );
    System.assertEquals(
      true,
      available,
      'Una reserva Cancelled no debería bloquear disponibilidad'
    );
  }

  @isTest
  static void getRoomsForProperty_returnsOnlyRoomsOfThatProperty() {
    // armá una segunda Property con su propia Room acá, y confirmá
    // que getRoomsForProperty de la primera propiedad no la incluye
    List<Property__c> lstProperty = PropertySelector.getPropertyByRoomCount(1);
    System.assertEquals(
      1,
      lstProperty.size(),
      'El número de propiedades no es el correcto.'
    );
    List<Room__c> lstRoom = RoomSelector.getRoomFromPropertyId(
      lstProperty[0].Id
    );
    System.assertEquals(
      1,
      lstRoom.size(),
      'El núermo de habitaciones no es el correcto'
    );
  }

  @IsTest
  static void getBlockedDateRangesForRoom_returnsOnlyBlockingReservationsForThatRoom() {
    List<Property__c> lstProperty = PropertySelector.getPropertyByRoomCount(2);
    System.assertEquals(
      1,
      lstProperty.size(),
      'El número de propiedades no es el correcto.'
    );
    List<Room__c> lstRoom = RoomSelector.getRoomFromPropertyId(
      lstProperty[0].Id
    );
    System.assertEquals(
      2,
      lstRoom.size(),
      'El núermo de habitaciones no es el correcto'
    );
    List<Reservation__c> lstReservation = new List<Reservation__c>();
    Test.startTest();
    lstReservation = RoomAvailabilityController.getBlockedDateRangesForRoom(
      lstRoom[0].Id
    );
    Test.stopTest();

    System.assertEquals(
      1,
      lstReservation.size(),
      'El número de reservas no es el correcto'
    );
  }
}
