import { LightningElement, api } from "lwc";

export default class KanbanColumn extends LightningElement {
  @api columnLabel;
  @api tasks;

  handleTaskMove(event) {
    this.dispatchEvent(new CustomEvent("taskmove", { detail: event.detail }));
  }
}
