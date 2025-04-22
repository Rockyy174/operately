import { TreeTester } from "./treeTester";
import { TimeframeSelector } from "../../../TimeframeSelector";

describe("WorkMap TreeBuilder", () => {
  // Create mock persons for testing
  const john = { id: "john", fullName: "John Doe" };
  const sarah = { id: "sarah", fullName: "Sarah Smith" };
  const peter = { id: "peter", fullName: "Peter Jones" };

  // Create mock spaces for testing
  const company = "Company";
  const product = "Product";
  const marketing = "Marketing";

  // Create timeframes for testing
  const createTimeframe = (year: number, month?: number, type: TimeframeSelector.TimeframeType = "month") => {
    const startDate = new Date(year, month || 0, 1);
    const endDate = new Date(year, month !== undefined ? month : 11, month !== undefined ? 28 : 31);
    return { startDate, endDate, type };
  };

  const currentYear = new Date().getFullYear();
  const previousYear = currentYear - 1;

  const currentYearTimeframe = createTimeframe(currentYear, undefined, "year");
  const previousYearTimeframe = createTimeframe(previousYear, undefined, "year");
  const currentMonthTimeframe = createTimeframe(currentYear, new Date().getMonth());
  const previousMonthTimeframe = createTimeframe(currentYear, new Date().getMonth() - 1);

  describe("Basic tree building", () => {
    it("builds a tree from goals and projects", () => {
      const t = new TreeTester();

      t.addGoal("G1", company, john);
      t.addGoal("G11", marketing, sarah, "G1");
      t.addGoal("G111", marketing, john, "G11");
      t.addProj("P1111", marketing, john, "G111");

      t.assertShape(`
        G1
          G11
            G111
              P1111
      `);
    });

    it("can display multiple roots", () => {
      const t = new TreeTester();

      t.addGoal("G1", company, john);
      t.addGoal("G11", marketing, sarah, "G1");
      t.addGoal("G2", company, john);
      t.addGoal("G21", marketing, john, "G2");

      t.assertShape(`
        G1
          G11
        G2
          G21
      `);
    });

    it("can show projects without associated goals", () => {
      const t = new TreeTester();

      t.addProj("P1", company, john);
      t.addProj("P2", marketing, sarah);

      t.assertShape(`
        P1
        P2
      `);
    });
  });

  describe("Filtering by node type", () => {
    test("showing both goals and projects", () => {
      const t = new TreeTester(["name"], { showProjects: true, showGoals: true });

      t.addGoal("G1", company, john);
      t.addProj("P1", company, john);
      t.addGoal("G2", company, john, "G1");
      t.addProj("P2", company, john, "G2");

      t.assertShape(`
        G1
          G2
            P2
        P1
      `);
    });

    test("showing only goals", () => {
      const t = new TreeTester(["name"], { showProjects: false });

      t.addGoal("G1", company, john);
      t.addProj("P1", company, john);
      t.addGoal("G2", company, john, "G1");
      t.addProj("P2", company, john, "G2");

      t.assertShape(`
        G1
          G2
      `);
    });

    test("showing only projects", () => {
      const t = new TreeTester(["name"], { showProjects: true, showGoals: false });

      t.addGoal("G1", company, john);
      t.addProj("P1", company, john);
      t.addGoal("G2", company, john, "G1");
      t.addProj("P2", company, john, "G2");

      t.assertShape(`
        P1
      `);
    });
  });

  describe("Filtering by timeframe", () => {
    describe("timeframe is not set", () => {
      it("shows all goals and projects", () => {
        const t = new TreeTester(["name"], { timeframe: undefined, showActive: false, showCompleted: true });

        t.addGoal("G1", company, john, null, { timeframe: previousYearTimeframe, isClosed: true });
        t.addGoal("G2", company, john, null, { timeframe: currentYearTimeframe, isClosed: true });

        t.assertShape(`
          G1
          G2
        `);
      });
    });

    describe("timeframe is set to current year", () => {
      it("shows only goals and projects from the current year", () => {
        const t = new TreeTester(["name"], {
          timeframe: currentYearTimeframe,
          showActive: false,
          showCompleted: true,
        });

        t.addGoal("G1", company, john, null, { timeframe: previousYearTimeframe, isClosed: true });
        t.addGoal("G2", company, john, null, { timeframe: currentYearTimeframe, isClosed: true });
        t.addProj("P1", company, john, null, {
          startedAt: previousYearTimeframe.startDate.toISOString(),
          closedAt: previousYearTimeframe.endDate.toISOString(),
          status: "completed",
        });
        t.addProj("P2", company, john, null, {
          startedAt: previousYearTimeframe.startDate.toISOString(),
          closedAt: currentYearTimeframe.endDate.toISOString(),
          status: "completed",
        });

        t.assertShape(`
          G2
        `);
      });
    });

    describe("timeframe is set to current month", () => {
      it("shows only goals from the current month", () => {
        const t = new TreeTester(["name"], {
          timeframe: currentMonthTimeframe,
          showActive: true,
          showCompleted: true,
        });

        t.addGoal("G1", company, john, null, { timeframe: previousMonthTimeframe });
        t.addGoal("G2", company, john, null, { timeframe: currentMonthTimeframe });

        t.assertShape(`
          G2
        `);
      });
    });
  });

  describe("Filtering by status", () => {
    describe("showActive", () => {
      it("shows only active goals", () => {
        const t = new TreeTester(["name", "status"], { showActive: true, showCompleted: false, showPaused: false });

        t.addGoal("G1", company, john);
        t.addGoal("G2", company, john, null, { isClosed: true });
        t.addGoal("G3", company, john);
        t.addGoal("G4", company, john, "G3", { isClosed: true });

        t.assertShape(`
          G1 on_track
          G3 on_track
        `);
      });

      it("shows completed ancestors of active goals", () => {
        const t = new TreeTester(["name", "status"], { showActive: true, showCompleted: false, showPaused: false });

        t.addGoal("G1", company, john, null, { isClosed: true });
        t.addGoal("G2", company, john, "G1", { isClosed: true });
        t.addGoal("G3", company, john, "G2");

        t.assertShape(`
          G1 completed
            G2 completed
              G3 on_track
        `);
      });
    });

    describe("showPaused", () => {
      it("shows only paused projects", () => {
        const t = new TreeTester(["name", "status"], { showActive: false, showPaused: true, showCompleted: false });

        t.addProj("P1", company, john, null, { status: "paused" });
        t.addProj("P2", company, john, null, { status: "on_track" });

        t.assertShape(`
          P1 paused
        `);
      });

      it("shows completed ancestors of paused projects", () => {
        const t = new TreeTester(["name", "status"], { showActive: false, showPaused: true, showCompleted: false });

        t.addGoal("G1", company, john, null, { isClosed: true });
        t.addProj("P1", company, john, "G1", { status: "paused" });
        t.addProj("P2", company, john, "G1", { status: "on_track" });

        t.assertShape(`
          G1 completed
            P1 paused
        `);
      });
    });

    describe("showCompleted", () => {
      it("shows only completed goals", () => {
        const t = new TreeTester(["name", "status"], { showActive: false, showPaused: false, showCompleted: true });

        t.addGoal("G1", company, john, null, { isClosed: true });
        t.addGoal("G2", company, john, null, { isClosed: false });

        t.assertShape(`
          G1 completed
        `);
      });

      it("shows active ancestors of completed goals", () => {
        const t = new TreeTester(["name", "status"], { showActive: false, showPaused: false, showCompleted: true });

        t.addGoal("G1", company, john);
        t.addGoal("G2", company, john, "G1");
        t.addGoal("G3", company, john, "G2", { isClosed: true });

        t.assertShape(`
          G1 on_track
            G2 on_track
              G3 completed
        `);
      });
    });
  });

  describe("Filtering by my role", () => {
    describe("ownedBy me", () => {
      it("shows only items where the user is the owner", () => {
        const t = new TreeTester(["name", "owner"], { ownedBy: "me" });
        t.setMe(john);

        t.addGoal("G1", company, sarah);
        t.addGoal("G11", product, sarah, "G1");

        t.addGoal("G2", marketing, peter);
        t.addGoal("G21", product, sarah, "G2");
        t.addGoal("G211", product, john, "G21");
        t.addProj("P1", product, john, "G2");

        t.assertShape(`
          G2 Peter Jones
            G21 Sarah Smith
              G211 John Doe
            P1 John Doe
        `);
      });
    });
  });

  describe("Filtering by space", () => {
    it("shows only items from the selected space", () => {
      const t = new TreeTester(["name", "space"], { spaceId: marketing });

      t.addGoal("G1", marketing, john);
      t.addGoal("G2", product, sarah);
      t.addGoal("G3", company, john);
      t.addGoal("G31", marketing, john, "G3");
      t.addGoal("G32", product, sarah, "G3");

      t.assertShape(`
        G1 Marketing
        G3 Company
          G31 Marketing
      `);
    });

    it("displays descendants of a goal from other spaces", () => {
      const t = new TreeTester(["name", "space"], { spaceId: marketing });

      t.addGoal("G1", marketing, john);
      t.addGoal("G11", product, sarah, "G1");
      t.addGoal("G111", product, john, "G11");

      t.assertShape(`
        G1 Marketing
      `);
    });

    it("displays ancestors of a goal from other spaces", () => {
      const t = new TreeTester(["name", "space"], { spaceId: marketing });

      t.addGoal("G1", company, john);
      t.addGoal("G11", product, sarah, "G1");
      t.addGoal("G111", marketing, john, "G11");

      t.assertShape(`
        G1 Company
          G11 Product
            G111 Marketing
      `);
    });
  });

  describe("Filtering by person", () => {
    it("shows only items from the selected person", () => {
      const t = new TreeTester(["name", "owner"], { personId: john.id });

      t.addGoal("G1", marketing, sarah);
      t.addGoal("G2", product, sarah);
      t.addGoal("G3", company, john);
      t.addGoal("G31", marketing, john, "G3");
      t.addGoal("G4", product, john);

      t.assertShape(`
        G3 John Doe
          G31 John Doe
        G4 John Doe
      `);
    });

    it("displays descendants owned by the selected person", () => {
      const t = new TreeTester(["name", "owner"], { personId: john.id });

      t.addGoal("G1", company, sarah);
      t.addGoal("G11", product, sarah, "G1");
      t.addGoal("G111", marketing, john, "G11");

      t.assertShape(`
        G1 Sarah Smith
          G11 Sarah Smith
            G111 John Doe
      `);
    });
  });

  describe("Filtering by goal ID", () => {
    it("shows only children of the selected goal", () => {
      const t = new TreeTester(["name"], { goalId: "G1" });

      t.addGoal("G1", company, john);
      t.addGoal("G11", marketing, sarah, "G1");
      t.addGoal("G12", product, john, "G1");
      t.addGoal("G2", company, sarah);

      t.assertShape(`
        G11
        G12
      `);
    });
  });

  describe("Combined filters", () => {
    describe("spaceId with other filters", () => {
      it("spaceId + showCompleted", () => {
        const t = new TreeTester(["name", "space", "status"], { 
          spaceId: marketing,
          showActive: false,
          showPaused: false,
          showCompleted: true
        });

        t.addGoal("G1", marketing, john, null, { isClosed: true });
        t.addGoal("G2", product, sarah, null, { isClosed: true });
        t.addGoal("G3", marketing, peter, null, { isClosed: false });

        t.assertShape(`
          G1 Marketing completed
        `);
      });

      it("spaceId + showGoals", () => {
        const t = new TreeTester(["name", "space", "type"], { 
          spaceId: marketing,
          showGoals: true,
          showProjects: false
        });

        t.addGoal("G1", marketing, john);
        t.addProj("P1", marketing, sarah);
        t.addGoal("G2", product, peter);

        t.assertShape(`
          G1 Marketing goal
        `);
      });

      it("spaceId + showProjects", () => {
        const t = new TreeTester(["name", "space", "type"], { 
          spaceId: marketing,
          showGoals: false,
          showProjects: true
        });

        t.addGoal("G1", marketing, john);
        t.addProj("P1", marketing, sarah);
        t.addProj("P2", product, peter);

        t.assertShape(`
          P1 Marketing project
        `);
      });

      it("spaceId + timeframe", () => {
        const t = new TreeTester(["name", "space"], { 
          spaceId: marketing,
          timeframe: currentYearTimeframe
        });

        t.addGoal("G1", marketing, john, null, { timeframe: currentYearTimeframe });
        t.addGoal("G2", marketing, sarah, null, { timeframe: previousYearTimeframe });
        t.addGoal("G3", product, john, null, { timeframe: currentYearTimeframe });

        t.assertShape(`
          G1 Marketing
        `);
      });
    });

    describe("personId with other filters", () => {
      it("personId + showCompleted", () => {
        const t = new TreeTester(["name", "owner", "status"], { 
          personId: john.id,
          showActive: false,
          showPaused: false,
          showCompleted: true
        });

        t.addGoal("G1", marketing, john, null, { isClosed: true });
        t.addGoal("G2", product, john, null, { isClosed: false });
        t.addGoal("G3", marketing, sarah, null, { isClosed: true });

        t.assertShape(`
          G1 John Doe completed
        `);
      });

      it("personId + showGoals", () => {
        const t = new TreeTester(["name", "owner", "type"], { 
          personId: john.id,
          showGoals: true,
          showProjects: false
        });

        t.addGoal("G1", marketing, john);
        t.addProj("P1", marketing, john);
        t.addGoal("G2", product, sarah);

        t.assertShape(`
          G1 John Doe goal
        `);
      });

      it("personId + showProjects", () => {
        const t = new TreeTester(["name", "owner", "type"], { 
          personId: john.id,
          showGoals: false,
          showProjects: true
        });

        t.addGoal("G1", marketing, john);
        t.addProj("P1", marketing, john);
        t.addProj("P2", product, sarah);

        t.assertShape(`
          P1 John Doe project
        `);
      });

      it("personId + timeframe", () => {
        const t = new TreeTester(["name", "owner"], { 
          personId: john.id,
          timeframe: currentYearTimeframe
        });

        t.addGoal("G1", marketing, john, null, { timeframe: currentYearTimeframe });
        t.addGoal("G2", marketing, john, null, { timeframe: previousYearTimeframe });
        t.addGoal("G3", product, sarah, null, { timeframe: currentYearTimeframe });

        t.assertShape(`
          G1 John Doe
        `);
      });
    });

    describe("goalId with other filters", () => {
      it("goalId + showCompleted", () => {
        const t = new TreeTester(["name", "status"], { 
          goalId: "G1",
          showActive: false,
          showPaused: false,
          showCompleted: true
        });

        t.addGoal("G1", marketing, john);
        t.addGoal("G11", product, sarah, "G1", { isClosed: true });
        t.addGoal("G12", marketing, peter, "G1", { isClosed: false });

        t.assertShape(`
          G11 completed
        `);
      });

      it("goalId + showGoals", () => {
        const t = new TreeTester(["name", "type"], { 
          goalId: "G1",
          showGoals: true,
          showProjects: false
        });

        t.addGoal("G1", marketing, john);
        t.addGoal("G11", product, sarah, "G1");
        t.addProj("P11", marketing, peter, "G1");

        t.assertShape(`
          G11 goal
        `);
      });

      it("goalId + showProjects", () => {
        const t = new TreeTester(["name", "type"], { 
          goalId: "G1",
          showGoals: false,
          showProjects: true
        });

        t.addGoal("G1", marketing, john);
        t.addGoal("G11", product, sarah, "G1");
        t.addProj("P11", marketing, peter, "G1");

        t.assertShape(`
          P11 project
        `);
      });

      it("goalId + timeframe", () => {
        const t = new TreeTester(["name"], { 
          goalId: "G1",
          timeframe: currentYearTimeframe
        });

        t.addGoal("G1", marketing, john);
        t.addGoal("G11", product, sarah, "G1", { timeframe: currentYearTimeframe });
        t.addGoal("G12", marketing, peter, "G1", { timeframe: previousYearTimeframe });

        t.assertShape(`
          G11
        `);
      });
    });
  });
});
