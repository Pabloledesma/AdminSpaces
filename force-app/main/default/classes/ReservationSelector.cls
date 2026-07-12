/**
 * Selector class for Reservation__c queries.
 * Encapsulates all SOQL for Reservation__c records so callers never write
 * ad-hoc queries against this object.
 */
public inherited sharing class ReservationSelector {
  /**
   * Selects reservations for the given rooms whose Status__c is one of the
   * provided values. Bulk-safe: callers should pass every Room__c Id and
   * status they need resolved in a single call.
   * @param roomIds Ids of the Room__c records to filter by
   * @param statuses Status__c values to include
   * @return List of matching Reservation__c records with Room__c and date fields
   * @example
   * List<Reservation__c> active = ReservationSelector.getByRoomIdsAndStatuses(
   *     roomIds, ReservationOverlapValidator.BLOCKING_STATUSES
   * );
   */
  public static List<Reservation__c> getByRoomIdsAndStatuses(
    Set<Id> roomIds,
    Set<String> statuses
  ) {
    return getByRoomIdsAndStatuses(roomIds, statuses, null);
  }

  /**
   * Same as getByRoomIdsAndStatuses(Set<Id>, Set<String>), but excludes the
   * given Ids from the results. Needed on update: a reservation being edited
   * is still visible in the database (with its pre-update values) until the
   * DML commits, so without this exclusion a record would be compared for
   * overlap against its own previous state.
   * @param roomIds Ids of the Room__c records to filter by
   * @param statuses Status__c values to include
   * @param excludeIds Reservation__c Ids to leave out of the results (may be null)
   * @return List of matching Reservation__c records with Room__c and date fields
   */
  public static List<Reservation__c> getByRoomIdsAndStatuses(
    Set<Id> roomIds,
    Set<String> statuses,
    Set<Id> excludeIds
  ) {
    if (
      roomIds == null ||
      roomIds.isEmpty() ||
      statuses == null ||
      statuses.isEmpty()
    ) {
      return new List<Reservation__c>();
    }

    if (excludeIds == null || excludeIds.isEmpty()) {
      return [
        SELECT Id, Room__c, Check_In_Date__c, Check_Out_Date__c
        FROM Reservation__c
        WHERE Room__c IN :roomIds AND Status__c IN :statuses
      ];
    }

    return [
      SELECT Id, Room__c, Check_In_Date__c, Check_Out_Date__c
      FROM Reservation__c
      WHERE
        Room__c IN :roomIds
        AND Status__c IN :statuses
        AND Id NOT IN :excludeIds
    ];
  }

  /**
   * Selects every reservation belonging to a single guest Contact.
   * Used by the authenticated guest self-service portal (Historia 4.2), where
   * this Contact Id filter is the only thing standing in for row-level
   * sharing: Reservation__c is ControlledByParent up to Property__c, so no
   * declarative Sharing Set/Rule can scope access to "just this guest's own
   * record" without also exposing every other reservation on the same
   * property. Callers must run this from a `without sharing` context and
   * must always pass the running user's own Contact Id, never one supplied
   * by the client.
   * @param guestContactId Contact Id of the running user
   * @return List of matching Reservation__c records with Room__c and date fields
   */
  public static List<Reservation__c> getByGuestContactId(Id guestContactId) {
    if (guestContactId == null) {
      return new List<Reservation__c>();
    }

    return [
      SELECT
        Id,
        Status__c,
        Check_In_Date__c,
        Check_Out_Date__c,
        Total_Amount__c,
        Room__r.Name,
        Room__r.Room_Type__c
      FROM Reservation__c
      WHERE Guest__c = :guestContactId
      WITH SECURITY_ENFORCED
      ORDER BY Check_In_Date__c DESC
    ];
  }

  /**
   * Selects a single reservation only if it belongs to the given guest Contact.
   * Used to re-verify ownership before an authenticated guest edits their own
   * reservation (Historia 4.3): the reservationId alone is client-supplied and
   * must never be trusted on its own — pairing it with guestContactId in the
   * WHERE clause is what stops a guest from editing another guest's record.
   * Returns an empty list both when the reservation doesn't exist and when it
   * exists but belongs to someone else, so callers can't distinguish the two
   * cases from the result alone.
   * @param guestContactId Contact Id of the running user
   * @param reservationId Id of the reservation to look up
   * @return Single-element list with the reservation if it exists and belongs
   *         to guestContactId, otherwise an empty list
   */
  public static List<Reservation__c> getByGuestAndReservationId(
    Id guestContactId,
    Id reservationId
  ) {
    if (guestContactId == null || reservationId == null) {
      return new List<Reservation__c>();
    }

    return [
      SELECT Id, Check_In_Date__c, Check_Out_Date__c
      FROM Reservation__c
      WHERE Id = :reservationId AND Guest__c = :guestContactId
      WITH SECURITY_ENFORCED
      ORDER BY Check_In_Date__c DESC
    ];
  }
}
