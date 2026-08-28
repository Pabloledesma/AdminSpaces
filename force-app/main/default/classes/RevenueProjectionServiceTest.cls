/**
 * La regla de la Historia 5.6: cada mes del período se resuelve con reservas
 * reales si las tiene, y con el promedio de los últimos 12 meses si no.
 */
@isTest
private class RevenueProjectionServiceTest {
  private static final Decimal NIGHTLY_RATE = 100;

  /**
   * Arma una propiedad con: 200 de ingreso histórico (2 noches hace dos meses)
   * y 300 de ingreso ya reservado para el mes que viene.
   */
  @TestSetup
  static void makeData() {
    Property__c property = TestDataFactory.createProperty();
    insert property;

    Room__c room = TestDataFactory.createRoomWithRate(
      property.Id,
      NIGHTLY_RATE
    );
    insert room;

    Date startOfThisMonth = Date.today().toStartOfMonth();
    Date historic = startOfThisMonth.addMonths(-2);
    Date nextMonth = startOfThisMonth.addMonths(1);

    insert new List<Reservation__c>{
      TestDataFactory.buildReservation(room.Id, historic, historic.addDays(2)),
      TestDataFactory.buildReservation(room.Id, nextMonth, nextMonth.addDays(3))
    };
  }

  private static Id propertyId() {
    return [SELECT Id FROM Property__c LIMIT 1].Id;
  }

  @isTest
  static void project_mesConReservas_usaElIngresoReal() {
    Date nextMonth = Date.today().toStartOfMonth().addMonths(1);

    Test.startTest();
    RevenueProjectionService.Projection projection = RevenueProjectionService.project(
      propertyId(),
      nextMonth,
      nextMonth.addMonths(1).addDays(-1)
    );
    Test.stopTest();

    System.assertEquals(1, projection.months.size(), 'Un solo mes proyectado');
    System.assertEquals(
      true,
      projection.months[0].fromReservations,
      'El mes tiene reservas: no debe usar el promedio'
    );
    System.assertEquals(
      300,
      projection.months[0].amount,
      '3 noches x 100 de la reserva ya cargada'
    );
    System.assertEquals(300, projection.total, 'El total es ese único mes');
  }

  @isTest
  static void project_mesSinReservas_usaElPromedioHistorico() {
    // Dos meses adelante: no tiene ninguna reserva cargada
    Date emptyMonth = Date.today().toStartOfMonth().addMonths(2);

    Test.startTest();
    RevenueProjectionService.Projection projection = RevenueProjectionService.project(
      propertyId(),
      emptyMonth,
      emptyMonth.addMonths(1).addDays(-1)
    );
    Test.stopTest();

    // 200 de histórico repartidos en los 12 meses de la ventana
    Decimal expectedAverage = ((Decimal) 200)
      .divide(12, 2, System.RoundingMode.HALF_UP);
    System.assertEquals(
      false,
      projection.months[0].fromReservations,
      'Sin reservas, el mes se estima con el promedio'
    );
    System.assertEquals(
      expectedAverage,
      projection.months[0].amount,
      'El promedio divide por los 12 meses, incluidos los vacíos'
    );
    System.assertEquals(
      expectedAverage,
      projection.historicalMonthlyAverage,
      'La proyección expone el promedio usado'
    );
  }

  @isTest
  static void project_periodoMixto_combinaRealYPromedio() {
    Date nextMonth = Date.today().toStartOfMonth().addMonths(1);

    Test.startTest();
    RevenueProjectionService.Projection projection = RevenueProjectionService.project(
      propertyId(),
      nextMonth,
      nextMonth.addMonths(3).addDays(-1)
    );
    Test.stopTest();

    Decimal expectedAverage = ((Decimal) 200)
      .divide(12, 2, System.RoundingMode.HALF_UP);

    System.assertEquals(3, projection.months.size(), 'Tres meses proyectados');
    System.assertEquals(
      true,
      projection.months[0].fromReservations,
      'El primer mes tiene reservas reales'
    );
    System.assertEquals(
      false,
      projection.months[1].fromReservations,
      'El segundo no'
    );
    System.assertEquals(
      false,
      projection.months[2].fromReservations,
      'El tercero tampoco'
    );
    System.assertEquals(
      300 + expectedAverage + expectedAverage,
      projection.total,
      'El total mezcla el mes real con los dos estimados'
    );
  }

  @isTest
  static void project_propiedadSinHistorial_promedioCero() {
    Property__c nueva = TestDataFactory.createProperty();
    insert nueva;
    Date nextMonth = Date.today().toStartOfMonth().addMonths(1);

    Test.startTest();
    RevenueProjectionService.Projection projection = RevenueProjectionService.project(
      nueva.Id,
      nextMonth,
      nextMonth.addMonths(1).addDays(-1)
    );
    Test.stopTest();

    System.assertEquals(
      0,
      projection.historicalMonthlyAverage,
      'Sin historial el promedio es 0, no un error'
    );
    System.assertEquals(0, projection.total, 'Y la proyección total es 0');
  }

