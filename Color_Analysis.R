# Analysis of color for plotting

library(tidyverse)
library(gridExtra)


color_analysis <- function(.dt, .var, .my_breaks, .n_cluster, .x_lim) {
  # .dt: data 
  # .var: variable for evlauation as an expression
  # .my_breaks: a vector of all breaks 
  # .n_cluster: n of cluster for k-means
  
  f <- enquo(.var) # add quotation to variable expression
  
  # remove outlier (get rid of top and bottom 2.5%)
  vec <- .dt %>% select(!!f) %>% unlist() %>% quantile(c(0.025, 0.975))
  .dt <- .dt %>% filter(!!f > vec[1] & !!f < vec[2])
  
  # kmeans
  k_clus <- .dt %>% select(!!f) %>% kmeans(.n_cluster) 
  print("--- k-mean breaks: ---")
  print(k_clus$centers %>% round(2))
  
  # jenks
  jenk_break <- BAMMtools::getJenksBreaks(.dt %>% select(!!f) %>% unlist, .n_cluster)
  print("--- jenks breaks: ---") 
  print(jenk_break %>% round(2))
  
  # quantile breaks
  quan_break <- .dt %>% select(!!f) %>% unlist() %>% quantile(seq(0,1,0.2)) %>% unlist() 
  print("--- quntile breaks: ---")
  print(quan_break %>% round(2))
  
  # sd breaks
  my_mean <- .dt %>% summarise(mean = mean(!!f)) %>% pull()
  my_sd <- .dt %>% summarise(sd = sd(!!f)) %>% pull()
  mean_sd_break <- c(my_mean, my_mean + my_sd, my_mean - my_sd, 
                     my_mean + 2 * my_sd, my_mean - 2 * my_sd)
  print("--- sd breaks: ---")
  print(mean_sd_break %>% round(2))
  
  # K-means
  clus_plot <- ggplot(.dt, aes(x = !!f)) + 
    geom_histogram(bins = 60) + 
    geom_vline(xintercept = k_clus$centers, color = "blue", show.legend = TRUE) +
    ggtitle("k-means") +
    scale_x_continuous(limits = .x_lim)
  theme(axis.title.x = element_blank())
  
  # Quantiles
  quantile_plot <- ggplot(.dt, aes(x = !!f)) +
    geom_histogram(bins = 60) +
    geom_vline(xintercept = quan_break, color = "orange") +
    ggtitle("20%, 40%, 60%, 80% Quantiles") +
    scale_x_continuous(limits = .x_lim) +
    theme(axis.title.x=element_blank())
  
  # My defined Breaks
  pct_plot <- ggplot(.dt, aes(x = !!f)) + 
    geom_histogram(bins = 60) + 
    geom_vline(xintercept = .my_breaks, color = "green", show.legend = TRUE) +
    ggtitle("My Breaks") +
    scale_x_continuous(limits = .x_lim) +
    theme(axis.title.x=element_blank())
  
  
  # Results from Jenks
  jenks_plot <- ggplot(.dt, aes(x = !!f)) +
    geom_histogram(bins = 60) +
    geom_vline(xintercept = jenk_break, color = "black", show.legend = TRUE) +
    ggtitle("Jenks") +
    scale_x_continuous(limits = .x_lim) +
    theme(axis.title.x = element_blank())
  
  # +- 2 Standard Deviations
  stdev_plot <- ggplot(.dt, aes(x = !!f)) + 
    geom_histogram(bins = 60) + 
    geom_vline(xintercept = mean_sd_break, color = "red", show.legend = TRUE) +
    ggtitle("+- 2 standard deviations from the mean") +
    scale_x_continuous(limits = .x_lim) +
    theme(axis.title.x=element_blank())
  
  # Plot all on one page
  grid.arrange(clus_plot, quantile_plot, pct_plot,
               jenks_plot, stdev_plot, nrow = 5)
  
  
}


# example 1: 
data_1 <- tibble(seq = 1:1000,val = rnorm(1000, 0, 1))
hist(data_1$val)

color_analysis(data_1, 
               val, 
               c(-2,-1, 0, 1, 2), # proposed breaks 
               5, # number of breaks
               c(-4, 4) # limit of x for the plot
               )

# example 2: 
data_2 <- tibble(seq = 1:1000,val = rexp(1000, 2))
hist(data_2$val)

color_analysis(data_2, 
               val, 
               c(0, 0.5, 1, 1.5, 2), # proposed breaks 
               6, # number of breaks
               c(0, 4) # limit of x for the plot
)
