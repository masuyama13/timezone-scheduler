# Timezone Scheduler

A Rails application for coordinating schedules across time zones.

## Prerequisites

Install the following on the host:

- Git
- VS Code with the Dev Containers extension
- A Docker-compatible runtime: Colima with the Docker runtime or Docker Desktop
- Docker CLI, Compose, and Buildx

Ruby and PostgreSQL run inside the Dev Container and do not need to be installed on the host.
Their versions are configured in `.ruby-version` and `.devcontainer/`.

## Setup

Clone the repository into a directory named `timezone_scheduler` to match the configured workspace path, then open that directory in VS Code.

Start Docker Desktop, or start Colima from a **host terminal**:

```bash
colima start --runtime docker
```

Check that Docker and its plugins are available on the host:

```bash
docker info
docker compose version
docker buildx version
```

In VS Code, run **Dev Containers: Reopen in Container** from the Command Palette.

The container starts PostgreSQL and runs `bin/setup --skip-server` automatically.
This installs missing gems, prepares the database, and clears old logs and temporary files.
If setup fails, resolve the reported error and rerun that command inside the container.

Unless stated otherwise, run all commands below from the project root in the **Dev Container terminal**.

## Run the application

For each development session, start your Docker runtime on the host, reopen the project in the Dev Container, and start Rails:

```bash
bin/dev
```

This starts the Rails server.
The container sets `BINDING=0.0.0.0` and forwards port 3000.
Open `http://localhost:3000`, or the forwarded address shown by VS Code.
The `/up` endpoint is available as a health check.

Press `Ctrl+C` in the server terminal to stop Rails.
To stop this project's containers, run the following from the repository root in a **host terminal**:

```bash
docker compose -f .devcontainer/compose.yaml stop
```

## Database

The Dev Container sets `DB_HOST=postgres`.
Development and test use separate databases, `timezone_scheduler_development` and `timezone_scheduler_test`.
PostgreSQL data persists in the Compose `postgres-data` volume.

Prepare the database when setting up or updating the application:

```bash
bin/rails db:prepare
```

Apply new migrations:

```bash
bin/rails db:migrate
```

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

## Dependencies

Add application dependencies to `Gemfile` and run:

```bash
bundle install
```

Alternatively, use `bundle add GEM_NAME`.
Commit both `Gemfile` and `Gemfile.lock` when dependencies change.

After pulling changes to dependencies, run `bundle install` again.
After pulling new database migrations, run `bin/rails db:prepare` before starting the server.
