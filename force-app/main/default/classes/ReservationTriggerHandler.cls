public with sharing class ReservationTriggerHandler {

    private static final String OVERLAP_ERROR_MESSAGE = 'Las fechas se solapan con otra reserva existente para esta habitación.';

    public void OnBeforeInsert(List<Reservation__c> newReservations)
    {
        Set<Id> roomIds = collectRoomIds(newReservations);
        List<Reservation__c> existingReservations = ReservationSelector.getByRoomIdsAndStatuses(
            roomIds,
            ReservationOverlapValidator.BLOCKING_STATUSES
        );

        for (Reservation__c overlapping : ReservationOverlapValidator.findOverlapping(newReservations, existingReservations)) {
            overlapping.addError(OVERLAP_ERROR_MESSAGE);
        }
    }

    private Set<Id> collectRoomIds(List<Reservation__c> reservations) {
        Set<Id> roomIds = new Set<Id>();
        for (Reservation__c reservation : reservations) {
            if (reservation.Room__c != null) {
                roomIds.add(reservation.Room__c);
            }
        }
        return roomIds;
    }
}
