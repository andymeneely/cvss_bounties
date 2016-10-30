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
  "Effect", "Cohen's d", "Cohen's U1", "p-value"
)

# Database Connection
db.connection <- get.db.connection()
dataset <- db.get.data(db.connection, QUERY)
db.disconnect(db.connection)

# Dataset Transformation
dataset <- transform.dataset(dataset)

# Correlation

## Overall
cor.test(dataset$score, dataset$amount, method = "spearman", exact = F)

## Individual Product
correlation.product = data.frame()
for(product in unique(dataset$product)){
  product.dataset <- dataset[dataset$product == product,]
  if(nrow(product.dataset) > 2 & sd(product.dataset$score) != 0 & sd(product.dataset$amount) != 0){
    correlation <- cor.test(
      product.dataset$score, product.dataset$amount, method = "spearman", exact = F
    )
    correlation.product <- rbind(
      correlation.product,
      data.frame(
        "product" = product, "p-value" = correlation$p.value, "rho" = correlation$estimate, "count" = nrow(product.dataset)
      )
    )
  }
}
print(correlation.product)

## Evolution by Product
correlation.product.evolution = data.frame()
for(product in unique(dataset$product)){
  product.dataset <- dataset[dataset$product == product,]
  for(year in unique(product.dataset$year)){
    product.year.dataset <- product.dataset[product.dataset$year == year,]
    if(nrow(product.year.dataset) > 2 & sd(product.year.dataset$score) != 0 & sd(product.year.dataset$amount) != 0){
      correlation <- cor.test(
        product.year.dataset$score, product.year.dataset$amount, method = "spearman", exact = F
      )
      correlation.product.evolution <- rbind(
        correlation.product.evolution,
        data.frame(
          "product" = product, "year" = year, "p-value" = correlation$p.value, "rho" = correlation$estimate,
          "count" = nrow(product.year.dataset)
        )
      )
    }
  }
}
print(correlation.product.evolution)

# Pairwise Effect Evaluation

## Log-transforming the data to approximate normal distribution
dataset$amount <- log(dataset$amount)

## Metric: Amount
effect.comparison <- data.frame()

### Access Complexity
#### Low vs. Medium
population.a <- dataset$amount[dataset$access_complexity == "LOW"]
population.b <- dataset$amount[dataset$access_complexity == "MEDIUM"]
es <- mes(
  mean(population.a), mean(population.b),
  sd(population.a), sd(population.b),
  length(population.a), length(population.b),
  verbose = F
)
effect.comparison <- rbind(
  effect.comparison,
  data.frame(
    "effect" = eval.es(es$d), "d" = es$d, "u1" = 100 - get.u1(es$d) * 100, "p-value" = es$pval.d
  )
)

#### Medium vs. High
population.a <- dataset$amount[dataset$access_complexity == "MEDIUM"]
population.b <- dataset$amount[dataset$access_complexity == "HIGH"]
es <- mes(
  mean(population.a), mean(population.b),
  sd(population.a), sd(population.b),
  length(population.a), length(population.b),
  verbose = F
)
effect.comparison <- rbind(
  effect.comparison,
  data.frame(
    "effect" = eval.es(es$d), "d" = es$d, "u1" = 100 - get.u1(es$d) * 100, "p-value" = es$pval.d
  )
)

### Access Vector
#### Local vs. Network
population.a <- dataset$amount[dataset$access_vector == "LOCAL"]
population.b <- dataset$amount[dataset$access_vector == "NETWORK"]
es <- mes(
  mean(population.a), mean(population.b),
  sd(population.a), sd(population.b),
  length(population.a), length(population.b),
  verbose = F
)
effect.comparison <- rbind(
  effect.comparison,
  data.frame(
    "effect" = eval.es(es$d), "d" = es$d, "u1" = 100 - get.u1(es$d) * 100, "p-value" = es$pval.d
  )
)

### Authentication
#### None vs. Single Instance
population.a <- dataset$amount[dataset$authentication == "NONE"]
population.b <- dataset$amount[dataset$authentication == "SINGLE_INSTANCE"]
es <- mes(
  mean(population.a), mean(population.b),
  sd(population.a), sd(population.b),
  length(population.a), length(population.b),
  verbose = F
)
effect.comparison <- rbind(
  effect.comparison,
  data.frame(
    "effect" = eval.es(es$d), "d" = es$d, "u1" = 100 - get.u1(es$d) * 100, "p-value" = es$pval.d
  )
)

