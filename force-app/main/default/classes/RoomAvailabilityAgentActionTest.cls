@isTest
private class RoomAvailabilityAgentActionTest {
  private static final Decimal NIGHTLY_RATE = 100;

  @isTest
  static void check_habitacionLibre_devuelveDisponibleSinMensaje() {
    Property__c property = TestDataFactory.createProperty();
    insert property;
    Room__c room = TestDataFactory.createRoomWithRate(
      property.Id,
      NIGHTLY_RATE
    );
    insert room;
    room = [SELECT Id, Name FROM Room__c WHERE Id = :room.Id];

    RoomAvailabilityAgentAction.Request request = new RoomAvailabilityAgentAction.Request();
    request.propertyId = property.Id;
    request.roomName = room.Name;
    request.checkIn = Date.today().addDays(10);
    request.checkOut = Date.today().addDays(12);

    Test.startTest();
    List<RoomAvailabilityAgentAction.Response> responses = RoomAvailabilityAgentAction.check(
      new List<RoomAvailabilityAgentAction.Request>{ request }
    );
    Test.stopTest();

    System.assertEquals(true, responses[0].available);
    System.assertEquals(null, responses[0].message);
  }

  @isTest
  static void check_habitacionOcupada_devuelveNoDisponibleConMensaje() {
    Property__c property = TestDataFactory.createProperty();
    insert property;
    Room__c room = TestDataFactory.createRoomWithRate(
      property.Id,
      NIGHTLY_RATE
    );
    insert room;
    room = [SELECT Id, Name FROM Room__c WHERE Id = :room.Id];

    Date checkIn = Date.today().addDays(10);
    Date checkOut = Date.today().addDays(15);
    insert TestDataFactory.buildReservation(room.Id, checkIn, checkOut); // Confirmed por defecto

    RoomAvailabilityAgentAction.Request request = new RoomAvailabilityAgentAction.Request();
    request.propertyId = property.Id;
    request.roomName = room.Name;
    request.checkIn = checkIn.addDays(1); // se solapa
    request.checkOut = checkOut.addDays(1);

    Test.startTest();
    List<RoomAvailabilityAgentAction.Response> responses = RoomAvailabilityAgentAction.check(
      new List<RoomAvailabilityAgentAction.Request>{ request }
    );
    Test.stopTest();

    System.assertEquals(false, responses[0].available);
    System.assertEquals(
      System.Label.Agent_Availability_Not_Available,
      responses[0].message
    );
  }

  @isTest
  static void check_fechasInvertidas_explicaUnMotivoDistintoAOcupada() {
    Property__c property = TestDataFactory.createProperty();
    insert property;
    Room__c room = TestDataFactory.createRoomWithRate(
      property.Id,
      NIGHTLY_RATE
    );
    insert room;
    room = [SELECT Id, Name FROM Room__c WHERE Id = :room.Id];

    RoomAvailabilityAgentAction.Request request = new RoomAvailabilityAgentAction.Request();
    request.propertyId = property.Id;
    request.roomName = room.Name;
    request.checkIn = Date.today().addDays(15);
    request.checkOut = Date.today().addDays(10); // invertidas

    Test.startTest();
    List<RoomAvailabilityAgentAction.Response> responses = RoomAvailabilityAgentAction.check(
      new List<RoomAvailabilityAgentAction.Request>{ request }
    );
    Test.stopTest();

    System.assertEquals(false, responses[0].available);
    System.assertEquals(
      System.Label.Agent_Availability_Invalid_Dates,
      responses[0].message,
      'No puede ser el mismo mensaje que "ocupada": acá el problema son las fechas'
    );
  }

