# widget_list Rails 8 caller

This is a **fresh Rails 8.1.4 app generated with `rails new . --minimal --database=sqlite3`** and then configured to call the local `widget_list` gem. It has two working pages:

- `/` — a Sequel SQL list with Ajax search, paging, sorting, and CSV export.
- `/ransack` — the same SQLite records through Active Record and Ransack. Open the down arrow beside the search field to add a filter such as **Name contains Apple**.

It uses Ruby 3.4.11, SQLite, Sequel 5.109.0, and Ransack 5.0.2. Rails 8.1 requires Ruby 3.2 or newer.

## Run it

Place this repo and `widget_list` next to each other, then:

```sh
bundle install
bin/rails db:prepare
bin/rails db:seed
bin/rails test
bin/rails server
```

Open [http://127.0.0.1:3000/](http://127.0.0.1:3000/) and [http://127.0.0.1:3000/ransack](http://127.0.0.1:3000/ransack). Search for SKU `1001` on the first page or filter Name to `Apple` on the second. The `Gemfile` uses `path: '../widget_list'`, so edit the gem locally and restart Rails to try changes.

## Changes to make in your own Rails app

1. Add `sprockets-rails`, `jquery-rails`, and `widget_list` to your `Gemfile`. Replace Rails 8's default `propshaft` entry with `sprockets-rails`. Use the released gem version after it is published, or a relative `path:` while developing locally.
2. Add [the asset manifest](app/assets/config/manifest.js) and [JavaScript entry point](app/assets/javascripts/application.js). Include `application.js`, `widget_list.css`, and `widgets.css` in [the layout](app/views/layouts/application.html.erb). The gem compiles its own image paths; there is no image copy step.
3. If using Sequel, add [the database mapping](config/widget-list.yml): a Sequel URI as `:primary`, and an Active Record environment name as `:secondary`. Point SQLite at the same file as [Rails database.yml](config/database.yml). For Active Record only, this file is optional and the gem uses the current Rails database as primary.
4. Add a model and allowlist the columns Ransack may search, as [Item](app/models/item.rb) does. Apply [the migration](db/migrate/20261006182200_create_items.rb) and create data with [the seeds](db/seeds.rb).
5. Add GET and POST routes for each list endpoint, as in [routes.rb](config/routes.rb). `widget_list` posts Ajax search and paging requests back to the same action. Build the list in [ItemsController](app/controllers/items_controller.rb), handle its `html`, `json`, and `export` return types, and render `@output` in the corresponding view.

The [gem README](https://github.com/davidrenne/widget_list#add-it-to-a-rails-8-app) includes copyable snippets and notes on the two database modes. To inspect this repo's one commit as an integration diff, run:

```sh
git show --stat HEAD
git diff dce9dd4..HEAD -- Gemfile app config/widget-list.yml config/routes.rb db test
```

`dce9dd4` is this repo's initial README-only commit; the diff shows the generated Rails app plus the caller integration. The tests in `test/integration/widget_list_test.rb` exercise rendering, SKU Ajax search, Ransack filtering, and CSV export.
