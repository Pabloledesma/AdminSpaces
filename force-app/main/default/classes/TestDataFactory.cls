public with sharing class TestDataFactory {
  public static Property__c createProperty() {
    return new Property__c(Is_Demo__c = true);
  }

  public static Room__c createRoom(Id propertyId) {
    return new Room__c(
      Property__c = propertyId,
      Room_Type__c = 'Single',
      Is_Demo__c = true
    );
  }

  public static Room__c createRoomWithRate(Id propertyId, Decimal rate) {
    return new Room__c(
      Property__c = propertyId,
      Room_Type__c = 'Single',
      Is_Demo__c = true,
      Nightly_Rate__c = rate
    );
  }

  public static Reservation__c buildReservation(
    Id roomId,
    Date checkIn,
    Date checkOut
  ) {
    return buildReservation(roomId, checkIn, checkOut, 'Confirmed');
  }

  public static Reservation__c buildReservation(
    Id roomId,
    Date checkIn,
    Date checkOut,
    String status
  ) {
    return new Reservation__c(
      Room__c = roomId,
      Check_In_Date__c = checkIn,
      Check_Out_Date__c = checkOut,
      Status__c = status,
      Is_Demo__c = true
    );
  }

  public static Budget__c buildBudget(
    Id propertyId,
    Date startDate,
    Date endDate,
    Decimal projectedIncome
  ) {
    return new Budget__c(
      Property__c = propertyId,
      Start_Date__c = startDate,
      End_Date__c = endDate,
      Projected_Income__c = projectedIncome,
      Is_Demo__c = true
    );
  }

  /**
   * Usuario sin ningún Permission Set del proyecto: sirve para probar, con
   * System.runAs, que las queries en USER_MODE efectivamente bloquean a quien
   * no tiene permisos de objeto sobre los custom objects.
   */
  public static User createUserWithoutAccess() {
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
        Math.round(Math.random() * 10000) +
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
}
