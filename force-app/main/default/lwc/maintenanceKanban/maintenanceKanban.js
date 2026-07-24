import { LightningElement, api, wire } from "lwc";
import { refreshApex } from "@salesforce/apex";
import getTasksForProperty from "@salesforce/apex/MaintenanceTaskBoardController.getTasksForProperty";
import getTaskStatusOptions from "@salesforce/apex/MaintenanceTaskBoardController.getTaskStatusOptions";
import updateTaskStatus from "@salesforce/apex/MaintenanceTaskBoardController.updateTaskStatus";

export default class MaintenanceKanban extends LightningElement {
  @api recordId;

  statusOptions;
  tasksResult;
  tasks;

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
    await updateTaskStatus({ taskId, newStatus });
    await refreshApex(this.tasksResult);
  }
}
