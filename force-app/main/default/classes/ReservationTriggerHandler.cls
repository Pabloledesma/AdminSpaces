public with sharing class ReservationTriggerHandler {

    private static final String OVERLAP_ERROR_MESSAGE = 'Las fechas se solapan con otra reserva existente para esta habitación.';

    public void OnBeforeInsert(List<Reservation__c> newReservations)
    {
        Set<Id> roomIds = collectRoomIds(newReservations);
        Map<Id, Room__c> roomsById = new Map<Id, Room__c>(RoomSelector.getRoomsById(roomIds));
        List<Reservation__c> existingReservations = ReservationSelector.getByRoomIdsAndStatuses(
            roomIds,
            ReservationOverlapValidator.BLOCKING_STATUSES
        );

        Set<Reservation__c> overlapping = validateNoOverlap(newReservations, existingReservations);

        calculatePricing(newReservations, overlapping, roomsById);
    }

    public void OnBeforeUpdate(List<Reservation__c> newReservations, Map<Id, Reservation__c> oldMap)
    {
        List<Reservation__c> changedReservations = new List<Reservation__c>();
        for (Reservation__c reservation : newReservations) {
            if (hasRelevantChange(reservation, oldMap.get(reservation.Id))) {
                changedReservations.add(reservation);
            }
        }

        if (changedReservations.isEmpty()) {
            return;
        }

        Set<Id> roomIds = collectRoomIds(changedReservations);
        Map<Id, Room__c> roomsById = new Map<Id, Room__c>(RoomSelector.getRoomsById(roomIds));
        Set<Id> editingIds = new Map<Id, Reservation__c>(changedReservations).keySet();
        List<Reservation__c> existingReservations = ReservationSelector.getByRoomIdsAndStatuses(
            roomIds,
            ReservationOverlapValidator.BLOCKING_STATUSES,
            editingIds
        );

        Set<Reservation__c> overlapping = validateNoOverlap(changedReservations, existingReservations);

        calculatePricing(changedReservations, overlapping, roomsById);
    }

    /**
     * Runs the overlap rule once for the given candidates, adds the validation
     * error to each conflicting record, and returns them so callers can skip
     * further processing (e.g. pricing) on invalid records.
     */
    private Set<Reservation__c> validateNoOverlap(List<Reservation__c> candidates, List<Reservation__c> existingReservations) {
        Set<Reservation__c> overlapping = new Set<Reservation__c>();
        for (Reservation__c reservation : ReservationOverlapValidator.findOverlapping(candidates, existingReservations)) {
            overlapping.add(reservation);
            reservation.addError(OVERLAP_ERROR_MESSAGE);
        }
        return overlapping;
    }

    private void calculatePricing(List<Reservation__c> reservations, Set<Reservation__c> overlapping, Map<Id, Room__c> roomsById) {
        for (Reservation__c reservation : reservations) {
            if (overlapping.contains(reservation)) {
                continue;
            }
            ReservationPricingCalculator.calculate(reservation, roomsById.get(reservation.Room__c));
        }
    }

    private Boolean hasRelevantChange(Reservation__c newReservation, Reservation__c oldReservation) {
        return newReservation.Room__c != oldReservation.Room__c
            || newReservation.Check_In_Date__c != oldReservation.Check_In_Date__c
            || newReservation.Check_Out_Date__c != oldReservation.Check_Out_Date__c;
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
