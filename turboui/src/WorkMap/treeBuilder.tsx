import { WorkMap } from "./index";
import { TimeframeSelector } from "../TimeframeSelector";
import { compareIds } from "../utils/ids";

// Define interfaces for Goal and Project that match the structure expected from the backend
interface Goal {
  id: string;
  parentId?: string;
  name: string;
  status: string;
  progress: number;
  deadline?: string;
  closedAt?: string;
  space: { name: string; isCompanySpace?: boolean };
  champion: {
    id: string;
    fullName: string;
    avatarUrl?: string;
  };
  reviewer?: {
    id: string;
    fullName: string;
    avatarUrl?: string;
  };
  nextStep?: string;
  timeframe: TimeframeSelector.Timeframe;
  completedOn?: string;
}

interface Project {
  id: string;
  parentId?: string;
  name: string;
  status: string;
  progress: number;
  deadline?: string;
  closedAt?: string;
  space: { name: string; isCompanySpace?: boolean };
  champion: {
    id: string;
    fullName: string;
    avatarUrl?: string;
  };
  reviewer?: {
    id: string;
    fullName: string;
    avatarUrl?: string;
  };
  nextStep?: string;
  startedAt: string;
  completedOn?: string;
}

export type SortColumn = "name" | "space" | "timeframe" | "progress" | "deadline" | "owner";
export type SortDirection = "asc" | "desc";

export interface TreeOptions {
  sortColumn: SortColumn;
  sortDirection: SortDirection;

  showActive: boolean;
  showPaused: boolean;
  showCompleted: boolean;

  showGoals: boolean;
  showProjects: boolean;

  ownedBy: "anyone" | "me";
  reviewedBy: "anyone" | "me";

  spaceId?: string;
  personId?: string;

  goalId?: string;
  timeframe?: TimeframeSelector.Timeframe;
}

export type Tree = WorkMap.Item[];

export function buildTree(me: WorkMap.Person, allGoals: Goal[], allProjects: Project[], options: TreeOptions): WorkMap.Item[] {
  return new TreeBuilder(me, allGoals, allProjects, options).build();
}

export function getAllIds(items: WorkMap.Item[]): string[] {
  return items.reduce((acc, item) => {
    return [...acc, item.id, ...(item.children ? getAllIds(item.children) : [])];
  }, [] as string[]);
}

class TreeBuilder {
  constructor(
    private me: WorkMap.Person,
    private allGoals: Goal[],
    private allProjects: Project[],
    private options: TreeOptions,
  ) {}

  private goalItems: WorkMap.GoalItem[] = [];
  private projectItems: WorkMap.ProjectItem[] = [];
  private items: WorkMap.Item[] = [];
  private rootItems: WorkMap.Item[] = [];

  build(): Tree {
    this.createItems();
    this.connectNodes();
    this.findRoots();
    this.sortNodes();

    this.rootItems = TreeFilter.filter(this.me, this.rootItems, this.options);
    this.setDepth();

    return this.rootItems;
  }

  setMeId(meId: string): void {
    this.me.id = meId;
  }

  private createItems(): void {
    this.goalItems = this.createGoalItems();
    this.projectItems = this.createProjectItems();

    this.items = [...this.goalItems, ...this.projectItems];
  }

  private createGoalItems(): WorkMap.GoalItem[] {
    if (this.options.showGoals) {
      return this.allGoals.map((g) => this.convertGoalToItem(g));
    } else {
      return [];
    }
  }

  private createProjectItems(): WorkMap.ProjectItem[] {
    if (this.options.showProjects) {
      return this.allProjects.map((p) => this.convertProjectToItem(p));
    } else {
      return [];
    }
  }

  private convertGoalToItem(goal: Goal): WorkMap.GoalItem {
    return {
      id: goal.id,
      parentId: goal.parentId,
      name: goal.name,
      status: this.convertStatus(goal.status),
      progress: goal.progress,
      deadline: goal.deadline ? { display: goal.deadline } : undefined,
      closedAt: goal.closedAt,
      space: goal.space.name,
      owner: {
        id: goal.champion.id,
        fullName: goal.champion.fullName,
        avatarUrl: goal.champion.avatarUrl
      },
      nextStep: goal.nextStep || "",
      type: "goal",
      timeframe: goal.timeframe,
      children: [],
      completedOn: goal.completedOn
    };
  }

