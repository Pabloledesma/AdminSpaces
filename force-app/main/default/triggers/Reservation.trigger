trigger Reservation on Reservation__c(before insert, before update) {
  ReservationTriggerHandler handler = new ReservationTriggerHandler();

  if (Trigger.isInsert) {
    if (Trigger.isBefore) {
      handler.OnBeforeInsert(Trigger.New);
    }
  }

  if (Trigger.isUpdate) {
    if (Trigger.isBefore) {
      handler.OnBeforeUpdate(Trigger.new, Trigger.oldMap);
    }
  }

}
