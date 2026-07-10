@isTest
private class ReservationTest {

    @IsTest
    static void las_habitaciones_cambian_de_estado_el_dia_del_checkout(){

        Property__c prop = TestDataFactory.createProperty();
        insert prop;
        Room__c room = TestDataFactory.createRoomWithRate(prop.Id, 10);
        insert room;
        insert TestDataFactory.buildReservation(room.Id, Date.today().addDays(-1), Date.today(), 'Checked Out');

        Test.startTest();
            new RoomCheckoutScheduler().execute(null);
        Test.stopTest();

        Room__c reloadedRoom = [SELECT Status__c FROM Room__c WHERE Id = :room.Id];
        System.assertEquals('Available', reloadedRoom.Status__c, 'La habitación debe quedar disponible el día del checkout');
    }

    @IsTest
    static void no_libera_la_habitacion_si_la_reserva_no_esta_marcada_como_checked_out(){

        Property__c prop = TestDataFactory.createProperty();
        insert prop;
        Room__c room = TestDataFactory.createRoomWithRate(prop.Id, 10);
        room.Status__c = 'Occupied';
        insert room;
        Reservation__c reservation = TestDataFactory.buildReservation(room.Id, Date.today().addDays(-1), Date.today(), 'Confirmed');
        insert reservation;

        Test.startTest();
            new RoomCheckoutScheduler().execute(null);
        Test.stopTest();

        Room__c reloadedRoom = [SELECT Status__c FROM Room__c WHERE Id = :room.Id];
        System.assertEquals('Occupied', reloadedRoom.Status__c, 'La habitación no debe liberarse si el huésped no hizo checkout');

        Reservation__c reloadedReservation = [SELECT Check_Out_Date__c, Total_Amount__c FROM Reservation__c WHERE Id = :reservation.Id];
        System.assertEquals(Date.today().addDays(1), reloadedReservation.Check_Out_Date__c, 'El checkout debe extenderse un día por no-show');
        System.assertEquals(20, reloadedReservation.Total_Amount__c, 'Se debe cobrar la noche extra (2 noches x 10 = 20)');
    }

    @IsTest
    static void no_toca_habitaciones_con_checkout_manana(){

        Property__c prop = TestDataFactory.createProperty();
        insert prop;
        Room__c room = TestDataFactory.createRoomWithRate(prop.Id, 10);
        room.Status__c = 'Occupied';
        insert room;
        insert TestDataFactory.buildReservation(room.Id, Date.today(), Date.today().addDays(1), 'Checked Out');

        Test.startTest();
            new RoomCheckoutScheduler().execute(null);
        Test.stopTest();

        Room__c reloadedRoom = [SELECT Status__c FROM Room__c WHERE Id = :room.Id];
        System.assertEquals('Occupied', reloadedRoom.Status__c, 'Una reserva que hace checkout mañana no debe afectar la habitación hoy');
    }

    @IsTest
    static void no_reprocesa_checkouts_de_dias_anteriores(){

        Property__c prop = TestDataFactory.createProperty();
        insert prop;
        Room__c room = TestDataFactory.createRoomWithRate(prop.Id, 10);
        room.Status__c = 'Occupied';
        insert room;
        insert TestDataFactory.buildReservation(room.Id, Date.today().addDays(-2), Date.today().addDays(-1), 'Checked Out');

        Test.startTest();
            new RoomCheckoutScheduler().execute(null);
        Test.stopTest();

        Room__c reloadedRoom = [SELECT Status__c FROM Room__c WHERE Id = :room.Id];
        System.assertEquals('Occupied', reloadedRoom.Status__c, 'Un checkout de un día anterior no debe reprocesarse hoy');
    }

