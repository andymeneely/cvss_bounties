  # Clear
rm(list = ls())
cat("\014")

# Source Library
source("library.R")

# Initialize Libraries
init.libraries()

# Database Connection
db.connection <- get.db.connection(environment="PRODUCTION")
dataset <- db.get.data(db.connection, QUERY)
db.disconnect(db.connection)

# Data Transformation
dataset <- transform.dataset(dataset)

# Plots

## Theme
use.color <- F
if(use.color){
  plot.trendline <- "gray45"
  # Green Palette
  plot.palette <- c(
    "#f2f7ee","#e5f0dd","#d8e8cc","#cbe1bc","#bed9ab","#b1d29a","#a4ca89",
    "#97c379","#8abb68","#7db457","#70ad47","#669e41","#5c8e3b","#527e34",
    "#486f2e","#3e5f27","#334f21","#293f1a","#1f3014","#15200d","#  0b1007"
  )
  values.palette <- c(
    "LOCAL" = "#d8e8cc", "ADJACENT_NETWORK" = "#97c379", "NETWORK" = "#5c8e3b",
    "SINGLE_INSTANCE" = "#97c379", "MULTIPLE_INSTANCES" = "#5c8e3b",
    "LOW" = "#d8e8cc", "MEDIUM" = "#97c379", "HIGH" = "#5c8e3b",
    "NONE" = "#d8e8cc", "PARTIAL" = "#97c379", "COMPLETE" = "#5c8e3b"
  )
  response.palette <- c("score" = "#f1a069", "amount" = "#97c379")
  hilo.palette <- c("0" = "#ffffff", "1" = "#000000")
} else {
  plot.trendline <- "#000000"
  plot.palette <- c(
    "#f9f9f9","#f3f3f3","#ededed","#e7e7e7","#e1e1e1","#dcdcdc","#d6d6d6",
    "#d0d0d0","#cacaca","#c4c4c4","#bfbfbf","#aeaeae","#9d9d9d","#8b8b8b",
    "#7a7a7a","#696969","#575757","#464646","#353535","#232323","#121212"
  )
  values.palette <- c(
    "LOCAL" = "#ededed", "ADJACENT_NETWORK" = "#d0d0d0", "NETWORK" = "#9d9d9d",
    "SINGLE_INSTANCE" = "#d0d0d0", "MULTIPLE_INSTANCES" = "#9d9d9d",
    "LOW" = "#ededed", "MEDIUM" = "#d0d0d0", "HIGH" = "#9d9d9d",
    "NONE" = "#ededed", "PARTIAL" = "#d0d0d0", "COMPLETE" = "#9d9d9d"
  )
  response.palette <- c("score" = "#e7e7e7", "amount" = "#bfbfbf")
  hilo.palette <- c("0" = "#ffffff", "1" = "#000000")
}

## Boxplots
# Export Resolution: 600 x 150
ggplot(dataset %>% mutate(metric = "bounty"), aes(x = metric, y = amount)) +
  geom_boxplot() +
  scale_y_log10(labels=scales::dollar) +
  labs(
    title = "Distribution of Vulnerability Bounty (Log Scale)",
    x = NULL, y = NULL
  ) +
  get.theme() +
  theme(axis.text.y = element_blank()) +
  coord_flip()

## Boxplots by Product
product.labels <- table(dataset$product)
for(i in 1:length(product.labels)){
  product.labels[i] <- paste(
    names(product.labels)[i], " (", product.labels[i], ")", sep = ""
  )
}

ggplot(dataset, aes(x = product, y = amount)) +
  geom_boxplot() +
  labs(
    x = "Product (Number of Vulnerabilities)",
    y = "Vulerability Bounty (Log Scale)"
  ) +
  scale_y_log10(labels = scales::dollar) +
  scale_x_discrete(breaks = names(product.labels), labels = product.labels) +
  get.theme()

## Scatterplots

### Base Score Only
plot.source <- dataset %>%
  select("amount" = amount, "score" = score) %>%
  mutate("type" = "Base Score")

correlation <- get.spearmansrho(dataset, "amount", "score")
plot.labels <- data.frame(
  "type" = c("Base Score"),
  "x" = c(min(dataset$score)), "y" = c(max(dataset$amount)),
  "correlation" = c(correlation$rho)
)

