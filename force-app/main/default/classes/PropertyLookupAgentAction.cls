/**
 * Historia 6 (Agentforce): acción invocable que expone la búsqueda de
 * propiedades como GenAiFunction. Devuelve candidatas por dirección o ciudad
 * en vez de resolver una propiedad puntual, porque `Property__c.Name` es
 * AutoNumber (PR-{000}) y nadie va a decirle eso a un agente en Slack.
 *
 * Existe porque `MaintenanceTaskAgentAction` y `RoomAvailabilityAgentAction`
 * necesitan un Id de propiedad y el usuario solo tiene una dirección: el
 * agente encadena esta acción primero, y si hay más de una candidata, le
 * repregunta al usuario cuál es antes de seguir.
 */
public with sharing class PropertyLookupAgentAction {
  public class Request {
    @InvocableVariable(
      label='Texto de búsqueda'
      description='Dirección o ciudad de la propiedad, tal como la mencionó el usuario. Por ejemplo "Santa Fe 1200" o "Palermo".'
      required=true
    )
    public String searchTerm;
  }

  public class PropertyCandidate {
    @InvocableVariable(
      description='Id de la propiedad. Usar este valor, no el nombre, en las demás acciones.'
    )
    public Id propertyId;

    @InvocableVariable(description='Dirección de la propiedad.')
    public String address;

    @InvocableVariable(description='Ciudad de la propiedad.')
    public String city;

    @InvocableVariable(description='Cantidad de habitaciones de la propiedad.')
    public Decimal roomCount;
  }

  public class Response {
    @InvocableVariable(
      description='Propiedades que coinciden con la búsqueda. Si hay más de una, hay que preguntarle al usuario cuál es antes de usarla en otra acción.'
    )
    public List<PropertyCandidate> candidates = new List<PropertyCandidate>();

    @InvocableVariable(
      description='Mensaje para el usuario cuando no se encontró ninguna coincidencia.'
    )
    public String message;
  }

  @InvocableMethod(
    label='Buscar propiedad'
    description='Busca propiedades por dirección o ciudad. Usar esta acción primero, antes de crear una tarea de mantenimiento o consultar disponibilidad: esas acciones necesitan el Id de la propiedad, no su dirección.'
    category='AdminSpaces'
  )
  public static List<Response> search(List<Request> requests) {
    List<Property__c> allProperties = PropertySelector.getForSearch();

    List<Response> responses = new List<Response>();
    for (Request req : requests) {
      Response resp = new Response();
      String term = req.searchTerm == null
        ? ''
        : req.searchTerm.trim().toLowerCase();

      if (String.isNotBlank(term)) {
        for (Property__c prop : allProperties) {
          if (matches(prop, term)) {
            PropertyCandidate candidate = new PropertyCandidate();
            candidate.propertyId = prop.Id;
            candidate.address = prop.Address__c;
            candidate.city = prop.City__c;
            candidate.roomCount = prop.Room_Count__c;
            resp.candidates.add(candidate);
          }
        }
      }

      if (resp.candidates.isEmpty()) {
        resp.message = System.Label.Agent_Property_Not_Found;
      }
      responses.add(resp);
    }
    return responses;
  }

  private static Boolean matches(Property__c prop, String term) {
    return (prop.Address__c != null &&
      prop.Address__c.toLowerCase().contains(term)) ||
      (prop.City__c != null && prop.City__c.toLowerCase().contains(term));
  }
}
