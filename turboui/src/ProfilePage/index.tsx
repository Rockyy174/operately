import React from "react";
import { useLocation } from "react-router-dom";

import { Page } from "../Page";
import { WorkMap } from "../WorkMap";
import { Colleagues, PageHeader, Contact, Tabs } from "./components";

export namespace ProfilePage {
  export interface Person {
    id: string;
    fullName: string;
    email: string;
    avatarUrl: string | null;
    title: string;
    link: string;
  }

  export interface Props {
    title: string | string[];

    person: Person;
    manager: Person | null;
    peers: Person[];
    reports: Person[];

    workMap: WorkMap.Item[];

    activityFeed: React.ReactNode;
  }
}

export function ProfilePage(props: ProfilePage.Props) {
  const location = useLocation();
  const searchParams = new URLSearchParams(location.search);
  const activeView = searchParams.get("view") || "assigned";

  return (
    <Page title={props.title} size="fullwidth">
      <PageHeader person={props.person} />

      <Tabs.Root activeView={activeView}>
        <Tabs.Tab id="assigned" label="Assigned" view="assigned" />
        <Tabs.Tab id="reviewing" label="Reviewing" view="reviewing" />
        <Tabs.Tab id="activity" label="Recent activity" view="activity" />
        <Tabs.Tab id="about" label="About" view="about" />
      </Tabs.Root>

      {activeView === "assigned" && <WorkMap items={props.workMap} type="personal" />}
      {activeView === "activity" && <ActivityFeed {...props} />}
      {activeView === "about" && <About {...props} />}
    </Page>
  );
}

function ActivityFeed(props: ProfilePage.Props) {
  return (
    <div className="p-4 max-w-5xl mx-auto my-6">
      <div className="font-bold text-lg mb-4">Recent activity</div>
      {props.activityFeed}
    </div>
  );
}

function About(props: ProfilePage.Props) {
  return (
    <div className="p-4 max-w-5xl mx-auto my-6">
      <div className="flex flex-col divide-y divide-stroke-base">
        <Contact person={props.person} />
        <Colleagues {...props} />
      </div>
    </div>
  );
}
