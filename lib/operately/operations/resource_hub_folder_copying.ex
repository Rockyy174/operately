defmodule Operately.Operations.ResourceHubFolderCopying do
  import Ecto.Query, only: [from: 2]

  alias Operately.{Repo, ResourceHubs}
  alias Operately.ResourceHubs.{Node, Document, File, Link, Folder}
  alias Operately.Notifications.SubscriptionList

  def run(resource_hub, folder) do
    Repo.transaction(fn ->
      new_folder = copy_main_folder(folder)

      folder.id
      |> query_folder_children()
      |> copy_nodes(resource_hub, new_folder)
      |> copy_subscriptions_list()
      |> separate_nodes()
      |> Enum.map(fn children_group ->
        copy_node_children(children_group)
      end)
      |> List.flatten()
    end)
  end

  defp copy_main_folder(folder) do
      node_attrs = Map.from_struct(folder.node)
      {:ok, new_node} = ResourceHubs.create_node(node_attrs)

      folder_attrs =
        Map.from_struct(folder)
        |> Map.put(:node_id, new_node.id)

      {:ok, new_folder} = ResourceHubs.create_folder(folder_attrs)
      new_folder
  end

  defp copy_nodes(nodes, resource_hub, parent_folder) do
    nodes = Enum.map(nodes, fn n -> Map.put(n, :new_id, Ecto.UUID.generate()) end)

    data = Enum.map(nodes, fn n ->
      now = get_now()

      %{
        id: n.new_id,
        resource_hub_id: resource_hub.id,
        parent_folder_id: parent_folder.id,
        name: n.name,
        type: n.type,
        inserted_at: now,
        updated_at: now,
      }
    end)

    count = length(data)
    {^count, new_nodes} = Repo.insert_all(Node, data, returning: true)

    Enum.map(new_nodes, fn new_node ->
      original_node = Enum.find(nodes, &(&1.new_id == new_node.id))

      Map.merge(new_node, %{
        folder: original_node.folder,
        document: original_node.document,
        link: original_node.link,
        file: original_node.file,
      })
    end)
  end

  defp copy_node_children({:documents, documents}) do
    data = Enum.map(documents, fn n = %{document: d} ->
      now = get_now()
      %{
        node_id: n.id,
        author_id: d.author_id,
        subscription_list_id: d.subscription_list_id,
        content: d.content,
        inserted_at: now,
        updated_at: now,
      }
    end)

    count = length(data)
    {^count, new_documents} = Repo.insert_all(Document, data, returning: true)

    new_documents
  end

  defp copy_node_children({:files, files}) do
    data = Enum.map(files, fn n = %{file: f} ->
      now = get_now()
      %{
        node_id: n.id,
        author_id: f.author_id,
        subscription_list_id: f.subscription_list_id,
        blob_id: f.blob_id,
        preview_blob_id: f.preview_blob_id,
        description: f.description,
        inserted_at: now,
        updated_at: now,
      }
    end)

    count = length(data)
    {^count, new_files} = Repo.insert_all(File, data, returning: true)

    new_files
  end

  defp copy_node_children({:links, links}) do
    data = Enum.map(links, fn n = %{link: l} ->
      now = get_now()
      %{
        node_id: n.id,
        author_id: l.author_id,
        subscription_list_id: l.subscription_list_id,
        url: l.url,
        description: l.description,
        type: l.type,
        inserted_at: now,
        updated_at: now,
      }
    end)

    count = length(data)
    {^count, new_links} = Repo.insert_all(Link, data, returning: true)

    new_links
  end

  defp copy_node_children({:folders, folders}) do
    data = Enum.map(folders, fn n ->
      now = get_now()
      %{
        node_id: n.id,
        inserted_at: now,
        updated_at: now,
      }
    end)

    count = length(data)
    {^count, new_folders} = Repo.insert_all(Folder, data, returning: true)

    new_folders
  end

  defp copy_subscriptions_list(nodes) do
    children =
      Enum.map(nodes, fn node ->
        cond do
          node.link ->
            Map.put(node.link, :new_subscription_list_id, Ecto.UUID.generate())
          node.file ->
            Map.put(node.file, :new_subscription_list_id, Ecto.UUID.generate())
          node.document ->
            Map.put(node.document, :new_subscription_list_id, Ecto.UUID.generate())
          true -> nil
        end
      end)
      |> Enum.filter(&(not is_nil(&1)))

    data = Enum.map(children, fn child ->
        now = get_now()

        %{
          id: child.new_subscription_list_id,
          parent_id: child.subscription_list.parent_id,
          parent_type: child.subscription_list.parent_type,
          send_to_everyone: child.subscription_list.send_to_everyone,
          inserted_at: now,
          updated_at: now,
        }
      end)

    count = length(data)
    {^count, new_lists} = Repo.insert_all(SubscriptionList, data, returning: true)

    Enum.map(nodes, fn node ->
      child = Enum.find(children, fn c ->
        cond do
          node.link && node.link.id == c.id -> true
          node.file && node.file.id == c.id -> true
          node.document && node.document.id == c.id -> true
          true -> false
        end
      end)

      if child do
        list = Enum.find(new_lists, &(&1.id == child.new_subscription_list_id))

        cond do
          node.link ->
            link = Map.put(node.link, :subscription_list, list)
            Map.put(node, :link, link)
          node.file -> true
            file = Map.put(node.file, :subscription_list, list)
            Map.put(node, :file, file)
          node.document -> true
            document = Map.put(node.document, :subscription_list, list)
            Map.put(node, :document, document)
        end
      else
        node
      end
    end)
    |> IO.inspect()
  end

  defp query_folder_children(folder_id) do
    from(n in Node,
      left_join: folder in assoc(n, :folder),
      left_join: n_folder in assoc(folder, :node),
      left_join: file in assoc(n, :file),
      left_join: n_file in assoc(file, :node),
      left_join: subs_list_file in assoc(file, :subscription_list),
      left_join: subs_file in assoc(subs_list_file, :subscriptions),
      left_join: document in assoc(n, :document),
      left_join: n_document in assoc(document, :node),
      left_join: subs_list_document in assoc(document, :subscription_list),
      left_join: subs_document in assoc(subs_list_document, :subscriptions),
      left_join: link in assoc(n, :link),
      left_join: n_link in assoc(link, :node),
      left_join: subs_list_link in assoc(link, :subscription_list),
      left_join: subs_link in assoc(subs_list_link, :subscriptions),
      preload: [
        link: {link, node: n_link, subscription_list: {subs_list_link, subscriptions: subs_link}},
        document: {document, node: n_document, subscription_list: {subs_list_document, subscriptions: subs_document}},
        file: {file, node: n_file, subscription_list: {subs_list_file, subscriptions: subs_file}},
        folder: {folder, node: n_folder},
      ],
      where: n.parent_folder_id == ^folder_id
    )
    |> Repo.all()
  end

  defp separate_nodes(nodes) do
    nodes
    |> Enum.reduce(%{links: [], folders: [], files: [], documents: []}, fn node, acc ->
      cond do
        node.link -> Map.update!(acc, :links, &([node | &1]))
        node.folder -> Map.update!(acc, :folders, &([node | &1]))
        node.file -> Map.update!(acc, :files, &([node | &1]))
        node.document -> Map.update!(acc, :documents, &([node | &1]))
      end
    end)
    |> Enum.into([])
  end

  defp get_now, do: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
end
