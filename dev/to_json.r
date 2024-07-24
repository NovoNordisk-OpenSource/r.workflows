cspell <- yaml::read_yaml("dev/cspell.config.yaml")
cspell %>%
    jsonlite::write_json(".github/linters/.cspell.json", pretty = TRUE)
