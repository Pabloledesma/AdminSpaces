@isTest
private class PropertyDashboardControllerTest {
  @TestSetup
  static void makeData() {
    // Property A: la que vamos a consultar en los tests
    Property__c propertyA = TestDataFactory.createProperty();
    insert propertyA;

    Room__c roomA1 = TestDataFactory.createRoom(propertyA.Id);
    roomA1.Status__c = 'Occupied';
    Room__c roomA2 = TestDataFactory.createRoom(propertyA.Id);
    roomA2.Status__c = 'Available';
    Room__c roomA3 = TestDataFactory.createRoom(propertyA.Id);
    roomA3.Status__c = 'Occupied';
    insert new List<Room__c>{ roomA1, roomA2, roomA3 };
    // → totalRooms = 3, occupiedRooms = 2

    Reservation__c thisMonthConfirmed = TestDataFactory.buildReservation(
      roomA1.Id,
      Date.today(),
      Date.today().addDays(2)
    );
    thisMonthConfirmed.Total_Amount__c = 100; // si el trigger ya lo calcula solo, no hace falta setearlo a mano

    Reservation__c thisMonthPending = TestDataFactory.buildReservation(
      roomA2.Id,
      Date.today().addDays(5),
      Date.today().addDays(7),
      'Pending'
    );

    Reservation__c thisMonthCancelled = TestDataFactory.buildReservation(
      roomA3.Id,
      Date.today(),
      Date.today().addDays(1),
      'Cancelled'
    );

    Reservation__c otherMonthConfirmed = TestDataFactory.buildReservation(
      roomA1.Id,
      Date.today().addMonths(2),
      Date.today().addMonths(2).addDays(2)
    );

    insert new List<Reservation__c>{
      thisMonthConfirmed,
      thisMonthPending,
      thisMonthCancelled,
      otherMonthConfirmed
    };

    Maintenance_Task__c pendingTask = new Maintenance_Task__c(
      Property__c = propertyA.Id,
      Status__c = 'Pending'
    );
    Maintenance_Task__c inProgressTask = new Maintenance_Task__c(
      Property__c = propertyA.Id,
      Status__c = 'In Progress'
    );
    Maintenance_Task__c doneTask = new Maintenance_Task__c(
      Property__c = propertyA.Id,
      Status__c = 'Done'
    );
    insert new List<Maintenance_Task__c>{
      pendingTask,
      inProgressTask,
      doneTask
    };
    // → pendingTasksCount = 2 (Pending + In Progress, no Done)

    // Property B: existe solo para probar que no se mezclan datos entre propiedades
    Property__c propertyB = TestDataFactory.createProperty();
    insert propertyB;

    Room__c roomB1 = TestDataFactory.createRoom(propertyB.Id);
    roomB1.Status__c = 'Occupied';
    insert roomB1;

    insert TestDataFactory.buildReservation(
      roomB1.Id,
      Date.today(),
      Date.today().addDays(1)
    );
    insert new Maintenance_Task__c(
      Property__c = propertyB.Id,
      Status__c = 'Pending'
    );
  }

  @isTest
  static void calcula_correctamente_los_datos_del_dashboard_para_la_propiedad() {
    List<Property__c> lstProperties = [
      SELECT Id, Name, Room_Count__c, Total_Expenses__c
      FROM Property__c
      WHERE Name LIKE '%001'
    ];

    PropertyDashboardController.DashboardData data = PropertyDashboardController.getDashboardData(
      lstProperties[0].Id
    );
    System.assertEquals(
      3,
      data.totalRooms,
      'El número total de habitaciones no es el correcto'
    );
    System.assertEquals(
      2,
      data.occupiedRooms,
      'El número de habitaciones ocupadas no es el correcto'
    );
    System.assertEquals(
      100,
      data.monthlyRevenue,
      'El ingreso mensual no es el correcto'
    );
    System.assertEquals(
      2,
      data.pendingTasksCount,
      'El número de tareas pendientes no es el correcto'
    );
  }

  @IsTest
  static void tira_excepcion_si_la_propiedad_no_existe() {
    Property__c tempProperty = TestDataFactory.createProperty();
    insert tempProperty;
    Id fakeId = tempProperty.Id;
    delete tempProperty;

    Test.startTest();
    try {
      PropertyDashboardController.getDashboardData(fakeId);
      System.assert(false, 'Deberia haber tirado una excepción');
    } catch (AuraHandledException e) {
      System.assertEquals('No se encontró ninguna propiedad!', e.getMessage());
    }
    Test.stopTest();
  }
}
