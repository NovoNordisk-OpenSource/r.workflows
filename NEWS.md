# r.workflows 0.1.3

* `check_nn_versions.yaml` now runs each lock date on the Ubuntu version set for it in the lock date list, and both current lock dates use `ubuntu-24.04`. On `ubuntu-latest` (Ubuntu 26.04) packages from the 2025-12-05 lock date fail to build from source, e.g. `later` 1.4.4 against glibc 2.43.

# r.workflows 0.1.2

* Added a Dependabot configuration so actions pinned in the reusable workflows are updated weekly in a single grouped PR (#70).
* Updated the pinned GitHub Actions, including `r-lib/actions` v2.14.0, which fixes pak installation on Ubuntu runners where `sudo -E` is not supported (#72).
* Dropped the 2023-10-25 lock date (R 4.3.1) from `check_nn_versions.yaml`, as the pak binaries fail to load on R 4.3.1 on macOS (#73).
* Fixed yamllint and prettier findings in the reusable workflows and linter configs.

# r.workflows 0.1.1

* Pinned all reusable workflow calls in README examples to the [v0.1.0](https://github.com/NovoNordisk-OpenSource/r.workflows/releases/tag/v0.1.0) release.
* `coverage.yaml` and `pkgdown.yaml` now skip the PR comment and pkgdown preview steps for pull requests from forks, where `GITHUB_TOKEN` is read-only (#67).

# r.workflows 0.1.0

* Initial release.
