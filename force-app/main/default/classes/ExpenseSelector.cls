public inherited sharing class ExpenseSelector {
  /**
   * `WITH USER_MODE` aplica permisos de objeto y FLS del usuario corriendo.
   * Va antes del GROUP BY: el orden de cláusulas de SOQL es
   * WHERE -> WITH -> GROUP BY.
   *
   * Solo agrega la capa de objeto/campo: el sharing a nivel registro ya venía
   * aplicado porque esta clase es `inherited sharing` y su único caller
   * (FinanceController) es `with sharing`.
   */
  public static List<AggregateResult> getTotalsByCategoryForProperty(
    Id propertyId
  ) {
    return [
      SELECT Category__c, SUM(Amount__c) total
      FROM Expense__c
      WHERE Property__c = :propertyId
      WITH USER_MODE
      GROUP BY Category__c
    ];
  }

  /**
   * Historia 5.6: gastos de la propiedad dentro de una ventana de fechas, para
   * comparar contra lo presupuestado. Devuelve los registros (no un SUM) porque
   * el caller reparte un solo resultado entre varios presupuestos con períodos
   * distintos: así son N presupuestos con 1 query, no N queries.
   */
  public static List<Expense__c> getForPropertyInPeriod(
    Id propertyId,
    Date startDate,
    Date endDate
  ) {
    if (propertyId == null || startDate == null || endDate == null) {
      return new List<Expense__c>();
    }

    return [
      SELECT Amount__c, Expense_Date__c
      FROM Expense__c
      WHERE
        Property__c = :propertyId
        AND Expense_Date__c >= :startDate
        AND Expense_Date__c <= :endDate
      WITH USER_MODE
    ];
  }
}
