@isTest
private class AuraExceptionUtilTest {
  @isTest
  static void create_preservesTheRealMessageInsteadOfTheGenericOne() {
    AuraHandledException ex = AuraExceptionUtil.create('mensaje de prueba');

    System.assertEquals(
      'mensaje de prueba',
      ex.getMessage(),
      'getMessage() debería devolver el mensaje real, no "Script-thrown exception"'
    );
  }

  @isTest
  static void create_isThrowableAndCatchableWithTheSameMessage() {
    try {
      throw AuraExceptionUtil.create('otro mensaje de prueba');
    } catch (AuraHandledException e) {
      System.assertEquals('otro mensaje de prueba', e.getMessage());
    }
  }
}
