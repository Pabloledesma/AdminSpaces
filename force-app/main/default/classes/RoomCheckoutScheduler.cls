/**
 * Historia 2.3: al hacerse el checkout, la habitación debe quedar disponible
 * automáticamente. Pensado para correr una vez al día (ej. 10am, después del
 * horario límite de checkout).
 *
 * Dos reglas independientes, cada una en su propio método:
 * - Reservas ya marcadas Checked Out ese día -> se libera la habitación.
 * - Reservas que debían hacer checkout hoy pero no lo hicieron (no-show) ->
 *   se extiende Check_Out_Date__c un día. El recálculo de Total_Amount__c
 *   (la noche extra) lo hace automáticamente ReservationTriggerHandler.OnBeforeUpdate,
 *   no hace falta duplicar esa lógica acá.
 *
 * El posible conflicto entre una extensión y la reserva del siguiente huésped
 * (overlap real) queda fuera de esta clase a propósito: si ocurre, el propio
 * trigger de Reservation__c rechaza esa actualización puntual (Database.update
 * con allOrNone=false no frena el resto del batch) y queda para resolución manual.
 */
public with sharing class RoomCheckoutScheduler implements Schedulable {

    public void execute(SchedulableContext context) {
        freeRoomsForCompletedCheckouts();
        extendUnconfirmedCheckouts();
    }

    private void freeRoomsForCompletedCheckouts() {
        List<Reservation__c> checkedOutToday = [
            SELECT Room__c
            FROM Reservation__c
            WHERE Check_Out_Date__c = TODAY AND Status__c = 'Checked Out'
        ];

        Set<Id> roomIds = new Set<Id>();
        for (Reservation__c reservation : checkedOutToday) {
            roomIds.add(reservation.Room__c);
        }

        if (roomIds.isEmpty()) {
            return;
        }

        List<Room__c> roomsToFree = new List<Room__c>();
        for (Id roomId : roomIds) {
            roomsToFree.add(new Room__c(Id = roomId, Status__c = 'Available'));
        }
        update roomsToFree;
    }

    private void extendUnconfirmedCheckouts() {
        List<Reservation__c> noShowReservations = [
            SELECT Id, Check_Out_Date__c
            FROM Reservation__c
            WHERE Check_Out_Date__c = TODAY AND Status__c IN :ReservationOverlapValidator.BLOCKING_STATUSES
        ];

        if (noShowReservations.isEmpty()) {
            return;
        }

        for (Reservation__c reservation : noShowReservations) {
            reservation.Check_Out_Date__c = reservation.Check_Out_Date__c.addDays(1);
        }

        Database.update(noShowReservations, false);
    }
}
