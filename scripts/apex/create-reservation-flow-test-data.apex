// Crea datos reales en el org para probar ReservationFlow con la opción
// "Run from Org Data" del Flow Test (en vez del data silo aislado por Apex).
//
// Ejecutar con: SFDX: Execute Anonymous Apex with Editor Contents
// o: sf apex run --file scripts/apex/create-reservation-flow-test-data.apex --target-org <alias>
//
// Después de correrlo, usá el Room__c creado (ver el debug log) para armar la
// Reservation__c inicial en el paso "Set Initial Triggering Record" del Flow Test.

Property__c prop = TestDataFactory.createProperty();
insert prop;

Room__c room = TestDataFactory.createRoomWithRate(prop.Id, 10);
insert room;

System.debug('Property__c creada -> Id: ' + prop.Id + ' | Name: ' + prop.Name);
System.debug('Room__c creada    -> Id: ' + room.Id + ' | Name: ' + room.Name);
System.debug('Usá este Room__c (por Id o por Name) al armar la Reservation__c de prueba en el Flow Test.');
