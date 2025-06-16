library(plumber)
library(RSQLite)
library(DBI)

#* @apiTitle Football Match Stats API
#* @apiDescription API to query football matches, stats, and events from my SQLite database

#* @get /teams
#* Returns all teams available in the database
function() {
  con <- DBI::dbConnect(RSQLite::SQLite(), "my_database.sqlite")
  on.exit(DBI::dbDisconnect(con)) 
  
  result <- dbGetQuery(con, "
                       SELECT * FROM teams
                       ")
  
  return(result)
}

#* @get /leagues
#* Returns all leagues in the database
function() {
  con <- DBI::dbConnect(RSQLite::SQLite(), "my_database.sqlite")
  on.exit(DBI::dbDisconnect(con)) 
  
  result <- dbGetQuery(con, "
                       SELECT * FROM leagues
                       ")
  
  return(result)
}

#* @get /matches
#* Returns all matches in a season
#* @param league_id:int
#* @param season The season e.g. 2022_23, 2023_24 or 2024_25
function(league_id, season) {
  con <- DBI::dbConnect(RSQLite::SQLite(), "my_database.sqlite")
  on.exit(DBI::dbDisconnect(con)) 
  
  result <- dbGetQuery(con, "
    SELECT * FROM matches
    WHERE league_id = ? AND season = ?
  ", params = list(league_id, season))
  
  return(result)
}

#* @get /stats
#* Stats per match e.g. possession, corners etc.
#* @param team_id:int
#* @param season
function(team_id, season) {
  con <- dbConnect(RSQLite::SQLite(), "my_database.sqlite")
  on.exit(dbDisconnect(con))
  
  result <- dbGetQuery(con, "
  SELECT s.*
  FROM stats s
  JOIN matches m ON s.match_id = m.match_id
  WHERE s.team_id = ? AND m.season = ?
", params = list(team_id, season))
  
  return(result)
}

#* @get /match_details
#* Everything related to a match, stats and match events
#* @param match_id:int
function(match_id) {
  con <- dbConnect(RSQLite::SQLite(), "my_database.sqlite")
  on.exit(dbDisconnect(con))
  
  # Summary: teams and results
  summary <- dbGetQuery(con, "
    SELECT 
      m.match_id, 
      m.season,
      th.team_name AS home_team,
      ta.team_name AS away_team,
      s1.result AS home_result,
      s2.result AS away_result
    FROM matches m
    JOIN teams th ON m.home_id = th.team_id
    JOIN teams ta ON m.away_id = ta.team_id
    JOIN stats s1 ON m.match_id = s1.match_id AND s1.team_id = m.home_id
    JOIN stats s2 ON m.match_id = s2.match_id AND s2.team_id = m.away_id
    WHERE m.match_id = ?
  ", params = list(match_id))
  
  # Events for the match
  events <- dbGetQuery(con, "
    SELECT  
      t.team_name AS team,
      e.time,
      e.event
    FROM events e
    JOIN teams t ON e.team_id = t.team_id
    WHERE e.match_id = ?
    ORDER BY e.time
  ", params = list(match_id))
  
  # Full stats for both teams
  stats <- dbGetQuery(con, "
    SELECT 
      t.team_name, 
      s.location,
      s.result,
      s.ball_possession,
      s.total_shots,
      s.shots_on_target,
      s.corner_kicks,
      s.shots_off_target,
      s.offsides,
      s.fouls,
      s.goalkeeper_saves
    FROM stats s
    JOIN teams t ON s.team_id = t.team_id
    WHERE s.match_id = ?
  ", params = list(match_id))
  
  return(list(
    summary = summary,
    stats = stats,
    events = events
  ))
}
