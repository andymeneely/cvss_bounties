# CVSS vs. Bounties Analysis

A collection of R scripts written for the CVSS vs. Bounties project.

# Dependencies

The R scripts depend on the libraries listed below.

1. `DBI` and the related `RPostgreSQL`. `RSQLite` is needed if a SQLite 
database is used instead of a PostgreSQL database.
1. `ggplot2` for plotting.
1. `effsize` for Cohen's d Effect Size measurement.
1. `rpart` for Recursive Partitioning and Regression Trees analysis.
1. `Rmisc` for the `multiplot` function.
1. `stringr` for `str_replace` function.

# Usage

The utility functions used by the scripts are contained in the file `library.R`
. In order to execute the scripts, use the `setwd` method of R to set the 
current working directory appropriately.

The `get.db.connection` utility function requires the connection string to be 
properly configured before executing the scripts.