import { LightningElement, api, wire } from "lwc";
import { refreshApex } from "@salesforce/apex";
import { subscribe, unsubscribe, onError } from "lightning/empApi";
import getTasksForProperty from "@salesforce/apex/MaintenanceTaskBoardController.getTasksForProperty";
import getTaskStatusOptions from "@salesforce/apex/MaintenanceTaskBoardController.getTaskStatusOptions";
import updateTaskStatus from "@salesforce/apex/MaintenanceTaskBoardController.updateTaskStatus";

const CHANNEL = "/event/Maintenance_Task_Moved__e";

export default class MaintenanceKanban extends LightningElement {
  @api recordId;

  statusOptions;
  tasksResult;
  tasks;
  subscription;
  moveError;

  connectedCallback() {
    subscribe(CHANNEL, -1, (message) => {
      this.handlePlatformEvent(message);
    }).then((response) => {
      this.subscription = response;
    });

    onError((error) => {
      console.error("Error de EMP API", JSON.stringify(error));
    });
  }

  disconnectedCallback() {
    if (this.subscription) {
      unsubscribe(this.subscription);
    }
  }

  handlePlatformEvent(message) {
    const propertyId = message.data.payload.Property_Id__c;
    if (propertyId === this.recordId) {
      refreshApex(this.tasksResult);
    }
  }

  @wire(getTaskStatusOptions)
  wiredStatusOptions({ data }) {
    if (data) {
      this.statusOptions = data;
    }
  }

  @wire(getTasksForProperty, { propertyId: "$recordId" })
  wiredTasks(result) {
    this.tasksResult = result;
    if (result.data) {
      this.tasks = result.data;
    }
  }

  get columns() {
    if (!this.statusOptions || !this.tasks) {
      return [];
    }
    return this.statusOptions.map((option, index) => ({
      value: option.value,
      label: option.label,
      tasks: this.tasks
        .filter((task) => task.Status__c === option.value)
        .map((task) => ({
          id: task.Id,
          description: task.Description__c,
          priority: task.Priority__c,
          dueDate: task.Due_Date__c,
          status: task.Status__c,
          moveTargets: this.getMoveTargets(index)
        }))
    }));
  }

  getMoveTargets(index) {
    const targets = [];
    if (index > 0) {
      targets.push(this.statusOptions[index - 1]);
    }
    if (index < this.statusOptions.length - 1) {
      targets.push(this.statusOptions[index + 1]);
    }
    return targets;
  }

  async handleTaskMove(event) {
    const { taskId, newStatus } = event.detail;
    this.moveError = undefined;
    try {
      await updateTaskStatus({ taskId, newStatus, propertyId: this.recordId });
      await refreshApex(this.tasksResult);
    } catch (error) {
      this.moveError =
        error.body?.message ?? "Ocurrió un error inesperado al mover la tarea";
    }
  }
}
