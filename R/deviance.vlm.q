# These functions are
# Copyright (C) 1998-2013 T.W. Yee, University of Auckland.
# All rights reserved.






deviance.vlm <- function(object, ...)
  object@criterion$deviance


deviance.vglm <- function(object, ...)
  object@criterion$deviance



if(!isGeneric("deviance"))
  setGeneric("deviance", function(object, ...)
  standardGeneric("deviance"))


setMethod("deviance", "vlm", function(object, ...)
           deviance.vlm(object, ...))


setMethod("deviance", "vglm", function(object, ...)
           deviance.vglm(object, ...))




df.residual_vlm <- function(object, type = c("vlm", "lm"), ...) {
  type <- type[1]


  switch(type,
         vlm = object@df.residual,
          lm = nobs(object, type = "lm") - nvar_vlm(object, type = "lm"),
         stop("argument 'type' unmatched"))
}




setMethod("df.residual", "vlm", function(object, ...)
           df.residual_vlm(object, ...))




nvar_vlm <- function(object, ...) {


  M <- npred(object)
  allH <- matrix(unlist(constraints(object, type = "lm")), nrow = M)
  checkNonZero <- function(m) sum(as.logical(m))
  numPars <- apply(allH, 1, checkNonZero)
  if (length(object@misc$predictors.names) == M)
    names(numPars) <- object@misc$predictors.names


  NumPars <- rep(0, length = M)
  for (jay in 1:M) {
    X.lm.jay <- model.matrix(object, type = "lm", linpred.index = jay)
    NumPars[jay] <- ncol(X.lm.jay)
  }
  if (length(object@misc$predictors.names) == M)
    names(NumPars) <- object@misc$predictors.names
  if (!all(NumPars == numPars)) {
    print(NumPars - numPars)  # Should be all 0s
    stop("something wrong in nvar_vlm()")
  }

  numPars
}












if (FALSE) {


set.seed(123)
zapdat <- data.frame(x2 = runif(nn <- 2000))
zapdat <- transform(zapdat, p0     = logit(-0.5 + 1*x2, inverse = TRUE),
                           lambda =  loge( 0.5 + 2*x2, inverse = TRUE),
                           f1     =  gl(4, 50, labels = LETTERS[1:4]),
                           x3     =  runif(nn))
zapdat <- transform(zapdat, y = rzapois(nn, lambda, p0))
with(zapdat, table(y))


fit1 <- vglm(y ~ x2, zapoisson, zapdat, trace = TRUE)
fit1 <- vglm(y ~ bs(x2), zapoisson, zapdat, trace = TRUE)
coef(fit1, matrix = TRUE)  # These should agree with the above values


fit2 <- vglm(y ~ bs(x2) + x3, zapoisson(zero = 2), zapdat, trace = TRUE)
coef(fit2, matrix = TRUE)


clist <- list("(Intercept)" = diag(2), "x2" = rbind(0,1),
             "x3" = rbind(1,0))
fit3 <- vglm(y ~ x2 + x3, zapoisson(zero = NULL), zapdat,
            constraints = clist, trace = TRUE)
coef(fit3, matrix = TRUE)


constraints(fit2, type = "term")
constraints(fit2, type = "lm")
head(model.matrix(fit2, type = "term"))
head(model.matrix(fit2, type = "lm"))




allH <- matrix(unlist(constraints(fit1)), nrow = fit1@misc$M)
allH <- matrix(unlist(constraints(fit2)), nrow = fit2@misc$M)
allH <- matrix(unlist(constraints(fit3)), nrow = fit3@misc$M)


checkNonZero <- function(m) sum(as.logical(m))

(numPars <- apply(allH, 1, checkNonZero))


nvar_vlm(fit1)
nvar_vlm(fit2)
nvar_vlm(fit3)


}






