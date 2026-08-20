@isTest
private class BudgetControllerTest {
  private static final Decimal NIGHTLY_RATE = 100;

  @TestSetup
  static void makeData() {
    Property__c property = TestDataFactory.createProperty();
    insert property;

    Room__c room = TestDataFactory.createRoomWithRate(
      property.Id,
      NIGHTLY_RATE
    );
    insert room;

    Date nextMonth = Date.today().toStartOfMonth().addMonths(1);
    insert TestDataFactory.buildReservation(
      room.Id,
      nextMonth,
      nextMonth.addDays(3)
    );
  }

  private static Id propertyId() {
    return [SELECT Id FROM Property__c LIMIT 1].Id;
  }

  @isTest
  static void previewProjection_devuelveElDesgloseSinGuardarNada() {
    Date nextMonth = Date.today().toStartOfMonth().addMonths(1);

    Test.startTest();
    RevenueProjectionService.Projection projection = BudgetController.previewProjection(
      propertyId(),
      nextMonth,
      nextMonth.addMonths(1).addDays(-1)
    );
    Test.stopTest();

    System.assertEquals(300, projection.total, '3 noches x 100');
    System.assertEquals(
      0,
      [SELECT COUNT() FROM Budget__c],
      'Previsualizar no puede crear registros'
    );
  }

  @isTest
  static void createBudget_congelaLaProyeccionEnElRegistro() {
    Date nextMonth = Date.today().toStartOfMonth().addMonths(1);

    Test.startTest();
    Id budgetId = BudgetController.createBudget(
      propertyId(),
      nextMonth,
      nextMonth.addMonths(1).addDays(-1)
    );
    Test.stopTest();

    Budget__c creado = [
      SELECT Projected_Income__c, Start_Date__c, End_Date__c
      FROM Budget__c
      WHERE Id = :budgetId
    ];
    System.assertEquals(
      300,
      creado.Projected_Income__c,
      'El presupuesto guarda la proyección calculada al crearlo'
    );
  }

  @isTest
  static void createBudget_noSeRecalculaCuandoEntranReservasNuevas() {
    Date nextMonth = Date.today().toStartOfMonth().addMonths(1);
    Id budgetId = BudgetController.createBudget(
      propertyId(),
      nextMonth,
      nextMonth.addMonths(1).addDays(-1)
    );

    // Después de crear el presupuesto entra otra reserva en el mismo mes
    Room__c otraHabitacion = TestDataFactory.createRoomWithRate(
      propertyId(),
      NIGHTLY_RATE
    );
    insert otraHabitacion;

    Test.startTest();
    insert TestDataFactory.buildReservation(
      otraHabitacion.Id,
      nextMonth.addDays(10),
      nextMonth.addDays(12)
    );
    Test.stopTest();

    Budget__c guardado = [
      SELECT Projected_Income__c
      FROM Budget__c
      WHERE Id = :budgetId
    ];
    System.assertEquals(
      300,
      guardado.Projected_Income__c,
      'El snapshot no se mueve: es la decisión tomada aquel día'
    );
  }

  @isTest
  static void getBudgets_calculaGastadoYDisponiblePorPeriodo() {
    Date inicio = Date.today().toStartOfMonth();
    Date fin = inicio.addMonths(2).addDays(-1);

    insert TestDataFactory.buildBudget(propertyId(), inicio, fin, 1000);

    insert new List<Expense__c>{
      new Expense__c(
        Property__c = propertyId(),
        Category__c = 'Materials',
        Amount__c = 250,
        Expense_Date__c = inicio.addDays(5)
      ),
      // Fuera del período: no debe contarse
      new Expense__c(
        Property__c = propertyId(),
        Category__c = 'Labor',
        Amount__c = 700,
        Expense_Date__c = fin.addDays(30)
      )
    };

    Test.startTest();
    List<BudgetController.BudgetSummary> resumenes = BudgetController.getBudgets(
      propertyId()
    );
    Test.stopTest();

    System.assertEquals(1, resumenes.size(), 'Un presupuesto');
    System.assertEquals(
      250,
      resumenes[0].actualExpenses,
      'Solo el gasto dentro del período del presupuesto'
    );
    System.assertEquals(
      750,
      resumenes[0].available,
      'Disponible = proyectado - gastado'
    );
  }

  @isTest
  static void getBudgets_sinPresupuestos_devuelveListaVacia() {
    Test.startTest();
    List<BudgetController.BudgetSummary> resumenes = BudgetController.getBudgets(
      propertyId()
    );
    Test.stopTest();

    System.assertEquals(0, resumenes.size(), 'Lista vacía, no excepción');
  }

  @isTest
  static void previewProjection_periodoInvalido_tiraErrorEntendible() {
    Date nextMonth = Date.today().toStartOfMonth().addMonths(1);
    String mensaje;

    Test.startTest();
    try {
      BudgetController.previewProjection(
        propertyId(),
        nextMonth.addMonths(2),
        nextMonth
      );
      System.assert(false, 'Se esperaba un error de período inválido');
    } catch (AuraHandledException e) {
      mensaje = e.getMessage();
    }
    Test.stopTest();

    System.assertEquals(System.Label.Budget_Invalid_Period, mensaje);
  }

  @isTest
  static void createBudget_sinPropiedad_tiraErrorEntendible() {
    Date nextMonth = Date.today().toStartOfMonth().addMonths(1);
    String mensaje;

    Test.startTest();
    try {
      BudgetController.createBudget(null, nextMonth, nextMonth.addMonths(1));
      System.assert(false, 'Se esperaba un error de propiedad faltante');
    } catch (AuraHandledException e) {
      mensaje = e.getMessage();
    }
    Test.stopTest();

    System.assertEquals(System.Label.Budget_Property_Required, mensaje);
  }

  @isTest
  static void getBudgets_usuarioSinAcceso_tiraErrorEntendible() {
    Id propId = propertyId();
    User restricted = TestDataFactory.createUserWithoutAccess();
    String mensaje;

    System.runAs(restricted) {
      Test.startTest();
      try {
        BudgetController.getBudgets(propId);
        System.assert(false, 'Se esperaba un error de acceso a Budget__c');
      } catch (AuraHandledException e) {
        mensaje = e.getMessage();
      }
      Test.stopTest();
    }

    System.assertEquals(
      System.Label.Budget_Load_Error,
      mensaje,
      'El QueryException de USER_MODE se traduce al Custom Label'
    );
  }

  @isTest
  static void previewProjection_usuarioSinAcceso_tiraErrorEntendible() {
    Id propId = propertyId();
    Date nextMonth = Date.today().toStartOfMonth().addMonths(1);
    User restricted = TestDataFactory.createUserWithoutAccess();
    String mensaje;

    System.runAs(restricted) {
      Test.startTest();
      try {
        BudgetController.previewProjection(
          propId,
          nextMonth,
          nextMonth.addMonths(1)
        );
        System.assert(false, 'Se esperaba un error de acceso a Reservation__c');
      } catch (AuraHandledException e) {
        mensaje = e.getMessage();
      }
      Test.stopTest();
    }

    System.assertEquals(System.Label.Budget_Projection_Error, mensaje);
  }
}
