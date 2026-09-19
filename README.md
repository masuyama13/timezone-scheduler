# Timezone Scheduler

A Rails application for coordinating schedules across time zones.

## Current status

The project is in early development. The initial models, database migrations,
Dev Container, and RSpec setup are in place. Scheduling screens, time zone
comparison, and application workflows are not implemented yet. Model specs
currently contain pending examples.

| Model | Purpose |
| --- | --- |
| `Event` | Scheduling event with a name, description, time zone, and `public_token`. |
| `TimeOption` | A candidate start time belonging to an event. |
| `Response` | An event participant's name, time zone, and comment. |
| `Vote` | Availability for a candidate time, linked to a response and a time option. |

The database has required-column constraints, foreign keys, and unique indexes
for event public tokens and candidate start times within an event. Additional
model associations, validations, and public token generation are still to be
implemented.

## Stack

- Ruby 4.0.3 and Rails 8.1
- PostgreSQL 16.1 in the Dev Container
- Hotwire (Turbo and Stimulus), import maps, and Propshaft
- RSpec Rails and FactoryBot
- AnnotateRb for schema annotations

## Development environment

Use VS Code with the Dev Containers extension and a running Docker-compatible
runtime, such as Colima with the Docker runtime or Docker Desktop. Docker CLI,
Compose, and Buildx must be available on the host.

For an existing Colima installation, start it on the host:

```bash
colima start --runtime docker
docker info
docker compose version
docker buildx version
```

Open the repository in VS Code and run **Dev Containers: Reopen in Container**.
Keep the checkout directory named `timezone_scheduler` to match the configured
workspace path.

The container starts PostgreSQL and runs `bin/setup --skip-server` automatically.
This installs missing gems, prepares the database, and clears old logs and
temporary files. If setup fails, resolve the reported error and rerun that
command inside the container.

Run the commands below inside the Dev Container terminal. Ruby and PostgreSQL
do not need to be installed on the host.

## Run the application

```bash
bin/dev
```

This starts the Rails server. The container sets `BINDING=0.0.0.0` and forwards
port 3000. Open `http://localhost:3000`, or the forwarded address shown by VS Code.
There is no application root route yet; `/up` is available as a health check.

## Database

The Dev Container sets `DB_HOST=postgres`. Development and test use separate
databases, `timezone_scheduler_development` and `timezone_scheduler_test`.
PostgreSQL data persists in the Compose `postgres-data` volume.

Prepare the database when setting up or updating the application:

```bash
bin/rails db:prepare
```

Apply new migrations:

```bash
bin/rails db:migrate
```

AnnotateRb is configured to update schema annotations through development
database tasks.

## Tests and checks

Prepare the test database and run RSpec:

```bash
RAILS_ENV=test bin/rails db:prepare
bundle exec rspec
```

Run a single model spec:

```bash
bundle exec rspec spec/models/event_spec.rb
```

Run style and security checks:

```bash
bin/rubocop
bin/brakeman
bin/bundler-audit
bin/importmap audit
```

`config/ci.rb` still invokes the default `bin/rails test` command. Run RSpec
explicitly until that configuration is updated; `bin/ci` does not currently
run the RSpec suite.

## Gem dependencies

Add application dependencies to `Gemfile` and run:

```bash
bundle install
```

Alternatively, use `bundle add GEM_NAME`. Commit both `Gemfile` and
`Gemfile.lock` when dependencies change. Installing a gem with `gem install`
alone does not record it as an application dependency.
