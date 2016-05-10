## Use only approved loans tos
split0 = h2o.splitFrame(loanStats, 0.8)
train0 = split0[[1]]
valid0 = split0[[2]]

myY_int = "int_rate"
myX_int = c("loan_amnt", "term", "emp_length", "home_ownership", 
            "annual_inc", "issue_d", "purpose", "addr_state", "dti",
            "delinq_2yrs", "fico_range_high", "inq_last_6mths",
            "mths_since_last_delinq", "open_acc", "pub_rec", "revol_bal",
            "revol_util", "total_acc", "credit_length_in_years")

int_m = h2o.gbm(x = myX_int,
                y = myY_int,
                training_frame = train0,
                validation_frame = valid0,
                distribution = "gaussian",
                ntrees = 100,
                learn_rate = 0.2,
                max_depth = 5,
                model_id = "Interest_Rate_GBM")

h2o.saveModel(object = int_m, path = normalizePath("../models/"), force = T)
