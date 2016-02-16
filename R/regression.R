# Clear
rm(list = ls())
cat("\014")

# Source Library
source("library.R")

# Initialize Libraries
init.libraries()

# Constants
QUERY = 
  "SELECT cve.id, cve.product, bounty.amount, cvss.score,
    cvss.access_complexity, cvss.access_vector,
    cvss.authentication, cvss.availability_impact,
    cvss.confidentiality_impact, cvss.integrity_impact
  FROM cve
    JOIN cvss ON cvss.cve_id = cve.id
    JOIN bounty ON bounty.cve_id = cve.id"

# Database Connection
db.connection <- get.db.connection()
dataset <- db.get.data(db.connection, QUERY)
db.disconnect(db.connection)

# Data Tranformations

## Transform Categoricals into Factors
dataset$access_complexity <- factor(dataset$access_complexity)
dataset$access_vector <- factor(dataset$access_vector)
dataset$authentication <- factor(dataset$authentication)
dataset$availability_impact <- factor(dataset$availability_impact)
dataset$confidentiality_impact <- factor(dataset$confidentiality_impact)
dataset$integrity_impact <- factor(dataset$integrity_impact)

# Regression Analysis

## Simple Linear Regression
### Metric: Score
lm.score <- lm(
  score ~ access_complexity + access_vector + authentication +
    availability_impact + confidentiality_impact + integrity_impact,
  data = dataset
)
print(summary(lm.score))

### Metric: Amount
lm.amount <- lm(
  amount ~ access_complexity + access_vector + authentication +
    availability_impact + confidentiality_impact + integrity_impact,
  data = dataset
)
print(summary(lm.amount))