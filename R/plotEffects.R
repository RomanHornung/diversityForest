# -------------------------------------------------------------------------------
#   This file is part of 'diversityForest'.
#
# 'diversityForest' is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# 'diversityForest' is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with 'diversityForest'. If not, see <http://www.gnu.org/licenses/>.
#
#  NOTE: 'diversityForest' is a fork of the popular R package 'ranger', written by Marvin N. Wright.
#  Most R and C++ code is identical with that of 'ranger'. The package 'diversityForest'
#  was written by taking the original 'ranger' code and making any
#  changes necessary to implement diversity forests.
#
# -------------------------------------------------------------------------------

##' This function allows to visualise the (estimated) bivariable influences of pairs of variables (with large quantitative and qualitative
##' EIM values) on the outcome. This step is crucial, because to interpret interaction effects
##' between variable pairs with large quantitative and qualitative EIM values, it is necessary to learn about the forms
##' these interaction effects take.
##'
##' For each considered pair the bivariable influence of both pair members on the outcome estimated 
##' using a two-dimensional flexible function is shown. Such visualisations make it possible to learn
##' about the forms of the interaction effects between variable pairs with large EIM values. Moreover,
##' these visualisations reveal (pathological) cases in which variable pairs do not show
##' indications of interaction effects despite featuring large EIM values.\cr
##' For binary outcomes the probabilities for the second class are estimated, for categorical outcomes with more than two classes
##' the probabilities for the largest class (i.e., the class with the most observations) are estimated (using the function \code{\link{plotPair}}, a different
##' class can be selected instead), for metric outcomes the means of the outcome are estimated, and for survival outcomes
##' the log hazards ratio values compared to the median effect are estimated.\cr
##' The kinds of estimates shown differ also according to whether both pair members are metric or only one of the two
##' members is metric and the other one categorical or both pair members are categorical:
##' \itemize{
##' \item If both pair members are metric and the outcome is categorical or metric we use two-dimensional LOESS regression, where 
##' in the case of categorical outcomes, to obtain probability estimates for
##' the first class (or largest class for multi-class outcomes), we use the value
##' '1' for the first class (largest class for multi-class outcomes) and the value '0' for the second class
##' (all other classes for multi-class outcomes).
##' \item If both pair members are metric and the outcome is
##' survival we use a Cox proportional hazard additive model with a two-dimensional LOESS smooth (\code{gamcox} function
##' from the 'MapGAM' package (version 1.2-5)) and in the rare cases for which the latter fails, we use classical Cox regression
##' with an interaction term between the two covariates.
##' \item If one pair member is metric and the other one
##' categorical and the outcome is categorical or metric, we use LOESS regression between
##' the outcome (coded as '0' and '1' in the case of categorical outcomes as described above)
##' and the values of the metric variable separately for each category of the categorical
##' variable. In the rare cases in which the LOESS regression fails we use classical linear regression.
##' \item If one pair member is metric and the other one categorical and the outcome is survival,
##' we use Cox regression with a linear tail-restricted cubic spline with four knots (univariable
##' LOESS regression for survival outcomes does not seem to be available yet in R) separately for each
##' category of the categorical variable. In cases in which
##' the fitting of this spline regression fails we use classical Cox regression.
##' \item If both pair members are categorical and the outcome is categorical or metric,
##' we simply calculate the mean of the outcome (coded as '0' and '1' in the case of categorical outcomes
##' as described above) for each possible combination of the categories of the two variables.
##' \item If both pair members are categorical and the outcome is survival, we use classical 
##' Cox regression with an interaction term between the two variables (there is no need for
##' any flexible modelling in this setting, because the Cox model with two categorical variables
##' plus interaction term is saturated).
##' }
##' As described above (function argument: \code{pvalues}), there is an option to add p-values from tests for interaction effect
##' to the plots. If at least one of the variables in the considered variable pair is categorical and features more
##' than two categories, there are more than one interaction terms in the regression approaches used for testing,
##' because the categorical variables are dummy-coded. Therefore, in these cases we obtain a p-value for each interaction term.
##' to obtain a single p-value for the test for interaction we adjust these multiple p-values using the Holm-Bonferroni
##' procedure and take the minimum of the adjusted p-values.
##' 
##' \strong{NOTE}: These p-values are generally much too optimistic, in particular for small data sets and 
##' large numbers of variables. The reason for this overoptimism is that these p-values are not adjusted 
##' for the fact that we already used the data to find the variable pairs with strongest indications of 
##' interaction effects. This is similar to a multiple testing problem.
##' Therefore, these p-values should only be seen as a rough guide to be interpreted very cautiously
##' and \strong{MUST NOT} be reported as the results of a statistical test for significance
##' of interaction. To obtain adjusted p-values that would correspond to
##' valid tests, it would be possible to multiply these p-values by the number of possible pairs, 
##' which would correspond to Bonferroni-adjusted p-values. For example, assume that we have 30 
##' covariate variables. In that case the number of possible pairs would be 'choose(30, 2) = 435', 
##' which is why we would need to multiply each p-value by 435
##' to obtain an adjusted p-value (or keep the original p-values and divide the significance 
##' level 0.05 by 435). Note, however, that Bonferroni-adjusted p-values deliver quite conservative results,
##' that is, weaker effects might not be detected using these p-values, while, however, effects for
##' which these p-values are small (\eqn{< 0.05}) are most likely relevant.
##' Note further that these Bonferroni-adjusted p-values should be interpreted
##' with caution because, stemming from bivariable models, these p-values do not take the 
##' multivariable nature of the data into account.
##' 
##' @title Interaction forest plots: exploring interaction forest results through visualisation
##' @param intobj Object of class \code{interactionfor}. 
##' @param type This can be either "quant" or "qual" and determines whether the plotted pairs
##'  are sorted according to either the quantitative or qualitative EIM values in decreasing order. Default is "quant".
##' @param numpairs The number of pairs to plot (default: 5). This is overwritten by \code{indpairs}.
##' @param indpairs Optional. The indices of the pairs in the sorted lists of quantitative (\code{type="quant"}) or qualitative EIM values to plot (\code{type="qual"}). This overwrites the \code{numpairs} argument.
##' @param pairs This can be used to specify the pairs to plot. It is an optional list of character string vectors, where each of these vectors has length two. Each list element corresponds to one
##' pair, where the first character string gives the name of the first member of the respective pair to plot and the second character string gives the name of the second member.
##' This argument overwrites \code{numpairs} and \code{indpairs}.
##' @param allwith This is an optional character string that can be set to the name of one of the variables. If provided, only variable pairs will
##' be considered that feature the variable specified by this argument \code{allwith}. These pairs are again sorted in decreasing order
##' according to the quantitative (\code{type="quant"}) or qualitative (\code{type="qual"}) EIM values and their number is restricted to the value given by \code{numpairs}.
##' This argument \code{allwith} can be used, if it is of interest to learn whether a specific variable (e.g., sex or age) interacts
##' with other variables in the data set and if so, which forms these interactions take.
##' @param pvalues Set to \code{TRUE} (default) to add to the plots p-values from tests for interaction effect obtained using classical
##' parametric regression approaches. For categorical outcomes logistic regression is used, for metric outcomes linear
##' regression and for survival outcomes Cox regression. NOTE: These p-values are generally much too optimistic and \strong{MUST NOT} be reported 
##' as the result of a statistical test for significance of interaction. See the 'Details' section below for further details.
##' @param twoplots Set to \code{TRUE} / \code{FALSE} if for each plot page the results of two / one pair(s) of variables should be shown. Default is \code{TRUE}.
##' @param addtitles Set to \code{TRUE} (default) to add headings providing the names of the variables in each pair. If \code{type="quant"}, these
##' headings also give information on the type of quantitative interaction effect. Setting \code{addtitles} to \code{FALSE} is, for example, useful,
##' when the produced plots are intended for use in a publication, where these headings might not be desirable.
##' @param plotit This states whether the plots are actually plotted or merely returned as \code{ggplot} objects. Default is \code{TRUE}.
##' @return A list of ggplot2 plots returned invisibly.
##' @examples
##' \dontrun{
##'
##' ## Load package:
##' 
##' library("diversityForest")
##' 
##' 
##' 
##' ## Set seed to make results reproducible:
##' 
##' set.seed(1234)
##' 
##' 
##'
##' ## Construct interaction forest and calculate EIM values:
##' 
##' data(stock)
##' model <- interactionfor(dependent.variable.name = "company10", data = stock, 
##'                         num.trees = 20)
##' 
##' # NOTE: num.trees = 20 (in the above) would be much too small for practical 
##' # purposes. This small number of trees was simply used to keep the
##' # runtime of the example short.
##' # The default number of trees is num.trees = 20000 if EIM values are calculated
##' # and num.trees = 2000 otherwise.
##'
##'
##'
##' ## Obtain a first overview by applying the plot() function for
##' ## interactionfor obects:
##'
##' plot(model)
##' 
##' 
##' 
##' ## Several possible application cases of the plotEffects() function:
##' 
##' # Visualise the estimated bivariable influences of the five variable pairs with the 
##' # largest quantitative EIM values:
##'
##' plotEffects(model) # type="quant" is default.
##' 
##' 
##' # Visualise the estimated bivariable influences of the five pairs with the 
##' # largest qualitative EIM values:
##' 
##' plotEffects(model, type="qual")
##' 
##' 
##' # Visualise the estimated bivariable influences of all (eight) pairs that involve
##' # the variable "company7" sorted in decreasing order according to the
##' # qualitative EIM values:
##' 
##' plotEffects(model, allwith="company7", type="qual", numpairs=8)
##' 
##' 
##' # Visualise the estimated bivariable influences of the pairs with third and fifth
##' # largest qualitative EIM values:
##' 
##' plotEffects(model, type="qual", indpairs=c(3,5))
##' 
##' 
##' # Visualise the estimated bivariable influences of the pairs ("company3", "company5") and
##' # ("company1", "company9"):
##' 
##' plotEffects(model, pairs=list(c("company3", "company5"), c("company1", "company9")))
##' 
##' 
##' 
##' ## Saving of plots generated with the plotEffects() function (e.g., for use in publications):
##' 
##' # Apply plotEffects() to obtain plots for the five variable pairs
##' # with the largest qualitative EIM values and store these plots in
##' # an object 'ps':
##' 
##' ps <- plotEffects(model, type="qual", pvalues=FALSE, twoplots=FALSE, addtitles=FALSE, plotit=FALSE)
##' 
##' # pvalues = FALSE states that no p-values should be shown in the plots,
##' # because these might not be desired in plots meant for publication.
##' # twoplots = FALSE ensures that we get one plot for each page instead of two plots per page.
##' # addtitles = FALSE removes the automatically generated titles, because these are likely
##' # not desired in publications.
##' # plotit = FALSE ensures that the plots are not displayed, but only returned (invisibly) 
##' # by plotEffects().
##' 
##' 
##' # Save the plot with second largest qualitative EIM value:
##' 
##' p1 <- ps[[2]]
##' 
##' # Add title:
##' library("ggpubr")
##' p1 <- annotate_figure(p1, top = text_grob("My descriptive plot title 1", face = "bold", size = 14))
##' p1
##' 
##' # Save as PDF:
##' # library("ggplot2")
##' # ggsave(file="mypathtofolder/FigureXY1.pdf", width=14, height=6)
##' 
##' 
##' # Save the plot with fifth largest qualitative EIM value:
##' 
##' p2 <- ps[[5]]
##' 
##' # Add title:
##' p2 <- annotate_figure(p2, top = text_grob("My descriptive plot title 2", face = "bold", size = 14))
##' p2
##' 
##' # Save as PDF:
##' # ggsave(file="mypathtofolder/FigureXY1.pdf", width=14, height=6)
##' 
##' 
##' # Combine both of the above plots:
##' p <- ggarrange(p1, p2, nrow = 2)
##' p
##' 
##' # Save the combined plot:
##' # ggsave(file="mypathtofolder/FigureXYcombined.pdf", width=14, height=11)
##' 
##' # NOTE: Using plotEffects() it is not possible to change the plots 
##' # themselves (by e.g., increasing the label sizes or changing the 
##' # axes ranges). However, the function plotPair() can be used to change 
##' # the plots themselves.
##' 
##' }
##'
##' @author Roman Hornung
##' @references
##' \itemize{
##'   \item Hornung, R., Boulesteix, A.-L. (2022). Interaction forests: Identifying and exploiting interpretable quantitative and qualitative interaction effects. Computational Statistics & Data Analysis 171:107460, <\doi{10.1016/j.csda.2022.107460}>.
##'   \item Hornung, R. (2022). Diversity forests: Using split sampling to enable innovative complex split procedures in random forests. SN Computer Science 3(2):1, <\doi{10.1007/s42979-021-00920-1}>.
##'   }
##' @seealso \code{\link{plot.interactionfor}}, \code{\link{plotPair}}
##' @encoding UTF-8
##' @useDynLib diversityForest, .registration = TRUE
##' @importFrom Rcpp evalCpp
##' @import stats 
##' @import utils
##' @importFrom Matrix Matrix
##' @export
plotEffects <- function(intobj, type="quant", numpairs=5, indpairs=NULL, pairs=NULL, allwith=NULL, pvalues=TRUE, twoplots=TRUE, addtitles=TRUE, plotit=TRUE) {
  
  data <- intobj$plotres$data
  yvarname <- intobj$plotres$yvarname
  statusvarname <- intobj$plotres$statusvarname
  
  annfig <- FALSE
  if(is.null(pairs)) {
    if(is.null(indpairs))
      indpairs <- 1:numpairs
    if (addtitles)
      annfig <- TRUE
    if(type=="quant") {
      if(is.null(intobj$eim.quant))
        stop("Error: Option type='quant' (default) is not available, because no quantitative EIM values were calculated.")
      if(!is.null(allwith)) {
        containallwith <- sapply(intobj$promispairs[intobj$plotres$eim.quant.order], function(x) allwith %in% intobj$forest$independent.variable.names[x])
        ninclude <- sum(containallwith)
        if(numpairs > ninclude) {
          warning(paste("The value numpairs = ", numpairs, " was larger than the number ", ninclude, 
                        " of pairs that include variable '", allwith, "'. Therefore, numpairs is set to ", ninclude, ".", sep=""))
          numpairs <- sum(containallwith)
          indpairs <- 1:numpairs
        }
        pairs <- lapply(intobj$promispairs[intobj$plotres$eim.quant.order][containallwith][indpairs], function(x) intobj$forest$independent.variable.names[x])
        pairnames <- names(intobj$eim.quant.sorted)[containallwith][indpairs]
      }  else {
        pairs <- lapply(intobj$promispairs[intobj$plotres$eim.quant.order][indpairs], function(x) intobj$forest$independent.variable.names[x])
        pairnames <- names(intobj$eim.quant.sorted)[indpairs]
      }
      pairnames[grep("small \\(", pairnames)] <- paste(sapply(pairnames[grep("small \\(", pairnames)], function(x) strsplit(x, split="small \\(")[[1]][1]), "small", sep="")
      pairnames[grep("large \\(", pairnames)] <- paste(sapply(pairnames[grep("large \\(", pairnames)], function(x) strsplit(x, split="large \\(")[[1]][1]), "large", sep="")
    }
    if(type=="qual") {
      if(is.null(intobj$eim.qual))
        stop("Error: Option type='qual' is not available, because no qualitative EIM values were calculated.")
      if(!is.null(allwith)) {
        containallwith <- sapply(intobj$promispairs[intobj$plotres$eim.qual.order], function(x) allwith %in% intobj$forest$independent.variable.names[x])
        ninclude <- sum(containallwith)
        if(numpairs > ninclude) {
          warning(paste("The value numpairs = ", numpairs, " was larger than the number ", ninclude, 
                        " of pairs that include variable '", allwith, "'. Therefore, numpairs is set to ", ninclude, ".", sep=""))
          numpairs <- sum(containallwith)
          indpairs <- 1:numpairs
        }
        pairs <- lapply(intobj$promispairs[intobj$plotres$eim.qual.order][containallwith][indpairs], function(x) intobj$forest$independent.variable.names[x])
        pairnames <- names(intobj$eim.qual.sorted)[containallwith][indpairs]
      }  else {
        pairs <- lapply(intobj$promispairs[intobj$plotres$eim.qual.order][indpairs], function(x) intobj$forest$independent.variable.names[x])
      }
      pairnames <- sapply(pairs, paste, collapse=" AND ")# names(intobj$eim.qual.sorted)[indpairs]
    }
  }
  
  ps <- list()
  
  if (!twoplots) {
    for(i in 1:length(pairs)) {
      p <- plotPair(pair=pairs[[i]], yvarname=yvarname, statusvarname=statusvarname, data=data, pvalue=pvalues, intobj=intobj)
      if(annfig) {
        p <- annotate_figure(p, top = text_grob(pairnames[i], face = "bold", size = 14))
      }
      if(plotit) {
        print(p)
        if (i != length(pairs))
          readline(prompt="Press [enter] for next plot.")
      }
      ps[[i]] <- p
    }
  } else if (length(pairs) %% 2 == 0) {
    for(i in 1:(length(pairs)/2)) {
      p1 <- plotPair(pair=pairs[[2*i-1]], yvarname=yvarname, statusvarname=statusvarname, data=data, pvalue=pvalues, intobj=intobj)
      p2 <- plotPair(pair=pairs[[2*i]], yvarname=yvarname, statusvarname=statusvarname, data=data, pvalue=pvalues, intobj=intobj)
      if(annfig) {
        p1 <- annotate_figure(p1, top = text_grob(pairnames[2*i-1], face = "bold", size = 14))
        p2 <- annotate_figure(p2, top = text_grob(pairnames[2*i], face = "bold", size = 14))
      }
      p <- ggarrange(p1, p2, nrow = 2)
      if(plotit) {
        print(p)
        if (i != (length(pairs)/2))
          readline(prompt="Press [enter] for next plot.")
      }
      ps[[i]] <- p
    }
  } else if (length(pairs) %% 2 != 0) {
    if(length(pairs) > 1) {
      for(i in 1:floor(length(pairs)/2)) {
        p1 <- plotPair(pair=pairs[[2*i-1]], yvarname=yvarname, statusvarname=statusvarname, data=data, pvalue=pvalues, intobj=intobj)
        p2 <- plotPair(pair=pairs[[2*i]], yvarname=yvarname, statusvarname=statusvarname, data=data, pvalue=pvalues, intobj=intobj)
        if(annfig) {
          p1 <- annotate_figure(p1, top = text_grob(pairnames[2*i-1], face = "bold", size = 14))
          p2 <- annotate_figure(p2, top = text_grob(pairnames[2*i], face = "bold", size = 14))
        }
        p <- ggarrange(p1, p2, nrow = 2)
        if(plotit) {
          print(p)
          readline(prompt="Press [enter] for next plot.")
        }
        ps[[i]] <- p
      }
    }
    p <- plotPair(pair=pairs[[length(pairs)]], yvarname=yvarname, statusvarname=statusvarname, data=data, pvalue=pvalues, intobj=intobj)
    if(annfig)
      p <- annotate_figure(p, top = text_grob(pairnames[length(pairs)], face = "bold", size = 14))
    if(plotit) {
      print(p)
    }
    ps[[ceiling(length(pairs)/2)]] <- p
  }
  
  invisible(ps)
  
}
