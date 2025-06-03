library(plumber)
plumb(file='api.R')$run(host="0.0.0.0", port=8000)

