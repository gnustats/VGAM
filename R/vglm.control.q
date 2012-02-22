# These functions are
# Copyright (C) 1998-2012 T.W. Yee, University of Auckland.
# All rights reserved.



.min.criterion.VGAM <-
  c("deviance" = TRUE,
    "loglikelihood" = FALSE,
    "AIC" = TRUE, 
    "Likelihood" = FALSE,
    "rss" = TRUE,
    "coefficients" = TRUE)



vlm.control <- function(save.weight = TRUE, tol = 1e-7, method="qr", 
                        checkwz = TRUE, wzepsilon = .Machine$double.eps^0.75,
                        ...) {
    if (tol <= 0) {
        warning("tol not positive; using 1e-7 instead")
        tol <- 1e-7
    }
    if (!is.logical(checkwz) || length(checkwz) != 1)
        stop("bad input for argument 'checkwz'")
    if (!is.Numeric(wzepsilon, allowable.length = 1, positive = TRUE))
        stop("bad input for argument 'wzepsilon'")

    list(save.weight=save.weight, tol=tol, method=method,
         checkwz = checkwz,
         wzepsilon = wzepsilon)
}


vglm.control <- function(checkwz = TRUE,
                         criterion = names(.min.criterion.VGAM), 
                         epsilon = 1e-7,
                         half.stepsizing = TRUE,
                         maxit = 30, 
                         stepsize = 1, 
                         save.weight = FALSE,
                         trace = FALSE,
                         wzepsilon = .Machine$double.eps^0.75,
                         xij = NULL,
                         ...)
{



    if (mode(criterion) != "character" && mode(criterion) != "name")
        criterion <- as.character(substitute(criterion))
    criterion <- pmatch(criterion[1], names(.min.criterion.VGAM), nomatch = 1)
    criterion <- names(.min.criterion.VGAM)[criterion]



    if (!is.logical(checkwz) || length(checkwz) != 1)
        stop("bad input for argument 'checkwz'")
    if (!is.Numeric(wzepsilon, allowable.length = 1, positive = TRUE))
        stop("bad input for argument 'wzepsilon'")

    convergence <- expression({


        switch(criterion,
        coefficients = if (iter == 1) iter < maxit else
          (iter < maxit &&
           max(abs(new.crit - old.crit) / (abs(old.crit) + epsilon))
           > epsilon),
           abs(old.crit-new.crit) / (abs(old.crit)+epsilon) > epsilon &&
           iter < maxit)
    })

    if (!is.Numeric(epsilon, allowable.length = 1, positive = TRUE)) {
        warning("bad input for argument 'epsilon'; using 0.00001 instead")
        epsilon <- 0.00001
    }
    if (!is.Numeric(maxit, allowable.length = 1,
                    positive = TRUE, integer.valued = TRUE)) {
        warning("bad input for argument 'maxit'; using 30 instead")
        maxit <- 30
    }
    if (!is.Numeric(stepsize, allowable.length = 1, positive = TRUE)) {
        warning("bad input for argument 'stepsize'; using 1 instead")
        stepsize <- 1
    }

    list(checkwz = checkwz,
         convergence = convergence, 
         criterion = criterion,
         epsilon = epsilon,
         half.stepsizing = as.logical(half.stepsizing)[1],
         maxit = maxit,
         min.criterion = .min.criterion.VGAM,
         save.weight = as.logical(save.weight)[1],
         stepsize = stepsize,
         trace = as.logical(trace)[1],
         wzepsilon = wzepsilon,
         xij = if (is(xij, "formula")) list(xij) else xij)
}




vcontrol.expression <- expression({

    control <- control   # First one, e.g., vgam.control(...)
    mylist <- family@vfamily
    for(i in length(mylist):1) {
        for(ii in 1:2) {
            temp <- paste(if(ii == 1) "" else paste(function.name, ".", sep=""),
                          mylist[i], ".control", sep="")
            tempexists = if (is.R()) exists(temp, envir = VGAM:::VGAMenv) else 
                         exists(temp, inherit = TRUE)
            if (tempexists) {
                temp <- get(temp)
                temp <- temp(...)
                for(k in names(temp))
                    control[[k]] <- temp[[k]]
            }
        }
    }


    orig.criterion = control$criterion
    if (control$criterion != "coefficients") {
        try.crit = c(names(.min.criterion.VGAM), "coefficients")
        for(i in try.crit) {
            if (any(slotNames(family) == i) &&
            (( is.R() && length(body(slot(family, i)))) ||
            ((!is.R() && length(slot(family, i)) > 1)))) {
                control$criterion <- i
                break
            } else
                control$criterion <- "coefficients"
        }
    }
    control$min.criterion <- control$min.criterion[control$criterion]





        for(ii in 1:2) {
            temp <- paste(if(ii == 1) "" else paste(function.name, ".", sep=""),
                          family@vfamily[1], 
                          ".", control$criterion, ".control", sep="")
            if (exists(temp, inherit=T)) {
                temp <- get(temp)
                temp <- temp(...)
                for(k in names(temp))
                    control[[k]] <- temp[[k]]
            }
        }

})


