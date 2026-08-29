@isTest
private class PropertyLookupAgentActionTest {
  @isTest
  static void search_encuentraPorDireccion() {
    Property__c property = TestDataFactory.createProperty(
      'Santa Fe 1200',
      'Buenos Aires'
    );
    insert property;

    PropertyLookupAgentAction.Request request = new PropertyLookupAgentAction.Request();
    request.searchTerm = 'Santa Fe';

    Test.startTest();
    List<PropertyLookupAgentAction.Response> responses = PropertyLookupAgentAction.search(
      new List<PropertyLookupAgentAction.Request>{ request }
    );
    Test.stopTest();

    System.assertEquals(1, responses.size());
    System.assertEquals(
      1,
      responses[0].candidates.size(),
      'Debería encontrar la propiedad por coincidencia parcial de dirección'
    );
    System.assertEquals(property.Id, responses[0].candidates[0].propertyId);
    System.assertEquals(
      null,
      responses[0].message,
      'Con una sola coincidencia no hace falta mensaje'
    );
  }

  @isTest
  static void search_encuentraPorCiudad() {
    Property__c property = TestDataFactory.createProperty(
      'Av. Rivadavia 500',
      'Palermo'
    );
    insert property;

    PropertyLookupAgentAction.Request request = new PropertyLookupAgentAction.Request();
    request.searchTerm = 'palermo';

    Test.startTest();
    List<PropertyLookupAgentAction.Response> responses = PropertyLookupAgentAction.search(
      new List<PropertyLookupAgentAction.Request>{ request }
    );
    Test.stopTest();

    System.assertEquals(
      1,
      responses[0].candidates.size(),
      'Búsqueda case-insensitive contra City__c'
    );
  }

  @isTest
  static void search_sinCoincidencias_devuelveListaVaciaConMensaje() {
    insert TestDataFactory.createProperty('Corrientes 800', 'Rosario');

    PropertyLookupAgentAction.Request request = new PropertyLookupAgentAction.Request();
    request.searchTerm = 'Mendoza';

    Test.startTest();
    List<PropertyLookupAgentAction.Response> responses = PropertyLookupAgentAction.search(
      new List<PropertyLookupAgentAction.Request>{ request }
    );
    Test.stopTest();

    System.assertEquals(0, responses[0].candidates.size());
    System.assertEquals(
      System.Label.Agent_Property_Not_Found,
      responses[0].message,
      'Sin coincidencias tiene que explicar, no tirar excepción'
    );
  }

  @isTest
  static void search_variasCoincidencias_devuelveTodas() {
    insert new List<Property__c>{
      TestDataFactory.createProperty('Corrientes 100', 'Buenos Aires'),
      TestDataFactory.createProperty('Corrientes 900', 'Buenos Aires'),
      TestDataFactory.createProperty('Santa Fe 1200', 'Buenos Aires')
    };

    PropertyLookupAgentAction.Request request = new PropertyLookupAgentAction.Request();
    request.searchTerm = 'Corrientes';

    Test.startTest();
    List<PropertyLookupAgentAction.Response> responses = PropertyLookupAgentAction.search(
      new List<PropertyLookupAgentAction.Request>{ request }
    );
    Test.stopTest();

    System.assertEquals(
      2,
      responses[0].candidates.size(),
      'Las dos direcciones de Corrientes tienen que volver, ninguna se descarta'
    );
  }

  @isTest
  static void search_terminoVacio_noMatcheaTodo() {
    // Blindaje del caso peligroso: si el guard de isNotBlank no estuviera,
    // ''.contains('') es true para cualquier registro y esto devolvería todas
    // las propiedades del org como si hubieran coincidido con la búsqueda.
    insert TestDataFactory.createProperty('Corrientes 100', 'Buenos Aires');

    PropertyLookupAgentAction.Request request = new PropertyLookupAgentAction.Request();
    request.searchTerm = '   ';

    Test.startTest();
    List<PropertyLookupAgentAction.Response> responses = PropertyLookupAgentAction.search(
      new List<PropertyLookupAgentAction.Request>{ request }
    );
    Test.stopTest();

    System.assertEquals(
      0,
      responses[0].candidates.size(),
      'Un término en blanco no puede matchear con todas las propiedades'
    );
  }

  @isTest
  static void search_bulkConVariosRequests_respondeEnElMismoOrden() {
    Property__c encontrable = TestDataFactory.createProperty(
      'Lavalle 300',
      'Córdoba'
    );
    insert encontrable;

    PropertyLookupAgentAction.Request requestQueEncuentra = new PropertyLookupAgentAction.Request();
    requestQueEncuentra.searchTerm = 'Lavalle';

    PropertyLookupAgentAction.Request requestQueNoEncuentra = new PropertyLookupAgentAction.Request();
    requestQueNoEncuentra.searchTerm = 'Inexistente';

    Test.startTest();
    List<PropertyLookupAgentAction.Response> responses = PropertyLookupAgentAction.search(
      new List<PropertyLookupAgentAction.Request>{
        requestQueEncuentra,
        requestQueNoEncuentra
      }
    );
    Test.stopTest();

    System.assertEquals(
      2,
      responses.size(),
      'Una response por cada request, en el mismo orden'
    );
    System.assertEquals(
      1,
      responses[0].candidates.size(),
      'La primera response corresponde al request que sí matchea'
    );
    System.assertEquals(
      0,
      responses[1].candidates.size(),
      'La segunda corresponde al que no matchea, no se mezclan entre sí'
    );
    System.assertEquals(
      System.Label.Agent_Property_Not_Found,
      responses[1].message
    );
  }
}
