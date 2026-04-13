# AGENTS

This document is the single source of truth for agentic contributors working inside `/home/dell2duo/projects/todo`, a Phoenix 1.8+ app backed by PostgreSQL, Tailwind, esbuild, and colocated LiveView hooks. Follow every line—agents run unattended here.

## Repository Snapshot
- Elixir 1.15+, OTP app `:todo`; web layer lives under `lib/todo_web`, domain logic under `lib/todo`.
- Phoenix LiveView powers most UI; `Layouts.app/1` wraps every template, and `TodoWeb.CoreComponents` provides `<.input>`, `<.icon>`, `<.button>`, etc.
- Assets are bundled via Mix-managed Tailwind (v4 import syntax in `assets/css/app.css`) and esbuild; JS entrypoint is `assets/js/app.js` with `phoenix-colocated/todo` hooks auto-imported.
- Tests rely on ExUnit, Faker, LazyHTML helpers, and the SQL sandbox (manual mode). All code must run `mix precommit` before handoff.
- No `.cursor` or Copilot instruction files exist right now—this AGENTS doc replaces them.

## Core Commands
- `mix setup` – install deps, create/migrate DB, and compile/build assets once per environment change.
- `mix phx.server` or `iex -S mix phx.server` – run dev server with live reload; watchers for Tailwind/esbuild defined in `config/dev.exs` so no extra npm scripts exist.
- `mix test` – runs sqlite? (Postgres) tests after creat/migrate via alias; respects SQL sandbox.
- `mix test test/todo/cards_test.exs` – single-file tests; append `:42` for a specific line (`mix test test/todo/card_test.exs:27`).
- `mix test --only focus:true` – use tagged tests; pair with `@tag :focus` or `@moduletag :focus`.
- `mix format` – uses `.formatter.exs` plus `Phoenix.LiveView.HTMLFormatter`; formats `.ex`, `.exs`, `.heex`, and seeds.
- `mix precommit` – gating alias (`compile --warnings-as-errors`, `deps.unlock --unused`, `format`, `test`). Always finish with this.
- `mix assets.build` (CI) / `mix assets.deploy` (production) – run compile passes plus Tailwind + esbuild (with digest for deploy).
- `mix ecto.reset` – teardown/reseed dev DB; prefer targeted `mix ecto.migrate` or `mix ecto.rollback` when possible.

## Testing Playbook
- Default `test_helper.exs` starts ExUnit + Faker and sets `Todo.Repo` sandbox to `:manual`; wrap each test with `use Todo.DataCase` (or similar) when available.
- Use `start_supervised!/1` for processes; never rely on `Process.sleep/1`. Monitor with `Process.monitor/1` and assert on `{:DOWN, ...}`.
- For LiveView, drive assertions with `Phoenix.LiveViewTest` helpers and `LazyHTML` selectors; avoid brittle raw HTML asserts.
- Tag integration tests with `@moduletag :integration` or custom tags, then filter using `mix test --only integration`.
- Re-run only failed tests via `mix test --failed` after an initial run.
- Use `MIX_ENV=test mix ecto.create` only when the alias fails (e.g., first-time DB permission issues).

## Source Control Expectations
- Keep the working tree clean; never revert user changes. Stage only the files you touched.
- Prefer small, reviewable commits with descriptive messages; however do **not** create commits unless the user explicitly asks.
- When editing, default to ASCII; introduce Unicode only when the surrounding file already uses it deliberately.
- Run `mix precommit` and relevant `mix test` subsets before surfacing large changes; include test command output summary in PR/hand-off notes.

## Code Style – Elixir & Imports
- Modules live one-per-file; never nest `defmodule` declarations.
- Predicate function names end with `?` and guard-only helpers may use `is_` prefix; other names use `snake_case` verbs.
- Use pattern matching, `with` chains, and tagged tuples for error handling. Do not raise for expected failures—return `{:error, reason}` or `{:error, changeset}`.
- Avoid map access syntax on structs (`struct.field` or `Ecto.Changeset.get_field/2` instead). Lists require `Enum.at/2` or pattern matching; no index access via `list[index]`.
- Keep `alias`/`import` blocks alphabetized; prefer `alias Todo.{Cards, Cards.Card}` style for sibling modules.
- Use `@spec` for public functions whenever types improve readability, especially for contexts and LiveView callbacks.
- Never call `String.to_atom/1` on user input. Prefer `String.to_existing_atom/1` only when the atom definitely exists.
- Use Task concurrency via `Task.async_stream/3` with `timeout: :infinity` when enumerating remote calls.

