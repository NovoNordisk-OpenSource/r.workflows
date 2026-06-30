#' Say hello to someone
#' @param name The name of the person to say hello to
#' @return A string saying hello to the person
#' @export
#' @examples
#' hello("world")
hello <- function(name) {
  return(
    paste("Hello", name)
  )
}