##### Simple Scatter Plot
ggplot(plot.source, aes(x = score, y = amount)) +
  geom_point() +
  geom_smooth(method = "lm", colour = plot.trendline, linetype = "dashed") +
  scale_x_continuous(breaks = seq(0.0, 10.0, by = 0.5)) +
  scale_y_continuous(labels = scales::dollar) +
  geom_text(
    data = plot.labels, parse = T, inherit.aes = F, hjust = 0, vjust = 1,
    aes(x = x, y = y, label = paste("rho==", correlation, sep = ""))
  ) +
  labs(x = "CVSS Base Score", y = "Bounty") +
  get.theme()

##### Hexagonal Scatter Plot
# Export Resolution: 600 x 350
ggplot(plot.source, aes(x = score, y = amount)) +
  geom_hex(bins = 30, colour = "black") +
  geom_smooth(method = "lm", colour = plot.trendline, linetype = "dashed") +
  geom_text(
    data = plot.labels, parse = T, inherit.aes = F, hjust = 0, vjust = 1,
    aes(x = x, y = y, label = paste("rho==", correlation, sep = ""))
  ) +
  scale_fill_gradientn(colors = plot.palette, name = "Density") +
  scale_x_continuous(breaks = seq(0.0, 10.0, by = 0.5)) +
  scale_y_continuous(labels = scales::dollar) +
  guides(fill = guide_colorbar(
    barwidth = 0.5, barheight = 3, ticks = F,
    title.theme = element_text(size = 10, angle = 0, face = "bold")
  )) +
  labs(x = "CVSS Base Score", y = "Vulnerability Bounty") +
  get.theme()

#### Subscores Only
plot.source <- bind_rows(
  dataset %>%
    select("amount" = amount, "score" = exploitability_subscore) %>%
    mutate("type" = "CVSS Exploitability Subscore"),
  dataset %>%
    select("amount" = amount, "score" = impact_subscore) %>%
    mutate("type" = "CVSS Impact Subscore")
)

plot.labels <- data.frame()
x <- c(
  min(dataset$exploitability_subscore, dataset$impact_subscore),
  min(dataset$exploitability_subscore, dataset$impact_subscore)
)
y <- c(max(dataset$amount), max(dataset$amount))
correlation <- get.spearmansrho(dataset, "amount", "exploitability_subscore")
if(correlation$significant){
  plot.labels <- rbind(
    plot.labels,
    data.frame(
      "type" = "CVSS Exploitability Subscore", "x" = x, "y" = y,
      "correlation" = correlation$rho
    )
  )
}
correlation <- get.spearmansrho(dataset, "amount", "impact_subscore")
if(correlation$significant){
  plot.labels <- rbind(
    plot.labels,
    data.frame(
      "type" = "CVSS Impact Subscore", "x" = x, "y" = y,
      "correlation" = correlation$rho
    )
  )
}

##### Simple Scatter Plot
ggplot(plot.source, aes(x = score, y = amount)) +
  geom_point() +
  geom_smooth(method = "lm", colour = "gray45", linetype = "dashed") +
  facet_grid(. ~ type, space = "free") +
  scale_x_continuous(breaks = seq(0.0, 10.0, by = 0.5)) +
  scale_y_continuous(labels = scales::dollar) +
  geom_text(
    data = plot.labels, parse = T, inherit.aes = F, hjust = 0, vjust = 1,
    aes(x = x, y = y, label = paste("rho==", correlation, sep = ""))
  ) +
  labs(x = "Score", y = "Vulnerability Bounty") +
  get.theme()

##### Hexagonal Scatter Plot
# Export Resolution: 1000 x 350
ggplot(plot.source, aes(x = score, y = amount)) +
  geom_smooth(method = "lm", colour = plot.trendline, linetype = "dashed") +
  geom_hex(bins = 30, colour = "black") +
  geom_text(
    data = plot.labels, parse = T, inherit.aes = F, hjust = 0, vjust = 1,
    aes(x = x, y = y, label = paste("rho==", correlation, sep = ""))
  ) +
  scale_fill_gradientn(colours = plot.palette, name = "Density") +
  scale_x_continuous(breaks = seq(0.0, 10.0, by = 0.5)) +
  scale_y_continuous(labels = scales::dollar) +
  guides(fill = guide_colorbar(
    barwidth = 0.5, barheight = 3, ticks = F,
    title.theme = element_text(size = 10, angle = 0, face = "bold")
  )) +
  facet_grid(. ~ type, scales = "free", space = "free") +
  labs(x = "Subscore", y = "Vulnerability Bounty") +
  get.theme()

