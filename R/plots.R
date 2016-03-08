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
    cvss.exploitability_subscore, cvss.impact_subscore,
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

## Transform Categoricals into Factors
dataset <- transform.dataset(dataset)

## Outlier Detection Using k-means Clustering
outlier.indices <- get.outlier.indices(dataset$amount)
outlier.cutoff <- max(dataset$amount[-outlier.indices])

# Plots

## Theme
plot.theme <-
  theme_bw() +
  theme(
    plot.title = element_text(size = 14, face = "bold", margin = margin(5,0,15,0)),
    axis.text.x = element_text(size=10, colour = "black", angle = 50, vjust = 1, hjust = 1),
    axis.title.x = element_text(colour = "black", face = "bold", margin = margin(15,0,5,0)),
    axis.text.y = element_text(size=10, colour = "black"),
    axis.title.y = element_text(colour = "black", face = "bold", margin = margin(0,15,0,5)),
    strip.text.x = element_text(size=10, face="bold")
  )

blank.theme <- plot.theme +
  theme(
    panel.border = element_rect(colour = NA),
    panel.grid.minor = element_blank(),
    panel.grid.major = element_blank(),
    axis.text = element_blank(),
    axis.title = element_blank(),
    axis.ticks =  element_blank(),
    plot.margin = unit(c(0,0,0,0), "lines")
  )

## Boxplots by Product
product.labels <- table(dataset$product)
for(i in 1:length(product.labels)){
  product.labels[i] <- paste(names(product.labels)[i], " (", product.labels[i], ")", sep = "")
}

qplot(
  product, amount, data = dataset,
  main = "",
  xlab = "Product (Number of Vulnerabilities)", ylab = "Bounty", geom = "boxplot"
) +
  plot.theme +
  scale_y_log10(labels = scales::dollar) +
  scale_x_discrete(
    breaks = names(product.labels), labels = product.labels
  )

## Scatterplots

### Entire Dataset
data.source <- dataset
plot.source <- rbind(
  data.frame(
    "type" = "Base Score",
    "amount" = data.source$amount, "score" = data.source$score
  ),
  data.frame(
    "type" = "Exploitability Subscore",
    "amount" = data.source$amount, "score" = data.source$exploitability_subscore
  ),
  data.frame(
    "type" = "Impact Subscore",
    "amount" = data.source$amount, "score" = data.source$impact_subscore
  )
)
plot.labels <- data.frame(
  "type" = c("Base Score", "Exploitability Subscore", "Impact Subscore"),
  "x" = c(min(data.source$score), min(data.source$exploitability_subscore), min(data.source$impact_subscore)),
  "y" = c(max(data.source$amount), max(data.source$amount), max(data.source$amount)),
  "correlation" = c(
    get.spearmansrho(data.source, "amount", "score"),
    get.spearmansrho(data.source, "amount", "exploitability_subscore"),
    get.spearmansrho(data.source, "amount", "impact_subscore")
  )
)

ggplot(plot.source, aes(x = score, y = amount)) +
  geom_point() +
  geom_smooth(method = "lm", colour = "gray45", linetype = "dashed") +
  facet_grid(. ~ type, scales = "free", space = "free") + 
  scale_x_continuous(breaks = seq(0.0, 10.0, by = 0.5)) +
  scale_y_continuous(labels = scales::dollar) +
  geom_text(
    data = plot.labels, parse = T, inherit.aes = F,
    aes(x = x, y = y, label = paste("rho==", correlation, sep = ""), hjust = 0, vjust = 1)
  ) +
  labs(title = "", x = "Score", y = "Bounty") +
  plot.theme

### Dataset with Outliers Removed
data.source <- dataset[-outlier.indices,]
plot.source <- rbind(
  data.frame(
    "type" = "Base Score",
    "amount" = data.source$amount, "score" = data.source$score
  ),
  data.frame(
    "type" = "Exploitability Subscore",
    "amount" = data.source$amount, "score" = data.source$exploitability_subscore
  ),
  data.frame(
    "type" = "Impact Subscore",
    "amount" = data.source$amount, "score" = data.source$impact_subscore
  )
)
plot.labels <- data.frame(
  "type" = c("Base Score", "Exploitability Subscore", "Impact Subscore"),
  "x" = c(min(data.source$score), min(data.source$exploitability_subscore), min(data.source$impact_subscore)),
  "y" = c(max(data.source$amount), max(data.source$amount), max(data.source$amount)),
  "correlation" = c(
    get.spearmansrho(data.source, "amount", "score"),
    get.spearmansrho(data.source, "amount", "exploitability_subscore"),
    get.spearmansrho(data.source, "amount", "impact_subscore")
  )
)

ggplot(plot.source, aes(x = score, y = amount)) +
  geom_point() +
  geom_smooth(method = "lm", colour = "gray45", linetype = "dashed") +
  facet_grid(. ~ type, scales = "free", space = "free") +
  scale_x_continuous(breaks = seq(0.0, 10.0, by = 0.5)) +
  scale_y_continuous(labels = scales::dollar) +
  geom_text(
    data = plot.labels, parse = T, inherit.aes = F,
    aes(x = x, y = y, label = paste("rho==", correlation, sep = ""), hjust = 0, vjust = 1)
  ) +
  labs(title = "", x = "Score", y = "Bounty") +
  plot.theme

