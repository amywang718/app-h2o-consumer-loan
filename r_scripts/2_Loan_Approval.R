## print("Subset loanStats to common columns with rejectStats...")
loanStats2 = loanStats[,names(rejectStats)]
## print("Filter out policy_code = 2, new product not publicly available...")
rejectStats2 = rejectStats[rejectStats$policy_code == 0, ]


allApps = h2o.rbind(loanStats2, rejectStats2)
allApps[, "policy_code"] = as.factor(allApps[, "policy_code"])
print(paste0(nrow(loanStats2), " out of ", nrow(allApps), 
             " loan application were accepted by Lending Club."))

## Set x and y variables
myY = "policy_code"
myX = setdiff(names(allApps), c (myY, "title", "zip_code") )

split = h2o.splitFrame(data = allApps, ratios = 0.8)
train = split[[1]]
valid = split[[2]]

gbm_m = h2o.gbm(x = myX, 
                y = myY, 
                training_frame = train, 
                validation_frame = valid, 
                distribution = "bernoulli",
                ntrees = 100,
                learn_rate = 0.2,
                max_depth = 5,
                model_id = "Loan_Approval_GBM")

h2o.saveModel(object = gbm_m, path = normalizePath("../models/"), force = T)
