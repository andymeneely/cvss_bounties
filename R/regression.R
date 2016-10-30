# Clear
rm(list = ls())
cat("\014")

# Source Library
source("library.R")

# Initialize Libraries
init.libraries()

# Database Connection
db.connection <- get.db.connection()
dataset <- db.get.data(db.connection, QUERY)
db.disconnect(db.connection)

# Dataset Transformation
dataset <- transform.dataset(dataset)

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

### Stepwise Selection

### Metric: Amount
lm.amount.subset <- step(lm.amount, direction = "both", k = 2)
print(summary(lm.amount.subset))

### Replicating CVSS v2
#### Metric: Score
lm.replication.score <- lm(
  score ~ availability_impact + confidentiality_impact + integrity_impact -
    availability_impact * confidentiality_impact - confidentiality_impact * integrity_impact - integrity_impact * availability_impact +
    availability_impact * confidentiality_impact * integrity_impact + access_vector * access_complexity * authentication,
  data = dataset
)
print(summary(lm.replication.score))

#### Metric: Amount
lm.replication.amount <- lm(
  amount ~ availability_impact + confidentiality_impact + integrity_impact -
    availability_impact * confidentiality_impact - confidentiality_impact * integrity_impact - integrity_impact * availability_impact +
    availability_impact * confidentiality_impact * integrity_impact + access_vector * access_complexity * authentication,
  data = dataset
)
print(summary(lm.replication.amount))

## Recursive Partitioning and Regression Trees

### Metric: Score
rpart.score <- rpart(
  score ~ access_complexity + access_vector + authentication +
    availability_impact + confidentiality_impact + integrity_impact,
  data = dataset, method = "anova"
)
print(summary(rpart.score))

### Metric: Amount
rpart.amount <- rpart(
  amount ~ access_complexity + access_vector + authentication +
    availability_impact + confidentiality_impact + integrity_impact,
  data = dataset, method = "anova"
)
print(summary(rpart.amount))
