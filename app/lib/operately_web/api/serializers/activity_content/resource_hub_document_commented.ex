defimpl OperatelyWeb.Api.Serializable, for: Operately.Activities.Content.ResourceHubDocumentCommented do
  alias OperatelyWeb.Api.Serializer

  def serialize(content, level: :essential) do
    document = Map.put(content["document"], :node, content["node"])

    %{
      space: Serializer.serialize(content["space"], level: :essential),
      document: Serializer.serialize(document, level: :essential),
      comment: Serializer.serialize(content["comment"], level: :essential),
    }
  end
end
