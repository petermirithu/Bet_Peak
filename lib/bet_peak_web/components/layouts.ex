defmodule BetPeakWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use BetPeakWeb, :html
  alias BetPeakWeb.Helpers

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
            <span class="text-xs font-semibold text-[#161616]/40">
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

  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current scope"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <div class="drawer min-h-screen bg-[#f6f4ee] lg:drawer-open">
      <input id="app-sidebar" type="checkbox" class="drawer-toggle" />

      <div class="drawer-content min-w-0">
        <header class="sticky top-0 z-20 flex h-16 items-center justify-between border-b border-[#ded9ce] bg-[#f6f4ee]/95 px-4 backdrop-blur lg:hidden">
          <label
            for="app-sidebar"
            class="grid size-10 cursor-pointer place-items-center text-[#161616] transition hover:bg-[#ece8de]"
            aria-label="Open navigation"
          >
            <.icon name="hero-bars-3" class="size-6" />
          </label>
          <span class="text-sm font-extrabold uppercase text-[#161616]">
            Bet Peak
          </span>
          <%= if @current_scope do %>
            <div class="grid size-9 place-items-center bg-[#161616] text-xs font-bold text-[#f4bf25]">
              {Helpers.user_initials(@current_scope.user)}
            </div>
          <% else %>
            <div class="size-9"></div>
          <% end %>
        </header>

        <main id="app-content" class="min-h-screen w-full">
          {render_slot(@inner_block)}
        </main>
      </div>

      <aside class="drawer-side z-30">
        <label for="app-sidebar" aria-label="Close navigation" class="drawer-overlay"></label>
        <div class="flex min-h-full w-72 flex-col bg-[#11110f] text-white shadow-2xl">
          <div class="flex h-24 items-center border-b border-white/10 px-6">
            <img
              src={~p"/images/logo.png"}
              alt="Bet Peak"
              class="h-16 w-16 object-contain"
            />
            <div class="ml-3">
              <p class="text-lg font-extrabold">BET PEAK</p>
              <p class="text-[0.6rem] font-semibold text-[#f4bf25]">
                Peak odds
              </p>
            </div>
          </div>

          <nav class="flex-1 px-4 py-6" aria-label="Primary navigation">
            <p class="mb-3 px-3 text-[0.65rem] font-bold text-white/35">
              Main menu
            </p>
            <ul class="space-y-1">
              <li>
                <.link
                  navigate={~p"/"}
                  class="flex h-11 items-center gap-3 px-3 text-sm font-semibold text-white/70 transition hover:bg-white/8 hover:text-white"
                >
                  <.icon name="hero-home" class="size-5 text-[#f4bf25]" /> Home
                </.link>
              </li>
              <li>
                <span class="flex h-11 items-center gap-3 px-3 text-sm font-semibold text-white/45">
                  <.icon name="hero-trophy" class="size-5" /> Football
                </span>
              </li>
              <li>
                <span class="flex h-11 items-center gap-3 px-3 text-sm font-semibold text-white/45">
                  <.icon name="hero-chart-bar" class="size-5" /> Baseball
                </span>
              </li>
            </ul>

            <%= if admin?(@current_scope) do %>
              <p class="mb-3 mt-8 px-3 text-[0.65rem] font-bold text-white/35">
                Administration
              </p>
              <ul class="space-y-1">
                <li>
                  <.link
                    navigate={~p"/admin"}
                    class="flex h-11 items-center gap-3 px-3 text-sm font-semibold text-white/70 transition hover:bg-white/8 hover:text-white"
                  >
                    <.icon name="hero-squares-2x2" class="size-5 text-[#f4bf25]" /> Dashboard
                  </.link>
                </li>
                <li>
                  <.link
                    navigate={~p"/admin/users"}
                    class="flex h-11 items-center gap-3 px-3 text-sm font-semibold text-white/70 transition hover:bg-white/8 hover:text-white"
                  >
                    <.icon name="hero-users" class="size-5 text-[#f4bf25]" /> Users
                  </.link>
                </li>
                <li>
                  <.link
                    navigate={~p"/admin/sports"}
                    class="flex h-11 items-center gap-3 px-3 text-sm font-semibold text-white/70 transition hover:bg-white/8 hover:text-white"
                  >
                    <.icon name="hero-play" class="size-5 text-[#f4bf25]" /> Sports
                  </.link>
                </li>
                <li>
                  <.link
                    navigate={~p"/admin/teams"}
                    class="flex h-11 items-center gap-3 px-3 text-sm font-semibold text-white/70 transition hover:bg-white/8 hover:text-white"
                  >
                    <.icon name="hero-user-group" class="size-5 text-[#f4bf25]" /> Teams
                  </.link>
                </li>
                <li>
                  <.link
                    navigate={~p"/admin/games"}
                    class="flex h-11 items-center gap-3 px-3 text-sm font-semibold text-white/70 transition hover:bg-white/8 hover:text-white"
                  >
                    <.icon name="hero-trophy" class="size-5 text-[#f4bf25]" /> Games
                  </.link>
                </li>
              </ul>
            <% end %>
          </nav>

          <div class="border-t border-white/10 p-4">
            <%= if @current_scope do %>
              <div class="mb-3 flex items-center gap-3 px-2">
                <div class="relative grid rounded-2xl size-11 shrink-0 place-items-center bg-[#f4bf25] font-extrabold text-[#161616]">
                  {Helpers.user_initials(@current_scope.user)}
                  <span class="absolute -bottom-0.5 -right-0.5 rounded-2xl size-3 border-2 border-[#11110f] bg-emerald-400"></span>
                </div>
                <div class="min-w-0">
                  <p class="truncate text-sm font-bold">
                    {user_display_name(@current_scope.user)}
                  </p>
                  <p class="truncate text-xs text-white/45">{@current_scope.user.email}</p>
                </div>
              </div>
              <div class="grid grid-cols-2 gap-2">
                <.link
                  navigate={~p"/users/settings"}
                  class="flex h-10 items-center justify-center gap-2 rounded-2xl border border-white/10 text-xs font-semibold text-white/65 transition hover:border-white/20 hover:bg-white/8 hover:text-white"
                >
                  <.icon name="hero-cog-6-tooth" class="size-4" /> Settings
                </.link>
                <.link
                  href={~p"/users/log-out"}
                  method="delete"
                  class="flex h-10 items-center justify-center gap-2 rounded-2xl border border-white/10 text-xs font-semibold text-white/65 transition hover:border-red-400/30 hover:bg-red-400/10 hover:text-red-300"
                >
                  <.icon name="hero-arrow-right-start-on-rectangle" class="size-4" /> Log out
                </.link>
              </div>
            <% else %>
              <.link
                navigate={~p"/users/log-in"}
                class="flex h-11 items-center justify-center bg-[#f4bf25] text-sm font-bold text-[#161616] transition hover:bg-[#ffd75a]"
              >
                Log in
              </.link>
            <% end %>
          </div>
        </div>
      </aside>
    </div>
    <.flash_group flash={@flash} />
    """
  end

  defp admin?(%{user: %{role: :admin}}), do: true
  defp admin?(%{user: %{is_superuser: true}}), do: true
  defp admin?(_current_scope), do: false

  defp user_display_name(user) do
    [user.first_name, user.last_name]
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.join(" ")
    |> case do
      "" -> user.email
      name -> name
    end
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
