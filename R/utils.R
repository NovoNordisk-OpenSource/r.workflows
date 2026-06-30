#' Convert a name to proper case
#' @param name A character string to convert
#' @return The name in proper case (first letter of each word capitalised)
#' @noRd
proper_case <- function(name) {
  return(
    tools::toTitleCase(tolower(name))
  )
}
