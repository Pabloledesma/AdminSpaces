/**
 * Historia 6.2 (Agentforce): crea una Maintenance_Task__c a partir de un
 * problema reportado en lenguaje natural. GenAiFunction invocable, bulk-safe:
 * resuelve todas las habitaciones con una sola query (RoomSelector.getByNames)
 * y hace un único Database.insert(allOrNone=false) al final, sin SOQL ni DML
 * dentro del loop de requests.
 *
 * A diferencia de Property__c/Room__c, `Maintenance_Task__c.Name` NO es
 * AutoNumber — es texto libre, y Salesforce lo acepta vacío (verificado
 * contra el org). Se genera acá a partir de la descripción, truncada a los
 * 80 caracteres del campo, para no dejar tareas sin identificador en
 * ninguna list view o reporte estándar.
 */

public with sharing class MaintenanceTaskAgentAction {
  private static final String DEFAULT_PRIORITY = 'Medium';
  private static final Integer MAX_NAME_LENGTH = 80;

  public class Request {
    @InvocableVariable(
      label='Id de la propiedad'
      description='Id de la propiedad donde está el problema. Se obtiene primero con la acción Buscar propiedad.'
      required=true
    )
    public Id propertyId;

    @InvocableVariable(
      label='Habitación'
      description='Código de la habitación afectada, por ejemplo R-0002. Dejar vacío si el problema es de la propiedad en general, no de una habitación puntual.'
    )
    public String roomName;

    @InvocableVariable(
      label='Descripción del problema'
      description='Descripción del problema reportado, en las palabras del usuario.'
      required=true
    )
    public String description;

    @InvocableVariable(
      label='Prioridad'
      description='Prioridad de la tarea: Low, Medium, High o Urgent. Si no se especifica, se usa Medium.'
    )
    public String priority;
  }

  public class Response {
    @InvocableVariable(description='true si la tarea se creó correctamente.')
    public Boolean created = false;

    @InvocableVariable(
      description='Título de la tarea creada (derivado de la descripción). Vacío si no se creó.'
    )
    public String taskName;

    @InvocableVariable(
      description='Link directo a la tarea en Salesforce, para que el usuario pueda abrirla y hacerle seguimiento. Vacío si no se creó.'
    )
    public String taskUrl;

    @InvocableVariable(
      description='Motivo por el que no se pudo crear la tarea. Vacío si se creó con éxito.'
    )
    public String message;
  }

  @InvocableMethod(
    label='Crear tarea de mantenimiento'
    description='Crea una tarea de mantenimiento para una propiedad, opcionalmente asociada a una habitación. Usar cuando alguien reporta un problema de mantenimiento en lenguaje natural.'
    category='AdminSpaces'
  )
  public static List<Response> createTask(List<Request> requests) {
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
    List<Maintenance_Task__c> tasksToInsert = new List<Maintenance_Task__c>();
    // índice en tasksToInsert -> índice en responses: los requests inválidos
    // (prioridad o habitación mal) nunca llegan a esta lista, así que hace
    // falta este mapeo para devolverle el resultado del insert a la Response
    // correcta y no a la que está en esa misma posición del array.

    List<Integer> responseIndexByTaskIndex = new List<Integer>();

    for (Integer i = 0; i < requests.size(); i++) {
      Request req = requests[i];
      Response resp = new Response();
      responses.add(resp);

      String priority = String.isBlank(req.priority)
        ? DEFAULT_PRIORITY
        : req.priority.trim();
      if (!MaintenanceTaskPriorityService.isValidPriority(priority)) {
        resp.message = String.format(
          System.Label.Agent_Maintenance_Invalid_Priority,
          new List<String>{
            priority,
            String.join(
              MaintenanceTaskPriorityService.getValidPriorityValues(),
              ', '
            )
          }
        );
        continue;
      }

      Id roomId = null;
      if (String.isNotBlank(req.roomName)) {
        Room__c room = roomsByName.get(req.roomName.trim());
        if (room == null || room.Property__c != req.propertyId) {
          resp.message = String.format(
            System.Label.Agent_Maintenance_Room_Not_In_Property,
            new List<String>{ req.roomName }
          );
          continue;
        }
        roomId = room.Id;
      }

      Maintenance_Task__c task = new Maintenance_Task__c(
        Name = buildTaskName(req.description),
        Property__c = req.propertyId,
        Room__c = roomId,
        Description__c = req.description,
        Priority__c = priority,
        Status__c = 'Pending'
      );
      tasksToInsert.add(task);
      responseIndexByTaskIndex.add(i);
    }

    if (tasksToInsert.isEmpty()) {
      return responses;
    }

    // allOrNone=false, mismo criterio que RoomCheckoutScheduler: un problema de
    // DB en un registro no tiene por qué frenar el resto del batch.
    List<Database.SaveResult> saveResults = Database.insert(
      tasksToInsert,
      false
    );
    for (Integer taskIdx = 0; taskIdx < saveResults.size(); taskIdx++) {
      Response resp = responses[responseIndexByTaskIndex[taskIdx]];
      if (saveResults[taskIdx].isSuccess()) {
        resp.created = true;
        resp.taskName = tasksToInsert[taskIdx].Name;
        resp.taskUrl =
          URL.getOrgDomainUrl().toExternalForm() +
          '/lightning/r/Maintenance_Task__c/' +
          tasksToInsert[taskIdx].Id +
          '/view';
      } else {
        resp.message = saveResults[taskIdx].getErrors()[0].getMessage();
      }
    }

    return responses;
  }

  private static String buildTaskName(String description) {
    String trimmed = description == null ? '' : description.trim();
    if (trimmed.length() <= MAX_NAME_LENGTH) {
      return trimmed;
    }
    return trimmed.left(MAX_NAME_LENGTH - 1) + '…';
  }
}