    @IsTest
    static void libera_multiples_habitaciones_en_una_sola_corrida(){

        Property__c prop = TestDataFactory.createProperty();
        insert prop;
        Room__c checkedOutRoom1 = TestDataFactory.createRoomWithRate(prop.Id, 10);
        checkedOutRoom1.Status__c = 'Occupied';
        Room__c checkedOutRoom2 = TestDataFactory.createRoomWithRate(prop.Id, 20);
        checkedOutRoom2.Status__c = 'Occupied';
        Room__c stillOccupiedRoom = TestDataFactory.createRoomWithRate(prop.Id, 30);
        stillOccupiedRoom.Status__c = 'Occupied';
        insert new List<Room__c>{ checkedOutRoom1, checkedOutRoom2, stillOccupiedRoom };

        insert new List<Reservation__c>{
            TestDataFactory.buildReservation(checkedOutRoom1.Id, Date.today().addDays(-1), Date.today(), 'Checked Out'),
            TestDataFactory.buildReservation(checkedOutRoom2.Id, Date.today().addDays(-3), Date.today(), 'Checked Out'),
            TestDataFactory.buildReservation(stillOccupiedRoom.Id, Date.today().addDays(-1), Date.today(), 'Confirmed')
        };

        Test.startTest();
            new RoomCheckoutScheduler().execute(null);
        Test.stopTest();

        Map<Id, Room__c> roomsById = new Map<Id, Room__c>(
            [SELECT Id, Status__c FROM Room__c WHERE Id IN :new Set<Id>{ checkedOutRoom1.Id, checkedOutRoom2.Id, stillOccupiedRoom.Id }]
        );

        System.assertEquals('Available', roomsById.get(checkedOutRoom1.Id).Status__c, 'Room1 hizo checkout, debe quedar disponible');
        System.assertEquals('Available', roomsById.get(checkedOutRoom2.Id).Status__c, 'Room2 hizo checkout, debe quedar disponible');
        System.assertEquals('Occupied', roomsById.get(stillOccupiedRoom.Id).Status__c, 'Room3 no hizo checkout, debe seguir ocupada');
    }

    // -- Casos Calculo Total Amount

    @IsTest
    static void se_reserva_una_sola_noche(){

        Property__c prop = TestDataFactory.createProperty();
        insert prop;
        Room__c room = TestDataFactory.createRoomWithRate(prop.Id, 10);
        insert room;
        
        Test.startTest();
        
            insert TestDataFactory.buildReservation(room.Id, Date.newInstance(2026, 8, 10), Date.newInstance(2026, 8, 11));
            Reservation__c reservation = [SELECT Id, Total_Amount__c FROM Reservation__c WHERE Room__c =: room.Id LIMIT 1];
      
        Test.stopTest();

        System.assertEquals(10, reservation.Total_Amount__c, 'El valor total de la reserva no es correcto');
        
    }

    /**
     * Regresión del bug encontrado en OnBeforeInsert: antes del fix, el código
     * trackeaba las reservas solapadas con un Map<Id, Reservation__c> — pero en
     * before insert TODAS las reservas nuevas tienen Id == null, así que el mapa
     * colapsaba todo en una sola entrada y, apenas UNA reserva del batch se
     * solapaba, TODAS las demás (incluidas las válidas) se saltaban el cálculo
     * de Total_Amount__c. El fix cambió el Map<Id,...> por un Set<Reservation__c>.
     */
    @IsTest
    static void calcula_el_total_de_la_reserva_valida_aunque_otra_del_mismo_batch_se_solape(){

        Property__c prop = TestDataFactory.createProperty();
        insert prop;
        Room__c room = TestDataFactory.createRoomWithRate(prop.Id, 10);
        insert room;
        insert TestDataFactory.buildReservation(room.Id, Date.newInstance(2026, 8, 1), Date.newInstance(2026, 8, 5));

        Reservation__c valid = TestDataFactory.buildReservation(room.Id, Date.newInstance(2026, 9, 1), Date.newInstance(2026, 9, 3)); // 2 noches x 10 = 20, no se solapa
        Reservation__c overlapping = TestDataFactory.buildReservation(room.Id, Date.newInstance(2026, 8, 2), Date.newInstance(2026, 8, 4)); // se solapa con la existente

        Test.startTest();
            List<Database.SaveResult> results = Database.insert(new List<Reservation__c>{ valid, overlapping }, false);
        Test.stopTest();

        System.assert(results[0].isSuccess(), 'La reserva válida debe insertarse');
        System.assert(!results[1].isSuccess(), 'La reserva solapada debe fallar');

        Reservation__c reloaded = [SELECT Total_Amount__c FROM Reservation__c WHERE Id = :valid.Id];
        System.assertEquals(20, reloaded.Total_Amount__c, 'La reserva válida debe tener su Total_Amount__c calculado aunque otra del mismo batch se haya solapado');
    }

