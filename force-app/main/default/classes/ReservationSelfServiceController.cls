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
    Id guestContactId = [
      SELECT ContactId
      FROM User
      WHERE Id = :UserInfo.getUserId()
    ]
    .ContactId;
    return ReservationSelector.getByGuestContactId(guestContactId);
  }
}
