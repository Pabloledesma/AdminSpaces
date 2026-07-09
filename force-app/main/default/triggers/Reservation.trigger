trigger Reservation on Reservation__c (before insert, before update) {
    ReservationTriggerHandler handler = new ReservationTriggerHandler();

    if( Trigger.isInsert ){
        if(Trigger.isBefore) {
            handler.OnBeforeInsert(trigger.New);
        }
    }
    
}