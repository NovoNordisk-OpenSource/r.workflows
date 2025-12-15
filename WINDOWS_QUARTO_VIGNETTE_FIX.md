# Windows Quarto Vignette R Library Path Issue - Analysis & Fix

## Problem Summary

When building R packages on Windows via GitHub Actions, Quarto vignette rendering fails because child R processes cannot locate installed packages, even though the packages were successfully installed in the pipeline.

## Root Cause Analysis

### What's Happening

**Step 1: Package Installation ✅**
```yaml
- uses: r-lib/actions/setup-r-dependencies@v2
```
- Installs packages to `D:\a\_temp\Library` on Windows
- Sets `R_LIBS_USER` environment variable for the current workflow step
- The main R process can find all packages correctly

**Step 2: Vignette Building ❌**
```yaml
- uses: r-lib/actions/check-r-package@v2
```
- Runs `R CMD check` which includes building vignettes
- When Quarto renders vignettes, it spawns a **NEW** R subprocess
- This child R process does NOT have `R_LIBS_USER` set
- Result: `.libPaths()` doesn't include `D:\a\_temp\Library`
- Error: `there is no package called 'mighty'`

### Why This Is Windows-Specific

**Environment Variable Inheritance Differences:**

| Platform | Behavior |
|----------|----------|
| **Linux/macOS** | Child processes inherit environment variables via `fork()` mechanism - works reliably |
| **Windows** | Process creation uses `CreateProcess()` with different inheritance - environment variables NOT reliably inherited |

**GitHub Actions Limitation:**
- `GITHUB_ENV` sets environment variables for **subsequent workflow steps**
- Does NOT set environment variables for **subprocesses within a step**
- When `check-r-package` step runs, it has `R_LIBS_USER` set
- When Quarto spawns a child R process, that child starts fresh without inheriting `R_LIBS_USER`

### Technical Details

```
Workflow Step (check-r-package)
  ├─ R_LIBS_USER = "D:\a\_temp\Library"  ✅
  │
  └─ R CMD check
      └─ Building vignettes
          └─ Quarto renders .qmd
              └─ Spawns new R process
                  └─ R_LIBS_USER = ""  ❌
                      └─ .libPaths() = ["C:/R/library"]
                          └─ Cannot find 'mighty' package
```

## Current r.workflows Configuration

The workflows use this sequence:

```yaml
- uses: r-lib/actions/setup-pandoc@v2
- uses: r-lib/actions/setup-r@v2
- uses: r-lib/actions/setup-r-dependencies@v2
  env:
    GITHUB_PAT: ${{ steps.generate-token.outputs.token || secrets.GITHUB_TOKEN }}
  with:
    extra-packages: 'any::rcmdcheck'
    needs: check
- uses: r-lib/actions/check-r-package@v2  # Vignettes fail here on Windows
```

**What's Missing:**
- No mechanism to persist R library paths across process boundaries
- No `.Renviron` configuration for child processes
- No Windows-specific workaround

## The Solution

### Use `.Renviron` for Persistent Configuration

R reads `~/.Renviron` on startup for **every R session**, including child processes. This is the standard R mechanism for persistent environment configuration.

### Implementation

Add this step between `setup-r-dependencies` and `check-r-package`:

```yaml
- name: Configure R library paths for Windows child processes
  if: runner.os == 'Windows'
  shell: bash
  run: |
    RLIBS=$(Rscript -e "cat(paste(.libPaths(), collapse=';'))")
    echo "R_LIBS_USER=$RLIBS" >> $HOME/.Renviron
    echo "Configured .Renviron for Windows with: $RLIBS"
    cat $HOME/.Renviron || echo ".Renviron file not found"
```

