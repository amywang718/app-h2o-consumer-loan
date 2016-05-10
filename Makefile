#
# Nightly build directions:
#
# Create ci/buildnumber.properties with the following entry:
#     BUILD_NUMBER=n
#
# $ make

clean:
	@echo "Clean up tmp and models folder"
	rm r_scripts/Master.R
	rm -rf models

build:
	@echo "Make tmp and models folder"
	rm r_scripts/Master.R
	rm -rf models
	mkdir models
	@echo "Concatonate R scripts..."
	cat r_scripts/1_Clean_Data.R r_scripts/2_Loan_Approval.R r_scripts/3_Interest_Rate.R > r_scripts/Master.R
	@echo "Run Master R script..."
	cd r_scripts; R -f Master.R


