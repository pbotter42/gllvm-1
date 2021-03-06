#' @title Confidence intervals for model parameters
#' @description Computes confidence intervals for  parameters in a fitted gllvm model.
#'
#' @param object an object of class 'gllvm'.
#' @param level the confidence level. Scalar between 0 and 1.
#' @param parm a specification of which parameters are to be given confidence intervals, a vector of names. If missing, all parameters are considered.
#' @param ...	not used.
#'
#' @author Jenni Niku <jenni.m.e.niku@@jyu.fi>
#'
#' @examples
#'## Load a dataset from the mvabund package
#'data(antTraits)
#'y <- as.matrix(antTraits$abund)
#'X <- as.matrix(antTraits$env[,1:2])
#'# Fit gllvm model
#'fit <- gllvm(y = y, X = X, family = "poisson")
#'# 95 % confidence intervals
#'confint(fit, level = 0.95)
#'
#'@export

confint.gllvm <- function(object, parm=NULL, level = 0.95, ...) {
  if(is.logical(object$sd)) stop("Standard errors for parameters haven't been calculated, so confidence intervals can not be calculated.");
  n <- NROW(object$y)
  p <- NCOL(object$y)
  nX <- 0; if(!is.null(object$X)) nX <- dim(object$X)[2]
  nTR <- 0; if(!is.null(object$TR)) nTR <- dim(object$TR)[2]
  num.lv <- object$num.lv
  alfa <- (1 - level) / 2
  if(object$row.eff == "random") object$params$row.params = NULL

  if(is.null(parm)){
    if (object$family == "negative.binomial") {
      object$params$phi <- NULL
      object$sd$phi <- NULL
    }
    parm_all <- c("theta", "beta0", "Xcoef", "B", "row.params", "sigma", "inv.phi", "phi", "p")
    parmincl <- parm_all[parm_all %in% names(object$params)]
    cilow <- unlist(object$params[parmincl]) + qnorm(alfa) * unlist(object$sd[parmincl])
    ciup <- unlist(object$params[parmincl]) + qnorm(1 - alfa) * unlist(object$sd[parmincl])
    M <- cbind(cilow, ciup)

    colnames(M) <- c(paste(alfa * 100, "%"), paste((1 - alfa) * 100, "%"))
    rnames <- names(unlist(object$params))
    cal <- 0
    if (num.lv > 0) {
      nr <- rep(1:num.lv, each = p)
      nc <- rep(1:p, num.lv)
      rnames[1:(num.lv * p)] <- paste(paste("theta.LV", nr, sep = ""), nc, sep = ".")
      cal <- cal + num.lv * p
    }
    rnames[(cal + 1):(cal + p)] <- paste("Intercept",names(object$params$beta0), sep = ".")
    cal <- cal + p
    if (!is.null(object$TR)) {
      nr <- names(object$params$B)
      rnames[(cal + 1):(cal + length(nr))] <- nr
      cal <- cal + length(nr)
    }

    if (is.null(object$TR) && !is.null(object$X)) {
      cnx <- rep(colnames(object$X), each = p)
      rnc <- rep(rownames(object$params$Xcoef), nX)
      newnam <- paste(cnx, rnc, sep = ":")
      rnames[(cal + 1):(cal + nX * p)] <- paste("Xcoef", newnam, sep = ".")
      cal <- cal + nX * p
    }
    if (object$row.eff %in% c("fixed",TRUE)) {
      rnames[(cal + 1):(cal + n)] <- paste("Row.Intercept", 1:n, sep = ".")
      cal <- cal + n
    }
    if (object$row.eff == "random") {
      rnames[(cal + 1)] <- "sigma"
      cal <- cal + 1
    }
    if(object$family == "negative.binomial"){
      s <- dim(M)[1]
      rnames[(cal + 1):s] <- paste("inv.phi", names(object$params$beta0), sep = ".")
    }
    if(object$family == "tweedie"){
      s <- dim(M)[1]
      rnames[(cal + 1):s] <- paste("Dispersion phi", names(object$params$phi), sep = ".")
    }
    if(object$family == "ZIP"){
      s <- dim(M)[1]
      rnames[(cal + 1):s] <- paste("p", names(object$params$p), sep = ".")
    }
    rownames(M) <- rnames
  } else {
    if ("beta0" %in% parm) {
      object$params$Intercept = object$params$beta0
      parm["beta0"] = "Intercept"
    }
    cilow <- unlist(object$params[parm]) + qnorm(alfa) * unlist(object$sd[parm])
    ciup <- unlist(object$params[parm]) + qnorm(1 - alfa) * unlist(object$sd[parm])
    M <- cbind(cilow, ciup)

  }
  return(M)
}
