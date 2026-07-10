/**
 * Data silo para el Flow Test de ReservationFlow. Crea la Property__c y la
 * Room__c que la Reservation__c disparadora del flow necesita (Room__c es
 * Master-Detail y requerido en Reservation__c).
 */
@isTest
public class ReservationFlowTestSetup {
    @TestSetup
    static void makeData() {
        Property__c prop = TestDataFactory.createProperty();
        insert prop;
        Room__c room = TestDataFactory.createRoomWithRate(prop.Id, 10);
        insert room;
    }
}