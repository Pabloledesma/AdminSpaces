@isTest
private class ReservationSelfServiceControllerTest {
  @TestSetup
  static void makeData() {
    Property__c property = TestDataFactory.createProperty();
    insert property;

    Room__c room = TestDataFactory.createRoom(property.Id);
    insert room;

    Account guestAccount = new Account(Name = 'Test Guest Account');
    insert guestAccount;

    Contact guestContact = new Contact(
      LastName = 'GuestOne',
      AccountId = guestAccount.Id,
      Email = 'guestone@adminspaces.test.com'
    );
    Contact otherGuestContact = new Contact(
      LastName = 'GuestTwo',
      AccountId = guestAccount.Id,
      Email = 'guesttwo@adminspaces.test.com'
    );
    insert new List<Contact>{ guestContact, otherGuestContact };

    Reservation__c myReservation = TestDataFactory.buildReservation(
      room.Id,
      Date.today().addDays(10),
      Date.today().addDays(12)
    );
    myReservation.Guest__c = guestContact.Id;

    Reservation__c otherGuestReservation = TestDataFactory.buildReservation(
      room.Id,
      Date.today().addDays(20),
      Date.today().addDays(22)
    );
    otherGuestReservation.Guest__c = otherGuestContact.Id;

    insert new List<Reservation__c>{ myReservation, otherGuestReservation };

    Profile guestProfile = [
      SELECT Id
      FROM Profile
      WHERE Name = 'AdminSpaces Guest Community'
    ];
    User guestUser = new User(
      FirstName = 'Guest',
      LastName = 'One',
      Email = 'guestone@adminspaces.test.com',
      Username = 'guestone' +
        DateTime.now().getTime() +
        '@adminspaces.test.com',
      Alias = 'gst1',
      TimeZoneSidKey = 'America/Sao_Paulo',
      LocaleSidKey = 'en_US',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US',
      ProfileId = guestProfile.Id,
      ContactId = guestContact.Id
    );
    insert guestUser;
  }

  @isTest
  static void getMyReservations_returnsOnlyRunningGuestsOwnReservation() {
    Reservation__c expected = [
      SELECT Id
      FROM Reservation__c
      WHERE Guest__c IN (SELECT Id FROM Contact WHERE LastName = 'GuestOne')
    ];
    User guestUser = [
      SELECT Id
      FROM User
      WHERE ContactId IN (SELECT Id FROM Contact WHERE LastName = 'GuestOne')
    ];

    List<Reservation__c> results;
    System.runAs(guestUser) {
      Test.startTest();
      results = ReservationSelfServiceController.getMyReservations();
      Test.stopTest();
    }

    System.assertEquals(
      1,
      results.size(),
      'Guest should see exactly their own reservation'
    );
    System.assertEquals(
      expected.Id,
      results[0].Id,
      'Guest should not see another guest\'s reservation'
    );
  }

  @isTest
  static void getMyReservations_returnsEmptyForUserWithoutContact() {
    List<Reservation__c> results = ReservationSelfServiceController.getMyReservations();

    System.assertEquals(
      0,
      results.size(),
      'Internal user with no Contact should see no reservations'
    );
  }
}
