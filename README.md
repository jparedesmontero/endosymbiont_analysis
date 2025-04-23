# Whitefly Endosymbiont Analysis
- Create a csv file
- Upload file to the repository
- Run R script into RStudio
```
# Load required libraries
library(tidyverse)

# Read the CSV file
data <- read.csv("your_table.csv", header = TRUE)

# Calculate richness (number of symbionts present per sample)
symbiont_cols <- c("Portiera", "Arsenophonus_2", "Hamiltonella", "Cardinium_2", "Hemipteriphilus", "Ricketssia", "Wolbachia")
data$richness <- rowSums(data[symbiont_cols] > 0)

# Convert relevant columns to factors for plotting
data$altitude <- factor(data$altitude, levels = c("Low", "Medium", "High"))
data$biotype <- factor(data$biotype, levels = c("Native", "Invasive"))

# Plot richness boxplot by altitude, faceted by biotype
ggplot(data, aes(x = altitude, y = richness, fill = altitude)) +
  geom_boxplot(outlier.shape = NA, alpha = 0.7) +
  geom_jitter(width = 0.2, size = 2, alpha = 0.9, aes(color = altitude)) +
  facet_wrap(~ biotype) +
  theme_minimal(base_size = 14) +
  labs(
    title = "Symbiont Richness by Altitude and Biotype",
    x = "Altitude",
    y = "Symbiont Richness"
  ) +
  theme(legend.position = "none")
```
