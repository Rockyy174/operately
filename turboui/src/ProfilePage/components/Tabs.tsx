import * as React from "react";
import { useLocation } from "react-router-dom";
import classNames from "classnames";
import { DivLink } from "../../Link";

interface TabsContext {
  activeView: string;
}

const Context = React.createContext<TabsContext>({ activeView: "" });

interface TabsProps {
  activeView: string;
  children?: React.ReactNode;
}

export function Root(props: TabsProps) {
  return (
    <Context.Provider value={{ activeView: props.activeView }}>
      <div className="flex gap-2 border-b border-surface-outline pl-4 mt-6">{props.children}</div>
    </Context.Provider>
  );
}

interface TabProps {
  id: string;
  label: string;
  view: string;
}

export function Tab(props: TabProps) {
  const { activeView } = React.useContext(Context);
  const isActive = activeView === props.view;
  const location = useLocation();

  const className = classNames("border-surface-outline rounded-t px-4 py-1 -mb-px cursor-pointer bg-surface-base", {
    "border-x border-t font-medium": isActive,
    border: !isActive,
    "hover:text-content": !isActive,
  });

  // Create a URL with the view parameter
  const searchParams = new URLSearchParams(location.search);
  searchParams.set("view", props.view);
  const linkTo = `${location.pathname}?${searchParams.toString()}`;

  return (
    <DivLink to={linkTo} className={className} testId={`tab-${props.id}`}>
      {props.label}
    </DivLink>
  );
}
