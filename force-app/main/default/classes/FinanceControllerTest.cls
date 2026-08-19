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

  /**
   * Usuario sin el Permission Set Property_Manager: no tiene permisos de objeto
   * sobre Property__c ni Expense__c, así que las SOQL en USER_MODE de los
   * selectores tienen que fallar. Es la prueba de que la enforcement de FLS
   * existe de verdad y no es solo una cláusula decorativa en la query.
   */
  private static User createUserWithoutAccess() {
    Profile standardProfile = [
      SELECT Id
      FROM Profile
      WHERE Name = 'Standard User'
      LIMIT 1
    ];
    User restricted = new User(
      FirstName = 'Sin',
      LastName = 'Permisos',
      Email = 'sinpermisos@adminspaces.test.com',
      Username = 'sinpermisos' +
        DateTime.now().getTime() +
        '@adminspaces.test.com',
      Alias = 'noperm',
      TimeZoneSidKey = 'America/Sao_Paulo',
      LocaleSidKey = 'en_US',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US',
      ProfileId = standardProfile.Id
    );
    insert restricted;
    return restricted;
  }

  @isTest
  static void getExpensesByCategory_userWithoutAccess_throwsFriendlyError() {
    Property__c property = [SELECT Id FROM Property__c LIMIT 1];
    User restricted = createUserWithoutAccess();

    String message;
    System.runAs(restricted) {
      Test.startTest();
      try {
        FinanceController.getExpensesByCategory(property.Id);
        System.assert(false, 'Se esperaba un error de acceso a Expense__c');
      } catch (AuraHandledException e) {
        message = e.getMessage();
      }
      Test.stopTest();
    }

    System.assertEquals(
      System.Label.Finance_Expenses_Load_Error,
      message,
      'El QueryException de USER_MODE debe traducirse al mensaje del Custom Label'
    );
  }

  @isTest
  static void getProperties_userWithoutAccess_throwsFriendlyError() {
    User restricted = createUserWithoutAccess();

    String message;
    System.runAs(restricted) {
      Test.startTest();
      try {
        FinanceController.getProperties();
        System.assert(false, 'Se esperaba un error de acceso a Property__c');
      } catch (AuraHandledException e) {
        message = e.getMessage();
      }
      Test.stopTest();
    }

    System.assertEquals(
      System.Label.Finance_Properties_Load_Error,
      message,
      'El QueryException de USER_MODE debe traducirse al mensaje del Custom Label'
    );
  }
}
