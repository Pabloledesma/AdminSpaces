public with sharing class RoomAvailabilityController {
  @AuraEnabled
  public static Boolean checkAvailability(
    Id roomId,
    Date checkIn,
    Date checkOut
  ) {
    List<Reservation__c> existingReservations = ReservationSelector.getByRoomIdsAndStatuses(
      new Set<Id>{ roomId },
      ReservationOverlapValidator.BLOCKING_STATUSES
    );

    Reservation__c candidate = new Reservation__c(
      Room__c = roomId,
      Check_In_Date__c = checkIn,
      Check_Out_Date__c = checkOut
    );

    for (Reservation__c existing : existingReservations) {
      if (ReservationOverlapValidator.overlaps(candidate, existing)) {
        return false;
      }
    }
    return true;
  }

  @AuraEnabled(cacheable=true)
  public static List<Room__c> getRoomsForProperty(Id propertyId) {
    return RoomSelector.getRoomFromPropertyId(propertyId);
  }

  @AuraEnabled(cacheable=true)
  public static List<Reservation__c> getBlockedDateRangesForRoom(Id roomId) {
    return ReservationSelector.getByRoomIdsAndStatuses(
      new Set<Id>{ roomId },
      ReservationOverlapValidator.BLOCKING_STATUSES
    );
  }
}
