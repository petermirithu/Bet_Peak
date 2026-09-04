defmodule BetPeakWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use BetPeakWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://phoenix.hexdocs.pm/scopes.html)"

  slot :inner_block, required: true

  def auth(assigns) do
    ~H"""
    <main
      id="auth-shell"
      class="min-h-screen bg-[#f6f4ee] text-[#161616] lg:grid lg:grid-cols-[minmax(22rem,0.88fr)_minmax(34rem,1.12fr)]"
    >
      <section class="relative min-h-52 overflow-hidden bg-[#080808] lg:sticky lg:top-0 lg:h-screen">
        <img
          src={~p"/images/premier_league.jpeg"}
          alt="Football stars under the stadium lights"
          class="absolute inset-0 size-full object-cover object-[center_32%] lg:object-center"
        />
        <div class="absolute inset-0 bg-[linear-gradient(180deg,rgba(8,8,8,0.05)_25%,rgba(8,8,8,0.92)_100%)]">
        </div>
        <div class="absolute inset-x-0 bottom-0 p-6 text-white sm:p-8 lg:p-12">
          <div class="mb-4 hidden h-px w-14 bg-[#f4bf25] lg:block"></div>
          <p class="hidden max-w-md text-3xl font-bold leading-tight lg:block">
            Your front-row seat to every fixture.
          </p>
          <p class="mt-3 hidden max-w-sm text-sm leading-6 text-white/70 lg:block">
            Follow the action, back your instincts, and stay close to the game.
          </p>
        </div>
      </section>

      <section class="relative flex min-h-[calc(100vh-13rem)] items-center px-5 py-10 sm:px-10 lg:min-h-screen lg:px-14 lg:py-14 xl:px-20">
        <div class="mx-auto w-full max-w-xl">
          <div class="mb-8 flex items-center justify-between">
            <img
              src={~p"/images/logo.png"}
              alt="Bet Peak"
              class="h-40 w-auto object-contain object-left mix-blend-multiply sm:h-14"
            />
            <span class="text-xs font-semibold tracking-[0.16em] text-[#161616]/40">
              Peak odds. Max returns.
            </span>
          </div>
          <div>
            {render_slot(@inner_block)}
          </div>
          <p class="mt-8 flex items-center gap-2 text-xs text-[#161616]/45">
            <.icon name="hero-shield-check-mini" class="size-4 text-[#947000]" />
            Your details are encrypted and securely stored.
          </p>
        </div>
      </section>
    </main>
    <.flash_group flash={@flash} />
    """
  end

  def app(assigns) do
    ~H"""
    <div class="drawer lg:drawer-open">
      <input id="my-drawer-3" type="checkbox" class="drawer-toggle" />
      <div class="drawer-content flex flex-col items-center justify-center">
        <label for="my-drawer-3" class="btn drawer-button lg:hidden">
          Open drawer
        </label>
        {render_slot(@inner_block)}
      </div>
      <div class="drawer-side">
        <label for="my-drawer-3" aria-label="close sidebar" class="drawer-overlay"></label>
        <ul class="menu bg-base-200 min-h-full w-80 p-4">
          <h1 class="text-lg font-bold">Bet Peak</h1>
          <li><a>Football</a></li>
          <li><a>Baseball</a></li>

          <ul class="menu menu-horizontal w-full relative z-10 flex items-center gap-4 px-4 sm:px-6 lg:px-8 justify-end">
            <%= if @current_scope do %>
              <li>
                {@current_scope.user.email}
              </li>
              <li>
                <.link href={~p"/users/settings"}>Settings</.link>
              </li>
              <li>
                <.link href={~p"/users/log-out"} method="delete">Log out</.link>
              </li>
            <% else %>
              <li>
                <.link href={~p"/users/register"}>Register</.link>
              </li>
              <li>
                <.link href={~p"/users/log-in"}>Log in</.link>
              </li>
            <% end %>
          </ul>
        </ul>
      </div>
    </div>
    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={
          show(".phx-client-error #client-error")
          |> JS.remove_attribute("hidden", to: ".phx-client-error #client-error")
        }
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={
          show(".phx-server-error #server-error")
          |> JS.remove_attribute("hidden", to: ".phx-server-error #server-error")
        }
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 [[data-theme-source=system]_&]:!left-0 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
