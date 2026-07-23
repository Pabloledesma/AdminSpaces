import { LightningElement, api } from "lwc";

export default class KanbanCard extends LightningElement {
  @api task;

  handleMove(event) {
    const newStatus = event.target.dataset.value;
    this.dispatchEvent(
      new CustomEvent("taskmove", {
        detail: {
          taskId: this.task.id,
          newStatus
        }
      })
    );
  }
}
