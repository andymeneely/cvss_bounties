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
METRIC.VALUE.LABELS$NONE <- "None"
METRIC.VALUE.LABELS$SINGLE_INSTANCE <- "Single"
METRIC.VALUE.LABELS$MULTIPLE_INSTANCES <- "Multiple"
METRIC.VALUE.LABELS$PARTIAL <- "Partial"
METRIC.VALUE.LABELS$COMPLETE <- "Complete"

QUERY =
  "SELECT cve.year, cve.id, cve.product, bounty.amount,
    cvss.score, cvss.exploitability_subscore,
    cvss.impact_subscore, cvss.access_complexity,
    cvss.access_vector, cvss.authentication,
    cvss.availability_impact, cvss.confidentiality_impact,
    cvss.integrity_impact
  FROM cve
    JOIN cvss ON cvss.cve_id = cve.id
    JOIN bounty ON bounty.cve_id = cve.id"

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
  suppressPackageStartupMessages(library("gridExtra"))
  suppressPackageStartupMessages(library("compute.es"))
  suppressPackageStartupMessages(library("irr"))
  suppressPackageStartupMessages(library("randomForest"))
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
<<<<<<< HEAD
}

# Spearman's Correlation
get.spearmansrho <- function(dataset, column.one, column.two, p.value = 0.05){
  correlation <- cor.test(dataset[[column.one]], dataset[[column.two]], method = "spearman", exact = F)
  if(correlation$p.value > p.value){
    stop(paste("Spearman's correlation insignificant with p-value =", correlation$p.value))
  }
  return(round(correlation$estimate, 4))
}

eval.es <- function(d){
  d = abs(d)
  if(d >= 0.8){
    return("large")
  } else if(d >= 0.5 && d < 0.8){
    return("medium")
  } else if(d >= 0.2 && d < 0.5){
    return("small")
  } else {
    return("negligible")
  }
}

# Cohen's Effect Size Metrics
get.u3 = function(d){
  return(pnorm(abs(d)))
}
get.u2 = function(d){
  return(pnorm(abs(d) / 2))
}
get.u1 = function(d){
  return((2 * get.u2(abs(d)) - 1) / get.u2(abs(d)))
}