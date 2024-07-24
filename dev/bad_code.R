bad_fct <- function(x) {
    x <- x + 1
    if (x > 10) {
        return(x)
    }

    return(x - 1)
}