    /**
     * Sospecha a verificar sobre OnBeforeUpdate: la consulta de existingReservations
     * no excluye el propio registro que se está editando. Si el nuevo rango de
     * fechas se solapa con el rango ANTERIOR de la misma reserva (algo común al
     * simplemente correr las fechas unos días), podría auto-rechazarse aunque no
     * exista ninguna otra reserva en conflicto real.
     */
    @IsTest
    static void puede_editar_reserva_desplazando_sus_propias_fechas_sin_otras_reservas_en_conflicto(){

        Property__c prop = TestDataFactory.createProperty();
        insert prop;
        Room__c room = TestDataFactory.createRoomWithRate(prop.Id, 10);
        insert room;

        Reservation__c reservation = TestDataFactory.buildReservation(room.Id, Date.newInstance(2026, 8, 10), Date.newInstance(2026, 8, 15));
        insert reservation;

        reservation.Check_In_Date__c = Date.newInstance(2026, 8, 12);
        reservation.Check_Out_Date__c = Date.newInstance(2026, 8, 17);

        Test.startTest();
        DmlException error;
        try {
            update reservation;
        } catch (DmlException e) {
            error = e;
        }
        Test.stopTest();

        System.assertEquals(null, error, 'Editar una reserva desplazando sus propias fechas no debe compararse contra su propia versión anterior');
    }

    @IsTest
    static void reserva_de_multiples_habitaciones(){

        Property__c prop = TestDataFactory.createProperty();
        insert prop;

        Room__c room1 = TestDataFactory.createRoomWithRate(prop.Id, 10);
        Room__c room2 = TestDataFactory.createRoomWithRate(prop.Id, 20);
        Room__c room3 = TestDataFactory.createRoomWithRate(prop.Id, 30);
        List<Room__c> lstRooms = new List<Room__c>{ room1, room2, room3 };
        insert lstRooms;

        List<Reservation__c> lstReservations = new List<Reservation__c>{
            TestDataFactory.buildReservation(room1.Id, Date.newInstance(2026, 8, 10), Date.newInstance(2026, 8, 15)), // 5 noches x 10 = 50
            TestDataFactory.buildReservation(room2.Id, Date.newInstance(2026, 8, 10), Date.newInstance(2026, 8, 11)), // 1 noche x 20 = 20
            TestDataFactory.buildReservation(room3.Id, Date.newInstance(2026, 8, 10), Date.newInstance(2026, 8, 13))  // 3 noches x 30 = 90
        };

        Test.startTest();
            insert lstReservations;
        Test.stopTest();

        Map<Id, Reservation__c> reservationByRoom = new Map<Id, Reservation__c>();
        for (Reservation__c reservation : [SELECT Id, Room__c, Total_Amount__c FROM Reservation__c WHERE Room__c IN :new Set<Id>{ room1.Id, room2.Id, room3.Id }]) {
            reservationByRoom.put(reservation.Room__c, reservation);
        }

        System.assertEquals(3, reservationByRoom.size(), 'Las 3 reservas en habitaciones distintas deben insertarse sin bloquearse entre sí');
        System.assertEquals(50, reservationByRoom.get(room1.Id).Total_Amount__c, 'Room1: 5 noches x 10 = 50');
        System.assertEquals(20, reservationByRoom.get(room2.Id).Total_Amount__c, 'Room2: 1 noche x 20 = 20');
        System.assertEquals(90, reservationByRoom.get(room3.Id).Total_Amount__c, 'Room3: 3 noches x 30 = 90');
    }

    // ── Casos negativos: variantes de solapamiento ──────────────────────────

    @isTest
    private static void no_puede_crear_reserva_por_que_se_solapa_con_fecha_de_otra_reserva() {
        Property__c prop = TestDataFactory.createProperty();
        insert prop;
        Room__c room = TestDataFactory.createRoom(prop.Id);
        insert room;
        insert TestDataFactory.buildReservation(room.Id, Date.newInstance(2026, 8, 10), Date.newInstance(2026, 8, 15));

        Reservation__c overlapping = TestDataFactory.buildReservation(room.Id, Date.newInstance(2026, 8, 12), Date.newInstance(2026, 8, 18));

        Test.startTest();
        DmlException error = insertAndCaptureError(overlapping);
        Test.stopTest();

        System.assertNotEquals(null, error, 'Se esperaba un error por solapamiento de fechas');
    }