  @isTest
  static void check_habitacionInexistente_explicaSinTirarExcepcion() {
    Property__c property = TestDataFactory.createProperty();
    insert property;

    RoomAvailabilityAgentAction.Request request = new RoomAvailabilityAgentAction.Request();
    request.propertyId = property.Id;
    request.roomName = 'R-9999';
    request.checkIn = Date.today().addDays(10);
    request.checkOut = Date.today().addDays(12);

    Test.startTest();
    List<RoomAvailabilityAgentAction.Response> responses = RoomAvailabilityAgentAction.check(
      new List<RoomAvailabilityAgentAction.Request>{ request }
    );
    Test.stopTest();

    System.assertEquals(false, responses[0].available);
    System.assert(responses[0].message.contains('R-9999'));
  }

  @isTest
  static void check_habitacionDeOtraPropiedad_mismoMotivoQueInexistente() {
    Property__c propertyA = TestDataFactory.createProperty();
    Property__c propertyB = TestDataFactory.createProperty();
    insert new List<Property__c>{ propertyA, propertyB };
    Room__c roomEnB = TestDataFactory.createRoomWithRate(
      propertyB.Id,
      NIGHTLY_RATE
    );
    insert roomEnB;
    roomEnB = [SELECT Id, Name FROM Room__c WHERE Id = :roomEnB.Id];

    RoomAvailabilityAgentAction.Request request = new RoomAvailabilityAgentAction.Request();
    request.propertyId = propertyA.Id; // no es la dueña
    request.roomName = roomEnB.Name;
    request.checkIn = Date.today().addDays(10);
    request.checkOut = Date.today().addDays(12);

    Test.startTest();
    List<RoomAvailabilityAgentAction.Response> responses = RoomAvailabilityAgentAction.check(
      new List<RoomAvailabilityAgentAction.Request>{ request }
    );
    Test.stopTest();

    System.assertEquals(false, responses[0].available);
    System.assertEquals(
      String.format(
        System.Label.Agent_Availability_Room_Not_Found,
        new List<String>{ roomEnB.Name }
      ),
      responses[0].message,
      'Mismo mensaje que "habitación inexistente": los dos casos son en el fondo "no encontré esa habitación en esa propiedad"'
    );
  }

  @isTest
  static void check_bulkConLibreYOcupada_respondeEnElMismoOrden() {
    Property__c property = TestDataFactory.createProperty();
    insert property;
    Room__c roomLibre = TestDataFactory.createRoomWithRate(
      property.Id,
      NIGHTLY_RATE
    );
    Room__c roomOcupada = TestDataFactory.createRoomWithRate(
      property.Id,
      NIGHTLY_RATE
    );
    insert new List<Room__c>{ roomLibre, roomOcupada };
    roomLibre = [SELECT Id, Name FROM Room__c WHERE Id = :roomLibre.Id];
    roomOcupada = [SELECT Id, Name FROM Room__c WHERE Id = :roomOcupada.Id];

    Date checkIn = Date.today().addDays(10);
    Date checkOut = Date.today().addDays(15);
    insert TestDataFactory.buildReservation(roomOcupada.Id, checkIn, checkOut);

    RoomAvailabilityAgentAction.Request requestLibre = new RoomAvailabilityAgentAction.Request();
    requestLibre.propertyId = property.Id;
    requestLibre.roomName = roomLibre.Name;
    requestLibre.checkIn = checkIn;
    requestLibre.checkOut = checkOut;

    RoomAvailabilityAgentAction.Request requestOcupada = new RoomAvailabilityAgentAction.Request();
    requestOcupada.propertyId = property.Id;
    requestOcupada.roomName = roomOcupada.Name;
    requestOcupada.checkIn = checkIn;
    requestOcupada.checkOut = checkOut;

    Test.startTest();
    List<RoomAvailabilityAgentAction.Response> responses = RoomAvailabilityAgentAction.check(
      new List<RoomAvailabilityAgentAction.Request>{
        requestLibre,
        requestOcupada
      }
    );
    Test.stopTest();

    System.assertEquals(2, responses.size());
    System.assertEquals(
      true,
      responses[0].available,
      'La primera corresponde a la habitación libre'
    );
    System.assertEquals(
      false,
      responses[1].available,
      'La segunda a la ocupada, no se mezclan'
    );
  }
}
