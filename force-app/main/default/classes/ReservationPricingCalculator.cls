public with sharing class ReservationPricingCalculator {
    public static void calculate(Reservation__c reservation, Room__c room){
        if(room != null && room.Nightly_Rate__c != null){
            reservation.Total_Amount__c = reservation.Check_In_Date__c.daysBetween(reservation.Check_Out_Date__c) * room.Nightly_Rate__c;
        }
    }
}