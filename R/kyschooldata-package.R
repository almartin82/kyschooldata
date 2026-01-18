#' kyschooldata: Fetch and Process Kentucky School Data
#'
#' Downloads and processes school data from the Kentucky Department of
#' Education (KDE). Provides functions for fetching enrollment data from the
#' School Report Card (SRC) datasets and SAAR (Superintendent's Annual
#' Attendance Report) data, transforming it into tidy format for analysis.
#'
#' @section Main functions:
#' \describe{
#'   \item{\code{\link{fetch_enr}}}{Fetch enrollment data for a school year}
#'   \item{\code{\link{fetch_enr_multi}}}{Fetch enrollment data for multiple years}
#'   \item{\code{\link{tidy_enr}}}{Transform wide data to tidy (long) format}
#'   \item{\code{\link{id_enr_aggs}}}{Add aggregation level flags}
#'   \item{\code{\link{enr_grade_aggs}}}{Create grade-level aggregations}
#'   \item{\code{\link{get_available_years}}}{Show available enrollment data years}
#' }
#'
#' @section Cache functions:
#' \describe{
#'   \item{\code{\link{cache_status}}}{View cached data files}
#'   \item{\code{\link{clear_cache}}}{Remove cached data files}
#' }
#'
#' @section ID System:
#' Kentucky uses a hierarchical ID system:
#' \itemize{
#'   \item District IDs: 3 digits (e.g., 275 = Jefferson County)
#'   \item School IDs: 6 digits (3-digit district + 3-digit school)
#' }
#'
#' @section Data Sources:
#' Data is sourced from the Kentucky Department of Education:
#' \itemize{
#'   \item SRC: \url{https://openhouse.education.ky.gov/Home/SRCData}
#'   \item Open House: \url{https://www.education.ky.gov/Open-House/data/Pages/default.aspx}
#'   \item SAAR: \url{https://www.education.ky.gov/districts/enrol/pages/historical-saar-data.aspx}
#' }
#'
#' @section Data Eras:
#' \itemize{
#'   \item Era 1 (1997-2011): SAAR Ethnic Membership Reports - district-level only
#'   \item Era 2 (2012-2019): SRC Historical Datasets - school and district level
#'   \item Era 3 (2020-2025): SRC Current Format - school and district level with grade data
#' }
#'
#' @docType package
#' @name kyschooldata-package
#' @aliases kyschooldata
#' @keywords internal
"_PACKAGE"

