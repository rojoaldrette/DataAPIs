# Package environment for configuration
.pkg_env <- new.env(parent = emptyenv())

# Initialize default configuration
.pkg_env$config <- list(
  banxico_token = NULL,
  inegi_token = NULL,
  fred_token = NULL
)

#' Set API tokens for the package
#'
#' @param banxico_token Banxico API token (character)
#' @param inegi_token INEGI API token (character)
#' @param fred_token FRED API token (character)
#' @return Invisible NULL
#' @export
#' @examples
#' set_api_tokens(
#'   banxico_token = "your_banxico_token",
#'   inegi_token = "your_inegi_token",
#'   fred_token = "your_fred_token"
#' )
set_api_tokens <- function(banxico_token = NULL, inegi_token = NULL, fred_token = NULL) {
  if (!is.null(banxico_token)) .pkg_env$config$banxico_token <- banxico_token
  if (!is.null(inegi_token)) .pkg_env$config$inegi_token <- inegi_token
  if (!is.null(fred_token)) .pkg_env$config$fred_token <- fred_token
  invisible()
}

#' Get current API tokens
#'
#' @return List of currently configured API tokens
#' @export
#' @examples
#' get_api_tokens()
get_api_tokens <- function() {
  return(.pkg_env$config)
}

# Package startup message
.onLoad <- function(libname, pkgname) {
  packageStartupMessage(
    "Remember to set your API tokens using set_api_tokens()"
  )
}
