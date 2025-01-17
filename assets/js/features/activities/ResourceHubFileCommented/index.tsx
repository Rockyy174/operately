import * as People from "@/models/people";

import type { Activity } from "@/models/activities";
import type { ActivityContentResourceHubFileCommented } from "@/api";
import type { ActivityHandler } from "../interfaces";

import { Paths } from "@/routes/paths";
import { Summary } from "@/components/RichContent";
import React from "react";
import { feedTitle, fileLink, spaceLink } from "../feedItemLinks";

const ResourceHubFileCommented: ActivityHandler = {
  pageHtmlTitle(_activity: Activity) {
    throw new Error("Not implemented");
  },

  pagePath(activity: Activity): string {
    return Paths.resourceHubFilePath(content(activity).file!.id!);
  },

  PageTitle(_props: { activity: any }) {
    throw new Error("Not implemented");
  },

  PageContent(_props: { activity: Activity }) {
    throw new Error("Not implemented");
  },

  PageOptions(_props: { activity: Activity }) {
    return null;
  },

  FeedItemTitle({ activity, page }: { activity: Activity; page: any }) {
    const data = content(activity);

    const file = fileLink(data.file!);
    const space = spaceLink(data.space!);

    if (page === "space") {
      return feedTitle(activity, "commented on", file);
    } else {
      return feedTitle(activity, "commented on", file, "in the", space, "space");
    }
  },

  FeedItemContent({ activity }: { activity: Activity }) {
    const comment = content(activity).comment!;
    const commentContent = JSON.parse(comment.content!)["message"];
    return <Summary jsonContent={commentContent} characterCount={200} />;
  },

  feedItemAlignment(_activity: Activity): "items-start" | "items-center" {
    return "items-start";
  },

  commentCount(_activity: Activity): number {
    throw new Error("Not implemented");
  },

  hasComments(_activity: Activity): boolean {
    throw new Error("Not implemented");
  },

  NotificationTitle({ activity }: { activity: Activity }) {
    return People.firstName(activity.author!) + " commented on: " + content(activity).file!.name!;
  },

  NotificationLocation({ activity }: { activity: Activity }) {
    return content(activity).file!.name!;
  },
};

function content(activity: Activity): ActivityContentResourceHubFileCommented {
  return activity.content as ActivityContentResourceHubFileCommented;
}

export default ResourceHubFileCommented;
