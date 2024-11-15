import React from "react";

import * as Pages from "@/components/Pages";
import * as Paper from "@/components/PaperContainer";

import { Paths } from "@/routes/paths";
import { useLoadedData } from "./loader";

export function Page() {
  return (
    <Pages.Page title="Space Tools">
      <Paper.Root size="large">
        <PageNavigation />

        <Paper.Body>
          <div className="text-content-accent text-center text-2xl font-extrabold">Set up tools for this space</div>
        </Paper.Body>
      </Paper.Root>
    </Pages.Page>
  );
}

function PageNavigation() {
  const { space } = useLoadedData();

  return (
    <Paper.Navigation>
      <Paper.NavItem linkTo={Paths.spacePath(space.id!)}>{space.name}</Paper.NavItem>
    </Paper.Navigation>
  );
}
