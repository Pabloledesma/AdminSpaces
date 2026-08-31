@isTest
private class MaintenanceTaskAgentActionTest {
  @isTest
  static void createTask_conHabitacion_creaLaTarea() {
    Property__c property = TestDataFactory.createProperty();
    insert property;
    Room__c room = TestDataFactory.createRoom(property.Id);
    insert room;
    // Room__c.Name SÍ es AutoNumber: queda null en memoria tras el insert.
    room = [SELECT Id, Name FROM Room__c WHERE Id = :room.Id];

    MaintenanceTaskAgentAction.Request request = new MaintenanceTaskAgentAction.Request();
    request.propertyId = property.Id;
    request.roomName = room.Name;
    request.description = 'Pierde agua el caño del baño';
    request.priority = 'High';

    Test.startTest();
    List<MaintenanceTaskAgentAction.Response> responses = MaintenanceTaskAgentAction.createTask(
      new List<MaintenanceTaskAgentAction.Request>{ request }
    );
    Test.stopTest();

    System.assertEquals(true, responses[0].created);
    System.assertNotEquals(null, responses[0].taskName);

    Maintenance_Task__c inserted = [
      SELECT Id, Room__c, Priority__c, Status__c
      FROM Maintenance_Task__c
      WHERE Property__c = :property.Id
    ];
    System.assertEquals(room.Id, inserted.Room__c);
    System.assertEquals('High', inserted.Priority__c);
    System.assertEquals('Pending', inserted.Status__c);
    System.assert(
      responses[0]
        .taskUrl.endsWith(
          '/lightning/r/Maintenance_Task__c/' + inserted.Id + '/view'
        ),
      'El link tiene que apuntar al registro recién creado, no a uno genérico'
    );
  }

  @isTest
  static void createTask_sinHabitacion_quedaSoloAsociadaALaPropiedad() {
    Property__c property = TestDataFactory.createProperty();
    insert property;

    MaintenanceTaskAgentAction.Request request = new MaintenanceTaskAgentAction.Request();
    request.propertyId = property.Id;
    request.description = 'La pintura de la fachada está descascarada';

    Test.startTest();
    MaintenanceTaskAgentAction.createTask(
      new List<MaintenanceTaskAgentAction.Request>{ request }
    );
    Test.stopTest();

    Maintenance_Task__c inserted = [
      SELECT Room__c
      FROM Maintenance_Task__c
      WHERE Property__c = :property.Id
    ];
    System.assertEquals(null, inserted.Room__c);
  }

  @isTest
  static void createTask_habitacionDeOtraPropiedad_noCreaYExplica() {
    Property__c propertyA = TestDataFactory.createProperty();
    Property__c propertyB = TestDataFactory.createProperty();
    insert new List<Property__c>{ propertyA, propertyB };
    Room__c roomEnB = TestDataFactory.createRoom(propertyB.Id);
    insert roomEnB;
    roomEnB = [SELECT Id, Name FROM Room__c WHERE Id = :roomEnB.Id];

    MaintenanceTaskAgentAction.Request request = new MaintenanceTaskAgentAction.Request();
    request.propertyId = propertyA.Id; // no es la dueña de la habitación
    request.roomName = roomEnB.Name;
    request.description = 'Problema';

    Test.startTest();
    List<MaintenanceTaskAgentAction.Response> responses = MaintenanceTaskAgentAction.createTask(
      new List<MaintenanceTaskAgentAction.Request>{ request }
    );
    Test.stopTest();

    System.assertEquals(false, responses[0].created);
    System.assertEquals(0, [SELECT COUNT() FROM Maintenance_Task__c]);
    System.assert(responses[0].message.contains(roomEnB.Name));
  }

  @isTest
  static void createTask_prioridadInvalida_noCreaYListaLasValidas() {
    Property__c property = TestDataFactory.createProperty();
    insert property;

    MaintenanceTaskAgentAction.Request request = new MaintenanceTaskAgentAction.Request();
    request.propertyId = property.Id;
    request.description = 'Problema';
    request.priority = 'Catastrófico';

    Test.startTest();
    List<MaintenanceTaskAgentAction.Response> responses = MaintenanceTaskAgentAction.createTask(
      new List<MaintenanceTaskAgentAction.Request>{ request }
    );
    Test.stopTest();

    System.assertEquals(false, responses[0].created);
    System.assert(responses[0].message.contains('Low'));
    System.assertEquals(0, [SELECT COUNT() FROM Maintenance_Task__c]);
  }

  @isTest
  static void createTask_sinPrioridad_usaMedium() {
    Property__c property = TestDataFactory.createProperty();
    insert property;

    MaintenanceTaskAgentAction.Request request = new MaintenanceTaskAgentAction.Request();
    request.propertyId = property.Id;
    request.description = 'Problema';

    Test.startTest();
    MaintenanceTaskAgentAction.createTask(
      new List<MaintenanceTaskAgentAction.Request>{ request }
    );
    Test.stopTest();

    Maintenance_Task__c inserted = [
      SELECT Priority__c
      FROM Maintenance_Task__c
      WHERE Property__c = :property.Id
    ];
    System.assertEquals('Medium', inserted.Priority__c);
  }

  @isTest
  static void createTask_descripcionLarga_truncaElNombreA80Caracteres() {
    Property__c property = TestDataFactory.createProperty();
    insert property;

    MaintenanceTaskAgentAction.Request request = new MaintenanceTaskAgentAction.Request();
    request.propertyId = property.Id;
    request.description = 'x'.repeat(120); // supera los 80 del campo Name

    Test.startTest();
    MaintenanceTaskAgentAction.createTask(
      new List<MaintenanceTaskAgentAction.Request>{ request }
    );
    Test.stopTest();

    Maintenance_Task__c inserted = [
      SELECT Name
      FROM Maintenance_Task__c
      WHERE Property__c = :property.Id
    ];
    System.assertEquals(
      80,
      inserted.Name.length(),
      'Name no puede superar el límite del campo'
    );
  }

  @isTest
  static void createTask_bulkConUnaValidaYUnaInvalida_respondeEnElMismoOrden() {
    Property__c property = TestDataFactory.createProperty();
    insert property;

    MaintenanceTaskAgentAction.Request valida = new MaintenanceTaskAgentAction.Request();
    valida.propertyId = property.Id;
    valida.description = 'Foco quemado en el pasillo';

    MaintenanceTaskAgentAction.Request invalida = new MaintenanceTaskAgentAction.Request();
    invalida.propertyId = property.Id;
    invalida.description = 'Otro problema';
    invalida.priority = 'Catastrófico';

    Test.startTest();
    List<MaintenanceTaskAgentAction.Response> responses = MaintenanceTaskAgentAction.createTask(
      new List<MaintenanceTaskAgentAction.Request>{ valida, invalida }
    );
    Test.stopTest();

    System.assertEquals(2, responses.size());
    System.assertEquals(
      true,
      responses[0].created,
      'La primera response corresponde al request válido'
    );
    System.assertEquals(
      false,
      responses[1].created,
      'La segunda corresponde al inválido, no se mezclan'
    );
    System.assertEquals(
      1,
      [SELECT COUNT() FROM Maintenance_Task__c],
      'Solo la válida se insertó'
    );
  }
}
