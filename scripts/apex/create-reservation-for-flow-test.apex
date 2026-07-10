// Crea una Reservation__c real en el org, relacionada al Room__c creado por
// create-reservation-flow-test-data.apex, para usar con "Run from Org Data"
// en el Flow Test de ReservationFlow (o para disparar el flow real).
//
// Ejecutar con: SFDX: Execute Anonymous Apex with Editor Contents
// o: sf apex run --file scripts/apex/create-reservation-for-flow-test.apex --target-org <alias>

Room__c room = [SELECT Id, Name FROM Room__c WHERE Id = 'a05ak00000cK0xFAAS' LIMIT 1];

Reservation__c reservation = TestDataFactory.buildReservation(
    room.Id,
    Date.newInstance(2026, 7, 15),
    Date.newInstance(2026, 7, 20)
);
insert reservation;

System.debug('Reservation__c creada -> Id: ' + reservation.Id + ' | Room: ' + room.Name
    + ' | Check_In: 2026-07-15 | Check_Out: 2026-07-20 | Status: Confirmed');
