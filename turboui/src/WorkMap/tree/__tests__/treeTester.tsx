import { buildTree, TreeOptions } from "../treeBuilder";
import { WorkMap } from "../../index";

type ParentId = string | null | undefined;

// Helper function to create a mock Goal
function goalMock(
  name: string, 
  space: string, 
  owner: WorkMap.Person, 
  options: any = {}
): any {
  const now = new Date();
  const nextMonth = new Date(now);
  nextMonth.setMonth(now.getMonth() + 1);

  return {
    id: options.id || name,
    parentId: options.parentId || null,
    name,
    status: options.status || (options.isClosed ? "completed" : "on_track"),
    progress: options.progress || 0,
    deadline: options.deadline ? { display: options.deadline } : undefined,
    closedAt: options.closedAt || (options.isClosed ? now.toISOString() : undefined),
    space: { name: space, isCompanySpace: space === "Company" },
    champion: owner,
    reviewer: options.reviewer,
    nextStep: options.nextStep || "",
    timeframe: options.timeframe || {
      startDate: now,
      endDate: nextMonth,
      type: "month"
    },
    completedOn: options.completedOn
  };
}

// Helper function to create a mock Project
function projectMock(
  name: string, 
  space: string, 
  owner: WorkMap.Person, 
  options: any = {}
): any {
  const now = new Date();
  const nextMonth = new Date(now);
  nextMonth.setMonth(now.getMonth() + 1);

  return {
    id: options.id || name,
    parentId: options.parentId || null,
    name,
    status: options.status || (options.isClosed ? "completed" : "on_track"),
    progress: options.progress || 0,
    deadline: options.deadline ? { display: options.deadline } : undefined,
    closedAt: options.closedAt || (options.isClosed ? now.toISOString() : undefined),
    space: { name: space, isCompanySpace: space === "Company" },
    champion: owner,
    reviewer: options.reviewer,
    nextStep: options.nextStep || "",
    startedAt: options.startedAt || now.toISOString(),
    completedOn: options.completedOn
  };
}

export class TreeTester {
  private me: WorkMap.Person;
  private goals: any[];
  private projects: any[];
  private display: string[];
  private options: TreeOptions;

  private defaultOpts = {
    sortColumn: "name",
    sortDirection: "asc",
    showCompleted: false,
    showActive: true,
    showPaused: false,
    showGoals: true,
    showProjects: true,
    ownedBy: "anyone",
    reviewedBy: "anyone",
  } as TreeOptions;

  constructor(display: string[] = ["name"], options: any = {}) {
    this.me = { id: "1", fullName: "Me" } as WorkMap.Person;
    this.goals = [];
    this.projects = [];
    this.display = display;
    this.options = { ...this.defaultOpts, ...options };
  }

  setMe(person: WorkMap.Person) {
    this.me = person;
  }

  addGoal(name: string, space: string, owner: WorkMap.Person, parentId: ParentId = null, options: any = {}) {
    this.goals.push(goalMock(name, space, owner, { parentId, ...options }));
  }

  addProj(name: string, space: string, owner: WorkMap.Person, parentId: ParentId = null, options: any = {}) {
    this.projects.push(projectMock(name, space, owner, { parentId, ...options }));
  }

  assertShape(expected: string) {
    const tree = buildTree(this.me, this.goals, this.projects, this.options);
    assertTreeShape(tree, this.display, expected);
  }
}

export function assertTreeShape(items: WorkMap.Item[], fields: string[], expected: string): void {
  const actual = drawTree(items, fields);

  const actualLines = actual.split("\n");
  const expectedLines = removeIndentation(expected).split("\n");

  const same = actualLines.length === expectedLines.length && actualLines.every((line, i) => line === expectedLines[i]);

  try {
    expect(same).toBe(true);
  } catch (e) {
    if (e instanceof Error) {
      e.message += `\n\nExpected:\n${expectedLines.join("\n")}\n\nActual:\n${actualLines.join("\n")}`;
      Error.captureStackTrace(e, assertTreeShape);
    }
    throw e;
  }
}

function drawTree(items: WorkMap.Item[], keys: string[], depth = 0): string {
  return items
    .map((item) => {
      const indent = "  ".repeat(depth);
      const keyValues = keys
        .map((key) => {
          if (key === "owner") return `${item.owner?.fullName}`;
          if (key === "name") return `${item.name}`;
          if (key === "space") return `${item.space}`;
          if (key === "type") return `${item.type}`;
          if (key === "status") return `${item.status}`;

          throw new Error(`Unknown key: ${key}`);
        })
        .join(" ");

      if (!item.children || item.children.length === 0) {
        return `${indent}${keyValues}`;
      } else {
        const children = drawTree(item.children, keys, depth + 1);
        return `${indent}${keyValues}\n${children}`;
      }
    })
    .join("\n");
}

function removeIndentation(str: string): string {
  const noEmptyLines = str
    .split("\n")
    .filter((s) => !/^\s*$/.test(s))
    .join("\n");

  const sharedPaddingSize: number = noEmptyLines
    .split("\n")
    .map((s) => s.match(/^[ ]*/)?.[0].length as number)
    .reduce((a: number, b: number) => Math.min(a, b), 1000);

  return noEmptyLines
    .split("\n")
    .map((line) => line.slice(sharedPaddingSize).trimEnd())
    .join("\n");
}
