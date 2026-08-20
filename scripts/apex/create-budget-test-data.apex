// Datos para ver la proyección de la Historia 5.6 funcionando de verdad.
// Es aditivo: crea una habitación nueva con tarifa y sus reservas, sin tocar
// nada de lo que ya existe. Las habitaciones de la demo no tienen
// Nightly_Rate__c, así que sus reservas tienen Total_Amount__c en null y la
// proyección da todo cero (correcto, pero poco demostrativo).

Property__c prop = [SELECT Id, Name FROM Property__c LIMIT 1];

Room__c room = new Room__c(
  Property__c = prop.Id,
  Room_Type__c = 'Double',
  Nightly_Rate__c = 120,
  Status__c = 'Available',
  Is_Demo__c = true
);
insert room;

Date startOfThisMonth = Date.today().toStartOfMonth();

List<Reservation__c> reservations = new List<Reservation__c>();

// Historial: tres meses cerrados con ingreso, para que el promedio no sea cero
for (Integer i = 1; i <= 3; i++) {
  Date checkIn = startOfThisMonth.addMonths(-i).addDays(4);
  reservations.add(
    new Reservation__c(
      Room__c = room.Id,
      Check_In_Date__c = checkIn,
      Check_Out_Date__c = checkIn.addDays(5), // 5 noches x 120 = 600
      Status__c = 'Checked Out',
      Is_Demo__c = true
    )
  );
}

// Futuro cercano: reservas ya confirmadas en los próximos dos meses
for (Integer i = 1; i <= 2; i++) {
  Date checkIn = startOfThisMonth.addMonths(i).addDays(9);
  reservations.add(
    new Reservation__c(
      Room__c = room.Id,
      Check_In_Date__c = checkIn,
      Check_Out_Date__c = checkIn.addDays(3), // 3 noches x 120 = 360
      Status__c = 'Confirmed',
      Is_Demo__c = true
    )
  );
}

insert reservations;

System.debug('Habitación creada: ' + room.Id + ' en la propiedad ' + prop.Name);
System.debug('Reservas creadas: ' + reservations.size());
System.debug('Promedio histórico esperado: 1800 / 12 = 150.00 por mes');
System.debug(
  'Proyectá desde el mes que viene a 6 meses: dos meses con 360 reales y el resto a 150.'
);
