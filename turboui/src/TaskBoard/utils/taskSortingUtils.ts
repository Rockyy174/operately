import * as Types from "../types";

/**
 * Sorts tasks based on their kanban state index within their milestone
 * Tasks without milestones are sorted by their creation order (by id)
 */
export function sortTasksByKanbanIndex(tasks: Types.Task[], milestones: Types.Milestone[]): Types.Task[] {
  // Create a map of milestone ID to milestone for quick lookup
  const milestoneMap = new Map(milestones.map(m => [m.id, m]));
  
  // Group tasks by milestone
  const tasksByMilestone = new Map<string | null, Types.Task[]>();
  
  tasks.forEach(task => {
    const milestoneId = task.milestone?.id || null;
    if (!tasksByMilestone.has(milestoneId)) {
      tasksByMilestone.set(milestoneId, []);
    }
    tasksByMilestone.get(milestoneId)!.push(task);
  });
  
  const sortedTasks: Types.Task[] = [];
  
  // Sort tasks within each milestone based on kanban state
  tasksByMilestone.forEach((milestoneTasks, milestoneId) => {
    if (milestoneId === null) {
      // Tasks without milestone - sort by id (creation order)
      const sorted = milestoneTasks.sort((a, b) => a.id.localeCompare(b.id));
      sortedTasks.push(...sorted);
    } else {
      // Tasks with milestone - sort by kanban state index
      const milestone = milestoneMap.get(milestoneId);
      if (milestone && (milestone as any).tasksKanbanState) {
        const kanbanState = (milestone as any).tasksKanbanState;
        const sorted = sortTasksByKanbanState(milestoneTasks, kanbanState);
        sortedTasks.push(...sorted);
      } else {
        // Fallback to id sorting if no kanban state
        const sorted = milestoneTasks.sort((a, b) => a.id.localeCompare(b.id));
        sortedTasks.push(...sorted);
      }
    }
  });
  
  return sortedTasks;
}

/**
 * Sorts tasks within a milestone based on their position in the kanban state
 */
function sortTasksByKanbanState(tasks: Types.Task[], kanbanState: any): Types.Task[] {
  // Create a map of task ID to task for quick lookup
  const taskMap = new Map(tasks.map(task => [task.id, task]));
  
  // Create an ordered list based on kanban state
  const orderedTasks: Types.Task[] = [];
  const processedTaskIds = new Set<string>();
  
  // Process each status column in order
  const statusOrder = ['todo', 'in_progress', 'done'];
  
  statusOrder.forEach(status => {
    const taskIds = kanbanState[status] || [];
    taskIds.forEach((taskId: string) => {
      const task = taskMap.get(taskId);
      if (task && !processedTaskIds.has(taskId)) {
        orderedTasks.push(task);
        processedTaskIds.add(taskId);
      }
    });
  });
  
  // Add any remaining tasks that weren't in the kanban state
  tasks.forEach(task => {
    if (!processedTaskIds.has(task.id)) {
      orderedTasks.push(task);
    }
  });
  
  return orderedTasks;
}

/**
 * Gets the kanban index for a task within its milestone
 */
export function getTaskKanbanIndex(taskId: string, milestoneKanbanState: any, status: string): number {
  if (!milestoneKanbanState || !milestoneKanbanState[status]) {
    return 0;
  }
  
  const taskIds = milestoneKanbanState[status];
  const index = taskIds.indexOf(taskId);
  return index >= 0 ? index : taskIds.length;
}
