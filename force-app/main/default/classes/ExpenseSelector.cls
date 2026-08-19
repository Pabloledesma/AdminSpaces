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
}
