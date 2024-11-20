import React from "react";

import { ResourceHubNode } from "@/models/resourceHubs";
import { IconFolder, IconFile } from "@tabler/icons-react";
import classNames from "classnames";

type NodeType = "document" | "folder";

export function NodesList({ nodes }: { nodes: ResourceHubNode[] }) {
  return (
    <div className="mt-12">
      {nodes.map((node) => (
        <NodeItem node={node} key={node.id} />
      ))}
    </div>
  );
}

function NodeItem({ node }: { node: ResourceHubNode }) {
  const className = classNames(
    "flex gap-4 py-4",
    "cursor-pointer hover:bg-surface-accent",
    "border-b border-stroke-base first:border-t last:border-b-0",
  );
  const Icon = findIcon(node.type as NodeType);

  return (
    <div className={className}>
      <Icon size={48} />
      <div>
        <div className="font-bold text-lg">{node.name}</div>
        <div>3 items</div>
      </div>
    </div>
  );
}

function findIcon(nodeType: NodeType) {
  switch (nodeType) {
    case "document":
      return IconFile;
    case "folder":
      return IconFolder;
  }
}
