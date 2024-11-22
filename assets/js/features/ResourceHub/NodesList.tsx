import React from "react";

import { ResourceHubNode } from "@/models/resourceHubs";
import { IconFolder, IconFile, IconPhoto, IconFileTypePdf, IconMovie } from "@tabler/icons-react";
import classNames from "classnames";
import { Paths } from "@/routes/paths";
import { DivLink } from "@/components/Link";

type NodeType = "document" | "folder" | "file";

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
  const Icon = findIcon(node.type as NodeType, node);
  const path = findPath(node.type as NodeType, node);

  return (
    <DivLink to={path} className={className}>
      <Icon size={48} />
      <div>
        <div className="font-bold text-lg">{node.name}</div>
        <div>3 items</div>
      </div>
    </DivLink>
  );
}

function findIcon(nodeType: NodeType, node: ResourceHubNode) {
  switch (nodeType) {
    case "document":
      return IconFile;
    case "folder":
      return IconFolder;
    case "file":
      if (node.file?.type?.includes("image")) return IconPhoto;
      if (node.file?.type?.includes("pdf")) return IconFileTypePdf;
      if (node.file?.type?.includes("video")) return IconMovie;
      return IconFile;
  }
}

function findPath(nodeType: NodeType, node: ResourceHubNode) {
  switch (nodeType) {
    case "document":
      return Paths.resourceHubDocumentPath(node.document!.id!);
    case "folder":
      return Paths.resourceHubFolderPath(node.folder!.id!);
    case "file":
      return "";
  }
}
