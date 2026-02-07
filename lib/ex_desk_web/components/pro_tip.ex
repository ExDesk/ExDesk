defmodule ExDeskWeb.ProTip do
  @moduledoc """
  Renders a Pro Tip Card.

  A visually appealing gradient card that displays helpful tips
  and suggestions to users, styled with the Elixir/Phoenix theme.
  """
  use Phoenix.Component

  @doc """
  Renders a pro tip card with gradient background.

  ## Attributes

    * `:title` - The title of the tip (default: "Pro Tip")
    * `:action_label` - The button label (default: "Learn More")

  ## Slots

    * `:inner_block` - The tip content

  ## Examples

      <.pro_tip>
        You can use keyboard shortcuts to navigate quickly between tickets.
      </.pro_tip>

      <.pro_tip title="Did you know?" action_label="Explore">
        ExDesk supports integrations with over 50 third-party tools.
      </.pro_tip>
  """
  attr :title, :string, default: "Pro Tip"
  attr :action_label, :string, default: "Learn More"
  attr :class, :string, default: nil
  attr :rest, :global

  slot :inner_block, required: true

  def pro_tip(assigns) do
    ~H"""
    <div
      class={[
        "card bg-gradient-to-br from-indigo-500 to-purple-600 text-white shadow-xl",
        @class
      ]}
      {@rest}
    >
      <div class="card-body">
        <h2 class="card-title">{@title}</h2>

        <p>{render_slot(@inner_block)}</p>

        <div class="card-actions justify-end mt-4">
          <button class="btn btn-sm btn-ghost bg-white/20 text-white hover:bg-white/30 border-none">
            {@action_label}
          </button>
        </div>
      </div>
    </div>
    """
  end
end