**How It Works:**
1. ✅ Runs only on Windows runners
2. ✅ Queries the current R session for `.libPaths()` (which includes the temp library)
3. ✅ Writes `R_LIBS_USER` to `~/.Renviron`
4. ✅ Uses semicolon (`;`) as path separator (Windows convention for R)
5. ✅ All subsequent R sessions (including Quarto's child processes) read this file on startup
6. ✅ Child processes now have correct library paths

## Required Changes

### File: `.github/workflows/check_current_version.yaml`

**Location:** After line 85 (between `setup-r-dependencies` and `check-r-package`)

```yaml
      - uses: r-lib/actions/setup-r-dependencies@v2
        env:
          GITHUB_PAT: ${{ steps.generate-token.outputs.token || secrets.GITHUB_TOKEN }}
        with:
          extra-packages: 'any::rcmdcheck'
          needs: check

      - name: Configure R library paths for Windows child processes
        if: runner.os == 'Windows'
        shell: bash
        run: |
          RLIBS=$(Rscript -e "cat(paste(.libPaths(), collapse=';'))")
          echo "R_LIBS_USER=$RLIBS" >> $HOME/.Renviron
          echo "Configured .Renviron for Windows with: $RLIBS"
          cat $HOME/.Renviron || echo ".Renviron file not found"

      - uses: r-lib/actions/check-r-package@v2
        with:
          upload-snapshots: true
          error-on: '${{ inputs.error-on || env.ERROR_ON_DEFAULT }}'
```

### File: `.github/workflows/check_nn_versions.yaml`

**Location:** After line 83 (between `setup-r-dependencies` and `check-r-package`)

```yaml
      - uses: r-lib/actions/setup-r-dependencies@v2
        env:
          GITHUB_PAT: ${{ steps.generate-token.outputs.token || secrets.GITHUB_TOKEN }}
        with:
          extra-packages: 'any::rcmdcheck'
          needs: check

      - name: Configure R library paths for Windows child processes
        if: runner.os == 'Windows'
        shell: bash
        run: |
          RLIBS=$(Rscript -e "cat(paste(.libPaths(), collapse=';'))")
          echo "R_LIBS_USER=$RLIBS" >> $HOME/.Renviron
          echo "Configured .Renviron for Windows with: $RLIBS"
          cat $HOME/.Renviron || echo ".Renviron file not found"

      - uses: r-lib/actions/check-r-package@v2
        with:
          upload-snapshots: true
          error-on: '${{ inputs.error-on || env.ERROR_ON_DEFAULT }}'
```

## Impact Assessment

### Affected Files
- `.github/workflows/check_current_version.yaml` (line 85)
- `.github/workflows/check_nn_versions.yaml` (line 83)

### Backward Compatibility
- ✅ **Fully backward compatible** - only runs on Windows
- ✅ No changes required in consuming repositories (like mighty)
- ✅ No new inputs or configuration needed
- ✅ Linux and macOS workflows unaffected

### Performance Impact
- Negligible - adds ~1-2 seconds on Windows builds only
- Only queries R once with a simple `.libPaths()` call

## Testing Strategy

### Pre-deployment Testing

1. **Create test branch in r.workflows:**
   ```bash
   git checkout -b fix/windows-renviron
   # Apply changes
   git commit -am "Fix Windows child process R library paths"
   git push origin fix/windows-renviron
   ```

2. **Test in mighty repository:**
   ```yaml
   check-current-version:
     uses: NovoNordisk-OpenSource/r.workflows/.github/workflows/check_current_version.yaml@fix/windows-renviron
   ```

3. **Remove vignette workaround code:**
   Delete the `if (!requireNamespace("mighty", quietly = TRUE))` block from vignettes

4. **Run workflow and verify:**
   - Windows builds pass
   - Vignettes render successfully
   - No "package not found" errors

### Verification Step (Optional)

Add temporary verification after the fix:

```yaml
- name: Verify R library paths (Windows)
  if: runner.os == 'Windows'
  shell: Rscript {0}
  run: |
    cat("=== R Library Configuration ===\n")
    cat("R_LIBS_USER env var:", Sys.getenv("R_LIBS_USER"), "\n")
    cat("\n.libPaths():\n")
    print(.libPaths())
    cat("\nCan load mighty?:", requireNamespace("mighty", quietly = TRUE), "\n")
```

## Alternative Solutions Considered

### ❌ Option 1: Set R_LIBS at Job Level
**Problem:** Library path is determined dynamically by `setup-r-dependencies`, so we can't set it at job level before the action runs.

### ❌ Option 2: Modify Vignette Code
**Problem:** This is a band-aid. Every package with Quarto vignettes would need the workaround. Not a proper fix.

### ❌ Option 3: Use Environment Variables
**Problem:** Environment variables set via `env:` or `GITHUB_ENV` don't propagate to child processes on Windows.

### ✅ Option 4: Use .Renviron (CHOSEN)
**Why:** This is the standard R mechanism for persistent environment configuration that works across all R sessions and child processes.

## Related Issues & Background

### Known Issues
- Windows GitHub Actions runners + R child processes
- Quarto subprocess environment inheritance
- `r-lib/actions` doesn't handle child process environment on Windows

### R Environment Configuration Hierarchy
1. **System-wide:** `R_HOME/etc/Renviron.site`
2. **User-level:** `~/.Renviron` ← **Our fix targets this**
3. **Project-level:** `./.Renviron`
4. **Session-level:** `Sys.setenv()` and environment variables

Child processes read `.Renviron` files but may not inherit session-level environment variables.

## Deployment Plan

1. ✅ Apply changes to r.workflows repository
2. ✅ Test on feature branch with mighty package
3. ✅ Verify Windows builds pass
4. ✅ Merge to main branch
5. ✅ Update CLAUDE.md with this known issue
6. ✅ Notify teams using Quarto vignettes
7. ✅ Remove workaround code from package vignettes

## Post-Deployment

### For Package Maintainers (mighty, etc.)

**Action Required:**
- Remove the workaround code from vignettes:
  ```r
  # DELETE THIS ENTIRE BLOCK:
  if (!requireNamespace("mighty", quietly = TRUE)) {
    extra_libs <- Sys.getenv("R_LIBS_USER")
    if (extra_libs != "" && dir.exists(extra_libs)) {
      .libPaths(c(extra_libs, .libPaths()))
    }
    extra_libs2 <- strsplit(Sys.getenv("R_LIBS"), .Platform$path.sep)[[1]]
    if (length(extra_libs2) > 0) {
      .libPaths(c(extra_libs2, .libPaths()))
    }
  }
  ```

**No workflow changes needed** - the fix is in r.workflows

### For r.workflows Maintainers

**Update CLAUDE.md** to document:
- This Windows-specific issue
- The `.Renviron` solution
- That it's automatically handled in check workflows

---

## Summary

| Aspect | Detail |
|--------|--------|
| **Root Cause** | Windows child processes don't inherit environment variables |
| **Affected** | Windows builds with Quarto vignettes |
| **Solution** | Use `.Renviron` to persist R library paths |
| **Files Modified** | 2 workflow files in r.workflows |
| **Breaking Changes** | None - fully backward compatible |
| **Testing Required** | Windows build with Quarto vignettes |
| **Downstream Changes** | None - remove workaround code from vignettes |

This is a proper infrastructure fix that benefits all packages using these reusable workflows.
