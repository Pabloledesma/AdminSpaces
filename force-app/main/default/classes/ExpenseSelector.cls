public inherited sharing class ExpenseSelector {
  public static List<AggregateResult> getTotalsByCategoryForProperty(
    Id propertyId
  ) {
    return [
      SELECT Category__c, SUM(Amount__c) total
      FROM Expense__c
      WHERE Property__c = :propertyId
      GROUP BY Category__c
    ];
  }
}
