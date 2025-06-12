library(dplyr)
library(jsonlite)
library(tidyr)
library(purrr)
library(glue)
setwd("/Users/sangmee/Desktop/FootballDataAPi")

pre_process_csv <- function(name, league){
  path <- paste(paste("Data/", league, sep=""), name, sep="/")
  dataset <- read.csv(paste(path, ".csv", sep=""))
  # format data
  filteredDataset <- dataset %>% 
    select_if(~ !any(is.na(.))) %>%
    select(, "team", "location", "result", "events", "Ball.Possession", "Total.shots", "Shots.on.target", "Corner.Kicks", "Shots.off.target", "Offsides", "Fouls", "Goalkeeper.Saves")
  filteredDataset$events <- as.list(filteredDataset$events)
  filteredDataset$events <- lapply(filteredDataset$events, fromJSON)
  filteredDataset$Ball.Possession <- as.integer(gsub("%", "", filteredDataset$Ball.Possession))
  saveRDS(filteredDataset, paste(path, ".rds", sep=""))
}

create_teams_table <- function(){
  rds_files <- list.files("Data", pattern = "\\.rds$", recursive = TRUE, full.names = TRUE)
  
  all_teams <- c()
  
  for (file in rds_files) {
    try({
      df <- readRDS(file)
      
      if ("team" %in% names(df)) {
        all_teams <- c(all_teams, as.character(df$team))
      }
      
    }, silent = TRUE)
  }
  unique_teams = sort(unique(all_teams))
  return(
    data.frame(
      team_id = seq_along(unique_teams),
      team_name = unique_teams,
      stringsAsFactors = FALSE
  ))
}
  

create_league_table<- function () {
  return (
    data.frame(
      league_id = c(1, 2, 3),
      league_name = c("premier_league", "la_liga", "bundesliga"),
      stringsAsFactors = FALSE
    )
  )
}




extract_match_stats <- function() {
  
}

extract_events <- function() {
  
}

extract_matches <- function (match_id, league_id, season, home_id, away_id) {
  return(list(
    match_id = match_id,
    league_id = league_id,
    season = season,
    home_id = home_id,
    away_id = away_id
  ))
}

extract_events_and_matches_and_stats <- function (team_df, league_df) {
  rds_files <- list.files("Data", 
                          pattern = "\\.rds$", 
                          recursive = TRUE, 
                          full.names = TRUE)
  
  match_rows <- list()
  for (file in rds_files) {
    try({
      df <- readRDS(file)
      season <- tools::file_path_sans_ext(basename(file))
      league <- basename(dirname(file))
      match_id <- 1
      
      for(i in seq(1, nrow(df), by=2)){
        pair <- df[i:(i+1), ]
        home <- pair[1, ]
        away <- pair[2, ]

        match_row <- extract_matches(match_id, 
                                     league_df$league_id[league_df$league_name == league], 
                                     season, 
                                     team_df$team_id[team_df$team_name == home$team], 
                                     team_df$team_id[team_df$team_name == away$team])
        
        match_rows[[length(match_rows) + 1]] <- as.data.frame(match_row)
        
        match_id <- match_id + 1
      }
    }, silent = FALSE)
    print("###################################")
  }
  t <- do.call(rbind, match_rows)
  return(t)
}



#pre_process_csv("2022_23", "la_liga")
teams_table <- create_teams_table()
league_table <- create_league_table()
f <- extract_events_and_matches_and_stats(teams_table, league_table)

f %>%
  filter(league_id == 3, season == "2024_25") %>%
  count()