## Boxplots

### Boxplot of Bounty by CVSS Metric
data.source <- dataset
plot.source <- rbind(
  data.frame(
    "metric" = "access_complexity", "label" = "Access Complexity",
    "value" = data.source$access_complexity, "amount" = data.source$amount
  ),
  data.frame(
    "metric" = "access_vector", "label" = "Access Vector",
    "value" = data.source$access_vector, "amount" = data.source$amount
  ),
  data.frame(
    "metric" = "authentication", "label" = "Authentication",
    "value" = data.source$authentication, "amount" = data.source$amount
  ),
  data.frame(
    "metric" = "availability_impact", "label" = "Availability Impact",
    "value" = data.source$availability_impact, "amount" = data.source$amount
  ),
  data.frame(
    "metric" = "confidentiality_impact", "label" = "Confidentiality Impact",
    "value" = data.source$confidentiality_impact, "amount" = data.source$amount
  ),
  data.frame(
    "metric" = "integrity_impact", "label" = "Integrity Impact",
    "value" = data.source$integrity_impact, "amount" = data.source$amount
  )
)

ggplot(plot.source, aes(x = value, y = amount)) +
  geom_boxplot() +
  facet_wrap(~ label, scales = "free_x") +
  scale_x_discrete(breaks = waiver(), labels = METRIC.VALUE.LABELS) +
  scale_y_log10(labels = scales::dollar) +
  labs(title = "", x = "Metric Value", y = "Bounty (Log Scale)") +
  plot.theme

## Histograms
title = "Distribution of Bounty for Vulnerabilities with metric_value metric_label"
for(metric in names(METRIC.LABELS)){
  cat(METRIC.LABELS[[metric]],"\n")
  for(value in METRIC.VALUES[[metric]]){
    cat("  ", value, "\n")
    filtered.dataset <- dataset[dataset[[metric]] == value,]
    if(nrow(filtered.dataset) > 0){
      # Boxplot Statistics
      boxplot.statistics <- boxplot.stats(filtered.dataset$amount)$stats

      # Number of Outliers
      outliers.count <- length(which(filtered.dataset$amount > outlier.cutoff))

      # Remove Outliers (For Plotting Purposes Only)
      if(outliers.count > 0){
        filtered.dataset <- filtered.dataset[filtered.dataset$amount <= outlier.cutoff,]
      }

      # Boxplot

      ## Plot the Statistics
      plot.box <- ggplot(
        filtered.dataset, aes(
            x = factor(value), y = amount,
            ymin = boxplot.statistics[1], lower = boxplot.statistics[2],
            middle = boxplot.statistics[3],
            upper = boxplot.statistics[4], ymax = boxplot.statistics[5]
          )
        ) + geom_boxplot(stat = "identity")
      ## Plot the Outliers in the Filtered Dataset
      filtered.dataset.outliers <- filtered.dataset[filtered.dataset$amount > boxplot.statistics[5],]
      if(nrow(filtered.dataset.outliers) > 0){
        plot.box <- plot.box +
          geom_point(aes(y = amount), data = filtered.dataset.outliers)
      }
      ## Indicate Number of Remaining Outliers
      plot.box <- plot.box +
        scale_y_continuous(limits = c(0, max(filtered.dataset$amount) + 1000)) +
        geom_text(aes(
          y = max(filtered.dataset$amount) + 1000,
          label = paste("(", outliers.count, ")", sep = "")
        ))
      ## Add Titles
      plot.box <- plot.box +
        labs(
          list(title = str_replace(
            str_replace(
              title, "metric_value", METRIC.VALUE.LABELS[[value]]
            ), "metric_label", METRIC.LABELS[[metric]]
          ))
        )
      ## Flip Coordinates and Assign Theme
      plot.box <- plot.box + coord_flip() + blank.theme

      # Histogram
      plot.hist <- qplot(
        amount, data = filtered.dataset,
        xlab = "Bounty", ylab = "Frequency",
        geom = "histogram", bins = 50
      ) +
        plot.theme +
        theme(axis.text.x = element_text(angle = 50, vjust = 1, hjust = 1)) +
        scale_x_continuous(
          labels = scales::dollar, expand = c(0,0),
          limits = c(0, max(filtered.dataset$amount) + 1000)
        )

      # Layout Plots in a Table
      plot.box <- ggplot_gtable(ggplot_build(plot.box))
      plot.hist <- ggplot_gtable(ggplot_build(plot.hist))
      # Maximum Width
      max.width <- unit.pmax(plot.box$widths[2:3], plot.hist$widths[2:3])

      plot.box$widths[2:3] <- as.list(max.width)
      plot.hist$widths[2:3] <- as.list(max.width)

      gt <- gtable(widths = unit(c(5), "null"), height = unit(c(1, 5), "null"))
      gt <- gtable_add_grob(gt, plot.box, 1, 1)
      gt <- gtable_add_grob(gt, plot.hist, 2, 1)

      grid.newpage()
      grid.draw(gt)
    }
  }
}