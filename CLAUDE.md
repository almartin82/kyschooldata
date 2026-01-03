## CRITICAL DATA SOURCE RULES

**NEVER use Urban Institute API, NCES CCD, or ANY federal data source** — the entire point of these packages is to provide STATE-LEVEL data directly from state DOEs. Federal sources aggregate/transform data differently and lose state-specific details. If a state DOE source is broken, FIX IT or find an alternative STATE source — do not fall back to federal data.

---

## Kentucky DOE Data Sources (Verified January 2026)

### CRITICAL: URL Requirements

**All KDE URLs MUST:**
1. Use `https://www.education.ky.gov/` (with `www.` prefix) — returns 403 without it
2. Include a browser-like User-Agent header in HTTP requests

### Data Source Locations

| Era | Years | Data Files | Base URL |
|-----|-------|------------|----------|
| SRC Current | 2024+ | `KYRC24_OVW_Student_Enrollment.csv` | `www.education.ky.gov/Open-House/data/HistoricalDatasets/` |
| SRC Current | 2020-2023 | `primary_enrollment_YYYY.csv`, `secondary_enrollment_YYYY.csv` | `www.education.ky.gov/Open-House/data/HistoricalDatasets/` |
| SAAR | 1997-2019 | `1996-2019 SAAR Summary ReportsADA.xlsx` | `www.education.ky.gov/districts/enrol/Documents/` |

### Verified URLs (HTTP 200 as of Jan 2026)

**SRC Current Format:**
- `https://www.education.ky.gov/Open-House/data/HistoricalDatasets/KYRC24_OVW_Student_Enrollment.csv`
- `https://www.education.ky.gov/Open-House/data/HistoricalDatasets/primary_enrollment_2023.csv`
- `https://www.education.ky.gov/Open-House/data/HistoricalDatasets/secondary_enrollment_2023.csv`

**SAAR Historical:**
- `https://www.education.ky.gov/districts/enrol/Documents/1996-2019%20SAAR%20Summary%20ReportsADA.xlsx`

### Pages Checked

1. [Historical SAAR Data](https://www.education.ky.gov/districts/enrol/Pages/Historical-SAAR-Data.aspx) - SAAR Excel files
2. [Historical SRC Datasets](https://www.education.ky.gov/Open-House/data/Pages/Historical-SRC-Datasets.aspx) - SRC CSV files
3. [Student Enrollment Page](https://www.education.ky.gov/districts/enrol/Pages/default.aspx) - Main enrollment data landing

### Known Issues Fixed

1. **403 Forbidden** - Fixed by adding `www.` prefix to all URLs
2. **403 with User-Agent** - Fixed by adding browser-like User-Agent header to httr requests

---


# Claude Code Instructions

## Git Commits and PRs
- NEVER reference Claude, Claude Code, or AI assistance in commit messages
- NEVER reference Claude, Claude Code, or AI assistance in PR descriptions
- NEVER add Co-Authored-By lines mentioning Claude or Anthropic
- Keep commit messages focused on what changed, not how it was written

---

## Local Testing Before PRs (REQUIRED)

**PRs will not be merged until CI passes.** Run these checks locally BEFORE opening a PR:

### CI Checks That Must Pass

| Check | Local Command | What It Tests |
|-------|---------------|---------------|
| R-CMD-check | `devtools::check()` | Package builds, tests pass, no errors/warnings |
| Python tests | `pytest tests/test_pykyschooldata.py -v` | Python wrapper works correctly |
| pkgdown | `pkgdown::build_site()` | Documentation and vignettes render |

### Quick Commands

```r
# R package check (required)
devtools::check()

# Python tests (required)
system("pip install -e ./pykyschooldata && pytest tests/test_pykyschooldata.py -v")

# pkgdown build (required)
pkgdown::build_site()
```

### Pre-PR Checklist

Before opening a PR, verify:
- [ ] `devtools::check()` — 0 errors, 0 warnings
- [ ] `pytest tests/test_pykyschooldata.py` — all tests pass
- [ ] `pkgdown::build_site()` — builds without errors
- [ ] Vignettes render (no `eval=FALSE` hacks)

---

## LIVE Pipeline Testing

This package includes `tests/testthat/test-pipeline-live.R` with LIVE network tests.

### Test Categories:
1. URL Availability - HTTP 200 checks
2. File Download - Verify actual file (not HTML error)
3. File Parsing - readxl/readr succeeds
4. Column Structure - Expected columns exist
5. get_raw_enr() - Raw data function works
6. Data Quality - No Inf/NaN, non-negative counts
7. Aggregation - State total > 0
8. Output Fidelity - tidy=TRUE matches raw

### Running Tests:
```r
devtools::test(filter = "pipeline-live")
```

See `state-schooldata/CLAUDE.md` for complete testing framework documentation.

