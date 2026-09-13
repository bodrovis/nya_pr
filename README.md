# NyaPr ฅ^•ﻌ•^ฅ

![Gem Version](https://img.shields.io/gem/v/nya_pr)
![CI](https://github.com/bodrovis/nya_pr/actions/workflows/ci.yml/badge.svg)

**NyaPr** is a tiny Ruby tool for people who have too many GitHub repositories, too many organizations, too many pull requests, and absolutely no desire to click through all that manually.

It collects repositories you own or contribute to, finds their open pull requests, and puts everything into one place.

For maximum kawaii.

## Why NyaPr?

GitHub is perfectly happy to show you:

* all repositories in a giant organization;
* pull requests you authored;
* pull requests where somebody mentioned you;
* approximately seventeen billion other things.

What it does not make particularly convenient is:

> Show me open pull requests from my own repositories **plus** repositories in these organizations where I actually contribute.

NyaPr does exactly that.

The basic flow is:

```text
GitHub users / organizations
        ↓
collect repositories
        ↓
keep repositories you actually contribute to
        ↓
optionally skip archived repositories
        ↓
cache the repository list
        ↓
find open pull requests
        ↓
terminal + timestamped CSV
        ↓
nya ฅ^•ﻌ•^ฅ
```

## Requirements

* Ruby 4+
* A GitHub personal access token
* A reasonable appreciation of cats

## Setup

Install the dependencies:

```bash
bundle install
```

Create a `.env` file:

```text
GITHUB_TOKEN=your_github_token
```

For private repositories, make sure the token has access to them. If an organization uses SSO, the token may also need to be authorized for that organization.

## Usage

Run NyaPr with your GitHub username:

```bash
ruby run.rb --user bodrovis
```

You can also provide additional users or organizations whose repositories should be inspected:

```bash
ruby run.rb \
  --user bodrovis \
  --owners org1,org2
```

Your own repositories are always included automatically.

For other users and organizations, NyaPr checks which repositories contain commits authored by the specified GitHub user.

## Data directory

By default, NyaPr stores generated data inside the `data` directory.

The repository cache is stored as:

```text
data/repositories.csv
```

Each pull request scan gets its own timestamped directory:

```text
data/
├── repositories.csv
├── pull_requests_20260912_201845/
│   └── pull_requests.csv
└── pull_requests_20260912_204112/
    └── pull_requests.csv
```

This keeps repository discovery cached while preserving the results of individual pull request scans.

Missing directories are created automatically.

## Repository cache

Repository discovery can involve a lot of GitHub API requests, especially for large organizations.

NyaPr therefore stores discovered repositories in:

```text
data/repositories.csv
```

On subsequent runs, this file is used as a cache instead of scanning GitHub again.

To force a fresh repository scan:

```bash
ruby run.rb \
  --user bodrovis \
  --owners org1,org2 \
  --refresh
```

You can use another repository cache file:

```bash
ruby run.rb \
  --user bodrovis \
  --repositories-csv "C:\Users\me\repositories.csv"
```

Both relative and absolute paths are supported.

Repository contribution checks are performed concurrently using a small thread pool, because waiting for hundreds of HTTP requests one by one is not particularly kawaii.

## Skipping archived repositories

Archived repositories are usually ancient tombs where pull requests go to sleep forever.

You can ignore them completely:

```bash
ruby run.rb \
  --user bodrovis \
  --owners org1,org2 \
  --skip-archived
```

When this option is enabled, archived repositories are removed before expensive contribution checks are performed.

Maximum efficiency. Minimum archaeology.

## Pull requests

After preparing the repository list, NyaPr searches each repository for open pull requests.

Results are grouped by repository and printed to the terminal:

```text
bodrovis/example
----------------

#42 Fix pagination
  Author: @someone
  https://github.com/bodrovis/example/pull/42

#43 [DRAFT] Add nya support
  Author: @someone_else
  https://github.com/bodrovis/example/pull/43
```

They are also written to a timestamped CSV file:

```text
data/pull_requests_20260912_201845/pull_requests.csv
```

The CSV contains:

```text
repository
number
title
author
draft
created_at
updated_at
html_url
```

By default, NyaPr stops after collecting **100 open pull requests**.

You can change the limit with `--limit`:

```bash
ruby run.rb \
  --user bodrovis \
  --limit 250
```

You can also change the base directory where pull request runs are stored:

```bash
ruby run.rb \
  --user bodrovis \
  --pull-requests-dir "C:\Users\me\nya-results"
```

This produces something like:

```text
C:\Users\me\nya-results\pull_requests_20260912_201845\pull_requests.csv
```

Each run still gets its own timestamped directory.

## Logging

NyaPr uses normal log levels instead of spraying random `puts` statements everywhere like an animal.

The default level is `info`.

Example:

```bash
ruby run.rb \
  --user bodrovis \
  --owners org1,org2 \
  --log-level info
```

At the `info` level, NyaPr reports the major stages of the run: loading or discovering repositories, filtering contributions, searching for pull requests, and saving results.

For HTTP-level details:

```bash
ruby run.rb ... --log-level debug
```

This also shows requests, responses, skipped empty repositories, detected contributions, and other useful diagnostic information.

Available levels:

```text
debug
info
warn
error
fatal
```

Logs are written to `stderr`, while actual pull request output goes to `stdout`.

## CLI options

```text
-u, --user USERNAME              GitHub username
-o, --owners LIST                Additional users or organizations, comma-separated
    --token TOKEN                GitHub token (GITHUB_TOKEN env variable is recommended)
    --repositories-csv PATH      Repository cache CSV path
    --pull-requests-dir PATH     Directory for pull request runs
-l, --limit N                    Maximum number of pull requests to collect
-r, --refresh                    Refresh repositories from GitHub
    --skip-archived              Ignore archived repositories
    --[no-]progress              Show or hide progress bars
    --log-level LEVEL            Logging level
-v, --version                    Show NyaPr version
```

Example with most options enabled:

```bash
ruby run.rb \
  --user bodrovis \
  --owners org1,org2 \
  --repositories-csv "data/repositories.csv" \
  --pull-requests-dir "data" \
  --limit 250 \
  --skip-archived \
  --refresh \
  --log-level debug
```

## How repository discovery works

For your own GitHub username, NyaPr collects repositories owned by your authenticated account.

For additional owners:

1. NyaPr determines whether the owner is a GitHub user or organization.
2. It collects their repositories.
3. Archived repositories can optionally be removed.
4. NyaPr checks whether your GitHub user has commits in each repository.
5. Only repositories where you contributed are retained.

Contribution checks run concurrently using a limited number of worker threads.

Empty Git repositories are simply skipped.

Repositories with pull requests disabled are also skipped when searching for PRs.

The prepared repository list is cached, but pull requests are fetched fresh on every run.

## License

(c) [Elijah S. Krukowski](https://bodrovis.tech), MIT license
