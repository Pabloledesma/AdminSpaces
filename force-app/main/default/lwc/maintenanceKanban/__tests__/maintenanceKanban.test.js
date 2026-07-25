import { createElement } from "lwc";
import MaintenanceKanban from "c/maintenanceKanban";
import getTasksForProperty from "@salesforce/apex/MaintenanceTaskBoardController.getTasksForProperty";
import getTaskStatusOptions from "@salesforce/apex/MaintenanceTaskBoardController.getTaskStatusOptions";
import updateTaskStatus from "@salesforce/apex/MaintenanceTaskBoardController.updateTaskStatus";
import { refreshApex } from "@salesforce/apex";
import { subscribe } from "lightning/empApi";

jest.mock(
  "@salesforce/apex",
  () => ({
    refreshApex: jest.fn()
  }),
  { virtual: true }
);

const STATUS_OPTIONS = [
  { value: "Pending", label: "Pending" },
  { value: "In Progress", label: "In Progress" },
  { value: "Done", label: "Done" }
];

const TASKS = [
  {
    Id: "a0X000000000001AAA",
    Description__c: "Tarea 1",
    Priority__c: "High",
    Due_Date__c: "2026-08-01",
    Status__c: "Pending"
  },
  {
    Id: "a0X000000000002AAA",
    Description__c: "Tarea 2",
    Priority__c: "Low",
    Due_Date__c: "2026-08-05",
    Status__c: "In Progress"
  }
];

describe("c-maintenance-kanban", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("renderiza una columna por cada estado del picklist", async () => {
    const element = createElement("c-maintenance-kanban", {
      is: MaintenanceKanban
    });
    element.recordId = "a06000000000001AAA";
    document.body.appendChild(element);

    getTaskStatusOptions.emit(STATUS_OPTIONS);
    getTasksForProperty.emit(TASKS);
    await Promise.resolve();
    await Promise.resolve();

    const columns = element.shadowRoot.querySelectorAll("c-kanban-column");
    expect(columns.length).toBe(3);
  });

  it("calcula moveTargets como el estado anterior/siguiente en el orden del picklist", async () => {
    const element = createElement("c-maintenance-kanban", {
      is: MaintenanceKanban
    });
    element.recordId = "a06000000000001AAA";
    document.body.appendChild(element);

    getTaskStatusOptions.emit(STATUS_OPTIONS);
    getTasksForProperty.emit(TASKS);
    await Promise.resolve();
    await Promise.resolve();

    const inProgressColumn =
      element.shadowRoot.querySelectorAll("c-kanban-column")[1];
    expect(inProgressColumn.tasks).toHaveLength(1);
    expect(inProgressColumn.tasks[0].moveTargets).toEqual([
      { value: "Pending", label: "Pending" },
      { value: "Done", label: "Done" }
    ]);
  });

  it("llama a updateTaskStatus y refresca la lista cuando una columna emite taskmove", async () => {
    updateTaskStatus.mockResolvedValue();
    const element = createElement("c-maintenance-kanban", {
      is: MaintenanceKanban
    });
    element.recordId = "a06000000000001AAA";
    document.body.appendChild(element);

    getTaskStatusOptions.emit(STATUS_OPTIONS);
    getTasksForProperty.emit(TASKS);
    await Promise.resolve();
    await Promise.resolve();

    const column = element.shadowRoot.querySelector("c-kanban-column");
    column.dispatchEvent(
      new CustomEvent("taskmove", {
        detail: { taskId: "a0X000000000001AAA", newStatus: "In Progress" }
      })
    );
    await Promise.resolve();
    await Promise.resolve();

    expect(updateTaskStatus).toHaveBeenCalledWith({
      taskId: "a0X000000000001AAA",
      newStatus: "In Progress",
      propertyId: "a06000000000001AAA"
    });
    expect(refreshApex).toHaveBeenCalledTimes(1);
  });

  it("refresca las tareas cuando llega un evento para la misma propiedad", async () => {
    const element = createElement("c-maintenance-kanban", {
      is: MaintenanceKanban
    });
    element.recordId = "a06000000000001AAA";
    document.body.appendChild(element);

    getTaskStatusOptions.emit(STATUS_OPTIONS);
    getTasksForProperty.emit(TASKS);
    await Promise.resolve();
    await Promise.resolve();

    const messageCallback = subscribe.mock.calls[0][2];
    messageCallback({
      data: { payload: { Property_Id__c: "a06000000000001AAA" } }
    });
    await Promise.resolve();

    expect(refreshApex).toHaveBeenCalledTimes(1);
  });

  it("ignora el evento si es de otra propiedad", async () => {
    const element = createElement("c-maintenance-kanban", {
      is: MaintenanceKanban
    });
    element.recordId = "a06000000000001AAA";
    document.body.appendChild(element);

    getTaskStatusOptions.emit(STATUS_OPTIONS);
    getTasksForProperty.emit(TASKS);
    await Promise.resolve();
    await Promise.resolve();

    const messageCallback = subscribe.mock.calls[0][2];
    messageCallback({
      data: { payload: { Property_Id__c: "a06999999999999AAA" } }
    });
    await Promise.resolve();

    expect(refreshApex).not.toHaveBeenCalled();
  });

  it("muestra un mensaje de error si falla mover la tarea", async () => {
    updateTaskStatus.mockRejectedValue({
      body: { message: "No tenés permiso para mover esta tarea." }
    });

    const element = createElement("c-maintenance-kanban", {
      is: MaintenanceKanban
    });
    element.recordId = "a06000000000001AAA";
    document.body.appendChild(element);

    getTaskStatusOptions.emit(STATUS_OPTIONS);
    getTasksForProperty.emit(TASKS);
    await Promise.resolve();
    await Promise.resolve();

    const column = element.shadowRoot.querySelector("c-kanban-column");
    column.dispatchEvent(
      new CustomEvent("taskmove", {
        detail: { taskId: "a0X000000000001AAA", newStatus: "In Progress" }
      })
    );
    await Promise.resolve();
    await Promise.resolve();

    expect(element.shadowRoot.textContent).toContain(
      "No tenés permiso para mover esta tarea."
    );
  });
});
