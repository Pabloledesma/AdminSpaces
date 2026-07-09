/**
 * Encapsulates the "two reservations for the same room can't overlap" rule
 * (Historia 2.1). Pure logic, no SOQL/DML — reusable from the trigger
 * handler and, later, from an availability-check LWC controller (Historia 3.2)
 * without duplicating the rule.
 */
public inherited sharing class ReservationOverlapValidator {

    // Reservation statuses that occupy a room and can block a new/edited
    // reservation. Cancelled and Checked Out reservations never block —
    // extend this set instead of touching the comparison logic below (OCP).
    public static final Set<String> BLOCKING_STATUSES = new Set<String>{ 'Pending', 'Confirmed', 'Checked In' };

    /**
     * Returns the subset of candidateReservations whose date range overlaps,
     * for the same Room__c, with either an existingReservation or an earlier
     * candidate already accepted earlier in this same call — so two new
     * overlapping records in the same batch are also caught before either
     * one exists in the database.
     * @param candidateReservations Reservations being inserted/updated
     * @param existingReservations Already-persisted reservations to compare against
     * @return The candidates that overlap with something else
     */
    public static List<Reservation__c> findOverlapping(
        List<Reservation__c> candidateReservations,
        List<Reservation__c> existingReservations
    ) {
        Map<Id, List<Reservation__c>> existingByRoom = groupByRoom(existingReservations);
        Map<Id, List<Reservation__c>> acceptedByRoom = new Map<Id, List<Reservation__c>>();
        List<Reservation__c> overlapping = new List<Reservation__c>();

        for (Reservation__c candidate : candidateReservations) {
            if (!hasCompleteDateRange(candidate)) {
                continue;
            }

            Boolean conflicts = overlapsAny(candidate, existingByRoom.get(candidate.Room__c))
                || overlapsAny(candidate, acceptedByRoom.get(candidate.Room__c));

            if (conflicts) {
                overlapping.add(candidate);
                continue;
            }

            if (!acceptedByRoom.containsKey(candidate.Room__c)) {
                acceptedByRoom.put(candidate.Room__c, new List<Reservation__c>());
            }
            acceptedByRoom.get(candidate.Room__c).add(candidate);
        }

        return overlapping;
    }

    /**
     * Two [Check_In_Date__c, Check_Out_Date__c) ranges overlap if each starts
     * before the other ends. The strict "<" means the same day used as one
     * reservation's checkout and another's checkin does NOT count as overlap
     * (business rule assumed for Historia 2.1).
     */
    public static Boolean overlaps(Reservation__c a, Reservation__c b) {
        return a.Check_In_Date__c < b.Check_Out_Date__c && b.Check_In_Date__c < a.Check_Out_Date__c;
    }

    private static Boolean hasCompleteDateRange(Reservation__c reservation) {
        return reservation.Room__c != null
            && reservation.Check_In_Date__c != null
            && reservation.Check_Out_Date__c != null;
    }

    private static Boolean overlapsAny(Reservation__c reservation, List<Reservation__c> others) {
        if (others == null) {
            return false;
        }
        for (Reservation__c other : others) {
            if (overlaps(reservation, other)) {
                return true;
            }
        }
        return false;
    }

    private static Map<Id, List<Reservation__c>> groupByRoom(List<Reservation__c> reservations) {
        Map<Id, List<Reservation__c>> byRoom = new Map<Id, List<Reservation__c>>();
        for (Reservation__c reservation : reservations) {
            if (!byRoom.containsKey(reservation.Room__c)) {
                byRoom.put(reservation.Room__c, new List<Reservation__c>());
            }
            byRoom.get(reservation.Room__c).add(reservation);
        }
        return byRoom;
    }
}