## Phoenix & HEEx Fundamentals
- Always wrap your template body with `<Layouts.app flash={@flash} current_scope={@current_scope}>...</Layouts.app>`; this is enforced by runtime checks.
- Never sprinkle `<.flash_group>` directly—`Layouts` now owns flash rendering.
- Use `<.form for={@form}>` with `to_form/2` assigns set in the LiveView/Controller; never pass raw changesets to `<.form>`.
- Build inputs exclusively with `<.input>`; overriding `class` removes defaults, so supply the full Tailwind class set when doing so.
- HEEx attributes use the list syntax: `class={["px-4", @active && "text-primary"]}`. Conditionals inside attr lists must be wrapped in `if(...)` to avoid compilation errors.
- To render literal `{` or `}` characters, add `phx-no-curly-interpolation` on the parent `<pre>`/`<code>`.
- Comments use `<%!-- --%>` only. Never use `<%# ... %>`.
- Replace `else if` chains with `cond` or nested `case`; Elixir does not support `else if`.

## LiveView Streams & Hooks
- Collections displayed in LiveViews should use `stream(socket, :collection, data)` plus `phx-update="stream"` containers to prevent DOM churn.
- Re-stream (`stream(..., reset: true)`) whenever filters change; streams are not enumerable, so refetch instead of `Enum.filter`.
- Manage empty states via CSS (`<div class="hidden only:block">No cards yet</div>`) within the stream container.
- When toggling edit state per item, reinsert that record via `stream_insert` so DOM IDs stay consistent.
- Hooks live either as colocated scripts inside `.heex` (`:type={Phoenix.LiveView.ColocatedHook}` with names like `.PhoneNumber`) or inside `assets/js` registered in `LiveSocket`. When a hook manipulates its own DOM children, set `phx-update="ignore"`.
- Use `push_event/3` to talk to hooks; always return the updated socket (`{:noreply, push_event(socket, "status", payload)}`).

## Routing & Layouts
- Router scopes already alias `TodoWeb`; declare routes as `live "/", BoardLive, :index` without extra `alias` boilerplate.
- Keep LiveViews named `TodoWeb.<Feature>Live`; controllers/components follow `TodoWeb.<Namespace>`.
- Verified routes (the `~p"/cards/#{card}"` sigil) are available everywhere via `TodoWeb` macro; prefer them over `Routes.card_path/2`.
- Use authenticated `live_session`s so `current_scope` is always available; missing `current_scope` errors mean the route belongs in the correct session or you forgot to pass it to `Layouts.app`.

## Ecto & Data
- Preload associations before rendering templates; LiveView disconnects quickly if you access unloaded associations inside assigns.
- Never include programmatic foreign keys (e.g., `user_id`) in `cast/3`; assign them manually before calling `Repo.insert/1`.
- Define schema fields using `:string`, even for `text` columns (Ecto standard). Keep migration timestamps via `timestamps(type: :utc_datetime)` for consistency.
- Generate migrations with `mix ecto.gen.migration descriptive_name`; do not handcraft filenames.
- Use changeset helpers (`Ecto.Changeset.validate_required`, `validate_number`) and remember they only run when that field is present—`:allow_nil` is unnecessary.
- Prefer Repo multi-operations via `Ecto.Multi` when orchestrating multiple inserts/updates.

