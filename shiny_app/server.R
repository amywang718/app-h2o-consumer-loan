library(shiny)
# Define server logic required to draw a histogram
shinyServer(function(input, output) {
  library(h2o)
  h2o.init(nthreads = -1)
  approval_model_path = normalizePath("../models/Loan_Approval_GBM")
  interest_model_path = normalizePath("../models/Interest_Rate_GBM")
  
  approval_model = h2o.loadModel(approval_model_path)
  interest_model = h2o.loadModel(interest_model_path)
  
  approval_f2 = 0.22
  
  applicant = reactive({
    loan_amt = input$loan_amnt
    term = input$term
    emp_length = input$emp_length
    home_ownership = input$home_ownership
    annual_inc = input$annual_inc
    issue_d = 2016
    purpose = input$purpose
    addr_state = input$addr_state
    dti = input$dti
    fico_range_high = input$fico_range_high
    open_acc = input$open_acc
    total_acc = input$open_acc
    credit_length_in_years = input$credit_length_in_years
    if(!is.null(input$delinq_2yrs)) delinq_2yrs = input$delinq_2yrs
    if(!is.null(input$inq_last_6mths)) inq_last_6mths = input$inq_last_6mths
    if(!is.null(input$mths_since_last_delinq)) mths_since_last_delinq = input$mths_since_last_delinq
    if(!is.null(input$pub_rec)) pub_rec = input$pub_rec
    if(!is.null(input$revol_bal)) revol_bal = input$revol_bal
    if(!is.null(input$revol_util)) revol_util = input$revol_util
    
    applicant = data.frame(loan_amt = loan_amt, term = term, emp_length = emp_length,
                           home_ownership = home_ownership, annual_inc = annual_inc, 
                           issue_d = issue_d, purpose = purpose, addr_state = addr_state,
                           dti = dti, fico_range_high = fico_range_high, open_acc = open_acc,
                           total_acc = total_acc, credit_length_in_years = credit_length_in_years)
    applicant = as.h2o(applicant)
  })
  
#   approval = reactive({
#     h2o.predict(object = approval_model, newdata = applicant())
#   })
#   interest = reactive({
#     h2o.predict(object = approval_model, newdata = applicant())
#   })
  
  output$decisionText = renderText({
    app = applicant()
    approval = as.data.frame(h2o.predict(approval_model, newdata = app))
    interest = as.data.frame(h2o.predict(interest_model, newdata = app))
    print(approval)
    print(interest)
    text = if(approval[1,3] < approval_f2) "Denied" else as.character(interest[1,1])
#     text = as.character(approval[,3])
    text
  })
  
  
  output$frame = renderDataTable({
    applicant()
  })
#   output$distPlot <- renderPlot({
# #     x    <- faithful[, 2]  # Old Faithful Geyser data
# #     bins <- seq(min(x), max(x), length.out = input$bins + 1)
#     
#     # draw the histogram with the specified number of bins
# #     hist(x, breaks = bins, col = 'darkgray', border = 'white')
#     if(input$show_only_subset == "All Loans") {
#       h2o.hist(data$risk_score, plot = T)
#     } else if (input$show_only_subset == "Good Loans"){
#       h2o.hist(good_loan$risk_score, plot = T)
#     } else {
#       h2o.hist(bad_loan$risk_score, plot = T)
#     }
#     
#   })
# 
#   output$prob_table <- renderDataTable({
#     df <- data.frame(loan_amnt = input$loan_amnt, risk_score = input$risk_score, dti = input$dti,
#                      zip_code = input$zip_code, addr_state = input$addr_state, emp_length = input$emp_length)
#     df.hex <- as.h2o(df)
#     pred <- h2o.predict(object = model, newdata = df.hex)
#     pred.R <- as.data.frame(pred)
#     pred.R
#   })
})
