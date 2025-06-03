library(plumber)
library(dplyr)

#* @apiTitle Football Match Stats API
#* @apiDescription An API for accessing and summarizing football match data across multiple leagues, teams, and seasons.


#* @param league 
#* @param season 
#* @param result 
#* @param team 
#* @get /matches
function(league = "bundesliga", season = NULL, result = NULL, team = NULL) {
  league_path <- file.path("Data", league)
  
  if (!dir.exists(league_path)) {
    return(list(error = sprintf("League not found: %s", league)))
  }
  
  season_files <- if (is.null(season)) {
    list.files(league_path, pattern = "\\.rds$", full.names = TRUE)
  } else {
    file <- file.path(league_path, paste0(season, ".rds"))
    if (!file.exists(file)) {
      return(list(error = sprintf("No data for %s %s", league, season)))
    }
    file
  }
  
  combined <- data.frame()
  
  for (file in season_files) {
    try({
      df <- readRDS(file)
      season_name <- tools::file_path_sans_ext(basename(file))
      df$season <- season_name  # tag the season
      
      if (!is.null(team)) {
        df <- df[tolower(df$team) == tolower(team), ]
      }
      if (!is.null(result)) {
        df <- df[tolower(df$result) == tolower(result), ]
      }
      
      combined <- rbind(combined, df)
    }, silent = TRUE)
  }
  
  return(combined)
}


#* @param league
#* @get /meta
function(league = NULL) {
  root <- "Data"
  all_leagues <- list.dirs(root, recursive = FALSE, full.names = FALSE)

  if (!is.null(league) && !(league %in% all_leagues)) {
    return(list(error = paste("League not found:", league)))
  }
      
  leagues_to_process <- if (is.null(league)) all_leagues else league
  result <- list()
  
  for (lg in leagues_to_process) {
    league_path <- file.path(root, lg)
    result[[lg]] <- list()
    
    season_files <- list.files(league_path, pattern = "\\.rds$", full.names = TRUE)
    for (season_file in season_files) {
      season_name <- tools::file_path_sans_ext(basename(season_file))
      
      try({
        df <- readRDS(season_file)
        if ("team" %in% names(df)) {
          teams <- unique(df[["team"]])
          result[[lg]][[season_name]] <- sort(as.character(teams))
        }
      }, silent = TRUE)
    }
  }
  return(result)
}

#* @param league
#* @param season 
#* @param team 
#* @get /summary
function(league = "bundesliga", season = "2024_25", team = NULL) {
  library(dplyr)
  
  league_path <- file.path("Data", league)
  if (!dir.exists(league_path)) {
    return(list(error = sprintf("League not found: %s", league)))
  }
  
  season_files <- if (is.null(season)) {
    list.files(league_path, pattern = "\\.rds$", full.names = TRUE)
  } else {
    file <- file.path(league_path, paste0(season, ".rds"))
    if (!file.exists(file)) {
      return(list(error = sprintf("No data for %s %s", league, season)))
    }
    file
  }
  
  combined <- data.frame()
  
  for (file in season_files) {
    try({
      df <- readRDS(file)
      df$season <- tools::file_path_sans_ext(basename(file))
      
      if (!is.null(team)) {
        df <- df[tolower(df$team) == tolower(team), ]
      }
      
      combined <- rbind(combined, df)
    }, silent = TRUE)
  }
  
  if (nrow(combined) == 0) {
    return(list(error = "No data matched your query."))
  }
  
  combined <- combined %>%
    mutate(
      total_goals = sapply(events, function(e) sum(e$event == "goal")),
      total_fouls = sapply(events, function(e) sum(e$event == "foul"))
    )
  
  summary_df <- combined %>%
    summarise(
      matches = n(),
      wins = sum(tolower(result) == "win"),
      draws = sum(tolower(result) == "draw"),
      losses = sum(tolower(result) == "loss"),
      avg_possession = mean(Ball.Possession, na.rm = TRUE),
      avg_shots = mean(Total.shots, na.rm = TRUE),
      total_goals = sum(total_goals),
      total_fouls = sum(total_fouls),
      total_corners = sum(Corner.Kicks, na.rm = TRUE),
      total_saves = sum(Goalkeeper.Saves, na.rm = TRUE)
    )
  
  return(summary_df)
}



