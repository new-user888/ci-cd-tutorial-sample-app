# CD/CI Tutorial Sample Application ⚙

![CI](https://github.com/new-user888/ci-cd-tutorial-sample-app/actions/workflows/ci.yml/badge.svg)

**NOTE:** This code was written for an
[article](https://medium.com/rockedscience/docker-ci-cd-pipeline-with-github-actions-6d4cd1731030)
in the **RockedScience** publication on Medium.

## Description

This sample Python REST API application was written for a tutorial on implementing Continuous Integration and Delivery pipelines.

It demonstrates how to:

 * Write a basic REST API using the [Flask](http://flask.pocoo.org) microframework
 * Basic database operations and migrations using the Flask wrappers around [Alembic](https://bitbucket.org/zzzeek/alembic) and [SQLAlchemy](https://www.sqlalchemy.org)
 * Write automated unit tests with [unittest](https://docs.python.org/2/library/unittest.html)

Also:

 * How to use [GitHub Actions](https://github.com/features/actions)

## Requirements

 * `Python 3.8`
 * `Pip`
 * `virtualenv`, or `conda`, or `miniconda`

The `psycopg2` package does require `libpq-dev` and `gcc`.
To install them (with `apt`), run:

```sh
$ sudo apt-get install libpq-dev gcc
```

## Installation

With `virtualenv`:

```sh
$ python -m venv venv
$ source venv/bin/activate
$ pip install -r requirements.txt
```

With `conda` or `miniconda`:

```sh
$ conda env create -n ci-cd-tutorial-sample-app python=3.8
$ source activate ci-cd-tutorial-sample-app
$ pip install -r requirements.txt
```

Optional: set the `DATABASE_URL` environment variable to a valid SQLAlchemy connection string. Otherwise, a local SQLite database will be created.

Initalize and seed the database:

```sh
$ flask db upgrade
$ python seed.py
```

## Running tests

Run:

```sh
$ python -m unittest discover
```

## Running the application

### Running locally

Run the application using the built-in Flask server:

```sh
$ flask run
```

### Running on a production server

Run the application using `gunicorn`:

```sh
$ pip install -r requirements-server.txt
$ gunicorn app:app
```

To set the listening address and port, run:

```
$ gunicorn app:app -b 0.0.0.0:8000
```

## Running on Docker

Run:

```
$ docker build -t ci-cd-tutorial-sample-app:latest .
$ docker run -d -p 8000:8000 ci-cd-tutorial-sample-app:latest
```

## Versioning and releases

Every push to `master` runs through [semantic-release](https://semantic-release.gitbook.io/), which reads commit messages (in [Conventional Commits](https://www.conventionalcommits.org/) format) to decide whether a new version is needed and what it should be. A `fix:` commit bumps the patch version, `feat:` bumps minor, and a commit with a `BREAKING CHANGE:` footer bumps major.

When a new version is released, semantic-release creates a Git tag, a GitHub release with generated notes, and updates `CHANGELOG.md`. The CI pipeline then builds a Docker image and pushes it to GHCR tagged with the version (`vX.Y.Z`), `latest`, and the commit SHA.

## Deployment and rollback

Deploying to the target VM is a manual step, triggered from the "CD" workflow in the Actions tab. Choose "Run workflow" and enter the image tag to deploy - a version like `v1.2.0`, or `latest`.

The workflow connects to the VM over SSH, pulls the requested image from GHCR, stops the running container, and starts a new one from that image. Since every released version stays available in GHCR, rolling back is just running the workflow again with an older version tag - no rebuild needed.

The app reports its running version at `/`, so you can confirm what is live:

```sh
$ curl http://<vm-host>:8000/
{"status": "ok", "version": "v1.2.0"}
```

## Notifications

Both pipelines report their result to a Telegram chat. The CI workflow sends a message once tests, release, and image build finish, with the status, branch, commit, a link to the run, and the new version if one was published. The CD workflow sends a message after deployment with the version and status.

Success and failure messages are worded differently so the outcome is clear at a glance. No secrets, tokens, or other sensitive details are included - only the result and version.

To enable this, set these repository secrets:

- `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID` - for notifications
- `VM_HOST`, `VM_USER`, `VM_SSH_KEY`, `VM_PORT` - for deployment over SSH

## Deploying to Heroku

Run:

```sh
$ heroku create
$ git push heroku master
$ heroku run flask db upgrade
$ heroku run python seed.py
$ heroku open
```

or use the automated deploy feature:

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy)

For more information about using Python on Heroku, see these Dev Center articles:

 - [Python on Heroku](https://devcenter.heroku.com/categories/python)