    @isTest
    private static void no_puede_crear_reserva_si_queda_completamente_dentro_de_otra() {
        Property__c prop = TestDataFactory.createProperty();
        insert prop;
        Room__c room = TestDataFactory.createRoom(prop.Id);
        insert room;
        insert TestDataFactory.buildReservation(room.Id, Date.newInstance(2026, 8, 1), Date.newInstance(2026, 8, 20));

        Reservation__c nested = TestDataFactory.buildReservation(room.Id, Date.newInstance(2026, 8, 5), Date.newInstance(2026, 8, 10));

        Test.startTest();
        DmlException error = insertAndCaptureError(nested);
        Test.stopTest();

        System.assertNotEquals(null, error, 'Una reserva anidada dentro de otra debe fallar');
    }

    @isTest
    private static void no_puede_crear_reserva_si_envuelve_completamente_a_otra() {
        Property__c prop = TestDataFactory.createProperty();
        insert prop;
        Room__c room = TestDataFactory.createRoom(prop.Id);
        insert room;
        insert TestDataFactory.buildReservation(room.Id, Date.newInstance(2026, 8, 5), Date.newInstance(2026, 8, 10));

        Reservation__c enclosing = TestDataFactory.buildReservation(room.Id, Date.newInstance(2026, 8, 1), Date.newInstance(2026, 8, 20));

        Test.startTest();
        DmlException error = insertAndCaptureError(enclosing);
        Test.stopTest();

        System.assertNotEquals(null, error, 'Una reserva que envuelve completamente a otra debe fallar');
    }

    @isTest
    private static void no_puede_crear_reserva_si_se_solapa_al_inicio() {
        Property__c prop = TestDataFactory.createProperty();
        insert prop;
        Room__c room = TestDataFactory.createRoom(prop.Id);
        insert room;
        insert TestDataFactory.buildReservation(room.Id, Date.newInstance(2026, 8, 10), Date.newInstance(2026, 8, 15));

        Reservation__c overlapsStart = TestDataFactory.buildReservation(room.Id, Date.newInstance(2026, 8, 5), Date.newInstance(2026, 8, 12));

        Test.startTest();
        DmlException error = insertAndCaptureError(overlapsStart);
        Test.stopTest();

        System.assertNotEquals(null, error, 'Una reserva que se solapa al inicio debe fallar');
    }

    @isTest
    private static void no_puede_crear_reserva_si_se_solapa_al_final() {
        Property__c prop = TestDataFactory.createProperty();
        insert prop;
        Room__c room = TestDataFactory.createRoom(prop.Id);
        insert room;
        insert TestDataFactory.buildReservation(room.Id, Date.newInstance(2026, 8, 10), Date.newInstance(2026, 8, 15));

        Reservation__c overlapsEnd = TestDataFactory.buildReservation(room.Id, Date.newInstance(2026, 8, 13), Date.newInstance(2026, 8, 20));

        Test.startTest();
        DmlException error = insertAndCaptureError(overlapsEnd);
        Test.stopTest();

        System.assertNotEquals(null, error, 'Una reserva que se solapa al final debe fallar');
    }

    @isTest
    private static void no_puede_crear_reserva_con_las_mismas_fechas_exactas() {
        Property__c prop = TestDataFactory.createProperty();
        insert prop;
        Room__c room = TestDataFactory.createRoom(prop.Id);
        insert room;
        insert TestDataFactory.buildReservation(room.Id, Date.newInstance(2026, 8, 10), Date.newInstance(2026, 8, 15));

        Reservation__c sameDates = TestDataFactory.buildReservation(room.Id, Date.newInstance(2026, 8, 10), Date.newInstance(2026, 8, 15));

        Test.startTest();
        DmlException error = insertAndCaptureError(sameDates);
        Test.stopTest();

        System.assertNotEquals(null, error, 'Dos reservas con las mismas fechas exactas deben fallar');
    }

