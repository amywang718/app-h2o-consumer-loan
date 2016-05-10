library(h2o)
h2o.init(nthreads = -1)

# loan_path = normalizePath('~/app-h2o-consumer-loan/data/loanStats/')
# reject_path = normalizePath('~/app-h2o-consumer-loan/data/rejectStats/')
loan_path = normalizePath('../data/loanStats/')
reject_path = normalizePath('../data/rejectStats/')

print('Import rejected loan requests for Lending Club...')
rejectStats = h2o.importFile(path = reject_path, parse = F)
col_types   = c('numeric', 'time', 'enum', 'numeric', 'string', 'enum', 'enum', 'string', 'numeric')
rejectStats = h2o.parseRaw(data = rejectStats, destination_frame = 'rejectStats', col.types = col_types)

print('Import approved loan requests for Lending Club...')
loanStats = h2o.importFile(path = loan_path, parse = F)
col_types = c('numeric', 'numeric', 'numeric', 'numeric', 'numeric', 'enum', 'string', 'numeric',
               'enum', 'enum', 'enum', 'string', 'enum', 'numeric', 'enum', 'enum', 'enum', 'enum',
               'string', 'enum', 'enum', 'enum', 'enum', 'enum', 'numeric', 'numeric', 'enum',
               'numeric', 'numeric', 'numeric', 'numeric', 'numeric', 'numeric', 'numeric', 'numeric',
               'string', 'numeric', 'enum', 'numeric', 'numeric', 'numeric', 'numeric', 'numeric',
               'numeric', 'numeric', 'numeric', 'numeric', 'enum', 'numeric', 'enum', 'enum', 'numeric', 
               'numeric', 'numeric', 'enum', 'numeric')
loanStats = h2o.parseRaw(data = loanStats, destination_frame = 'loanStats', col.types = col_types)

print('Change column names for rejected applications to be uniform with accepted loans...')
names(rejectStats) = c('loan_amnt', 'issue_d', 'title', 'fico_range_high', 'dti', 'zip_code', 
                       'addr_state', 'emp_length', 'policy_code')

## Munge rejectStats
print('Turn string dti column into numeric...')
rejectStats$dti = h2o.strsplit(rejectStats$dti, split = '%')
rejectStats$dti = h2o.trim(rejectStats$dti)
rejectStats$dti = as.numeric(rejectStats$dti)

print('Convert emp_length column into numeric...')
rejectStats$emp_length = h2o.sub(x = rejectStats$emp_length, pattern = '([ ]*+[a-zA-Z].*)|(n/a)', replacement = '')
rejectStats$emp_length = h2o.trim(rejectStats$emp_length)
rejectStats$emp_length = h2o.sub(x = rejectStats$emp_length, pattern = '< 1', replacement = '0')
rejectStats$emp_length = h2o.sub(x = rejectStats$emp_length, pattern = '10\\+', replacement = '10')
rejectStats$emp_length = as.numeric(rejectStats$emp_length)

## Munge loanStats
print('Turn string interest rate and revoling util columns into numeric columns...')
loanStats$int_rate = h2o.strsplit(loanStats$int_rate, split = '%')
loanStats$int_rate = h2o.trim(loanStats$int_rate)
loanStats$int_rate = as.numeric(loanStats$int_rate)
loanStats$revol_util = h2o.strsplit(loanStats$revol_util, split = '%')
loanStats$revol_util = h2o.trim(loanStats$revol_util)
loanStats$revol_util = as.numeric(loanStats$revol_util)

print('Calculate the longest credit length in years...')
time1 = as.Date(h2o.strsplit(x = loanStats$earliest_cr_line, split = '-')[,2], format = '%Y') 
time2 = as.Date(h2o.strsplit(x = loanStats$issue_d, split = '-')[,2], format = '%Y')
loanStats$credit_length_in_years = year(time2) - year(time1)

print('Convert emp_length column into numeric...')
## remove ' year' and ' years', also translate n/a to ''
loanStats$emp_length = h2o.sub(x = loanStats$emp_length, pattern = '([ ]*+[a-zA-Z].*)|(n/a)', replacement = '')
loanStats$emp_length = h2o.trim(loanStats$emp_length)
loanStats$emp_length = h2o.sub(x = loanStats$emp_length, pattern = '< 1', replacement = '0')
loanStats$emp_length = h2o.sub(x = loanStats$emp_length, pattern = '10\\+', replacement = '10')
loanStats$emp_length = as.numeric(loanStats$emp_length)

print('Map multiple levels into one factor level for verification_status...')
loanStats$verification_status = h2o.sub(x = loanStats$verification_status, pattern = 'VERIFIED - income source', replacement = 'verified')
loanStats$verification_status = h2o.sub(x = loanStats$verification_status, pattern = 'VERIFIED - income', replacement = 'verified')
loanStats$verification_status = as.h2o(as.matrix(loanStats$verification_status))
#h2o.setLevels(x = loanStats$verification_status, levels = c('not verified', 'verified', ''))

print("Set issue_d to the year the application is submitted")
rejectStats$issue_d = h2o.year(rejectStats$issue_d) + 1900
loanStats$issue_d = as.numeric( h2o.strsplit(loanStats$issue_d, "-")[,2])## print("Subset loanStats to common columns with rejectStats...")
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
