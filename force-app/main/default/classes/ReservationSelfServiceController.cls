/**
 * Apex controller behind the authenticated guest self-service portal (Historia 4.2).
 * Runs `without sharing` on purpose: Reservation__c is ControlledByParent all the
 * way up to the Private Property__c, so no declarative Sharing Rule/Set can scope
 * visibility to "just this guest's own reservation" (see docs/property-manager-roadmap.md).
 * The WHERE Guest__c = :runningUserContactId filter below is the only access
 * control in effect — it must never be replaced by a client-supplied Id.
 */
public without sharing class ReservationSelfServiceController {
  @AuraEnabled(cacheable=true)
  public static List<Reservation__c> getMyReservations() {
    Id guestContactId = getContactId();
    return ReservationSelector.getByGuestContactId(guestContactId);
  }

  /**
   * Lets the authenticated guest change the dates of their own reservation
   * (Historia 4.3). Ownership is re-verified server-side via
   * ReservationSelector.getByGuestAndReservationId — the reservationId argument
   * is client-supplied and must never be trusted on its own. CRUD/FLS is not
   * automatically enforced on plain DML in Apex, so Security.stripInaccessible
   * is used to make the Permission Set-based edit permission actually load-bearing
   * (without it, this method would silently succeed regardless of the running
   * user's object/field permissions). The overlap rule (Historia 2.1) is not
   * duplicated here — it's enforced by the same Reservation trigger that runs
   * on any update, guest-initiated or not.
   * @param reservationId Id of the reservation to update
   * @param newCheckin New Check_In_Date__c, or null to leave it unchanged
   * @param newCheckout New Check_Out_Date__c, or null to leave it unchanged
   */
  @AuraEnabled
  public static void updateMyReservationDates(
    Id reservationId,
    Date newCheckin,
    Date newCheckout
  ) {
    Id guestContactId = getContactId();
    List<Reservation__c> lstReservation = ReservationSelector.getByGuestAndReservationId(
      guestContactId,
      reservationId
    );
    if (lstReservation.isEmpty()) {
      throw new AuraHandledException('No se encontró la reserva');
    }

    Reservation__c toUpdate = new Reservation__c(Id = lstReservation[0].Id);

    if (newCheckin != null) {
      toUpdate.Check_In_Date__c = newCheckin;
    }
    if (newCheckout != null) {
      toUpdate.Check_Out_Date__c = newCheckout;
    }

    SObjectAccessDecision decision = Security.stripInaccessible(
      AccessType.UPDATABLE,
      new List<Reservation__c>{ toUpdate }
    );

    if (!decision.getRemovedFields().isEmpty()) {
      throw new AuraHandledException(
        'No tenés permiso para modificar esta reserva.'
      );
    }

    try {
      update decision.getRecords();
    } catch (DmlException e) {
      throw new AuraHandledException(e.getDmlMessage(0));
    }
  }

  private static Id getContactId() {
    return [
      SELECT ContactId
      FROM User
      WHERE Id = :UserInfo.getUserId()
    ]
    .ContactId;
  }
}
