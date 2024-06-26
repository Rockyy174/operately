import * as React from "react";

import { FeedItem, Container } from "../FeedItem";
import ActivityHandler from "@/features/activities";

export const GoalCheckIn: FeedItem = {
  typename: "ActivityContentGoalCheckIn",
  contentQuery: `
    update {
      id
      title
      message
      messageType
      updatableId
      insertedAt
      commentsCount

      content {
        __typename

        ... on UpdateContentGoalCheckIn {
          message

          targets {
            id
            name
            value
            previousValue
            unit
            from
            to
          }
        }
      }
    }

    goal {
      id
      name
    }
  `,

  component: ({ activity, content, page }) => {
    return (
      <Container
        title={<ActivityHandler.FeedItemTitle activity={activity} content={content} page={page} />}
        author={activity.author}
        time={activity.insertedAt}
        content={<ActivityHandler.FeedItemContent activity={activity} content={content} page={page} />}
      />
    );
  },
};
