@isTest
private class PropertySelectorTest {
  @isTest
  static void getAllProperties_returnsAllPropertiesOrderedByName() {
    Property__c property1 = TestDataFactory.createProperty();
    Property__c property2 = TestDataFactory.createProperty();
    insert new List<Property__c>{ property1, property2 };

    Test.startTest();
    List<Property__c> properties = PropertySelector.getAllProperties();
    Test.stopTest();

    System.assertEquals(2, properties.size());
    System.assertEquals(
      property1.Id,
      properties[0].Id,
      'Debería venir ordenado por Name (AutoNumber, orden de inserción)'
    );
    System.assertEquals(property2.Id, properties[1].Id);
  }
}
