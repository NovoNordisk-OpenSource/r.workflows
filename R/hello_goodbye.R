#' Say hello and goodbye to someone
#' @param name The name of the person
#' @return A string saying hello and goodbye to the person
#' @export
#' @examples
#' hello_goodbye("world")
hello_goodbye <- function(name) {
  paste(
    hello(name),
    "and goodbye!"
  )
}
