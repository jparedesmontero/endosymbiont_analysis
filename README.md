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


- Trying a violin plot now
```
# Load required libraries
library(tidyverse)

# Read your data
data <- read.csv("your_table.csv", header = TRUE)

# Calculate richness: number of non-zero symbionts per sample
symbiont_cols <- c("Portiera", "Arsenophonus_2", "Hamiltonella", "Cardinium_2", "Hemipteriphilus", "Ricketssia", "Wolbachia")
data$richness <- rowSums(data[symbiont_cols] > 0)

# Set factors for clean facet and x-axis ordering
data$altitude <- factor(data$altitude, levels = c("Low", "Medium", "High"))
data$biotype <- factor(data$biotype, levels = c("Native", "Invasive"))

# Plot: Violin with boxplot, faceted by biotype
ggplot(data, aes(x = altitude, y = richness, fill = altitude)) +
  geom_violin(trim = FALSE, alpha = 0.6, color = NA) +
  geom_boxplot(width = 0.1, outlier.shape = NA, alpha = 0.9) +
  facet_wrap(~ biotype, labeller = label_both) +
  theme_minimal(base_size = 14) +
  labs(
    title = "Symbiont Richness by Altitude and Biotype",
    x = "Altitude Category",
    y = "Richness (Non-zero symbionts)"
  ) +
  theme(
    legend.position = "none",
    strip.text = element_text(face = "bold")
  )
```
