defmodule OperatelyWeb.Api.Mutations.EditGoal do
  use TurboConnect.Mutation
  use OperatelyWeb.Api.Helpers

  inputs do
    field :goal_id, :string
    field :name, :string
    field :champion_id, :string
    field :reviewer_id, :string
    field :timeframe, :timeframe
    field :added_targets, list_of(:create_target_input)
    field :updated_targets, list_of(:update_target_input)
    field :description, :string
  end

  outputs do
    field :goal, :goal
  end

  def call(conn, inputs) do
    goal = Operately.Goals.get_goal!(inputs.goal_id)
    {:ok, goal} = Operately.Operations.GoalEditing.run(me(conn), goal, inputs)

    {:ok, %{goal: Serializer.serialize(goal, level: :essential)}}
  end
end