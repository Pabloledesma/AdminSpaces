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
    myReservation.Status__c = 'Pending';

    Reservation__c myCheckedInReservation = TestDataFactory.buildReservation(
      room.Id,
      Date.today().addDays(30),
      Date.today().addDays(32)
    );
    myCheckedInReservation.Guest__c = guestContact.Id;
    myCheckedInReservation.Status__c = 'Checked In';

    Reservation__c otherPendingReservation = TestDataFactory.buildReservation(
      room.Id,
      Date.today().addDays(13),
      Date.today().addDays(15)
    );
    otherPendingReservation.Guest__c = otherGuestContact.Id;
    otherPendingReservation.Status__c = 'Pending';

    Reservation__c otherGuestReservation = TestDataFactory.buildReservation(
      room.Id,
      Date.today().addDays(20),
      Date.today().addDays(22)
    );
    otherGuestReservation.Guest__c = otherGuestContact.Id;
    otherGuestReservation.Status__c = 'Checked In';

    Reservation__c cancelledReservation = TestDataFactory.buildReservation(
      room.Id,
      Date.today().addDays(22),
      Date.today().addDays(24)
    );
    cancelledReservation.Guest__c = otherGuestContact.Id;
    cancelledReservation.Status__c = 'Cancelled';

    insert new List<Reservation__c>{
      myReservation,
      otherGuestReservation,
      cancelledReservation,
      otherPendingReservation,
      myCheckedInReservation
    };

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

  private static void assignPermissionSet(Id userId, String permissionSetName) {
    PermissionSet huespedPermSet = [
      SELECT Id
      FROM PermissionSet
      WHERE Name = :permissionSetName
    ];
    insert new PermissionSetAssignment(
      AssigneeId = userId,
      PermissionSetId = huespedPermSet.Id
    );
  }

  @IsTest
  static void cancelMyReservation_cancelsOwnPendingReservation() {
    User guestUser = [
      SELECT Id
      FROM User
      WHERE
        ContactId IN (
          SELECT Id
          FROM Contact
          WHERE LastName = 'GuestOne'
        )
    ];

    assignPermissionSet(guestUser.Id, 'Huesped');

    List<Reservation__c> results;
    Reservation__c pending;
    System.runAs(guestUser) {
      Test.startTest();
      results = ReservationSelfServiceController.getMyReservations();
      for (Reservation__c reservation : results) {
        if (reservation.Status__c == 'Pending') {
          pending = reservation;
        }
      }

      ReservationSelfServiceController.cancelMyReservation(pending.Id);
      Test.stopTest();
    }

    List<Reservation__c> cancelledReservation = [
      SELECT Id
      FROM Reservation__c
      WHERE
        Guest__c IN (SELECT Id FROM Contact WHERE LastName = 'GuestOne')
        AND Status__c = 'Cancelled'
    ];

    System.assertEquals(
      1,
      cancelledReservation.size(),
      'El usuario puede cancelar su reserva'
    );
  }

  @IsTest
  static void cancelMyReservation_blocksCancelingAnotherGuestsReservation() {
    User guestUser = [
      SELECT Id
      FROM User
      WHERE ContactId IN (SELECT Id FROM Contact WHERE LastName = 'GuestOne')
    ];
    assignPermissionSet(guestUser.Id, 'Huesped');

    Reservation__c otherGuestsPendingReservation = [
      SELECT Id
      FROM Reservation__c
      WHERE
        Guest__c IN (SELECT Id FROM Contact WHERE LastName = 'GuestTwo')
        AND Status__c = 'Pending'
    ];

    String message;
    Test.startTest();
    System.runAs(guestUser) {
      try {
        ReservationSelfServiceController.cancelMyReservation(
          otherGuestsPendingReservation.Id
        );
        System.assert(false, 'Debería haber tirado una excepción');
      } catch (AuraHandledException e) {
        System.assertEquals('No se encontró la reserva', e.getMessage());
      }
    }
    Test.stopTest();

    Reservation__c stillPending = [
      SELECT Status__c
      FROM Reservation__c
      WHERE Id = :otherGuestsPendingReservation.Id
    ];
    System.assertEquals(
      'Pending',
      stillPending.Status__c,
      'La reserva de otro huésped no debería cambiar de estado'
    );
  }

  @IsTest
  static void cancelMyReservation_blocksCancelingFromNonCancellableStatus() {
    User guestUser = [
      SELECT Id
      FROM User
      WHERE ContactId IN (SELECT Id FROM Contact WHERE LastName = 'GuestOne')
    ];
    assignPermissionSet(guestUser.Id, 'Huesped');

    Reservation__c checkedIn = [
      SELECT Id
      FROM Reservation__c
      WHERE
        Guest__c IN (SELECT Id FROM Contact WHERE LastName = 'GuestOne')
        AND Status__c = 'Checked In'
    ];

    Test.startTest();
    System.runAs(guestUser) {
      try {
        ReservationSelfServiceController.cancelMyReservation(checkedIn.Id);
        System.assert(false, 'Debería haber tirado una excepción');
      } catch (AuraHandledException e) {
        System.assertEquals(
          'Esta reserva ya no se puede cancelar.',
          e.getMessage()
        );
      }
    }
    Test.stopTest();
  }

  @IsTest
  static void actualiza_las_fechas_de_la_reserva() {
    User guestUser = [
      SELECT Id
      FROM User
      WHERE
        ContactId IN (
          SELECT Id
          FROM Contact
          WHERE LastName = 'GuestOne'
        )
    ];

    assignPermissionSet(guestUser.Id, 'Huesped');

    Contact guestOne = [
      SELECT Id, Name
      FROM contact
      WHERE Name LIKE 'GuestOne%'
    ];

    List<Reservation__c> reservation = ReservationSelector.getByGuestContactId(
      guestOne.Id
    );

    Test.startTest();
    System.runAs(guestUser) {
      ReservationSelfServiceController.updateMyReservationDates(
        reservation[0].Id,
        Date.today().addDays(11),
        Date.today().addDays(13)
      );
    }
    Test.stopTest();

    List<Reservation__c> reservationUpdated = ReservationSelector.getByGuestContactId(
      guestOne.Id
    );
    System.assertNotEquals(
      reservation[0].Check_In_Date__c,
      reservationUpdated[0].Check_In_Date__c,
      'La fecha de checkin no fue actualizada'
    );
    System.assertNotEquals(
      reservation[0].Check_Out_Date__c,
      reservationUpdated[0].Check_Out_Date__c,
      'La fecha de checkout no fue actualizada'
    );
  }

  @isTest
  static void getMyReservations_returnsOnlyRunningGuestsOwnReservation() {
    List<Reservation__c> expected = [
      SELECT Id
      FROM Reservation__c
      WHERE Guest__c IN (SELECT Id FROM Contact WHERE LastName = 'GuestOne')
    ];
    User guestUser = [
      SELECT Id
      FROM User
      WHERE
        ContactId IN (
          SELECT Id
          FROM Contact
          WHERE LastName = 'GuestOne'
        )
    ];

    List<Reservation__c> results;
    System.runAs(guestUser) {
      Test.startTest();
      results = ReservationSelfServiceController.getMyReservations();
      Test.stopTest();
    }

    System.assertEquals(
      2,
      results.size(),
      'Guest should see exactly their own reservation'
    );
    System.assertEquals(
      true,
      !expected.isEmpty(),
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
