import { createElement } from "lwc";
import KanbanCard from "c/kanbanCard";

const TASK_WITH_ONE_TARGET = {
  id: "a0X000000000001AAA",
  description: "Cambiar filtro de aire",
  priority: "High",
  dueDate: "2026-08-01",
  status: "Pending",
  moveTargets: [{ value: "In Progress", label: "In Progress" }]
};

const TASK_WITH_TWO_TARGETS = {
  id: "a0X000000000002AAA",
  description: "Revisar cañería",
  priority: "Medium",
  dueDate: "2026-08-10",
  status: "In Progress",
  moveTargets: [
    { value: "Pending", label: "◀ Pending" },
    { value: "Done", label: "Done ▶" }
  ]
};

describe("c-kanban-card", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("muestra la descripción, prioridad y fecha límite de la tarea", () => {
    const element = createElement("c-kanban-card", { is: KanbanCard });
    element.task = TASK_WITH_ONE_TARGET;
    document.body.appendChild(element);

    expect(element.shadowRoot.textContent).toContain("Cambiar filtro de aire");
    expect(element.shadowRoot.textContent).toContain("High");
    expect(element.shadowRoot.textContent).toContain("2026-08-01");
  });

  it("renderiza un botón por cada moveTarget", () => {
    const element = createElement("c-kanban-card", { is: KanbanCard });
    element.task = TASK_WITH_TWO_TARGETS;
    document.body.appendChild(element);

    const buttons = element.shadowRoot.querySelectorAll("lightning-button");
    expect(buttons.length).toBe(2);
    expect(buttons[0].label).toBe("◀ Pending");
    expect(buttons[1].label).toBe("Done ▶");
  });

  it("dispara taskmove con el taskId y el estado del botón clickeado", () => {
    const element = createElement("c-kanban-card", { is: KanbanCard });
    element.task = TASK_WITH_TWO_TARGETS;
    document.body.appendChild(element);

    const handler = jest.fn();
    element.addEventListener("taskmove", handler);

    const doneButton =
      element.shadowRoot.querySelectorAll("lightning-button")[1];
    doneButton.dispatchEvent(new CustomEvent("click"));

    expect(handler).toHaveBeenCalledTimes(1);
    expect(handler.mock.calls[0][0].detail).toEqual({
      taskId: TASK_WITH_TWO_TARGETS.id,
      newStatus: "Done"
    });
  });

  it("no renderiza ningún botón cuando moveTargets está vacío", () => {
    const element = createElement("c-kanban-card", { is: KanbanCard });
    element.task = { ...TASK_WITH_ONE_TARGET, moveTargets: [] };
    document.body.appendChild(element);

    expect(element.shadowRoot.querySelectorAll("lightning-button").length).toBe(
      0
    );
  });
});
