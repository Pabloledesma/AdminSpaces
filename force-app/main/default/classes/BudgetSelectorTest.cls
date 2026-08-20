@isTest
private class BudgetSelectorTest {
  @isTest
  static void getByPropertyId_devuelveLosDeLaPropiedadOrdenadosPorFecha() {
    Property__c property = TestDataFactory.createProperty();
    Property__c otra = TestDataFactory.createProperty();
    insert new List<Property__c>{ property, otra };

    Date hoy = Date.today();
    insert new List<Budget__c>{
      TestDataFactory.buildBudget(
        property.Id,
        hoy.addMonths(-6),
        hoy.addMonths(-3),
        1000
      ),
      TestDataFactory.buildBudget(property.Id, hoy, hoy.addMonths(3), 2000),
      TestDataFactory.buildBudget(otra.Id, hoy, hoy.addMonths(3), 9999)
    };

    Test.startTest();
    List<Budget__c> resultado = BudgetSelector.getByPropertyId(property.Id);
    Test.stopTest();

    System.assertEquals(2, resultado.size(), 'Solo los de esta propiedad');
    System.assertEquals(
      2000,
      resultado[0].Projected_Income__c,
      'El más reciente primero (ORDER BY Start_Date__c DESC)'
    );
  }

  @isTest
  static void getByPropertyId_sinPropiedad_devuelveListaVacia() {
    Test.startTest();
    List<Budget__c> resultado = BudgetSelector.getByPropertyId(null);
    Test.stopTest();

    System.assertEquals(
      0,
      resultado.size(),
      'Sin propiedad no hay query ni excepción'
    );
  }
}
