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
db.connection <- db.connect(
  user = "", password = "",
  host = "localhost", port = "5432",
  dbname = "bountyvscvss"
)
dataset <- db.get.data(db.connection, QUERY)
db.disconnect(db.connection)

# Scatterplots
plot(
  dataset$score, dataset$amount, 
  main = "Scatter of Bounty vs. CVSS Score",
  xlab = "CVSS Score", ylab = "Bounty (in USD)"
)
abline(lm(amount ~ score, data = dataset), col = "blue", lty = 2, lwd = 2)

# Boxplots
par(mfrow = c(2,3))
boxplot(
  amount ~ access_complexity, data = dataset,
  xlab = "Access Complexity", ylab = "Bounty (in USD)"
)
boxplot(
  amount ~ access_vector, data = dataset,
  xlab = "Access Vector", ylab = "Bounty (in USD)"
)
boxplot(
  amount ~ authentication, data = dataset,
  xlab = "Authentication", ylab = "Bounty (in USD)"
)
boxplot(
  amount ~ availability_impact, data = dataset,
  xlab = "Availability Impact", ylab = "Bounty (in USD)"
)
boxplot(
  amount ~ confidentiality_impact, data = dataset,
  xlab = "Confidentiality Impact", ylab = "Bounty (in USD)"
)
boxplot(
  amount ~ integrity_impact, data = dataset,
  xlab = "Integrity Impact", ylab = "Bounty (in USD)"
)