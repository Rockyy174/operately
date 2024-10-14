defmodule Operately.Support.Features.FeedSteps do
  alias Operately.Support.Features.UI
  alias Operately.People.Person

  def assert_goal_added(ctx, author: author) do
    ctx |> assert_feed_item_exists(author, "added this goal", "")
  end

  def assert_goal_edited(ctx, author: author) do
    ctx |> assert_feed_item_exists(author, "edited the goal", "")
  end

  def assert_goal_edited(ctx, author: author, goal_name: name) do
    ctx |> assert_feed_item_exists(author, "edited the #{name} goal", "")
  end

  def assert_goal_check_in_acknowledgement(ctx, author: author) do
    ctx |> assert_feed_item_exists(author, "acknowledged", "")
  end

  def assert_project_created(ctx, author: author) do
    ctx |> assert_feed_item_exists(author, "created the project", "")
  end

  def assert_project_created(ctx, author: author, project_name: project_name) do
    ctx |> assert_feed_item_exists(author, "created the #{project_name} project", "")
  end

  def assert_project_moved(ctx, author: author, old_space: old_space, new_space: new_space) do
    ctx |> assert_feed_item_exists(author, "moved the project", "From #{old_space.name} to #{new_space.name}")
  end

  def assert_project_archived(ctx, author: author) do
    ctx |> assert_feed_item_exists(author, "archived this project", "")
  end

  def assert_project_retrospective_posted(ctx, author: author) do
    ctx |> assert_feed_item_exists(author, "closed the project and submitted a retrospective", "")
  end

  def assert_project_paused(ctx, author: author) do
    ctx |> assert_feed_item_exists(author, "paused the project", "")
  end

  def assert_project_paused(ctx, author: author, project_name: project_name) do
    ctx |> assert_feed_item_exists(author, "paused the #{project_name} project", "")
  end

  def assert_project_resumed(ctx, author: author) do
    ctx |> assert_feed_item_exists(author, "resumed the project", "")
  end

  def assert_project_resumed(ctx, author: author, project_name: project_name) do
    ctx |> assert_feed_item_exists(author, "resumed the #{project_name} project", "")
  end

  def assert_project_renamed(ctx, author: author) do
    ctx |> assert_feed_item_exists(author, "renamed the project", "")
  end

  def assert_project_renamed(ctx, author: author, project_name: project_name) do
    ctx |> assert_feed_item_exists(author, "renamed the #{project_name} project", "")
  end

  def assert_project_milestone_commented(ctx, author: author, milestone_tile: milestone_title, comment: comment) do
    ctx |> assert_feed_item_exists(author, "commented on the #{milestone_title} milestone", comment)
  end

  def assert_project_timeline_edited(ctx, attrs) do
    title = case Keyword.get(attrs, :project_name, nil) do
      nil -> "edited the timeline"
      name -> "edited the timeline on the #{name} project"
    end
    author = Keyword.get(attrs, :author)
    messages = Keyword.get(attrs, :messages)

    ctx
    |> UI.assert_text(Person.first_name(author))
    |> UI.assert_text(title)
    |> then(fn ctx ->
      Enum.each(messages, fn message ->
        ctx |> UI.assert_text(message)
      end)

      ctx
    end)
  end

  #
  # Utility functions
  #

  def assert_feed_item_exists(ctx, %{author: author, title: title}) do
    ctx |> assert_feed_item_exists(author, title, "")
  end

  def assert_feed_item_exists(ctx, %{author: author, title: title, subtitle: subtitle}) do
    ctx |> assert_feed_item_exists(author, title, subtitle)
  end

  def assert_feed_item_exists(ctx, author, title, subtitle) do
    ctx
    |> UI.assert_text(Person.first_name(author))
    |> UI.assert_text(title)
    |> UI.assert_text(subtitle)
  end
end