## Assets, CSS, and JS
- `assets/css/app.css` already contains Tailwind v4 imports plus heroicons/daisyUI plugins. Maintain the `@import` + `@source` block at the top; never remove it. New custom CSS should live below the plugin declarations.
- Tailwind classes should be composed manually—avoid `@apply`. Even though daisyUI plugins exist for legacy reasons, new UI work should lean on bespoke Tailwind stacks for a distinct look.
- Backgrounds should use gradients/shapes/patterns instead of flat colors; define CSS variables for repeated palettes.
- `app.js` bootstraps `LiveSocket` with `phoenix-colocated` hooks. When adding new hooks, export them from `assets/js/hooks/<name>.js` (or colocate) and merge into the `hooks` object.
- Keep `topbar` progress bar configuration consistent; adjust colors through that module if brand colors change.
- No external `<script>` or `<link>` tags belong in templates—import libraries through the esbuild pipeline only.

## Error Handling & Logging
- Favor `with` statements for multi-step operations; pattern-match on `{:ok, value}` / `{:error, reason}` and provide explicit fallback clauses.
- Use `Logger` macros with structured metadata; keep log noise low in production, but feel free to use verbose logging guarded by `if Mix.env() == :dev do ... end` during debugging.
- When raising errors, use descriptive exception modules or `raise ArgumentError, "message"`; never `raise "string"` without context.
- Wrap potentially failing IO or HTTP operations in `case Req.request(...) do` statements and propagate errors up.

## HTTP & External Calls
- Use the bundled `Req` client (`Req.new(...) |> Req.get!()`) for outbound HTTP; `:httpoison`, `:tesla`, and `:httpc` are forbidden.
- Configure reusable Req clients inside contexts, not LiveViews. Keep them supervised if they maintain connections.
- For GraphQL/JSON APIs, prefer decoding via `Jason` and validating keys with `with {:ok, value} <- Map.fetch(...)`.

## Tooling Notes
- `mix phx.gen.*` generators are modernized for Phoenix 1.7/1.8; prefer them over copying code. Remove scaffolding you don't need.
- Live reload is augmented: in development you can press `c` or `d` with an element selected to open the definition (see `assets/js/app.js`). Keep this binding working when tweaking JS.
- Configure environment secrets via standard OS env vars read inside `config/runtime.exs`; never check secrets into git.

## UI & UX Expectations
- Strive for world-class UI: purposeful typography (avoid Inter/Roboto/Arial defaults), bold color/focus states, and micro-interactions (hover reveals, loading shimmer, button press depth).
- Provide delightful transitions (page fade, staggered cards) but avoid gratuitous motion. Use Tailwind `transition` utilities or Alpine-style hooks if needed.
- Design with both desktop and mobile breakpoints in mind. Use CSS Grid/Flex thoughtfully to keep layouts intentional rather than boilerplate.
- Document any bespoke design tokens you add (colors, radii) near the declaration site.

## Form Handling Cheatsheet
- Build forms from `to_form(context.change_entity(...))` assigns stored in `socket.assigns`. Access fields via `@form[:field]` only.
- Give every form and major interactive element a deterministic DOM id (`id="card-form"`); tests reference these IDs via `element/2`.
- Validation flows: `handle_event("validate", %{"entity" => params}, socket)` → `changeset = Context.change_entity(entity, params)` → `assign(socket, form: to_form(%{changeset | action: :validate}))`.
- Submit flows: `handle_event("save", %{"entity" => params}, socket)` → call context -> `{:noreply, push_navigate(...)}` on success or reassign form with errors.

## Database & Fixtures
- Use factories under `test/support` (create them if absent) or helpers provided by contexts. Random data can come from `Faker` but keep deterministic values where assertions depend on them.
- Wrap DB helpers with `Todo.DataCase` for automatic sandbox checkout/checkout release.
- Seeds live in `priv/repo/seeds.exs`; run via `mix run priv/repo/seeds.exs` after `mix ecto.setup` when new data is required locally.

## Final Checklist Before Hand-off
- [ ] Updated docs/tests accompany behavior changes.
- [ ] `mix format`, `mix test`, and `mix precommit` succeed locally; rerun `mix assets.build` if you touched `assets/`.
- [ ] Database migrations are reversible and named descriptively; run `mix ecto.migrate` before tests.
- [ ] Notes about new environment variables or external services are added to README and, if relevant, this AGENTS file.

Agents that follow these ~150 lines should be able to ramp instantly, run the right commands, and keep the codebase consistent and safe.
