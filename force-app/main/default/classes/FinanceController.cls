public with sharing class FinanceController {
  public class CategoryTotal {
    @AuraEnabled
    public String category;
    @AuraEnabled
    public Decimal total;
  }

  /**
   * Los selectores corren en USER_MODE, así que una SOQL sobre un objeto/campo
   * sin permisos tira QueryException. Sin este catch, el LWC recibe el genérico
   * "An internal server error has occurred"; con él recibe el mensaje del Custom
   * Label, mismo criterio que el resto de los controllers del proyecto.
   */
  @AuraEnabled(cacheable=true)
  public static List<Property__c> getProperties() {
    try {
      return PropertySelector.getAllProperties();
    } catch (QueryException e) {
      throw AuraExceptionUtil.create(
        System.Label.Finance_Properties_Load_Error
      );
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<CategoryTotal> getExpensesByCategory(Id propertyId) {
    List<CategoryTotal> totals = new List<CategoryTotal>();
    try {
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
    } catch (QueryException e) {
      throw AuraExceptionUtil.create(System.Label.Finance_Expenses_Load_Error);
    }
    return totals;
  }
}
