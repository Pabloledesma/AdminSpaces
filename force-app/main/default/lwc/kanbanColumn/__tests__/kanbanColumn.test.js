import { createElement } from "@lwc/engine-dom";
import KanbanColumn from "c/kanbanColumn";

const TASKS = [
  {
    id: "a0X000000000001AAA",
    description: "Tarea 1",
    priority: "High",
    dueDate: "2026-08-01",
    status: "Pending",
    moveTargets: []
  },
  {
    id: "a0X000000000002AAA",
    description: "Tarea 2",
    priority: "Low",
    dueDate: "2026-08-05",
    status: "Pending",
    moveTargets: []
  }
];

describe("c-kanban-column", () => {
  afterEach(() => {
    // The jsdom instance is shared across test cases in a single file so reset the DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("muestra el titulo de la columna y una tarjeta por tarea", () => {
    const element = createElement("c-kanban-column", { is: KanbanColumn });
    element.columnLabel = "Pending";
    element.tasks = TASKS;
    document.body.appendChild(element);

    expect(element.shadowRoot.textContent).toContain("Pending");
    expect(element.shadowRoot.querySelectorAll("c-kanban-card").length).toBe(2);
  });

  it("re-emite taskmove cuando una tarjeta lo dispara", () => {
    const element = createElement("c-kanban-column", { is: KanbanColumn });
    element.columnLabel = "Pending";
    element.tasks = TASKS;
    document.body.appendChild(element);

    const handler = jest.fn();
    element.addEventListener("taskmove", handler);

    const card = element.shadowRoot.querySelector("c-kanban-card");
    card.dispatchEvent(
      new CustomEvent("taskmove", {
        detail: { taskId: TASKS[0].id, newStatus: "In Progress" }
      })
    );

    expect(handler).toHaveBeenCalledTimes(1);
    expect(handler.mock.calls[0][0].detail).toEqual({
      taskId: TASKS[0].id,
      newStatus: "In Progress"
    });
  });
});
