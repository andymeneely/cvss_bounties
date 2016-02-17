# Clear
rm(list = ls())
cat("\014")

# Source Library
source("library.R")

# Initialize Libraries
init.libraries()

# Constants
CRITERIA <- c(
  "[Access Complexity] Low vs. Medium",
  "[Access Complexity] Medium vs. High",
  "[Access Vector] Local vs. Network",
  "[Authentication] None vs. Single",
  "[Availability Impact] None vs. Partial",
  "[Availability Impact] Partial vs. Complete",
  "[Confidentiality Impact] None vs. Partial",
  "[Confidentiality Impact] Partial vs. Complete",
  "[Integrity Impact] None vs. Partial",
  "[Integrity Impact] Partial vs. Complete"
)
COLNAMES <- c(
  "Cohen's d (Bounty)", "Effect (Bounty)",
  "Cohen's d (Score)", "Effect (Score)"
)
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

# Correlation
cor.test(dataset$score, dataset$amount, method = "spearman", exact = F)

# Pairwise Effect Evaluation

## Metric: Amount
effect.amount <- vector(mode = "list", length = length(CRITERIA))

### Access Complexity
#### Low vs. Medium
effect.amount[[1]] <- cohen.d(
  dataset$amount[dataset$access_complexity == "LOW"],
  dataset$amount[dataset$access_complexity == "MEDIUM"]
)
#### Medium vs. High
effect.amount[[2]] <- cohen.d(
  dataset$amount[dataset$access_complexity == "MEDIUM"],
  dataset$amount[dataset$access_complexity == "HIGH"]
)

### Access Vector
#### Local vs. Network
effect.amount[[3]] <- cohen.d(
  dataset$amount[dataset$access_vector == "LOCAL"],
  dataset$amount[dataset$access_vector == "NETWORK"]
)

### Authentication
#### None vs. Single Instance
effect.amount[[4]] <- cohen.d(
  dataset$amount[dataset$authentication == "NONE"],
  dataset$amount[dataset$authentication == "SINGLE_INSTANCE"]
)

### Availability Impact
#### None vs. Partial
effect.amount[[5]] <- cohen.d(
  dataset$amount[dataset$availability_impact == "NONE"],
  dataset$amount[dataset$availability_impact == "PARTIAL"]
)
#### Partial vs. Complete
effect.amount[[6]] <- cohen.d(
  dataset$amount[dataset$availability_impact == "PARTIAL"],
  dataset$amount[dataset$availability_impact == "COMPLETE"]
)

## Confidentiality Impact
#### None vs. Partial
effect.amount[[7]] <- cohen.d(
  dataset$amount[dataset$confidentiality_impact == "NONE"],
  dataset$amount[dataset$confidentiality_impact == "PARTIAL"]
)
#### Partial vs. Complete
effect.amount[[8]] <- cohen.d(
  dataset$amount[dataset$confidentiality_impact == "PARTIAL"],
  dataset$amount[dataset$confidentiality_impact == "COMPLETE"]
)

### Integrity Impact
#### None vs. Partial
effect.amount[[9]] <- cohen.d(
  dataset$amount[dataset$integrity_impact == "NONE"],
  dataset$amount[dataset$integrity_impact == "PARTIAL"]
)
#### Partial vs. Complete
effect.amount[[10]] <- cohen.d(
  dataset$amount[dataset$integrity_impact == "PARTIAL"],
  dataset$amount[dataset$integrity_impact == "COMPLETE"]
)

## Metric: Score
effect.score <- vector(mode = "list", length = length(CRITERIA))

### Access Complexity
#### Low vs. Medium
effect.score[[1]] <- cohen.d(
  dataset$score[dataset$access_complexity == "LOW"],
  dataset$score[dataset$access_complexity == "MEDIUM"]
)
#### Medium vs. High
effect.score[[2]] <- cohen.d(
  dataset$score[dataset$access_complexity == "MEDIUM"],
  dataset$score[dataset$access_complexity == "HIGH"]
)

### Access Vector
#### Local vs. Network
effect.score[[3]] <- cohen.d(
  dataset$score[dataset$access_vector == "LOCAL"],
  dataset$score[dataset$access_vector == "NETWORK"]
)

### Authentication
#### None vs. Single Instance
effect.score[[4]] <- cohen.d(
  dataset$score[dataset$authentication == "NONE"],
  dataset$score[dataset$authentication == "SINGLE_INSTANCE"]
)

### Availability Impact
#### None vs. Partial
effect.score[[5]] <- cohen.d(
  dataset$score[dataset$availability_impact == "NONE"],
  dataset$score[dataset$availability_impact == "PARTIAL"]
)
#### Partial vs. Complete
effect.score[[6]] <- cohen.d(
  dataset$score[dataset$availability_impact == "PARTIAL"],
  dataset$score[dataset$availability_impact == "COMPLETE"]
)

## Confidentiality Impact
#### None vs. Partial
effect.score[[7]] <- cohen.d(
  dataset$score[dataset$confidentiality_impact == "NONE"],
  dataset$score[dataset$confidentiality_impact == "PARTIAL"]
)
#### Partial vs. Complete
effect.score[[8]] <- cohen.d(
  dataset$score[dataset$confidentiality_impact == "PARTIAL"],
  dataset$score[dataset$confidentiality_impact == "COMPLETE"]
)

### Integrity Impact
#### None vs. Partial
effect.score[[9]] <- cohen.d(
  dataset$score[dataset$integrity_impact == "NONE"],
  dataset$score[dataset$integrity_impact == "PARTIAL"]
)
#### Partial vs. Complete
effect.score[[10]] <- cohen.d(
  dataset$score[dataset$integrity_impact == "PARTIAL"],
  dataset$score[dataset$integrity_impact == "COMPLETE"]
)

### Comparison
amount.d <- numeric(length = length(CRITERIA))
amount.effect <- character(length = length(CRITERIA))
score.d <- numeric(length = length(CRITERIA))
score.effect <- character(length = length(CRITERIA))
for(i in 1:length(CRITERIA)){
  amount.d[i] <- round(effect.amount[[i]]$estimate, 4)
  amount.effect[i] <- effect.amount[[i]]$magnitude
  
  score.d[i] <- round(effect.score[[i]]$estimate, 4)
  score.effect[i] <- effect.score[[i]]$magnitude
}
effect.comparison <- data.frame(
  amount.d, amount.effect, score.d, score.effect 
)
rownames(effect.comparison) <- CRITERIA
colnames(effect.comparison) <- COLNAMES

### Output
print(effect.comparison)