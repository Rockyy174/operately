import React from "react";
import { Tabs } from "../../Tabs";

export interface Props {
  tabsState: Tabs.State;
  layout?: Tabs.Layout;
}

export function WorkMapNavigation({ tabsState, layout }: Props) {
  return (
    <div className="overflow-x-auto px-4 py-2">
      <Tabs tabs={tabsState} layout={layout} />
    </div>
  );
}

export default WorkMapNavigation;
