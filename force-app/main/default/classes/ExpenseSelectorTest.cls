@isTest
private class ExpenseSelectorTest {
  @isTest
  static void getTotalsByCategoryForProperty_agrupaYSumaCorrectamente() {
    Property__c property = TestDataFactory.createProperty();
    insert property;

    insert new List<Expense__c>{
      new Expense__c(
        Property__c = property.Id,
        Category__c = 'Materials',
        Amount__c = 100,
        Expense_Date__c = Date.today()
      ),
      new Expense__c(
        Property__c = property.Id,
        Category__c = 'Materials',
        Amount__c = 50,
        Expense_Date__c = Date.today()
      ),
      new Expense__c(
        Property__c = property.Id,
        Category__c = 'Labor',
        Amount__c = 200,
        Expense_Date__c = Date.today()
      )
    };

    Test.startTest();
    List<AggregateResult> totals = ExpenseSelector.getTotalsByCategoryForProperty(
      property.Id
    );
    Test.stopTest();

    Map<String, Decimal> totalsByCategory = new Map<String, Decimal>();
    for (AggregateResult ar : totals) {
      totalsByCategory.put(
        (String) ar.get('Category__c'),
        (Decimal) ar.get('total')
      );
    }

    System.assertEquals(150, totalsByCategory.get('Materials'));
    System.assertEquals(200, totalsByCategory.get('Labor'));
  }

  @isTest
  static void getTotalsByCategoryForProperty_ignoraOtrasPropiedades() {
    Property__c property1 = TestDataFactory.createProperty();
    Property__c property2 = TestDataFactory.createProperty();
    insert new List<Property__c>{ property1, property2 };

    insert new Expense__c(
      Property__c = property1.Id,
      Category__c = 'Materials',
      Amount__c = 100,
      Expense_Date__c = Date.today()
    );
    insert new Expense__c(
      Property__c = property2.Id,
      Category__c = 'Materials',
      Amount__c = 999,
      Expense_Date__c = Date.today()
    );

    Test.startTest();
    List<AggregateResult> totals = ExpenseSelector.getTotalsByCategoryForProperty(
      property1.Id
    );
    Test.stopTest();

    System.assertEquals(1, totals.size());
    System.assertEquals(100, (Decimal) totals[0].get('total'));
  }
}
