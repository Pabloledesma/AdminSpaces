@isTest
private class ReservationTest {

    private static Property__c createProperty() {
        return new Property__c(Name = 'Test Property', Is_Demo__c = true);
    }

    private static Room__c createRoom(Id propertyId) {
        return new Room__c(Property__c = propertyId, Room_Type__c = 'Single', Is_Demo__c = true);
    }

    private static Reservation__c buildReservation(Id roomId, Date checkIn, Date checkOut) {
        return buildReservation(roomId, checkIn, checkOut, 'Confirmed');
    }

    private static Reservation__c buildReservation(Id roomId, Date checkIn, Date checkOut, String status) {
        return new Reservation__c(
            Room__c = roomId,
            Check_In_Date__c = checkIn,
            Check_Out_Date__c = checkOut,
            Status__c = status,
            Is_Demo__c = true
        );
    }

    // ── Casos negativos: variantes de solapamiento ──────────────────────────

    @isTest
    private static void no_puede_crear_reserva_por_que_se_solapa_con_fecha_de_otra_reserva() {
        Property__c prop = createProperty();
        insert prop;
        Room__c room = createRoom(prop.Id);
        insert room;
        insert buildReservation(room.Id, Date.newInstance(2026, 8, 10), Date.newInstance(2026, 8, 15));

        Reservation__c overlapping = buildReservation(room.Id, Date.newInstance(2026, 8, 12), Date.newInstance(2026, 8, 18));

        Test.startTest();
        DmlException error = insertAndCaptureError(overlapping);
        Test.stopTest();

        System.assertNotEquals(null, error, 'Se esperaba un error por solapamiento de fechas');
    }

    @isTest
    private static void no_puede_crear_reserva_si_queda_completamente_dentro_de_otra() {
        Property__c prop = createProperty();
        insert prop;
        Room__c room = createRoom(prop.Id);
        insert room;
        insert buildReservation(room.Id, Date.newInstance(2026, 8, 1), Date.newInstance(2026, 8, 20));

        Reservation__c nested = buildReservation(room.Id, Date.newInstance(2026, 8, 5), Date.newInstance(2026, 8, 10));

        Test.startTest();
        DmlException error = insertAndCaptureError(nested);
        Test.stopTest();

        System.assertNotEquals(null, error, 'Una reserva anidada dentro de otra debe fallar');
    }

    @isTest
    private static void no_puede_crear_reserva_si_envuelve_completamente_a_otra() {
        Property__c prop = createProperty();
        insert prop;
        Room__c room = createRoom(prop.Id);
        insert room;
        insert buildReservation(room.Id, Date.newInstance(2026, 8, 5), Date.newInstance(2026, 8, 10));

        Reservation__c enclosing = buildReservation(room.Id, Date.newInstance(2026, 8, 1), Date.newInstance(2026, 8, 20));

        Test.startTest();
        DmlException error = insertAndCaptureError(enclosing);
        Test.stopTest();

        System.assertNotEquals(null, error, 'Una reserva que envuelve completamente a otra debe fallar');
    }

    @isTest
    private static void no_puede_crear_reserva_si_se_solapa_al_inicio() {
        Property__c prop = createProperty();
        insert prop;
        Room__c room = createRoom(prop.Id);
        insert room;
        insert buildReservation(room.Id, Date.newInstance(2026, 8, 10), Date.newInstance(2026, 8, 15));

        Reservation__c overlapsStart = buildReservation(room.Id, Date.newInstance(2026, 8, 5), Date.newInstance(2026, 8, 12));

        Test.startTest();
        DmlException error = insertAndCaptureError(overlapsStart);
        Test.stopTest();

        System.assertNotEquals(null, error, 'Una reserva que se solapa al inicio debe fallar');
    }

    @isTest
    private static void no_puede_crear_reserva_si_se_solapa_al_final() {
        Property__c prop = createProperty();
        insert prop;
        Room__c room = createRoom(prop.Id);
        insert room;
        insert buildReservation(room.Id, Date.newInstance(2026, 8, 10), Date.newInstance(2026, 8, 15));

        Reservation__c overlapsEnd = buildReservation(room.Id, Date.newInstance(2026, 8, 13), Date.newInstance(2026, 8, 20));

        Test.startTest();
        DmlException error = insertAndCaptureError(overlapsEnd);
        Test.stopTest();

        System.assertNotEquals(null, error, 'Una reserva que se solapa al final debe fallar');
    }

    @isTest
    private static void no_puede_crear_reserva_con_las_mismas_fechas_exactas() {
        Property__c prop = createProperty();
        insert prop;
        Room__c room = createRoom(prop.Id);
        insert room;
        insert buildReservation(room.Id, Date.newInstance(2026, 8, 10), Date.newInstance(2026, 8, 15));

        Reservation__c sameDates = buildReservation(room.Id, Date.newInstance(2026, 8, 10), Date.newInstance(2026, 8, 15));

        Test.startTest();
        DmlException error = insertAndCaptureError(sameDates);
        Test.stopTest();

        System.assertNotEquals(null, error, 'Dos reservas con las mismas fechas exactas deben fallar');
    }