  private convertProjectToItem(project: Project): WorkMap.ProjectItem {
    return {
      id: project.id,
      parentId: project.parentId,
      name: project.name,
      status: this.convertStatus(project.status),
      progress: project.progress,
      deadline: project.deadline ? { display: project.deadline } : undefined,
      closedAt: project.closedAt,
      space: project.space.name,
      owner: {
        id: project.champion.id,
        fullName: project.champion.fullName,
        avatarUrl: project.champion.avatarUrl
      },
      nextStep: project.nextStep || "",
      type: "project",
      startedAt: project.startedAt,
      children: [],
      completedOn: project.completedOn
    };
  }

  private convertStatus(status: string): WorkMap.Status {
    // This is a simplified conversion. You may need to adjust based on your actual status mapping
    return status as WorkMap.Status;
  }

  private connectNodes(): void {
    this.items.forEach((item) => {
      const children = this.items.filter((child) => compareIds(child.parentId, item.id));
      const parent = this.items.find((potential) => compareIds(item.parentId, potential.id));

      item.children = children;
      if (parent) {
        item.parentId = parent.id;
      }
    });
  }

  private findRoots(): void {
    if (this.options.spaceId) {
      this.rootItems = this.rootItemsForSpace();
    } else if (this.options.personId) {
      this.rootItems = this.rootItemsForPerson();
    } else if (this.options.goalId) {
      this.rootItems = this.rootItemsForGoal();
    } else {
      this.rootItems = this.rootItemsInTheCompany();
    }
  }

  private rootItemsForSpace(): WorkMap.Item[] {
    return this.items
      .filter((item) => !item.parentId)
      .filter((item) => item.space === this.options.spaceId || this.hasDescendantFromSpace(item, this.options.spaceId!));
  }

  private rootItemsForPerson(): WorkMap.Item[] {
    return this.items
      .filter((item) => !item.parentId)
      .filter(
        (item) =>
          this.isOwnedBy(item, this.options.personId!) || this.hasDescendantOwnedBy(item, this.options.personId!),
      );
  }

  private rootItemsInTheCompany(): WorkMap.Item[] {
    return this.items.filter((item) => !item.parentId);
  }

  private rootItemsForGoal(): WorkMap.Item[] {
    return this.items.filter((item) => compareIds(item.parentId, this.options.goalId));
  }

  private hasDescendantFromSpace(item: WorkMap.Item, spaceId: string): boolean {
    return item.children?.some(
      (child) => child.space === spaceId || this.hasDescendantFromSpace(child, spaceId)
    ) || false;
  }

  private isOwnedBy(item: WorkMap.Item, personId: string): boolean {
    return compareIds(item.owner.id, personId);
  }

  private hasDescendantOwnedBy(item: WorkMap.Item, personId: string): boolean {
    return item.children?.some(
      (child) => this.isOwnedBy(child, personId) || this.hasDescendantOwnedBy(child, personId)
    ) || false;
  }

  private setDepth(): void {
    TreeBuilder.setDepth(this.rootItems, 0);
  }

  private sortNodes(): void {
    TreeBuilder.sortNodes(this.rootItems, this.options.sortColumn, this.options.sortDirection);
  }

  // Recursive utility functions

  static sortNodes(items: WorkMap.Item[], column: SortColumn, direction: SortDirection): WorkMap.Item[] {
    let res = items.sort((a, b) => TreeBuilder.compareItems(a, b, column, direction));

    res.forEach((item) => {
      if (item.children && item.children.length > 0) {
        item.children = TreeBuilder.sortNodes(item.children, column, direction);
      }
    });

    return res;
  }

