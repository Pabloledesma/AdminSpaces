public inherited sharing class RoomSelector {
   public static List<Room__c> getRoomsById(Set<Id> setId){
        return [SELECT Id, Nightly_Rate__c FROM Room__c WHERE Id IN :setId];
   }
}