defmodule ExDeskWeb.Markdown do
  use Phoenix.Component

  @doc """
  Renders markdown content.
  """
  attr :content, :string, required: true
  attr :class, :string, default: nil
  attr :opts, :list, default: []

  def markdown(assigns) do
    ~H"""
    <div class={["prose prose-sm prose-slate max-w-none text-base-content/70", @class]}>
      {render_markdown(@content, @opts)}
    </div>
    """
  end

  defp render_markdown(nil, _), do: ""

  defp render_markdown(content, opts) do
    default_opts = [extension: [header_ids: ""]]
    final_opts = Keyword.merge(default_opts, opts)

    content
    |> MDEx.to_html!(final_opts)
    |> Phoenix.HTML.raw()
  end
end
