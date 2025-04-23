# Whitefly Endosymbiont Analysis
- Create a csv file
- Upload file to the repository
- Run R script into RStudio
```
# Load required libraries
library(tidyverse)

# Read your CSV
data <- read.csv("your_table.csv", header = TRUE)

# Calculate richness (number of non-zero symbionts per sample)
symbiont_cols <- c("Portiera", "Arsenophonus_2", "Hamiltonella", "Cardinium_2", "Hemipteriphilus", "Ricketssia", "Wolbachia")
data$richness <- rowSums(data[symbiont_cols] > 0)

# Set factors for plotting
data$altitude <- factor(data$altitude, levels = c("Low", "Medium", "High"))
data$biotype <- factor(data$biotype, levels = c("Native", "Invasive"))

# Create the boxplot with theme_bw()
ggplot(data, aes(x = altitude, y = richness, fill = altitude)) +
  geom_boxplot(alpha = 0.8, outlier.shape = NA) +
  geom_jitter(aes(color = altitude), width = 0.2, size = 2, alpha = 0.9) +
  facet_wrap(~ biotype, labeller = label_both) +
  theme_bw(base_size = 14) +
  labs(
    title = "Symbiont Richness by Altitude and Biotype",
    x = "Altitude Category",
    y = "Richness (Non-zero Symbionts)"
  ) +
  theme(
    legend.position = "none",
    strip.text = element_text(face = "bold")
  )
```
