/**
 * Historia 6.1 (Agentforce): consulta si una habitación está disponible en
 * un rango de fechas. GenAiFunction invocable que delega en
 * RoomAvailabilityController.checkAvailability en vez de reimplementar la
 * regla de solapamiento.
 *
 * Es la única de las tres acciones que sí ejecuta una SOQL por request (vía
 * checkAvailability -> ReservationSelector): la alternativa sería duplicar
 * ReservationOverlapValidator acá para resolver todo en una sola query, y se
 * prefirió reusar lógica ya probada. A la escala real (el agente llama de a
 * un request; Flow, que sí manda lotes, sigue acotado por el límite de 100
 * SOQL) es un costo aceptado.
 */
public with sharing class RoomAvailabilityAgentAction {
  public class Request {
    @InvocableVariable(
      label='Id de la propiedad'
      description='Id de la propiedad donde está la habitación. Se obtiene primero con la acción Buscar propiedad.'
      required=true
    )
    public Id propertyId;

    @InvocableVariable(
      label='Habitación'
      description='Código de la habitación a consultar, por ejemplo R-0002.'
      required=true
    )
    public String roomName;

    @InvocableVariable(
      label='Check-in'
      description='Fecha de entrada.'
      required=true
    )
    public Date checkIn;

    @InvocableVariable(
      label='Check-out'
      description='Fecha de salida. Tiene que ser posterior al check-in.'
      required=true
    )
    public Date checkOut;
  }

  public class Response {
    @InvocableVariable(
      description='true si la habitación está disponible en ese rango de fechas.'
    )
    public Boolean available = false;

    @InvocableVariable(
      description='Motivo cuando no está disponible o la consulta no se pudo resolver. Vacío si está disponible.'
    )
    public String message;
  }

  @InvocableMethod(
    label='Consultar disponibilidad de habitación'
    description='Indica si una habitación de una propiedad está disponible en un rango de fechas. Usar cuando alguien pregunta si puede reservar o si hay lugar en determinadas fechas.'
    category='AdminSpaces'
  )
  public static List<Response> check(List<Request> requests) {
    Set<String> roomNames = new Set<String>();
    for (Request req : requests) {
      if (String.isNotBlank(req.roomName)) {
        roomNames.add(req.roomName.trim());
      }
    }

    Map<String, Room__c> roomsByName = new Map<String, Room__c>();
    for (Room__c room : RoomSelector.getByNames(roomNames)) {
      roomsByName.put(room.Name, room);
    }

    List<Response> responses = new List<Response>();
    for (Request req : requests) {
      Response resp = new Response();
      responses.add(resp);

      Room__c room = String.isBlank(req.roomName)
        ? null
        : roomsByName.get(req.roomName.trim());
      if (room == null || room.Property__c != req.propertyId) {
        resp.message = String.format(
          System.Label.Agent_Availability_Room_Not_Found,
          new List<String>{ req.roomName }
        );
        continue;
      }

      if (
        req.checkIn == null ||
        req.checkOut == null ||
        req.checkOut <= req.checkIn
      ) {
        resp.message = System.Label.Agent_Availability_Invalid_Dates;
        continue;
      }

      // 1 SOQL por request acá adentro, vía checkAvailability. A propósito:
      // la alternativa es reimplementar la regla de solapamiento en esta
      // clase, duplicando lógica ya probada en RoomAvailabilityController /
      // ReservationOverlapValidator.
      resp.available = RoomAvailabilityController.checkAvailability(
        room.Id,
        req.checkIn,
        req.checkOut
      );
      if (!resp.available) {
        resp.message = System.Label.Agent_Availability_Not_Available;
      }
    }

    return responses;
  }
}
