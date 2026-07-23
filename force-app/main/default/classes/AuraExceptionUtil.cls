/**
 * AuraHandledException.getMessage() siempre devuelve "Script-thrown exception"
 * salvo que se llame explícitamente a .setMessage(...) después de construirla
 * (gotcha confirmado empíricamente, ver docs/property-manager-roadmap.md).
 * Este helper centraliza ese fix para no repetirlo en cada controller.
 */
public inherited sharing class AuraExceptionUtil {
  public static AuraHandledException create(String message) {
    AuraHandledException ex = new AuraHandledException(message);
    ex.setMessage(message);
    return ex;
  }
}
