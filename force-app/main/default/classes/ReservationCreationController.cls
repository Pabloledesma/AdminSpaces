public with sharing class ReservationCreationController {
  @AuraEnabled
  public static Id createReservation(
    Id roomId,
    Id guestContactId,
    Date checkIn,
    Date checkOut
  ) {
    Reservation__c reservation = new Reservation__c(
      Room__c = roomId,
      Guest__c = guestContactId,
      Check_In_Date__c = checkIn,
      Check_Out_Date__c = checkOut,
      Status__c = 'Pending'
    );

    try {
      insert reservation;
    } catch (DmlException e) {
      throw AuraExceptionUtil.create(e.getDmlMessage(0));
    }

    return reservation.Id;
  }
}