    @isTest
    private static void no_puede_editar_reserva_para_que_quede_solapada_con_otra() {
        Property__c prop = createProperty();
        insert prop;
        Room__c room = createRoom(prop.Id);
        insert room;
        insert buildReservation(room.Id, Date.newInstance(2026, 8, 10), Date.newInstance(2026, 8, 15));

        Reservation__c toEdit = buildReservation(room.Id, Date.newInstance(2026, 9, 1), Date.newInstance(2026, 9, 5));
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
        Property__c prop = createProperty();
        insert prop;
        Room__c room = createRoom(prop.Id);
        insert room;
        insert buildReservation(room.Id, Date.newInstance(2026, 8, 10), Date.newInstance(2026, 8, 15));

        Reservation__c before = buildReservation(room.Id, Date.newInstance(2026, 7, 1), Date.newInstance(2026, 7, 5));

        Test.startTest();
        DmlException error = insertAndCaptureError(before);
        Test.stopTest();

        System.assertEquals(null, error, 'Una reserva completamente antes de otra no debe fallar');
    }

    @isTest
    private static void puede_crear_reserva_completamente_despues_de_otra() {
        Property__c prop = createProperty();
        insert prop;
        Room__c room = createRoom(prop.Id);
        insert room;
        insert buildReservation(room.Id, Date.newInstance(2026, 8, 10), Date.newInstance(2026, 8, 15));

        Reservation__c after = buildReservation(room.Id, Date.newInstance(2026, 9, 1), Date.newInstance(2026, 9, 5));

        Test.startTest();
        DmlException error = insertAndCaptureError(after);
        Test.stopTest();

        System.assertEquals(null, error, 'Una reserva completamente después de otra no debe fallar');
    }

    @isTest
    private static void puede_crear_reserva_en_otra_habitacion_con_mismas_fechas() {
        Property__c prop = createProperty();
        insert prop;
        Room__c room1 = createRoom(prop.Id);
        Room__c room2 = createRoom(prop.Id);
        insert new List<Room__c>{ room1, room2 };
        insert buildReservation(room1.Id, Date.newInstance(2026, 8, 10), Date.newInstance(2026, 8, 15));

        Reservation__c sameDatesOtherRoom = buildReservation(room2.Id, Date.newInstance(2026, 8, 10), Date.newInstance(2026, 8, 15));

        Test.startTest();
        DmlException error = insertAndCaptureError(sameDatesOtherRoom);
        Test.stopTest();

        System.assertEquals(null, error, 'El solapamiento debe validarse por habitación, no de forma global');
    }

    @isTest
    private static void puede_editar_reserva_sin_cambiar_fechas_sin_disparar_falso_positivo() {
        Property__c prop = createProperty();
        insert prop;
        Room__c room = createRoom(prop.Id);
        insert room;
        Reservation__c reservation = buildReservation(room.Id, Date.newInstance(2026, 8, 10), Date.newInstance(2026, 8, 15));
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
        Property__c prop = createProperty();
        insert prop;
        Room__c room = createRoom(prop.Id);
        insert room;
        insert buildReservation(room.Id, Date.newInstance(2026, 8, 10), Date.newInstance(2026, 8, 15));

        Reservation__c backToBack = buildReservation(room.Id, Date.newInstance(2026, 8, 15), Date.newInstance(2026, 8, 20));

        Test.startTest();
        DmlException error = insertAndCaptureError(backToBack);
        Test.stopTest();

        System.assertEquals(null, error, 'El mismo día de checkout/checkin no debe contar como solapamiento');
    }

    @isTest
    private static void no_bloquea_solapamiento_si_la_reserva_existente_esta_cancelled() {
        Property__c prop = createProperty();
        insert prop;
        Room__c room = createRoom(prop.Id);
        insert room;
        insert buildReservation(room.Id, Date.newInstance(2026, 8, 10), Date.newInstance(2026, 8, 15), 'Cancelled');

        Reservation__c overlapping = buildReservation(room.Id, Date.newInstance(2026, 8, 12), Date.newInstance(2026, 8, 18));

        Test.startTest();
        DmlException error = insertAndCaptureError(overlapping);
        Test.stopTest();

        System.assertEquals(null, error, 'Una reserva Cancelled no debe bloquear la habitación');
    }

    // ── Bulk ─────────────────────────────────────────────────────────────────

    @isTest
    private static void permite_insertar_200_reservas_sin_solapamientos_en_bulk() {
        Property__c prop = createProperty();
        insert prop;
        Room__c room = createRoom(prop.Id);
        insert room;

        List<Reservation__c> reservations = new List<Reservation__c>();
        for (Integer i = 0; i < 200; i++) {
            Date checkIn = Date.newInstance(2026, 1, 1).addDays(i * 2);
            Date checkOut = checkIn.addDays(1);
            reservations.add(buildReservation(room.Id, checkIn, checkOut));
        }

        Test.startTest();
        insert reservations;
        Test.stopTest();

        System.assertEquals(200, [SELECT COUNT() FROM Reservation__c], 'Las 200 reservas sin solapamientos deben insertarse');
    }

    @isTest
    private static void bloquea_solapamientos_entre_registros_del_mismo_batch() {
        Property__c prop = createProperty();
        insert prop;
        Room__c room = createRoom(prop.Id);
        insert room;

        List<Reservation__c> reservations = new List<Reservation__c>{
            buildReservation(room.Id, Date.newInstance(2026, 8, 10), Date.newInstance(2026, 8, 15)),
            buildReservation(room.Id, Date.newInstance(2026, 8, 12), Date.newInstance(2026, 8, 18))
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
