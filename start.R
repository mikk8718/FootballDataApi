library(plumber)
plumb(file='backend.R')$run(host="0.0.0.0", port=8000)

