@isTest
private class ReservationCreationControllerTest {
  @TestSetup
  static void makeData() {
    Property__c property = TestDataFactory.createProperty();
    insert property;

    Room__c room = TestDataFactory.createRoom(property.Id);
    insert room;

    Contact guest = new Contact(LastName = 'Guest');
    insert guest;

    // Reserva existente, para probar el bloqueo por solapamiento
    insert TestDataFactory.buildReservation(
      room.Id,
      Date.today().addDays(10),
      Date.today().addDays(12)
    );
  }

  @isTest
  static void createReservation_createsReservationSuccessfully() {
    Room__c room = [SELECT Id FROM Room__c LIMIT 1];
    Contact guest = [SELECT Id FROM Contact LIMIT 1];

    Test.startTest();
    Id reservationId = ReservationCreationController.createReservation(
      room.Id,
      guest.Id,
      Date.today().addDays(30),
      Date.today().addDays(32)
    );
    Test.stopTest();

    Reservation__c reservation = [
      SELECT Room__c, Guest__c, Check_In_Date__c, Check_Out_Date__c, Status__c
      FROM Reservation__c
      WHERE Id = :reservationId
    ];
    System.assertEquals(
      room.Id,
      reservation.Room__c,
      'La habitación no es la correcta'
    );
    System.assertEquals(
      guest.Id,
      reservation.Guest__c,
      'El huésped no es el correcto'
    );
    System.assertEquals(
      'Pending',
      reservation.Status__c,
      'El estado inicial debería ser Pending'
    );
  }

  @isTest
  static void createReservation_blocksOverlappingDates() {
    Room__c room = [SELECT Id FROM Room__c LIMIT 1];
    Contact guest = [SELECT Id FROM Contact LIMIT 1];

    try {
      ReservationCreationController.createReservation(
        room.Id,
        guest.Id,
        Date.today().addDays(11),
        Date.today().addDays(13)
      );
      System.assert(
        false,
        'Debería haber tirado una excepción por solapamiento'
      );
    } catch (AuraHandledException e) {
      System.assertEquals(
        'Las fechas se solapan con otra reserva existente para esta habitación.',
        e.getMessage()
      );
    }
  }
}
