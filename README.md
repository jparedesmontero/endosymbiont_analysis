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
- Add box plot even with fewer obesrvations
```
library(tidyverse)

# Load data
data <- read.csv("your_table.csv", header = TRUE)

# Richness calculation
symbiont_cols <- c("Portiera", "Arsenophonus_2", "Hamiltonella", "Cardinium_2", "Hemipteriphilus", "Ricketssia", "Wolbachia")
data$richness <- rowSums(data[symbiont_cols] > 0)

# Factor levels
data$altitude <- factor(data$altitude, levels = c("Low", "Medium", "High"))
data$biotype <- factor(data$biotype, levels = c("Native", "Invasive"))

# Plot: Jitter + median & IQR bars
ggplot(data, aes(x = altitude, y = richness, color = altitude)) +
  geom_jitter(width = 0.2, size = 2, alpha = 0.8) +
  stat_summary(fun = median, fun.min = function(x) quantile(x, 0.25),
               fun.max = function(x) quantile(x, 0.75), geom = "crossbar",
               width = 0.5, color = "black", fatten = 0.8) +
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
- We are switching to barplot isntead because of number of observations
```
# Load libraries
library(tidyverse)

# Read the data
data <- read.csv("your_table.csv", header = TRUE)

# Calculate richness per sample
symbiont_cols <- c("Portiera", "Arsenophonus_2", "Hamiltonella", "Cardinium_2", "Hemipteriphilus", "Ricketssia", "Wolbachia")
data$richness <- rowSums(data[symbiont_cols] > 0)

# Clean up factor levels
data$altitude <- factor(data$altitude, levels = c("Low", "Medium", "High"))
data$biotype <- factor(data$biotype, levels = c("Native", "Invasive"))

# Calculate mean and SD per group
summary_df <- data %>%
  group_by(altitude, biotype) %>%
  summarise(
    mean_richness = mean(richness),
    sd_richness = sd(richness),
    n = n()
  ) %>%
  ungroup()

# Barplot with error bars (± SD), faceted by biotype
ggplot(summary_df, aes(x = altitude, y = mean_richness, fill = altitude)) +
  geom_col(width = 0.6, alpha = 0.8) +
  geom_errorbar(aes(ymin = mean_richness - sd_richness,
                    ymax = mean_richness + sd_richness),
                width = 0.2, linewidth = 0.8) +
  facet_wrap(~ biotype, labeller = as_labeller(c(Native = "Native", Invasive = "Invasive"))) +
  theme_bw(base_size = 14) +
  labs(
    title = "Average Symbiont Richness by Altitude",
    x = "Altitude Category",
    y = "Mean Richness (± SD)"
  ) +
  theme(
    legend.position = "none",
    strip.text = element_text(face = "bold")
  )
```
- Correlation between richness and masl
```

# Load libraries
library(tidyverse)

# Read data
data <- read.csv("endosym_ec.csv", header = TRUE)

# Calculate richness
symbiont_cols <- c("Portiera", "Arsenophonus_2", "Hamiltonella", "Cardinium_2", "Hemipteriphilus", "Ricketssia", "Wolbachia")
data$richness <- rowSums(data[symbiont_cols] > 0)

# Clean factor labels
data$biotype <- factor(data$biotype, levels = c("Native", "Invasive"))

# Scatter plot with linear regression, faceted by biotype
ggplot(data, aes(x = masl, y = richness, color = biotype)) +
  geom_point(size = 2, alpha = 0.8) +
  geom_smooth(method = "lm", se = TRUE, color = "black", linewidth = 0.8) +
  facet_wrap(~ biotype, labeller = as_labeller(c(Native = "Native", Invasive = "Invasive"))) +
  theme_bw(base_size = 14) +
  labs(
    title = "Symbiont Richness vs. Elevation (masl)",
    x = "Elevation (m above sea level)",
    y = "Symbiont Richness"
  ) +
  theme(
    legend.position = "none",
    strip.text = element_text(face = "bold")
  )
```
- Calculate p-value
```
summary(lm(richness ~ masl, data = data[data$biotype == "Native", ]))
```
---
- Calculate shannon diversity
```
# Load libraries
library(tidyverse)
library(vegan)  # for diversity() function

# Read data
data <- read.csv("endosym_ec.csv", header = TRUE)

# Select symbiont abundance columns and compute Shannon index
symbiont_cols <- c("Portiera", "Arsenophonus_2", "Hamiltonella", "Cardinium_2",
                   "Hemipteriphilus", "Ricketssia", "Wolbachia")

# Calculate Shannon index per row/sample
data$shannon <- diversity(data[symbiont_cols], index = "shannon")

# Set factors
data$altitude <- factor(data$altitude, levels = c("Low", "Medium", "High"))
data$biotype <- factor(data$biotype, levels = c("Native", "Invasive"))

# Summarize by environmental condition and biotype
summary_df <- data %>%
  group_by(altitude, biotype) %>%
  summarise(
    mean_shannon = mean(shannon),
    sd_shannon = sd(shannon),
    n = n()
  ) %>%
  ungroup()

# Plot
ggplot(summary_df, aes(x = altitude, y = mean_shannon, fill = altitude)) +
  geom_col(width = 0.6, alpha = 0.85) +
  geom_errorbar(aes(ymin = mean_shannon - sd_shannon,
                    ymax = mean_shannon + sd_shannon),
                width = 0.2, linewidth = 0.8) +
  facet_wrap(~ biotype, labeller = as_labeller(c(Native = "Native", Invasive = "Invasive"))) +
  theme_bw(base_size = 14) +
  labs(
    title = "Shannon Diversity Index by Altitude and Biotype",
    x = "Altitude Category",
    y = "Shannon Diversity Index"
  ) +
  theme(
    legend.position = "none",
    strip.text = element_text(face = "bold")
  )
```
