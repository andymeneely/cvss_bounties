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

# Plots

## Theme
plot.theme <-
  theme_bw() +
  theme(
    plot.title = element_text(size = 14, face = "bold", margin = margin(5,0,15,0)),
    axis.text.x = element_text(size=10, colour = "black", vjust = 0.5),
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

## Scatterplots
qplot(
  dataset$score, dataset$amount,
  main = "Scatter of Bounty vs. CVSS Score",
  xlab = "CVSS Score", ylab = "Bounty",
  geom = "point"
) +
geom_smooth(method = "lm", se = FALSE) +
scale_y_continuous(labels = scales::dollar) + plot.theme

## Boxplots
ac.plot <- qplot(
  access_complexity, amount, data = dataset,
  xlab = "Access Complexity", ylab = "Bounty", geom = "boxplot"
) + scale_y_log10(labels = scales::dollar) + plot.theme

av.plot <- qplot(
  access_vector, amount,  data = dataset,
  xlab = "Access Vector", ylab = "Bounty", geom = "boxplot"
) + scale_y_log10(labels = scales::dollar) + plot.theme

au.plot <- qplot(
  authentication, amount, data = dataset,
  xlab = "Authentication", ylab = "Bounty", geom = "boxplot"
) + scale_y_log10(labels = scales::dollar) + plot.theme

ai.plot <- qplot(
  availability_impact, amount, data = dataset,
  xlab = "Availability Impact", ylab = "Bounty", geom = "boxplot"
) + scale_y_log10(labels = scales::dollar) + plot.theme

ci.plot <- qplot(
  confidentiality_impact, amount, data = dataset,
  xlab = "Confidentiality Impact", ylab = "Bounty", geom = "boxplot"
) + scale_y_log10(labels = scales::dollar) + plot.theme

ii.plot <- qplot(
  integrity_impact, amount, data = dataset,
  xlab = "Integrity Impact", ylab = "Bounty", geom = "boxplot"
) + scale_y_log10(labels = scales::dollar) + plot.theme

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
      # Boxplot
      ac.low.box <- qplot(
        factor(value), amount, data = filtered.dataset,
        main = str_replace(
          str_replace(
            title, "metric_value", METRIC.VALUE.LABELS[[value]]
          ), "metric_label", METRIC.LABELS[[metric]]
        ),
        geom = "boxplot"
      ) + coord_flip() + blank.theme
      # Histogram
      ac.low.hist <- qplot(
        amount, data = filtered.dataset,
        xlab = "Bounty", ylab = "Frequency",
        geom = "histogram", bins = 100
      ) +
        plot.theme +
        theme(axis.text.x = element_text(angle = 50)) +
        scale_x_continuous(labels = scales::dollar)

      # Layout Plots in a Table
      gt.ac.low.box <- ggplot_gtable(ggplot_build(ac.low.box))
      gt.ac.low.hist <- ggplot_gtable(ggplot_build(ac.low.hist))
      # Maximum Width
      max.width <- unit.pmax(gt.ac.low.box.horizontal$widths[2:3], gt.ac.low.hist$widths[2:3])

      gt.ac.low.box$widths[2:3] <- as.list(max.width)
      gt.ac.low.hist$widths[2:3] <- as.list(max.width)

      gt <- gtable(widths = unit(c(7), "null"), height = unit(c(1, 7), "null"))
      gt <- gtable_add_grob(gt, gt.ac.low.box, 1, 1)
      gt <- gtable_add_grob(gt, gt.ac.low.hist, 2, 1)

      grid.newpage()
      grid.draw(gt)
    }
  }
}