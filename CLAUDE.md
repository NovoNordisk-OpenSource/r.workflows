# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository (`r.workflows`) is a centralized collection of reusable GitHub Actions workflows for R package development at NovoNordisk-OpenSource. It is itself an R package (used only for demonstration/testing purposes) but its primary purpose is to provide standardized CI/CD workflows that other R packages can reference.

## Architecture

### Reusable Workflows Structure

The repository provides 5 reusable workflows located in `.github/workflows/`:

1. **check_current_version.yaml** - R CMD check on current/latest R versions across multiple OS platforms (macOS, Windows, Ubuntu with R devel/release/oldrel-1)
2. **check_nn_versions.yaml** - R CMD check using specific historical R versions and package snapshots (currently 4.3.1 from 2023-10-25 and 4.4.1 from 2024-08-06) via CRAN snapshots
3. **coverage.yaml** - Generates test coverage reports using `covr`, posts results as PR comments, optionally uploads to codecov.io
4. **pkgdown.yaml** - Builds and deploys pkgdown documentation site to gh-pages; for PRs deploys preview to `/dev/{pr-number}`
5. **megalinter.yaml** - Runs MegaLinter with custom configuration, automatically applies fixes via PR or commit

### Workflow Features

All workflows (except megalinter) support these common inputs:
- `use_local_setup_action: true` - Execute custom composite action from `.github/actions/setup/action.yaml` in the calling repo (for special dependencies like Quarto)
- `generate_token: true` - Generate GitHub App token for accessing private org repositories (requires `TOKEN_APP_ID` and `TOKEN_APP_PRIVATE_KEY` secrets)

Additional workflow-specific inputs:
- **check workflows**: `error-on` parameter (default: `"warning"`) controls rcmdcheck strictness
- **coverage**: `use_codecov: true` enables codecov.io upload
- **pkgdown**: Deploys to gh-pages on push/release, creates preview sites for PRs

### Key Workflow Patterns

**NN Versions Check**: Uses Posit Package Manager CRAN snapshots (`https://packagemanager.posit.co/cran/{date}`) to test against historical package versions, ensuring reproducibility. Also includes NovoNordisk r-universe as extra repository.

**MegaLinter Configuration**: Automatically fetches standard linter configs from this repo's `.github/linters/` directory if they don't exist in calling repo. Special handling for `inst/WORDLIST` - if present, uses `.cspell-wordlist.json` config that includes words from WORDLIST file.

**Pkgdown PR Previews**: Complex multi-step process that builds site, commits to gh-pages under `/dev/{pr-number}`, and posts comment with preview URL.

## Development Commands

### Testing Changes to Workflows

Since this is a workflow repository, testing requires using it from another repository or using workflow_dispatch. The package itself is minimal and mainly for demonstration.

```bash
# Run R CMD check locally
R CMD build .
R CMD check r.workflows_*.tar.gz

# Run tests
Rscript -e "testthat::test_dir('tests/testthat')"
```

### Linting

The repository uses its own MegaLinter workflow. Configuration is in `.github/linters/.mega-linter.yml` which:
- Disables: `REPOSITORY_GIT_DIFF`, `REPOSITORY_CHECKOV`
- Excludes: `dev/` directory
- Special file extensions handling for R/Rmd/qmd files

### Local Development

The `dev/` directory contains development scripts and is excluded from linting and package builds (see `.Rbuildignore`). This is where experimental code and helper scripts belong.

## Important Implementation Details

### Token Generation for Private Repos

When packages depend on private GitHub repositories within the organization, the workflow uses `actions/create-github-app-token@v2` to generate a temporary token with appropriate permissions. This token is passed to `r-lib/actions/setup-r-dependencies@v2` via the `GITHUB_PAT` environment variable.

### Custom Wordlist Handling

If a calling package has `inst/WORDLIST`, the megalinter workflow automatically uses `.cspell-wordlist.json` config which adds those words to the cspell dictionary. This is handled in the "Copy linting config" step (lines 47-66 in megalinter.yaml).

### Version Pinning Strategy

The check_nn_versions workflow maintains specific R version and date combinations in a matrix. When updating these, ensure the R version matches what was current on the specified CRAN snapshot date.

## Package Structure

- `R/` - Minimal R code (just hello.R for demonstration)
- `.github/workflows/` - The reusable workflow definitions (primary deliverable)
- `.github/linters/` - Standard linter configurations used by megalinter workflow
- `inst/WORDLIST` - Custom dictionary for spell checking
- `dev/` - Development scripts (excluded from package)
- `tests/testthat/` - Minimal test suite

## Updating Workflows

When modifying workflows, consider:
1. Backward compatibility - other repos depend on these workflows
2. Default values should work for most use cases
3. Test changes by referencing your branch in a test repo: `uses: NovoNordisk-OpenSource/r.workflows/.github/workflows/{workflow}.yaml@{your-branch}`
4. The megalinter workflow has special logic to use the current branch when run from this repo (lines 39-46 in megalinter.yaml)
