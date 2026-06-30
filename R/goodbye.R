#' Say goodbye to someone
#' @param name The name of the person to say goodbye to
#' @return A string saying goodbye to the person, reusing [hello()] as the prefix
#' @export
#' @examples
#' goodbye("world")
goodbye <- function(name) {
  return(
    paste(hello(name), "and goodbye")
  )
}
