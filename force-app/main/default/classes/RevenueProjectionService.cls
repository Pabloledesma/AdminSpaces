/**
 * Historia 5.6: proyecta el ingreso de una propiedad mes a mes dentro de un
 * período, resolviendo cada mes con el dato más confiable que exista para ese
 * mes:
 *
 * - si el mes ya tiene reservas activas, usa la suma real de esas reservas;
 * - si no tiene ninguna (lo esperable cuanto más lejos se proyecta), usa el
 *   promedio mensual de los últimos 12 meses de esa propiedad.
 *
 * Ni todo reservas (no existen tan lejos en el futuro) ni todo promedio
 * (ignoraría lo que ya está confirmado en el corto plazo). El promedio divide
 * por los 12 meses completos, incluidos los vacíos: una propiedad que estuvo
 * medio año sin alquilar no debe proyectar como si siempre estuviera llena.
 *
 * La clase no hace DML ni conoce a Budget__c: solo calcula. Quien decide
 * congelar el resultado en un presupuesto es BudgetController.
 */
public inherited sharing class RevenueProjectionService {
  @TestVisible
  private static final Integer HISTORY_MONTHS = 12;

  public class MonthlyProjection {
    @AuraEnabled
    public String label;
    @AuraEnabled
    public Decimal amount;
    /** true = suma real de reservas de ese mes; false = promedio histórico. */
    @AuraEnabled
    public Boolean fromReservations;
  }

  public class Projection {
    @AuraEnabled
    public List<MonthlyProjection> months = new List<MonthlyProjection>();
    @AuraEnabled
    public Decimal total = 0;
    @AuraEnabled
    public Decimal historicalMonthlyAverage = 0;
  }

  /**
   * @param propertyId Propiedad a proyectar
   * @param startDate Primer día del período (se proyecta desde su mes)
   * @param endDate Último día del período (se proyecta hasta su mes, inclusive)
   * @return La proyección; vacía si los parámetros no describen un período válido
   */
  public static Projection project(
    Id propertyId,
    Date startDate,
    Date endDate
  ) {
    Projection projection = new Projection();
    if (
      propertyId == null ||
      startDate == null ||
      endDate == null ||
      endDate <= startDate
    ) {
      return projection;
    }

    projection.historicalMonthlyAverage = averageMonthlyRevenue(propertyId);

    // La proyección razona en meses calendario completos (ver el javadoc de
    // Start_Date__c/End_Date__c), así que la query tiene que preguntar por los
    // mismos meses completos y no por los días exactos del período. Si se
    // mezclan las dos escalas, un período que arranca el 15 pierde las reservas
    // del 1 al 14 de ese mismo mes: el mes cae al promedio y encima se muestra
    // etiquetado como "Promedio" aunque el dato real exista.
    Date cursor = startDate.toStartOfMonth();
    Date lastMonth = endDate.toStartOfMonth();
    Map<String, Decimal> revenueByMonth = revenueByMonth(
      propertyId,
      cursor,
      lastMonth.addMonths(1).addDays(-1)
    );
    while (cursor <= lastMonth) {
      String key = monthKey(cursor.year(), cursor.month());

      MonthlyProjection monthProjection = new MonthlyProjection();
      monthProjection.label = key;
      monthProjection.fromReservations = revenueByMonth.containsKey(key);
      monthProjection.amount = monthProjection.fromReservations
        ? revenueByMonth.get(key)
        : projection.historicalMonthlyAverage;

      projection.months.add(monthProjection);
      projection.total += monthProjection.amount;
      cursor = cursor.addMonths(1);
    }

    return projection;
  }

  /**
   * Promedio de los últimos 12 meses cerrados: la ventana termina el último día
   * del mes pasado, no hoy, porque el mes en curso está incompleto por
   * definición y arrastraría el promedio para abajo.
   */
  private static Decimal averageMonthlyRevenue(Id propertyId) {
    Date startOfThisMonth = Date.today().toStartOfMonth();
    Date historyStart = startOfThisMonth.addMonths(-HISTORY_MONTHS);
    Date historyEnd = startOfThisMonth.addDays(-1);

    Decimal total = 0;
    for (
      Decimal monthlyTotal : revenueByMonth(
          propertyId,
          historyStart,
          historyEnd
        )
        .values()
    ) {
      total += monthlyTotal;
    }

    return total.divide(HISTORY_MONTHS, 2, System.RoundingMode.HALF_UP);
  }

  private static Map<String, Decimal> revenueByMonth(
    Id propertyId,
    Date startDate,
    Date endDate
  ) {
    Map<String, Decimal> revenueByMonth = new Map<String, Decimal>();
    for (
      AggregateResult ar : ReservationSelector.getRevenueByMonthForProperty(
        propertyId,
        startDate,
        endDate
      )
    ) {
      Decimal total = (Decimal) ar.get('total');
      // SUM devuelve null cuando el mes tiene reservas pero ninguna con importe
      // (por ejemplo, habitaciones sin tarifa cargada). Eso es ausencia de
      // información, no un ingreso de cero: se deja fuera del mapa para que el
      // mes caiga en el promedio histórico, que es justamente el dato más
      // confiable que queda disponible. Un 0 real sí se respeta como 0.
      if (total != null) {
        revenueByMonth.put(
          monthKey((Integer) ar.get('yr'), (Integer) ar.get('mth')),
          total
        );
      }
    }
    return revenueByMonth;
  }

  private static String monthKey(Integer year, Integer month) {
    return year + '-' + String.valueOf(month).leftPad(2, '0');
  }
}