  static compareItems(a: WorkMap.Item, b: WorkMap.Item, column: SortColumn, direction: SortDirection): number {
    if (a.type === "goal" && b.type === "project") return -1;
    if (a.type === "project" && b.type === "goal") return 1;

    if (a.completedOn && !b.completedOn) return 1;
    if (!a.completedOn && b.completedOn) return -1;

    let result = 0;

    switch (column) {
      case "name":
        result = a.name.localeCompare(b.name);
        break;
      case "space":
        result = a.space.localeCompare(b.space);
        break;
      case "timeframe":
        if (a.type === "goal" && b.type === "goal") {
          result = TreeBuilder.compareTimeframes(a.timeframe, b.timeframe);
        }
        break;
      case "progress":
        result = a.progress - b.progress;
        break;
      case "deadline":
        if (a.deadline && b.deadline) {
          result = a.deadline.display.localeCompare(b.deadline.display);
        } else if (a.deadline) {
          result = -1;
        } else if (b.deadline) {
          result = 1;
        }
        break;
      case "owner":
        result = a.owner.fullName.localeCompare(b.owner.fullName);
        break;
    }

    const directionFactor = direction === "asc" ? 1 : -1;
    return result * directionFactor;
  }

  static compareTimeframes(a: TimeframeSelector.Timeframe, b: TimeframeSelector.Timeframe): number {
    // Compare timeframes based on startDate
    if (!a.startDate || !b.startDate) return 0;
    
    // Compare by start date
    return a.startDate.getTime() - b.startDate.getTime();
  }

  static setDepth(items: WorkMap.Item[], depth: number): void {
    items.forEach((item) => {
      (item as any).depth = depth; // Adding depth property dynamically
      if (item.children && item.children.length > 0) {
        TreeBuilder.setDepth(item.children, depth + 1);
      }
    });
  }
}

class TreeFilter {
  static filter(me: WorkMap.Person, items: WorkMap.Item[], options: TreeOptions): WorkMap.Item[] {
    return new TreeFilter(me, options).filter(items);
  }

  private options: TreeOptions;
  private me: WorkMap.Person;

  constructor(me: WorkMap.Person, options: TreeOptions) {
    this.me = me;
    this.options = options;
  }

  filter(items: WorkMap.Item[]): WorkMap.Item[] {
    return items
      .map((item) => this.filterChildren(item))
      .filter((item) => this.isItemVisible(item) || (item.children && item.children.length > 0));
  }

  private filterChildren(item: WorkMap.Item): WorkMap.Item {
    if (item.children && item.children.length > 0) {
      item.children = this.filter(item.children);
    }
    return item;
  }

  private isItemVisible(item: WorkMap.Item): boolean {
    return (
      this.spaceFilter(item) &&
      this.personFilter(item) &&
      this.statusFilter(item) &&
      this.timeframeFilter(item) &&
      this.myRoleFilter(item)
    );
  }

  private spaceFilter(item: WorkMap.Item): boolean {
    if (!this.options.spaceId) return true;
    return item.space === this.options.spaceId;
  }

  private personFilter(item: WorkMap.Item): boolean {
    if (!this.options.personId) return true;
    return compareIds(item.owner.id, this.options.personId);
  }

  private statusFilter(item: WorkMap.Item): boolean {
    const isCompleted = ["completed", "achieved", "partial", "missed"].includes(item.status);
    const isPaused = item.status === "paused";
    const isActive = !isCompleted && !isPaused;

    if (isCompleted && !this.options.showCompleted) return false;
    if (isPaused && !this.options.showPaused) return false;
    if (isActive && !this.options.showActive) return false;

    return true;
  }

  private timeframeFilter(item: WorkMap.Item): boolean {
    if (!this.options.timeframe) return true;
    if (item.type !== "goal") return true;

    const goalItem = item as WorkMap.GoalItem;
    const optionsTimeframe = this.options.timeframe;
    
    // If either timeframe doesn't have start/end dates, we can't compare them properly
    if (!goalItem.timeframe.startDate || !goalItem.timeframe.endDate || 
        !optionsTimeframe.startDate || !optionsTimeframe.endDate) {
      return true;
    }

    // Check if the timeframes have the same type
    if (goalItem.timeframe.type !== optionsTimeframe.type) {
      return false;
    }
    
    // For exact match, check if start and end dates are the same
    return (
      goalItem.timeframe.startDate.getTime() === optionsTimeframe.startDate.getTime() &&
      goalItem.timeframe.endDate.getTime() === optionsTimeframe.endDate.getTime()
    );
  }

  private myRoleFilter(item: WorkMap.Item): boolean {
    if (this.options.ownedBy === "anyone") return true;
    return compareIds(item.owner.id, this.me.id);
  }
}
