public with sharing class FinanceController {
  public class CategoryTotal {
    @AuraEnabled
    public String category;
    @AuraEnabled
    public Decimal total;
  }

  @AuraEnabled(cacheable=true)
  public static List<Property__c> getProperties() {
    return PropertySelector.getAllProperties();
  }

  @AuraEnabled(cacheable=true)
  public static List<CategoryTotal> getExpensesByCategory(Id propertyId) {
    List<CategoryTotal> totals = new List<CategoryTotal>();
    for (
      AggregateResult ar : ExpenseSelector.getTotalsByCategoryForProperty(
        propertyId
      )
    ) {
      CategoryTotal ct = new CategoryTotal();
      ct.category = (String) ar.get('Category__c');
      ct.total = (Decimal) ar.get('total');
      totals.add(ct);
    }
    return totals;
  }
}