    @isTest
    private static void no_puede_editar_reserva_para_que_quede_solapada_con_otra() {
        Property__c prop = TestDataFactory.createProperty();
        insert prop;
        Room__c room = TestDataFactory.createRoom(prop.Id);
        insert room;
        insert TestDataFactory.buildReservation(room.Id, Date.newInstance(2026, 8, 10), Date.newInstance(2026, 8, 15));

        Reservation__c toEdit = TestDataFactory.buildReservation(room.Id, Date.newInstance(2026, 9, 1), Date.newInstance(2026, 9, 5));
        insert toEdit;
        toEdit.Check_In_Date__c = Date.newInstance(2026, 8, 12);
        toEdit.Check_Out_Date__c = Date.newInstance(2026, 8, 18);

        Test.startTest();
        DmlException error;
        try {
            update toEdit;
        } catch (DmlException e) {
            error = e;
        }
        Test.stopTest();

        System.assertNotEquals(null, error, 'Editar una reserva para que quede solapada con otra debe fallar');
    }

    // ── Casos positivos ──────────────────────────────────────────────────────

    @isTest
    private static void puede_crear_reserva_completamente_antes_de_otra() {
        Property__c prop = TestDataFactory.createProperty();
        insert prop;
        Room__c room = TestDataFactory.createRoom(prop.Id);
        insert room;
        insert TestDataFactory.buildReservation(room.Id, Date.newInstance(2026, 8, 10), Date.newInstance(2026, 8, 15));

        Reservation__c before = TestDataFactory.buildReservation(room.Id, Date.newInstance(2026, 7, 1), Date.newInstance(2026, 7, 5));

        Test.startTest();
        DmlException error = insertAndCaptureError(before);
        Test.stopTest();

        System.assertEquals(null, error, 'Una reserva completamente antes de otra no debe fallar');
    }

    @isTest
    private static void puede_crear_reserva_completamente_despues_de_otra() {
        Property__c prop = TestDataFactory.createProperty();
        insert prop;
        Room__c room = TestDataFactory.createRoom(prop.Id);
        insert room;
        insert TestDataFactory.buildReservation(room.Id, Date.newInstance(2026, 8, 10), Date.newInstance(2026, 8, 15));

        Reservation__c after = TestDataFactory.buildReservation(room.Id, Date.newInstance(2026, 9, 1), Date.newInstance(2026, 9, 5));

        Test.startTest();
        DmlException error = insertAndCaptureError(after);
        Test.stopTest();

        System.assertEquals(null, error, 'Una reserva completamente después de otra no debe fallar');
    }

    @isTest
    private static void puede_crear_reserva_en_otra_habitacion_con_mismas_fechas() {
        Property__c prop = TestDataFactory.createProperty();
        insert prop;
        Room__c room1 = TestDataFactory.createRoom(prop.Id);
        Room__c room2 = TestDataFactory.createRoom(prop.Id);
        insert new List<Room__c>{ room1, room2 };
        insert TestDataFactory.buildReservation(room1.Id, Date.newInstance(2026, 8, 10), Date.newInstance(2026, 8, 15));

        Reservation__c sameDatesOtherRoom = TestDataFactory.buildReservation(room2.Id, Date.newInstance(2026, 8, 10), Date.newInstance(2026, 8, 15));

        Test.startTest();
        DmlException error = insertAndCaptureError(sameDatesOtherRoom);
        Test.stopTest();

        System.assertEquals(null, error, 'El solapamiento debe validarse por habitación, no de forma global');
    }

    @isTest
    private static void puede_editar_reserva_sin_cambiar_fechas_sin_disparar_falso_positivo() {
        Property__c prop = TestDataFactory.createProperty();
        insert prop;
        Room__c room = TestDataFactory.createRoom(prop.Id);
        insert room;
        Reservation__c reservation = TestDataFactory.buildReservation(room.Id, Date.newInstance(2026, 8, 10), Date.newInstance(2026, 8, 15));
        insert reservation;
        reservation.Status__c = 'Checked In';

        Test.startTest();
        DmlException error;
        try {
            update reservation;
        } catch (DmlException e) {
            error = e;
        }
        Test.stopTest();

        System.assertEquals(null, error, 'Editar una reserva sin tocar sus fechas no debe compararse consigo misma');
    }

