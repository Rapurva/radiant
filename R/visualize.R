#' Visualize data using ggplot2 \url{http://docs.ggplot2.org/current/}
#'
#' @details See \url{http://mostly-harmless.github.io/radiant/base/visualize.html} for an example in Radiant
#'
#' @param dataset Dataset name (string). This can be a dataframe in the global environment or an element in an r_data list from Radiant
#' @param viz_vars1 One or more variables to display along the X-axis of the plot
#' @param viz_vars2 Variable to display along the Y-axis of the plot (default = "none")
#' @param data_filter Expression used to filter the dataset. This should be a string (e.g., "price > 10000")
#' @param viz_type Type of plot to create. One of Histogram ('hist'), Density ('density'), Scatter ('scatter'), Line ('line'), Bar ('bar'), or Box-plot ('box')
#' @param viz_facet_row Create vertically arranged subplots for each level of the selected factor variable
#' @param viz_facet_col Create horizontally arranged subplots for each level of the selected factor variable
#' @param viz_color Adds color to a scatter plot to generate a heat map. For a line plot one line is created for each group and each is assigned a different colour
#' @param viz_bins Number of bins used for a histogram (not accessible in Radiant)
#' @param viz_smooth Adjust the flexibility of the loess line for scatter plots (not accessible in Radiant)
#' @param viz_check Add a regression line ("line"), a loess line ("loess"), or jitter ("jitter") to a scatter plot
#' @param viz_axes Flip the axes in a plot ("flip") or apply a log transformation (base e) to the y-axis ("log_y") or the x-axis ("log_x")
#'
#' @return Generated plots
#'
#' @examples
#' visualize("diamonds", "carat", "price", viz_type = "scatter", viz_check = "loess")
#'
#' @export
visualize <- function(dataset, viz_vars1, viz_vars2 = "none",
                      data_filter = "",
                      viz_type = "hist",
                      viz_facet_row = ".",
                      viz_facet_col = ".",
                      viz_color = "none",
                      viz_bins = 10,
                      viz_smooth = 1,
                      viz_check = "",
                      viz_axes = "") {

  # inspired by Joe Cheng's ggplot2 browser app http://www.youtube.com/watch?feature=player_embedded&v=o2B5yJeEl1A#!
  vars <- viz_vars1
  if(viz_vars2 != "none") vars %<>% c(., viz_vars2)
  if(viz_color != "none") vars %<>% c(., viz_color)
  if(viz_facet_row != ".") vars %<>% c(., viz_facet_row)
  if(viz_facet_col != ".") vars %<>% c(., viz_facet_col)

  dat <- getdata_exp(dataset, vars, filt = data_filter)

  plots <- list()

  if (viz_type == "hist") {
    for (i in viz_vars1) {
      plots[[i]] <- ggplot(dat, aes_string(x=i))
      if ("factor" %in% class(dat[,i])) {
        plots[[i]] <- plots[[i]] + geom_histogram()
      } else {
        bw <- select_(dat,i) %>% range %>% diff(.)/viz_bins
        plots[[i]] <- plots[[i]] + geom_histogram(binwidth = bw)
      }
    }
  } else if (viz_type == "density") {
    for (i in viz_vars1) {
      plots[[i]] <- ggplot(dat, aes_string(x=i)) +
                    geom_density(adjust=viz_smooth, fill = "green", alpha=.3)
                    # + labs(list(y = "", x = ""))
    }
  } else if (viz_type == "scatter") {
    itt <- 1
    for (i in viz_vars1) {
      for (j in viz_vars2) {
        plots[[itt]] <- ggplot(dat, aes_string(x=i, y=j)) + geom_point(alpha = .5)
        itt <- itt + 1
      }
    }
  } else if (viz_type == "line") {
    itt <- 1
    for (i in viz_vars1) {
      for (j in viz_vars2) {
        if (viz_color == 'none') {
          plots[[itt]] <- ggplot(dat, aes_string(x=i, y=j)) + geom_line()
          itt <- itt + 1
        } else {
          for (z in viz_color) {
            plots[[itt]] <- ggplot(dat, aes_string(x=i, y=j, color = z)) + geom_line()
            itt <- itt + 1
          }
        }
      }
    }
  } else if (viz_type == "bar") {
    itt <- 1
    for (i in viz_vars1) {
      for (j in viz_vars2) {
        plots[[itt]] <- ggplot(dat, aes_string(x=i, y=j)) + geom_bar(stat="identity")
        itt <- itt + 1
      }
    }
  } else if (viz_type == "box") {
    itt <- 1
    for (i in viz_vars1) {
      dat[,i] %<>% as.factor
      for (j in viz_vars2) {
        plots[[itt]] <- ggplot(dat, aes_string(x=i, y=j, fill=i)) + geom_boxplot(alpha = .7)
        itt <- itt + 1
      }
    }
  }

  facets <- paste(viz_facet_row, '~', viz_facet_col)
  if (facets != '. ~ .')
    for (i in 1:length(plots)) plots[[i]] <- plots[[i]] + facet_grid(facets)

  if (viz_color != 'none')
    for (i in 1:length(plots))
      plots[[i]] <- plots[[i]] + aes_string(color=viz_color) + scale_fill_brewer()

  if ("jitter" %in% viz_check)
    for (i in 1:length(plots)) plots[[i]] <- plots[[1]] + geom_jitter()

  if ("line" %in% viz_check)
    for (i in 1:length(plots))
      plots[[i]] <- plots[[i]] + geom_smooth(method = "lm", fill = 'blue', alpha = .1, size = .75, linetype = "dashed", colour = 'black')

  if ("loess" %in% viz_check)
    for (i in 1:length(plots))
      plots[[i]] <- plots[[i]] + geom_smooth(span = viz_smooth, size = .75, linetype = "dotdash", aes(group=1))

  if ("flip" %in% viz_axes)
    for (i in 1:length(plots)) plots[[i]] <- plots[[i]] + coord_flip()

  if ("log_y" %in% viz_axes)
    for (i in 1:length(plots))
      plots[[i]] <- plots[[i]] + scale_y_continuous(trans = "log")

  if ("log_x" %in% viz_axes)
    for (i in 1:length(plots))
      plots[[i]] <- plots[[i]] + scale_x_continuous(trans = "log")

  sshh(do.call(grid.arrange, c(plots, list(ncol = min(length(plots), 2)))))

}
