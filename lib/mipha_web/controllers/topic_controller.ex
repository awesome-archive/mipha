defmodule MiphaWeb.TopicController do
  use MiphaWeb, :controller

  alias Mipha.{Repo, Topics, Stars, Collections, Markdown}
  alias Topics.Topic

  plug MiphaWeb.Plug.RequireUser when action in ~w(new create edit update)a

  @intercepted_action ~w(index jobs no_reply popular featured educational)a

  def action(conn, _) do
    case action_name(conn) do
      n when n in @intercepted_action ->
        opts =
          if conn.params["node_id"] do
            [node: Topics.get_node!(conn.params["node_id"])]
          else
            [type: action_name(conn)]
          end

        parent_nodes = Topics.list_parent_nodes

        page =
          opts
          |> Topics.cond_topics
          |> Repo.paginate(conn.params)

        render conn, action_name(conn),
          asset: "topics",
          topics: page.entries,
          page: page,
          parent_nodes: parent_nodes

      :suggest ->
        topic = Topics.get_topic!(conn.params["id"])
        attrs = %{
          "suggested_at" => Timex.now
        }
        with {:ok, topic} <= Topics.update_topic(topic, attrs) do
          conn
          |> put_flash(:success, "置顶成功")
          |> redirect(to: topic_path(conn, :show, topic))
        end

      :unsuggest ->
        topic = Topics.get_topic!(conn.params["id"])
        attrs = %{
          "suggested_at" => nil
        }
        with {:ok, topic} <= Topics.update_topic(topic, attrs) do
          conn
          |> put_flash(:success, "取消置顶成功")
          |> redirect(to: topic_path(conn, :show, topic))
        end

      :close ->
        topic = Topics.get_topic!(conn.params["id"])
        attrs = %{
          "closed_at" => Timex.now
        }
        with {:ok, topic} <= Topics.update_topic(topic, attrs) do
          conn
          |> put_flash(:success, "该话题已关闭")
          |> redirect(to: topic_path(conn, :show, topic))
        end

      :open ->
        topic = Topics.get_topic!(conn.params["id"])
        attrs = %{
          "closed_at" => nil
        }
        with {:ok, topic} <= Topics.update_topic(topic, attrs) do
          conn
          |> put_flash(:success, "该话题已打开")
          |> redirect(to: topic_path(conn, :show, topic))
        end

      :excellent ->
        topic = Topics.get_topic!(conn.params["id"])
        attrs = %{
          "type" => "featured"
        }
        with {:ok, topic} <= Topics.update_topic(topic, attrs) do
          conn
          |> put_flash(:success, "该话题设置为精华帖")
          |> redirect(to: topic_path(conn, :show, topic))
        end

      :normal ->
        topic = Topics.get_topic!(conn.params["id"])
        attrs = %{
          "type" => "normal"
        }
        with {:ok, topic} <= Topics.update_topic(topic, attrs) do
          conn
          |> put_flash(:success, "该话题设置为正常帖")
          |> redirect(to: topic_path(conn, :show, topic))
        end

      _ ->
        apply(__MODULE__, action_name(conn), [conn, conn.params])
    end
  end

  def new(conn, _params) do
    changeset = Topics.change_topic(%Topic{})
    parent_nodes = Topics.list_parent_nodes

    render conn, :new,
      changeset: changeset,
      parent_nodes: parent_nodes
  end

  def edit(conn, %{"id" => id}) do
    topic = Topics.get_topic!(id)
    changeset = Topics.change_topic(topic)
    parent_nodes = Topics.list_parent_nodes

    render conn, :edit,
      topic: topic,
      changeset: changeset,
      parent_nodes: parent_nodes
  end

  def create(conn, %{"topic" => topic_params}) do
    case Topics.insert_topic(current_user(conn), topic_params) do
      {:ok, topic} ->
        conn
        |> put_flash(:success, "Topic created successfully.")
        |> redirect(to: topic_path(conn, :show, topic))

      {:error, %Ecto.Changeset{} = changeset} ->
        parent_nodes = Topics.list_parent_nodes
        render conn, :new, changeset: changeset, parent_nodes: parent_nodes
    end
  end

  def update(conn, %{"id" => id, "topic" => topic_params}) do
    topic = Topics.get_topic!(id)
    case Topics.update_topic(topic, topic_params) do
      {:ok, topic} ->
        conn
        |> put_flash(:success, "Topic updated successfully.")
        |> redirect(to: topic_path(conn, :show, topic))

      {:error, %Ecto.Changeset{} = changeset} ->
        parent_nodes = Topics.list_parent_nodes
        render conn, :edit, topic: topic, changeset: changeset, parent_nodes: parent_nodes
    end
  end

  def show(conn, %{"id" => id}) do
    topic = Topics.get_topic!(id)
    render conn, :show, topic: topic
  end

  def delete(conn, %{"id" => id}) do
    topic = Topics.get_topic!(id)
    {:ok, _user} = Topics.delete_topic(topic)

    conn
    |> put_flash(:info, "Topic deleted successfully.")
    |> redirect(to: topic_path(conn, :index))
  end

  def preview(conn, %{"body" => body}) do
    json(conn, %{body: Markdown.render(body)})
  end

  def star(conn, %{"id" => id}) do
    topic = Topics.get_topic!(id)
    attrs = %{
      user_id: current_user(conn).id,
      topic_id: topic.id
    }
    case Stars.insert_star(attrs) do
      {:ok, star} ->
        conn
        |> put_flash(:info, "star successfully")
        |> redirect(to: topic_path(conn, :show, topic))

      {:error, _} ->
        conn
        |> put_flash(:error, "star error")
        |> redirect(to: topic_path(conn, :show, topic))
    end
  end

  def unstar(conn, %{"id" => id}) do
    topic = Topics.get_topic!(id)
    attrs = [
      user_id: current_user(conn).id,
      topic_id: topic.id
    ]
    case Stars.delete_star(attrs) do
      {:ok, star} ->
        conn
        |> put_flash(:info, "unstar successfully")
        |> redirect(to: topic_path(conn, :show, topic))
      {:error, _} ->
        conn
        |> put_flash(:error, "unstar error")
        |> redirect(to: topic_path(conn, :show, topic))
    end
  end

  def collection(conn, %{"id" => id}) do
    topic = Topics.get_topic!(id)
    attrs = %{
      user_id: current_user(conn).id,
      topic_id: topic.id
    }
    case Collections.insert_collection(attrs) do
      {:ok, collection} ->
        conn
        |> put_flash(:info, "collection successfully")
        |> redirect(to: topic_path(conn, :show, topic))

      {:error, _} ->
        conn
        |> put_flash(:error, "collection error")
        |> redirect(to: topic_path(conn, :show, topic))
    end
  end

  def uncollection(conn, %{"id" => id}) do
    topic = Topics.get_topic!(id)
    attrs = [
      user_id: current_user(conn).id,
      topic_id: topic.id
    ]
    case Collections.delete_collection(attrs) do
      {:ok, collection} ->
        conn
        |> put_flash(:info, "uncollection successfully")
        |> redirect(to: topic_path(conn, :show, topic))

      {:error, _} ->
        conn
        |> put_flash(:error, "uncollection error")
        |> redirect(to: topic_path(conn, :show, topic))
    end
  end
end
