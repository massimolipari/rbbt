
#' Detect pandoc-style citations
#'
#' By default, this omits any references within code chunks, inline R code,
#' or URLs. To force the inclusion of a reference in the output, include it
#' in an HTML comment or the
#' [nocite front matter field](https://rmarkdown.rstudio.com/authoring_bibliographies_and_citations.html#Unused_References_(nocite)).
#'
#' @param path A character vector, file or URL whose contents may contain citation keys.
#'   Multiple files can be passed in as a vector (e.g., from [list.files()]).
#' @param locale See [readr::default_locale()]. Use if encoding might
#'   be a problem.
#'
#' @return A character vector of unique citation keys.
#' @export
#'
#' @examples
#' bbt_detect_citations("\n@citation1 and [@citation2] but not \\@citation3")
#'
bbt_detect_citations <- function(path = bbt_guess_citation_context(), locale = readr::default_locale()) {
  text <- vapply(path, readr::read_file, locale = locale, FUN.VALUE = character(1))
  bbt_detect_citations_chr(text)
}

#' @rdname bbt_detect_citations
#' @export
bbt_guess_citation_context <- function() {
  knitr_doc <- knitr::current_input()
  if (!is.null(knitr_doc)) {
    knitr_doc
  } else {
    stop("Can't detect context (tried current knitr doc)", call. = FALSE)
  }
}

prepare_whitelists <- function(){
  quarto_wl <- getOption("rbbt.whitelist.quarto")
  user_wl <- getOption("rbbt.whitelist.user")
  wl <- vector("character")
  if(length(quarto_wl)>0)
    wl <- c(wl, paste(paste0("(",quarto_wl, ")"), collapse="|"))
  if(length(user_wl)>0)
    wl <- c(wl, paste(paste0("(",user_wl, ")"), collapse="|"))
  wl
}

bbt_detect_citations_chr <- function(text) {
  text <- paste0(text, collapse = "\n")

  # regexes inspired from here:
  # https://github.com/benmarwick/wordcountaddin/blob/master/R/hello.R#L163-L199

  # don't include text in code chunks
  text <- gsub("\n```\\{.+?\\}.+?\r?\n```", "", text)

  # don't include text in in-line R code
  text <- gsub("`r.+?`", "", text)

  # don't include inline markdown URLs
  text <- gsub("\\(http.+?\\)", "", text)
  text <- gsub("<http.+?>", "", text)

  refs <- stringr::str_match_all(
    text,
    stringr::regex("[^a-zA-Z0-9\\\\]@([a-zA-Z0-9_\\.\\-:]+[a-zA-Z0-9])", multiline = TRUE, dotall = TRUE)
  )[[1]][, 2, drop = TRUE]

  refs <- stringr::str_subset(string = refs, pattern =prepare_whitelists(), negate = TRUE)

  unique(refs)
}
