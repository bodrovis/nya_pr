# NyaPr ฅ^•ﻌ•^ฅ

**NyaPr** is a tiny Ruby tool for people who have too many GitHub repositories, too many organizations, too many pull requests, and absolutely no desire to click through all that manually.

It collects repositories that actually matter to you, finds their open pull requests, and puts everything into one place. For maximum kawaii.

## Why NyaPr?

GitHub is perfectly happy to show you:

* all repositories in a giant organization;
* pull requests you authored;
* pull requests where somebody mentioned you;
* approximately seventeen billion other things.

What it does not make particularly convenient is:

> Show me open pull requests from my own repositories **plus** repositories in these organizations where I actually contribute.

NyaPr does exactly that. The basic flow is:

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
terminal + CSV
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

Create an `.env` file:

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

Your own repositories are always included automatically. For other users and organizations, NyaPr checks which repositories contain commits authored by the specified GitHub user.

## Repository cache

Repository discovery can involve a lot of GitHub API requests, especially for large organizations. NyaPr therefore stores discovered repositories in:

```text
repositories.csv
```

On subsequent runs, this file is used as a cache instead of scanning GitHub again.

To force a fresh repository scan:

```bash
ruby run.rb \
  --user bodrovis \
  --owners org1,org2 \
  --refresh
```

You can use another cache file:

```bash
ruby run.rb \
  --user bodrovis \
  --csv my_repositories.csv
```

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

After preparing the repository list, NyaPr searches each repository for open pull requests. Results are printed to the terminal:

```text
lokalise/example #42 Fix pagination — @someone — https://github.com/...
lokalise/another-repo #81 [DRAFT] Add nya support — @someone_else — https://github.com/...
```

They are also written to:

```text
pull_requests.csv
```

The CSV contains useful metadata such as:

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

By default, NyaPr stops after collecting **100 open pull requests**. You can change the limit with `--limit`:

```bash
ruby run.rb \
  --user bodrovis \
  --limit 250
```

Use another output file with:

```bash
ruby run.rb \
  --user bodrovis \
  --pr-csv nya_prs.csv
```

## Logging

NyaPr uses normal log levels instead of spraying random `puts` statements everywhere like an animal. The default level is `info`.

Example:

```bash
ruby run.rb \
  --user bodrovis \
  --owners lokalise,scrapingbee \
  --log-level info
```

For HTTP-level details:

```bash
ruby run.rb ... --log-level debug
```

This shows requests, responses, skipped empty repositories, detected contributions, and other useful diagnostic information. Available levels:

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
-u, --user USERNAME       GitHub username
-o, --owners LIST         Additional users or organizations, comma-separated
    --csv FILE            Repository cache CSV
    --pr-csv FILE         Pull request output CSV
-l, --limit N             Maximum number of pull requests to collect
-r, --refresh             Refresh repositories from GitHub
    --skip-archived       Ignore archived repositories
    --log-level LEVEL     Logging level
```

Example with most options enabled:

```bash
ruby run.rb \
  --user bodrovis \
  --owners lokalise,scrapingbee \
  --csv repositories.csv \
  --pr-csv pull_requests.csv \
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

## LICENSE

(c) [Elijah S. Krukowski](https://bodrovis.tech), MIT license