# Function Definitions
init.libraries <- function(){
    suppressPackageStartupMessages(library("DBI"))
    suppressPackageStartupMessages(library("ggplot2"))
    suppressPackageStartupMessages(library("effsize"))
}

get.db.connection <- function(environment="PRODUCTION"){
  if(environment == "PRODUCTION"){
    return(
      db.connect(
        provider = "PostgreSQL",
        user = "", password = "",
        host = "localhost", port = "5432",
        dbname = "bountyvscvss"
      )
    )
  } else if(environment == "DEVELOPMENT") {
    return(
      db.connect(
        provider = "SQLite", dbname = "../db.sqlite3"
      )
    )
  } else {
    stop(sprint("Unknown environment %s.", environment))
  }
}

db.connect <- function(host = NA, port = NA, user = NA, password = NA, dbname,
                       provider = "PostgreSQL"){
    connection <- NULL

    if(provider == "PostgreSQL"){
        library("RPostgreSQL")
        driver <- dbDriver(provider)
        connection <- dbConnect(driver,
            host=host,
            port=port,
            user=user,
            password=password,
            dbname=dbname
        )
    } else if(provider == "MySQL"){
      library("RMySQL")
      driver <- dbDriver(provider)
      connection <- dbConnect(driver,
                              host=host,
                              port=port,
                              user=user,
                              password=password,
                              dbname=dbname
      )
    } else if(provider == "SQLite"){
      library("RSQLite")
      driver <- dbDriver(provider)
      connection <- dbConnect(driver,
                              dbname=dbname
      )
    } else {
        # TODO: Add other providers
        stop(sprint("Database provider %s not supported.", provider))
    }

    return(connection)
}

db.disconnect <- function(connection){
    return(dbDisconnect(connection))
}

db.get.data <- function(connection, query){
    return(dbGetQuery(connection, query))
}