### Availability Impact
#### None vs. Partial
population.a <- dataset$amount[dataset$availability_impact == "NONE"]
population.b <- dataset$amount[dataset$availability_impact == "PARTIAL"]
es <- mes(
  mean(population.a), mean(population.b),
  sd(population.a), sd(population.b),
  length(population.a), length(population.b),
  verbose = F
)
effect.comparison <- rbind(
  effect.comparison,
  data.frame(
    "effect" = eval.es(es$d), "d" = es$d, "u1" = 100 - get.u1(es$d) * 100, "p-value" = es$pval.d
  )
)
#### Partial vs. Complete
population.a <- dataset$amount[dataset$availability_impact == "PARTIAL"]
population.b <- dataset$amount[dataset$availability_impact == "COMPLETE"]
es <- mes(
  mean(population.a), mean(population.b),
  sd(population.a), sd(population.b),
  length(population.a), length(population.b),
  verbose = F
)
effect.comparison <- rbind(
  effect.comparison,
  data.frame(
    "effect" = eval.es(es$d), "d" = es$d, "u1" = 100 - get.u1(es$d) * 100, "p-value" = es$pval.d
  )
)

## Confidentiality Impact
#### None vs. Partial
population.a <- dataset$amount[dataset$confidentiality_impact == "NONE"]
population.b <- dataset$amount[dataset$confidentiality_impact == "PARTIAL"]
es <- mes(
  mean(population.a), mean(population.b),
  sd(population.a), sd(population.b),
  length(population.a), length(population.b),
  verbose = F
)
effect.comparison <- rbind(
  effect.comparison,
  data.frame(
    "effect" = eval.es(es$d), "d" = es$d, "u1" = 100 - get.u1(es$d) * 100, "p-value" = es$pval.d
  )
)
#### Partial vs. Complete
population.a <- dataset$amount[dataset$confidentiality_impact == "PARTIAL"]
population.b <- dataset$amount[dataset$confidentiality_impact == "COMPLETE"]
es <- mes(
  mean(population.a), mean(population.b),
  sd(population.a), sd(population.b),
  length(population.a), length(population.b),
  verbose = F
)
effect.comparison <- rbind(
  effect.comparison,
  data.frame(
    "effect" = eval.es(es$d), "d" = es$d, "u1" = 100 - get.u1(es$d) * 100, "p-value" = es$pval.d
  )
)

### Integrity Impact
#### None vs. Partial
population.a <- dataset$amount[dataset$integrity_impact == "NONE"]
population.b <- dataset$amount[dataset$integrity_impact == "PARTIAL"]
es <- mes(
  mean(population.a), mean(population.b),
  sd(population.a), sd(population.b),
  length(population.a), length(population.b),
  verbose = F
)
effect.comparison <- rbind(
  effect.comparison,
  data.frame(
    "effect" = eval.es(es$d), "d" = es$d, "u1" = 100 - get.u1(es$d) * 100, "p-value" = es$pval.d
  )
)
#### Partial vs. Complete
population.a <- dataset$amount[dataset$integrity_impact == "PARTIAL"]
population.b <- dataset$amount[dataset$integrity_impact == "COMPLETE"]
es <- mes(
  mean(population.a), mean(population.b),
  sd(population.a), sd(population.b),
  length(population.a), length(population.b),
  verbose = F
)
effect.comparison <- rbind(
  effect.comparison,
  data.frame(
    "effect" = eval.es(es$d), "d" = es$d, "u1" = 100 - get.u1(es$d) * 100, "p-value" = es$pval.d
  )
)

### Comparison
rownames(effect.comparison) <- CRITERIA
colnames(effect.comparison) <- COLNAMES

### Output
print(effect.comparison)

# Inter Rater Reliability
irr.projects <- data.frame()
ratings <- read.csv("ratings.csv", header = T)
for(project in unique(ratings$project)){
  cat(project, "\n")
  ratings.project <- ratings[ratings$project == project, ]
  irr.project <- kappa2(ratings.project[,3:4])
  irr.projects <- rbind(
    irr.projects,
    data.frame(
      "project" = project, "kappa" = irr.project$value, "p-value" = irr.project$p.value)
  )
}
print(irr.projects)