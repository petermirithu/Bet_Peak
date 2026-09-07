defmodule BetPeakWeb.VerifyAccountHTML do
  use BetPeakWeb, :html

  def index(assigns) do
    ~H"""
    <Layouts.auth flash={@flash} current_scope={@current_scope}>
      <div class="mb-7">
        <h1 class="text-3xl font-extrabold leading-tight text-[#161616] sm:text-4xl">
          Verify account
        </h1>

        <div class="card card-md bg-base-100 w-96 shadow-sm mt-10">
          <div class="card-body">
            <h2 class="card-title">Hello {@current_scope.user.first_name} 👋🏼!</h2>

            <p
              :if={!@current_scope.user.confirmed_at}
              class="mt-3 text-md leading-6 text-[#161616]/60"
            >
              You need to check your email and follow the instructions given to verify your acocunt.
            </p>

            <div :if={@current_scope.user.confirmed_at}>
              <p class="mt-3 text-md leading-6 text-[#161616]/60">
                Your account is already confirmed!
              </p>

              <.button
                navigate={~p"/"}
                class="mt-3 group rounded-2xl flex h-12 w-full items-center justify-center gap-2 bg-[#161616] px-5 font-bold text-white shadow-[0_8px_24px_rgba(22,22,22,0.16)] transition hover:-translate-y-0.5 hover:bg-[#735700] focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#b28708]"
              >
                Back to home
                <.icon
                  name="hero-arrow-right-mini"
                  class="size-4 transition-transform group-hover:translate-x-1"
                />
              </.button>
            </div>
          </div>
        </div>
      </div>
    </Layouts.auth>
    """
  end
end
