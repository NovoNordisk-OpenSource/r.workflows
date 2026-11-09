# r.workflows 0.1.2

* Added a Dependabot configuration so actions pinned in the reusable workflows are updated weekly in a single grouped PR (#70).
* Updated the pinned GitHub Actions, including `r-lib/actions` v2.14.0, which fixes pak installation on Ubuntu runners where `sudo -E` is not supported (#72).
* Dropped the 2023-10-25 lock date (R 4.3.1) from `check_nn_versions.yaml`, as the pak binaries fail to load on R 4.3.1 on macOS (#73).

# r.workflows 0.1.1

* Pinned all reusable workflow calls in README examples to the [v0.1.0](https://github.com/NovoNordisk-OpenSource/r.workflows/releases/tag/v0.1.0) release.
* `coverage.yaml` and `pkgdown.yaml` now skip the PR comment and pkgdown preview steps for pull requests from forks, where `GITHUB_TOKEN` is read-only (#67).

# r.workflows 0.1.0

* Initial release.
