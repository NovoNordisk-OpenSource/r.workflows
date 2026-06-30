# r.workflows

Repository to manage GitHub Actions workflows for our Open-Source projects.

It contains the following workflows:

1. [R-CMD-check standard](.github/workflows/check_current_version.yaml): Standard R CMD check, that checks the package for current version of R on MacOs and Windows, and for the previous, current, and development version of R on Linux.
2. [R-CMD-check NN versions](.github/workflows/check_nn_versions.yaml): Same as 1., but uses the R version and packages available as per given lock dates. See below for how to configure the lock dates.
3. [Test coverage](.github/workflows/coverage.yaml): Derives test coverage for the package and publishes a summary table to the pull request. For Open-Source repositories this also gives you the option to upload code coverage results to [codecov.io](https://codecov.io).
4. [pkgdown](.github/workflows/pkgdown.yaml): Renders and publishes a `pkgdown` website for your package (to your `gh-pages` branch). For a pull request the page is published to `{base url of package}/dev/{pr number}`, and a link to this development webpage is posted as a comment to your pull request.
5. [megalinter](.github/workflows/megalinter.yaml): Lints your entire project using the [megalinter](https://megalinter.io/) tool. Note that for the [cspell](https://github.com/streetsidesoftware/cspell) linter words in `inst/WORDLIST` are automatically added as a dictionary if the file exists.

## Use in your package

The easiest way to use the workflows is to create a single workflow in your package (e.g. `.github/workflows/check_and_co.yaml`) with the following content:

```yaml
on:
  push:
    branches:
      - main
      - master
  pull_request:
    branches:
      - main
      - master
permissions:
  contents: write
  pull-requests: write
name: All actions
jobs:
  check-current-version:
    name: Check current version
    uses: >-
      NovoNordisk-OpenSource/r.workflows/.github/workflows/check_current_version.yaml@main
  check-nn-version:
    name: Check NN version
    uses: >-
      NovoNordisk-OpenSource/r.workflows/.github/workflows/check_nn_versions.yaml@main
  pkgdown:
    name: Pkgdown site
    uses: NovoNordisk-OpenSource/r.workflows/.github/workflows/pkgdown.yaml@main
  coverage:
    name: Coverage report
    uses: NovoNordisk-OpenSource/r.workflows/.github/workflows/coverage.yaml@main
    secrets: inherit # Required if use_codecov below is true, in order to access organisational codecov token
    with:
      use_codecov: false # Change to true if you want to upload coverage results to codecov.io.
  megalinter:
    name: Megalinter
    uses: NovoNordisk-OpenSource/r.workflows/.github/workflows/megalinter.yaml@main
```

This will run all five workflows on your project whenever there is a push or a pull request to the `main`/`master` branch.

## Custom setup

Your package might have special dependencies that are not installed in the general workflows. 
As an example the package may depend on [quarto](https://quarto.org/) being installed.
All the applicable workflows (all but megalinter) allows for you to provide a custom action to install these dependencies.

This is done using [composite actions](https://docs.github.com/en/actions/sharing-automations/creating-actions/creating-a-composite-action) and you have to store it
as `.github/actions/setup/action.yaml` in your repository.

An action to install `quarto` looks like this:

```yaml
name: Install Quarto
description: Installs Quarto since it is needed in my project
runs:
  using: "composite"
  steps:
    - name: Install Quarto
      uses: quarto-dev/quarto-actions/setup@v2
```

Using e.g. the `R-CMD-check standard` workflow all you need to do is to call it with the input `use_local_setup_action: true` and the action above will be executed just after checking out your repository:

```yaml
...
jobs:
  check-current-version:
    name: Check current version
    uses: >-
      NovoNordisk-OpenSource/r.workflows/.github/workflows/check_current_version.yaml@main
    with:
      use_local_setup_action: true
...
```
You can of course add much more complicated setup steps this way, but now Quarto is available for all following steps in the `R-CMD-check standard` workflow.

## Install from private repositories in your organisation

If you have dependencies on private repositories insider your GitHub organisation
you need to run the workflows (excluding MegaLinter) with `generate_token: true` input,
and supply an App Id and App Private key as secrets.

Using e.g. the `R-CMD-check standard` workflow it can be done like this:

```yaml
...
jobs:
  check-current-version:
    name: Check current version
    uses: >-
      NovoNordisk-OpenSource/r.workflows/.github/workflows/check_current_version.yaml@main
    secrets:
      TOKEN_APP_ID: ${{ secrets.TOKEN_APP_ID }}
      TOKEN_APP_PRIVATE_KEY: ${{ secrets.TOKEN_APP_PRIVATE_KEY }}
    with:
      generate_token: true
      token_repositories: |
        private-dep-1
        private-dep-2
...
```

Where the secrets point to a GitHub App in your organisation that have read access to the relevant
repositories. Using the `actions/create-github-app-token@v2` action this generates a new token, that
have the necessary access, to be used in the step setting up the R dependencies.

The `token_repositories` input scopes the token to the listed repositories. It defaults to the caller
repository only, so set it to the names of the private dependency repos your package needs to install
from. Accepts a comma- or newline-separated list.

See also [Authenticating with a GitHub App](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/making-authenticated-api-requests-with-a-github-app-in-a-github-actions-workflow#authenticating-with-a-github-app)
for more information on this way of authenticating.

## Filter NN lock dates

The lock dates used in [R-CMD-check NN versions](.github/workflows/check_nn_versions.yaml) can be
configured using the `min_lock_date` input. This subsets the standard list of lock dates and
their corresponding R versions to only include lock dates from this date going forward.

The below snippet only uses lock dates from 06Aug2024 and going forward:

```yaml
  check-nn-version:
    name: Check NN version
    uses: >-
      NovoNordisk-OpenSource/r.workflows/.github/workflows/check_nn_versions.yaml@main
    with:
      min_lock_date: '2024-08-06'
```

For list of used lock dates can be seen inside the workflow file.
