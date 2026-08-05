@isTest
private class FinanceControllerTest {
  @TestSetup
  static void makeData() {
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
        Category__c = 'Labor',
        Amount__c = 200,
        Expense_Date__c = Date.today()
      )
    };
  }

  @isTest
  static void getProperties_returnsAllProperties() {
    Test.startTest();
    List<Property__c> properties = FinanceController.getProperties();
    Test.stopTest();

    System.assertEquals(1, properties.size());
  }

  @isTest
  static void getExpensesByCategory_returnsTotalsPerCategory() {
    Property__c property = [SELECT Id FROM Property__c LIMIT 1];

    Test.startTest();
    List<FinanceController.CategoryTotal> totals = FinanceController.getExpensesByCategory(
      property.Id
    );
    Test.stopTest();

    Map<String, Decimal> totalsByCategory = new Map<String, Decimal>();
    for (FinanceController.CategoryTotal ct : totals) {
      totalsByCategory.put(ct.category, ct.total);
    }
    System.assertEquals(
      100,
      totalsByCategory.get('Materials'),
      'Materials total should be 100'
    );
    System.assertEquals(
      200,
      totalsByCategory.get('Labor'),
      'Labor total should be 200'
    );
  }

  @isTest
  static void getExpensesByCategory_noExpenses_returnsEmptyList() {
    Property__c newProperty = TestDataFactory.createProperty();
    insert newProperty;

    Test.startTest();
    List<FinanceController.CategoryTotal> totals = FinanceController.getExpensesByCategory(
      newProperty.Id
    );
    Test.stopTest();

    System.assertEquals(
      0,
      totals.size(),
      'Should return an empty list when there are no expenses'
    );
  }

  @isTest
  static void getExpensesByCategory_nullPropertyId_returnsEmptyList() {
    Test.startTest();
    List<FinanceController.CategoryTotal> totals = FinanceController.getExpensesByCategory(
      null
    );
    Test.stopTest();

    System.assertEquals(
      0,
      totals.size(),
      'Should return an empty list when propertyId is null'
    );
  }
}
