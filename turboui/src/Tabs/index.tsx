// Tabs in this file are controlled by the URL query parameter (e.g., ?tab=tabId).
// The useTabs hook uses react-router-dom's useLocation to read the current tab query parameter from the URL.
// Whenever the query parameter changes (via navigation, clicking a tab, or browser navigation),
// useTabs will update the active tab accordingly. This ensures the tab state is always
// in sync with the URL, and works seamlessly with React Router navigation.
//
// To add a new tab, add a Tab object to the tabs array with a unique id (which will be used as the tab query parameter).
// Clicking a tab updates the tab query parameter in the URL, which triggers a re-render with the new active tab.
//
// If you need to control the active tab from a parent component, pass the correct tab query parameter in the URL.
//
// This approach does not require manual event listeners for popstate, as React Router
// handles location changes and triggers re-renders automatically.
//
// The component supports two layout options:
// - "row" (default): Tabs are displayed horizontally in a row
// - "dropdown": Tabs are displayed in a dropdown menu, with the active tab shown as the trigger

import React, { useState } from "react";
import { useLocation } from "react-router-dom";

import { DivLink } from "../Link";
import classNames from "../utils/classnames";
import * as DropdownMenu from "@radix-ui/react-dropdown-menu";
import { IconChevronDown } from "@tabler/icons-react";

export namespace Tabs {
  export interface Tab {
    id: string;
    label: string;
    icon: React.ReactNode;
    count?: number;
  }

  export type Layout = "row" | "dropdown";

  export interface State {
    active: string;
    tabs: Tab[];
    tabParamKey?: string;
  }
}

export function useTabs(defaultTab: string, tabs: Tabs.Tab[], tabParamKey: string = "tab"): Tabs.State {
  const location = useLocation();
  const searchParams = new URLSearchParams(location.search);
  const active = searchParams.get(tabParamKey) || defaultTab;

  return {
    active,
    tabs: tabs,
    tabParamKey,
  };
}

function useTabPath(tabId: string, tabParamKey: string = "tab") {
  const location = useLocation();
  const searchParams = new URLSearchParams(location.search);
  searchParams.set(tabParamKey, tabId);
  return `${location.pathname}?${searchParams.toString()}`;
}

export function Tabs({ tabs, layout = "row" }: { tabs: Tabs.State; layout?: Tabs.Layout }) {
  if (layout === "dropdown") {
    return <DropdownTabs tabs={tabs} />;
  }

  return (
    <div className="border-b shadow-b-xs pl-4 mt-2">
      <nav className="flex gap-4 px-2 sm:px-0">
        {tabs.tabs.map((tab) => (
          <TabItem key={tab.id} tab={tab} activeTab={tabs.active} tabParamKey={tabs.tabParamKey || "tab"} />
        ))}
      </nav>
    </div>
  );
}

function TabItem({ tab, activeTab, tabParamKey }: { tab: Tabs.Tab; activeTab: string; tabParamKey: string }) {
  const tabPath = useTabPath(tab.id, tabParamKey);

  const labelClass = classNames("flex items-center gap-1 px-1.5 py-1.5 text-sm relative -mb-px font-medium -mx-1.5", {
    "text-white rounded-t": activeTab === tab.id,
    "text-content-dimmed hover:text-content-base": activeTab !== tab.id,
    "hover:bg-surface-dimmed rounded-lg": activeTab !== tab.id,
  });

  return (
    <div className="relative pb-1.5">
      <DivLink className={labelClass} to={tabPath}>
        {tab.icon}
        <span className="leading-none">{tab.label}</span>
        <TabCountBadge count={tab.count} />
      </DivLink>

      <TabUnderline isActive={activeTab === tab.id} />
    </div>
  );
}

function TabUnderline({ isActive }: { isActive: boolean }) {
  const underlineClass = classNames(
    "absolute inset-x-0 bottom-0 h-[1.5px] bg-blue-500 transition-all duration-200 ease-in-out",
    {
      "scale-x-100": isActive,
      "scale-x-0": !isActive,
    },
  );

  return <div className={underlineClass} />;
}

function TabCountBadge({ count }: { count?: number }) {
  if (!count || count <= 0) {
    return null;
  } else {
    return <span className="bg-stone-100 dark:bg-stone-900 text-xs font-medium rounded-lg px-1.5">{count}</span>;
  }
}

function DropdownTabs({ tabs }: { tabs: Tabs.State }) {
  const [open, setOpen] = useState(false);
  // Ensure we always have a valid activeTab by falling back to the first tab if none is active
  const activeTab = tabs.tabs.find((tab) => tab.id === tabs.active) ||
    tabs.tabs[0] || {
      id: "",
      label: "No tabs",
      icon: null,
    };
  const tabParamKey = tabs.tabParamKey || "tab";

  // Use useLocation to detect URL changes that will happen when a tab is selected
  // This will automatically close the dropdown when navigation occurs
  const location = useLocation();
  React.useEffect(() => {
    if (open) setOpen(false);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [location]);

  return (
    <div className="relative">
      <DropdownMenu.Root open={open} onOpenChange={setOpen}>
        <DropdownMenu.Trigger asChild>
          <button
            className="flex items-center gap-1 px-3 py-2 text-sm font-medium border rounded-md hover:bg-surface-dimmed focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-opacity-50"
            aria-label="Tabs"
          >
            {activeTab.icon}
            <span className="leading-none">{activeTab.label}</span>
            <TabCountBadge count={activeTab.count} />
            <IconChevronDown size={14} className="ml-2" />
          </button>
        </DropdownMenu.Trigger>

        <DropdownMenu.Portal>
          <DropdownMenu.Content
            className="min-w-[200px] rounded-md shadow-lg p-1 z-50 border dark:border-stone-700"
            style={{ backgroundColor: "white" }}
            sideOffset={5}
            align="start"
            onInteractOutside={() => setOpen(false)}
          >
            <div
              className="rounded-md w-full h-full"
              style={{ backgroundColor: "white" }}
              data-theme-dark-style={{ backgroundColor: "#1c1917" }}
            >
              {tabs.tabs.map((tab) => {
                const tabPath = useTabPath(tab.id, tabParamKey);
                return (
                  <DropdownMenu.Item key={tab.id} asChild>
                    <DivLink
                      to={tabPath}
                      className={classNames("flex items-center gap-2 px-3 py-2 text-sm rounded-md", {
                        "bg-blue-50 dark:bg-blue-900/20 text-blue-700 dark:text-blue-300": tabs.active === tab.id,
                        "hover:bg-surface-dimmed": tabs.active !== tab.id,
                      })}
                    >
                      {tab.icon}
                      <span>{tab.label}</span>
                      <TabCountBadge count={tab.count} />
                    </DivLink>
                  </DropdownMenu.Item>
                );
              })}
            </div>
          </DropdownMenu.Content>
        </DropdownMenu.Portal>
      </DropdownMenu.Root>
    </div>
  );
}