    // ── Edge cases de regla de negocio ──────────────────────────────────────

    /**
     * Asunción de negocio: el día de checkout de una reserva queda libre para el
     * checkin de otra (regla común en hotelería). Si la regla real es distinta
     * (ej. requiere un día completo de limpieza entre reservas), ajustar este test
     * antes de implementar el trigger.
     */
    @isTest
    private static void puede_crear_reserva_cuyo_checkin_coincide_con_checkout_de_otra() {
        Property__c prop = TestDataFactory.createProperty();
        insert prop;
        Room__c room = TestDataFactory.createRoom(prop.Id);
        insert room;
        insert TestDataFactory.buildReservation(room.Id, Date.newInstance(2026, 8, 10), Date.newInstance(2026, 8, 15));

        Reservation__c backToBack = TestDataFactory.buildReservation(room.Id, Date.newInstance(2026, 8, 15), Date.newInstance(2026, 8, 20));

        Test.startTest();
        DmlException error = insertAndCaptureError(backToBack);
        Test.stopTest();

        System.assertEquals(null, error, 'El mismo día de checkout/checkin no debe contar como solapamiento');
    }

    @isTest
    private static void no_bloquea_solapamiento_si_la_reserva_existente_esta_cancelled() {
        Property__c prop = TestDataFactory.createProperty();
        insert prop;
        Room__c room = TestDataFactory.createRoom(prop.Id);
        insert room;
        insert TestDataFactory.buildReservation(room.Id, Date.newInstance(2026, 8, 10), Date.newInstance(2026, 8, 15), 'Cancelled');

        Reservation__c overlapping = TestDataFactory.buildReservation(room.Id, Date.newInstance(2026, 8, 12), Date.newInstance(2026, 8, 18));

        Test.startTest();
        DmlException error = insertAndCaptureError(overlapping);
        Test.stopTest();

        System.assertEquals(null, error, 'Una reserva Cancelled no debe bloquear la habitación');
    }

    // ── Bulk ─────────────────────────────────────────────────────────────────

    @isTest
    private static void permite_insertar_200_reservas_sin_solapamientos_en_bulk() {
        Property__c prop = TestDataFactory.createProperty();
        insert prop;
        Room__c room = TestDataFactory.createRoom(prop.Id);
        insert room;

        List<Reservation__c> reservations = new List<Reservation__c>();
        for (Integer i = 0; i < 200; i++) {
            Date checkIn = Date.newInstance(2026, 1, 1).addDays(i * 2);
            Date checkOut = checkIn.addDays(1);
            reservations.add(TestDataFactory.buildReservation(room.Id, checkIn, checkOut));
        }

        Test.startTest();
        insert reservations;
        Test.stopTest();

        System.assertEquals(200, [SELECT COUNT() FROM Reservation__c], 'Las 200 reservas sin solapamientos deben insertarse');
    }

    @isTest
    private static void bloquea_solapamientos_entre_registros_del_mismo_batch() {
        Property__c prop = TestDataFactory.createProperty();
        insert prop;
        Room__c room = TestDataFactory.createRoom(prop.Id);
        insert room;

        List<Reservation__c> reservations = new List<Reservation__c>{
            TestDataFactory.buildReservation(room.Id, Date.newInstance(2026, 8, 10), Date.newInstance(2026, 8, 15)),
            TestDataFactory.buildReservation(room.Id, Date.newInstance(2026, 8, 12), Date.newInstance(2026, 8, 18))
        };

        Test.startTest();
        List<Database.SaveResult> results = Database.insert(reservations, false);
        Test.stopTest();

        Integer failureCount = 0;
        for (Database.SaveResult result : results) {
            if (!result.isSuccess()) {
                failureCount++;
            }
        }
        System.assertEquals(1, failureCount, 'Una de las dos reservas solapadas del mismo batch debe fallar');
    }

    // ── Helper ───────────────────────────────────────────────────────────────

    private static DmlException insertAndCaptureError(Reservation__c reservation) {
        try {
            insert reservation;
            return null;
        } catch (DmlException e) {
            return e;
        }
    }
}
