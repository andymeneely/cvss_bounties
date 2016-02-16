# Function Definitions
init.libraries <- function(){
    suppressPackageStartupMessages(library("DBI"))
    suppressPackageStartupMessages(library("ggplot2"))
    suppressPackageStartupMessages(library("effsize"))
    suppressPackageStartupMessages(library("corrplot"))
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