  @isTest
  static void project_periodoInvertido_devuelveProyeccionVacia() {
    Date nextMonth = Date.today().toStartOfMonth().addMonths(1);

    Test.startTest();
    RevenueProjectionService.Projection invertido = RevenueProjectionService.project(
      propertyId(),
      nextMonth.addMonths(2),
      nextMonth
    );
    RevenueProjectionService.Projection sinPropiedad = RevenueProjectionService.project(
      null,
      nextMonth,
      nextMonth.addMonths(1)
    );
    Test.stopTest();

    System.assertEquals(
      0,
      invertido.months.size(),
      'Un período invertido no proyecta nada'
    );
    System.assertEquals(0, sinPropiedad.months.size(), 'Sin propiedad tampoco');
  }

  @isTest
  static void project_reservaCancelada_noCuentaComoIngreso() {
    Property__c property = [SELECT Id FROM Property__c LIMIT 1];
    Room__c room = TestDataFactory.createRoomWithRate(
      property.Id,
      NIGHTLY_RATE
    );
    insert room;

    Date emptyMonth = Date.today().toStartOfMonth().addMonths(2);
    insert TestDataFactory.buildReservation(
      room.Id,
      emptyMonth,
      emptyMonth.addDays(4),
      'Cancelled'
    );

    Test.startTest();
    RevenueProjectionService.Projection projection = RevenueProjectionService.project(
      property.Id,
      emptyMonth,
      emptyMonth.addMonths(1).addDays(-1)
    );
    Test.stopTest();

    System.assertEquals(
      false,
      projection.months[0].fromReservations,
      'Una reserva cancelada no convierte el mes en "mes con reservas"'
    );
  }

  @isTest
  static void project_mesConReservasSinImporte_caeAlPromedio() {
    Property__c property = [SELECT Id FROM Property__c LIMIT 1];
    // Habitación sin tarifa: el trigger no puede calcular Total_Amount__c,
    // así que SUM devuelve null para ese mes.
    Room__c sinTarifa = TestDataFactory.createRoom(property.Id);
    insert sinTarifa;

    Date emptyMonth = Date.today().toStartOfMonth().addMonths(3);
    insert TestDataFactory.buildReservation(
      sinTarifa.Id,
      emptyMonth,
      emptyMonth.addDays(2)
    );

    Test.startTest();
    RevenueProjectionService.Projection projection = RevenueProjectionService.project(
      property.Id,
      emptyMonth,
      emptyMonth.addMonths(1).addDays(-1)
    );
    Test.stopTest();

    System.assertEquals(
      false,
      projection.months[0].fromReservations,
      'Un mes con reservas sin importe no tiene dato real: usa el promedio'
    );
    System.assertEquals(
      projection.historicalMonthlyAverage,
      projection.months[0].amount,
      'Y el monto proyectado es el del promedio'
    );
  }

  @isTest
  static void project_periodoQueNoEmpiezaElDiaUno_igualVeLasReservasDelMes() {
    // La reserva del mes que viene arranca el día 1; el período pedido empieza
    // el 20. Como la proyección razona en meses completos, ese mes tiene dato
    // real y no puede caer al promedio.
    Date nextMonth = Date.today().toStartOfMonth().addMonths(1);

    Test.startTest();
    RevenueProjectionService.Projection projection = RevenueProjectionService.project(
      propertyId(),
      nextMonth.addDays(19),
      nextMonth.addDays(25)
    );
    Test.stopTest();

    System.assertEquals(1, projection.months.size(), 'Un solo mes tocado');
    System.assertEquals(
      true,
      projection.months[0].fromReservations,
      'El mes tiene reservas reales aunque el período no las incluya por día'
    );
    System.assertEquals(
      300,
      projection.months[0].amount,
      'Y usa el ingreso real del mes completo, no el promedio'
    );
  }

  @isTest
  static void project_periodoDeDosDiasEntreDosMeses_proyectaLosDosMesesCompletos() {
    Date nextMonth = Date.today().toStartOfMonth().addMonths(1);
    Date finDeMes = nextMonth.addMonths(1).addDays(-1);

    Test.startTest();
    RevenueProjectionService.Projection projection = RevenueProjectionService.project(
      propertyId(),
      finDeMes,
      finDeMes.addDays(1)
    );
    Test.stopTest();

    Decimal promedio = ((Decimal) 200)
      .divide(12, 2, System.RoundingMode.HALF_UP);
    System.assertEquals(2, projection.months.size(), 'Toca dos meses');
    System.assertEquals(
      true,
      projection.months[0].fromReservations,
      'El primero tiene la reserva del mes, aunque caiga fuera de los dos días'
    );
    System.assertEquals(300, projection.months[0].amount);
    System.assertEquals(promedio, projection.months[1].amount);
  }
}
