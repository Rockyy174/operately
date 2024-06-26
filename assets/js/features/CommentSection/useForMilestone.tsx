import * as Milestones from "@/models/milestones";
import * as Comments from "@/models/comments";

import { Item, ItemType, FormState } from "./form";

export function useForMilestone(milestone: Milestones.Milestone): FormState {
  let items: Item[] = milestone.comments!.map((c) => {
    const comment = c!.comment;
    const action = c!.action;

    if (action === "none") {
      return { type: "comment" as ItemType, insertedAt: comment.insertedAt, value: comment };
    }

    if (action === "complete") {
      return { type: "milestone-completed" as ItemType, insertedAt: comment.insertedAt, value: comment };
    }

    if (action === "reopen") {
      return { type: "milestone-reopened" as ItemType, insertedAt: comment.insertedAt, value: comment };
    }

    throw new Error("Invalid comment action " + action);
  });

  const [post, { loading: submittingPost }] = Milestones.usePostComment();
  const [edit, { loading: submittingEdit }] = Comments.useEditComment();

  const postComment = async (content: string) => {
    await post({
      variables: {
        input: {
          milestoneID: milestone.id,
          content: JSON.stringify(content),
          action: "none",
        },
      },
    });
  };

  const editComment = async (commentID: string, content: string) => {
    await edit({
      variables: {
        input: {
          commentId: commentID,
          content: JSON.stringify(content),
        },
      },
    });
  };

  const res = {
    items,
    postComment,
    editComment,
    submitting: submittingPost || submittingEdit,
  };

  return res;
}
