library(shiny)
setwd("~/app-h2o-consumer-loan/shiny_app/")
# Define UI for application that draws a histogram
shinyUI(pageWithSidebar(headerPanel("Consumer Loan Approval"),
  sidebarPanel(
    numericInput(inputId = "loan_amnt", min = 0, max = 40000, value = 1000,
                 label = "Input Loan Amount"),
    selectInput(inputId = "term", choices = c("36 months", "60 months"), selected = "36 months",
                label = "Select Term Length"),
    numericInput(inputId = "emp_length", min = 0, max = 10, value = 2,
                label = "Input Employment Length"),
    selectInput(inputId = "home_ownership", choices = c("MORTGAGE", "RENT", "OWN", "OTHER"), selected = "RENT",
                label = "State of Home Ownership"),
    numericInput(inputId = "annual_inc", min = 10000, value = 65000,
                 label = "Input Annual Gross Income"),
    numericInput(inputId = "fico_range_high", min = 550, max = 880, value = 700,
                 label = "Input credit score"),
    selectInput(inputId = "purpose", 
                choices = c("car","credit_card","debt_consolidation","educational","home_improvement","house","major_purchase",
                            "medical","moving","other","renewable_energy","small_business","vacation","wedding"),
                selected = "credit_card",
                label = "Select Purpose of Loan"),
    selectInput(inputId = "addr_state",
                label = "Choose State",
                choices = levels(read.table("addr_state.txt")[,1]),
                selected = "CA"),
    numericInput(inputId = "dti", min = 0, max = 50, value = 15,
                 label = "Input debt-to-income ratio"),
    numericInput(inputId = "credit_length_in_years", min = 0, max = 90, value = 10,
                 label = "Input length of longest standing installment loan"),
    numericInput(inputId = "open_acc", min = 0, max = 30, value = 4,
                 label = "Input number of open credit lines you hold")
#     selectInput(inputId = "show_only_subset",
#                 label = "Choose loan types",
#                 choices = c("All Loans", "Bad Loans", "Good Loans"),
#                 selected = "All Loans")
  ), 
#   mainPanel(textOutput("approvalText"), plotOutput("distPlot"))
  mainPanel(dataTableOutput("frame"), textOutput("decisionText"))
))
