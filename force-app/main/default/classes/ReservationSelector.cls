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
    public static List<Reservation__c> getByRoomIdsAndStatuses(Set<Id> roomIds, Set<String> statuses) {
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
    public static List<Reservation__c> getByRoomIdsAndStatuses(Set<Id> roomIds, Set<String> statuses, Set<Id> excludeIds) {
        if (roomIds == null || roomIds.isEmpty() || statuses == null || statuses.isEmpty()) {
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
            WHERE Room__c IN :roomIds AND Status__c IN :statuses AND Id NOT IN :excludeIds
        ];
    }
}
