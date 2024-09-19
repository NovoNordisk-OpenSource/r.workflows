# r.workflows

Repository to manage GitHub Actions workflows for our Open-Source projects.

It contains the following workflows:

1. [R-CMD-check standard](.github/workflows/check_current_version.yaml): Standard R CMD check, that checks the package for current version of R on MacOs and Windows, and for the previous, current, and development version of R on Linux.
2. [R-CMD-check NN versions](.github/workflows/check_nn_versions.yaml): Same as 1., but uses the R version and packages available as per given lock dates.
3. [Test coverage](.github/workflows/coverage.yaml): Derives test coverage for the package and publishes a summary table to the pull request.
4. [pkgdown](.github/workflows/pkgdown.yaml): Renders and publishes a `pkgdown` website for your package (to your `gh-pages` branch). For a pull request the page is published to `{base url of package}/dev/{pr number}`, and a link to this development webpage is posted as a comment to your pull request.
5. [megalinter](.github/workflows/megalinter.yaml): Lints your entire project using the [megalinter](https://megalinter.io/) tool.

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

Using e.g. the `R-CMD-check standard` workflow all you need to do is to call it with the input `setup: true` and the action above will be executed just after checking out your repository:

```yaml
...
jobs:
  check-current-version:
    name: Check current version
    uses: >-
      NovoNordisk-OpenSource/r.workflows/.github/workflows/check_current_version.yaml@main
    with:
      setup: true
...
```
You can of course add much more complicated setup steps this way, but now Quarto is available for all following steps in the `R-CMD-check standard` workflow.