## Boxplots

### Boxplot of Bounty by CVSS Metric
plot.source <- rbind(
  data.frame(
    "metric" = "access_complexity", "label" = "Access Complexity",
    "value" = dataset$access_complexity, "amount" = dataset$amount
  ),
  data.frame(
    "metric" = "access_vector", "label" = "Access Vector",
    "value" = dataset$access_vector, "amount" = dataset$amount
  ),
  data.frame(
    "metric" = "authentication", "label" = "Authentication",
    "value" = dataset$authentication, "amount" = dataset$amount
  ),
  data.frame(
    "metric" = "availability_impact", "label" = "Availability Impact",
    "value" = dataset$availability_impact, "amount" = dataset$amount
  ),
  data.frame(
    "metric" = "confidentiality_impact", "label" = "Confidentiality Impact",
    "value" = dataset$confidentiality_impact, "amount" = dataset$amount
  ),
  data.frame(
    "metric" = "integrity_impact", "label" = "Integrity Impact",
    "value" = dataset$integrity_impact, "amount" = dataset$amount
  )
)

#### Single Row
# Export Resolution: 1200 x 350
ggplot(plot.source, aes(x = value, y = amount, fill = value)) +
  geom_boxplot() +
  facet_wrap(~ label, scales = "free_x", nrow = 1) +
  scale_x_discrete(breaks = waiver(), labels = METRIC.VALUE.LABELS) +
  scale_y_log10(labels = scales::dollar) +
  scale_fill_manual(values = values.palette) +
  labs(x = "Metric Value", y = "Vulnerability Bounty (Log Scale)") +
  get.theme() +
  theme(legend.position = "none")

#### Double Row
# Export Resolution:
ggplot(plot.source, aes(x = value, y = amount, fill = value)) +
  geom_boxplot() +
  facet_wrap(~ label, scales = "free_x", nrow = 2) +
  scale_x_discrete(breaks = waiver(), labels = METRIC.VALUE.LABELS) +
  scale_y_log10(labels = scales::dollar) +
  scale_fill_manual(values = values.palette) +
  labs(x = "Metric Value", y = "Vulnerability Bounty (Log Scale)") +
  get.theme() +
  theme(legend.position = "none")

## Associating Qualitative Codes to Products
associations <- read.csv(
  "codeassociation.csv", header = T, stringsAsFactors = F
) %>% filter(., code != 'The Internet')

# products <- sort(unique(associations$product))
products <- (associations %>%
               group_by(., product) %>%
               summarize(., count = n()) %>%
               arrange(-count) %>%
               select(product))$product
# codes <- sort(unique(associations$code))
codes <- (associations %>%
            group_by(., code) %>%
            summarize(., count = n()) %>%
            arrange(-count) %>%
            select(code))$code
association.matrix <- matrix(
  data = 0, nrow = length(codes), ncol = length(products)
)
rownames(association.matrix) <- codes
colnames(association.matrix) <- products

for(p in products){
  cat(p, "\n")
  codes.subset <- associations %>% filter(., product == p)
  for(c in codes){
    if(c %in% codes.subset$code){
      association.matrix[c, p] <- 1
    }
  }
}

groups <- read.csv("groups.csv", header = TRUE)
groups$code <- factor(groups$code, levels = codes)

plot.source <- melt(association.matrix) %>%
  select(code = Var1, product = Var2, value)

plot.source$code <- factor(plot.source$code, levels = codes)
plot.source$product <- factor(plot.source$product, levels = products)
plot.source$value <- factor(plot.source$value, levels = c(0,1))
plot.source <- inner_join(plot.source, groups, by = "code")
plot.source$group <- factor(
  plot.source$group, levels = c("generic", "technology", "product", "quality")
)

# Export Resolution: 1000 x 600
ggplot(data = plot.source, aes(x = code, y = product, fill = value)) +
  geom_tile(color = "#e7e7e7", size = 1) +
  scale_fill_manual(values = hilo.palette) +
  # scale_x_discrete(label = format.label) +
  coord_fixed() +
  facet_grid(
    . ~ group, scales = "free_x", space = "free",
    labeller = as_labeller(QCODE.GROUP.LABELS)
  ) +
  labs(x = "Vulnerability Bounty Determination Criterion", y = "Product") +
  get.theme() +
  theme(legend.position = "none")
