# Constants
METRIC.LABELS <- vector(mode = "list", length = 6)
names(METRIC.LABELS) <- c(
  "access_complexity", "access_vector", "authentication",
  "availability_impact", "confidentiality_impact", "integrity_impact"
)
METRIC.LABELS$access_complexity <- "Access Complexity"
METRIC.LABELS$access_vector <- "Access Vector"
METRIC.LABELS$authentication <- "Authentication"
METRIC.LABELS$availability_impact <- "Availability Impact"
METRIC.LABELS$confidentiality_impact <- "Confidentiality Impact"
METRIC.LABELS$integrity_impact <- "Integrity Impact"

METRIC.VALUES <- vector(mode = "list", length = 6)
names(METRIC.VALUES) <- c(
  "access_complexity", "access_vector", "authentication",
  "availability_impact", "confidentiality_impact", "integrity_impact"
)
METRIC.VALUES$access_complexity <- c("LOW", "MEDIUM", "HIGH")
METRIC.VALUES$access_vector <- c("LOCAL", "ADJACENT_NETWORK", "NETWORK")
METRIC.VALUES$authentication <- c("NONE", "SINGLE_INSTANCE", "MULTIPLE_INSTANCES")
METRIC.VALUES$availability_impact <- c("NONE", "PARTIAL", "COMPLETE")
METRIC.VALUES$confidentiality_impact <- c("NONE", "PARTIAL", "COMPLETE")
METRIC.VALUES$integrity_impact <- c("NONE", "PARTIAL", "COMPLETE")

METRIC.VALUE.LABELS <- vector(mode = "list", length = 11)
names(METRIC.VALUE.LABELS) <- c(
  "LOW", "MEDIUM", "HIGH",
  "LOCAL", "ADJACENT_NETWORK", "NETWORK",
  "NONE", "SINGLE_INSTANCE", "MULTIPLE_INSTANCES",
  "PARTIAL", "COMPLETE"
)
METRIC.VALUE.LABELS$LOW <- "Low"
METRIC.VALUE.LABELS$MEDIUM <- "Medium"
METRIC.VALUE.LABELS$HIGH <- "High"
METRIC.VALUE.LABELS$LOCAL <- "Local"
METRIC.VALUE.LABELS$ADJACENT_NETWORK <- "Adjacent Network"
METRIC.VALUE.LABELS$NETWORK <- "Network"
METRIC.VALUE.LABELS$NONE <- "No"
METRIC.VALUE.LABELS$SINGLE_INSTANCE <- "Single"
METRIC.VALUE.LABELS$MULTIPLE_INSTANCES <- "Multiple"
METRIC.VALUE.LABELS$PARTIAL <- "Partial"
METRIC.VALUE.LABELS$COMPLETE <- "Complete"

# Function Definitions
init.libraries <- function(){
  suppressPackageStartupMessages(library("DBI"))
  suppressPackageStartupMessages(library("gtable"))
  suppressPackageStartupMessages(library("ggplot2"))
  suppressPackageStartupMessages(library("effsize"))
  suppressPackageStartupMessages(library("rpart"))
  suppressPackageStartupMessages(library("Rmisc"))
  suppressPackageStartupMessages(library("stringr"))
  suppressPackageStartupMessages(library("grid"))
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

transform.dataset <- function(dataset){
  dataset$access_complexity <- factor(dataset$access_complexity, level = METRIC.VALUES$access_complexity)
  dataset$access_vector <- factor(dataset$access_vector, level = METRIC.VALUES$access_vector)
  dataset$authentication <- factor(dataset$authentication, level = METRIC.VALUES$authentication)
  dataset$availability_impact <- factor(dataset$availability_impact, level = METRIC.VALUES$availability_impact)
  dataset$confidentiality_impact <- factor(dataset$confidentiality_impact, level = METRIC.VALUES$confidentiality_impact)
  dataset$integrity_impact <- factor(dataset$integrity_impact, level = METRIC.VALUES$integrity_impact)
  return(dataset)
}

# Outlier detection using kmeans clustering
get.outlier.indices <- function(data.vector){
  clusters <- kmeans(x = data.vector, centers = 2)$cluster
  clusters.count <- table(clusters)
  outlier.cluster <- names(clusters.count[clusters.count == min(clusters.count)])
  outlier.indices <- which(clusters == outlier.cluster)
  return(outlier.indices)
}