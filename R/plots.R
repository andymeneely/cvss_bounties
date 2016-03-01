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
    axis.title.y = element_text(colour =" black", face = "bold", margin = margin(0,15,0,5))
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
  main = "Distribution of Bounty by Product",
  xlab = "Product (Number of Bounties)", ylab = "Bounty", geom = "boxplot"
) +
  plot.theme +
  scale_y_log10(labels = scales::dollar) +
  scale_x_discrete(
    breaks = names(product.labels), labels = product.labels
  )

## Scatterplots
correlation.coefficient <- round(cor.test(dataset$score, dataset$amount, method="spearman", exact=F)$estimate, 4)
correlation.label <- paste("rho==", correlation.coefficient, sep = "")

qplot(
  dataset$score, dataset$amount,
  xlab = "CVSS Score", ylab = "Bounty",
  geom = "point"
) +
  geom_smooth(method = "lm", colour = "gray45", linetype = "dashed") +
  scale_x_continuous(breaks = seq(min(dataset$score), max(dataset$score), by = 0.5)) +
  scale_y_continuous(labels = scales::dollar) +
  annotate(
    "text",  parse = T,
    x = min(dataset$score), y = max(dataset$amount),
    label = correlation.label, hjust = 0, vjust = 1, size = 4.5
  ) +
  plot.theme

## Boxplots
ac.plot <- qplot(
  access_complexity, amount, data = dataset,
  xlab = "Access Complexity", ylab = "Bounty", geom = "boxplot"
) +
  scale_y_log10(labels = scales::dollar) +
  scale_x_discrete(breaks = METRIC.VALUES$access_complexity, labels = METRIC.VALUE.LABELS) +
  plot.theme

av.plot <- qplot(
  access_vector, amount,  data = dataset,
  xlab = "Access Vector", ylab = "Bounty", geom = "boxplot"
) +
  scale_y_log10(labels = scales::dollar) +
  scale_x_discrete(breaks = METRIC.VALUES$access_vector, labels = METRIC.VALUE.LABELS) +
  plot.theme

au.plot <- qplot(
  authentication, amount, data = dataset,
  xlab = "Authentication", ylab = "Bounty", geom = "boxplot"
) +
  scale_y_log10(labels = scales::dollar) +
  scale_x_discrete(breaks = METRIC.VALUES$authentication, labels = METRIC.VALUE.LABELS) +
  plot.theme

ai.plot <- qplot(
  availability_impact, amount, data = dataset,
  xlab = "Availability Impact", ylab = "Bounty", geom = "boxplot"
) +
  scale_y_log10(labels = scales::dollar) +
  scale_x_discrete(breaks = METRIC.VALUES$availability_impact, labels = METRIC.VALUE.LABELS) +
  plot.theme

ci.plot <- qplot(
  confidentiality_impact, amount, data = dataset,
  xlab = "Confidentiality Impact", ylab = "Bounty", geom = "boxplot"
) +
  scale_y_log10(labels = scales::dollar) +
  scale_x_discrete(breaks = METRIC.VALUES$confidentiality_impact, labels = METRIC.VALUE.LABELS) +
  plot.theme

ii.plot <- qplot(
  integrity_impact, amount, data = dataset,
  xlab = "Integrity Impact", ylab = "Bounty", geom = "boxplot"
) +
  scale_y_log10(labels = scales::dollar) +
  scale_x_discrete(breaks = METRIC.VALUES$integrity_impact, labels = METRIC.VALUE.LABELS) +
  plot.theme

multiplot(
  ac.plot, av.plot, au.plot, ai.plot, ci.plot, ii.plot,
  layout = matrix(1:6, nrow = 2, byrow = T)
)

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