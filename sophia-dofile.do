/* -----------------------------------------------------------------------------
PROJECT: CHECC Parents Labor Supply
TOPIC: CLEANING DATASET 
AUTHOR: Sophia
DATE CREATED: 30/06/2021
LAST MODIFIED: 14/07/2021 

NOTES: 

------------------------------------------------------------------------------*/

*--------* Basic Setup *-------*

clear all 
ssc install nmissing //installing necessary packages
set maxvar 30000 //increasing number of variables because this dataset is huge

*creating personal pathway to data file
if "`c(username)'"=="sophi" {
	gl path "/Users/sophi/desktop/stata"
}
else if "`c(username)'"=="jonathanlambrinos" {
	gl path "/Users/jonathanlambrinos/Desktop/CHECC_parentslabor_cleaning"
}

cd $path

*Importing data
import delimited "$path/Final_Survey 2_Wave_3_Single_or_Multiple_June 30, 2021_12.52.csv", bindquote(strict) //The bindquote(strict) makes sure it doesn't get scrambled in the process.

*-------* Data cleaning *-------*

*creating a temp file to manipulate data and test code
save temp, replace
use temp, clear

*droping empty variables
quietly nmissing, min(_all) piasm trim " " // returns a list of all variables that are missing a minimun of all observations. This also saves this list of variables as r(varlist)
quietly drop `r(varlist)' // dropping all the variables that are missing all observations

*getting rid of the starting _ from variable names
rename _* *

*renaming variables that start with v as their label
local vnames "v*" // assigning all variables that start with a v to the variable list called vnames
foreach v of varlist `vnames' { //going through each variable in vnames
	local x: variable label `v' //assigning the variable's label to the variable x
	local y= strlower("`x'") //assigning the lowercase version of the label to the variable y
rename `v' q`y' //renaming the variable to the lowercase label with a q in front
}

*generating key for potential merging
numlist "1/635", ascending
egen uniqueid = fill(`r(numlist)')
order uniqueid, first

save temp, replace //saving changes

*---------*  Experimenting  *---------*

use temp, clear

*****fixing qid671*****
quietly keep uniqueid qid671* // dropping all other questions
quietly tostring (qid671*), replace // turning all variables to strings so I can reshape without different type errors
quietly reshape long qid671, i(uniqueid) j(job_entry) string //reshaping the data to extract the different parts of qid671 and rename properly
quietly drop if missing(qid671) | qid671 == "." //getting rid of missing values in data 
local vars "employment_type start_month end_month title status start_year end_year" //creating correct names for numbers in data
replace job_entry = "job " + substr(job_entry, 2, length(job_entry)-3) + " " + word("`vars'", real(substr(job_entry, -1, .))) //assigning more specific naming to values
***********************

*use temp, clear

/*labeling variables
foreach v of varlist _all {
	local x: variable label `v' 
	local y=lower(subinstr("`x'", " ", "", .))
	label var `v' "q`y'"
}

local vars "enddate ipaddress progress durationinseconds finished externalreference locationlatitude locationlongitude distributionchannel fid child_name address city phone1 phone2 email2 child_race interview_date location interviewer parent_name otherguardian otherguardian_relation other_child1 livewith_child marital_status parent_education job_title hours_week income income_period otherguardian_job_title otherguardian_hours_week otherguardian_income otherguardian_income_period email3 phone3 phone4 penr_id other_child2 other_adult1 other_adult2 other_child3 other_child4 multiple other_adult3 phone5 adult1 adult2 previous_address child_birthday child_gender district1 other_child_id_1 other_child1_birthday other_child1_gender double_child1 missingf1name1 missingf1email1 other_child_id_2 other_child2_birthday other_child2_gender missingf1phone1 phone21 missingf1address1 f1_home1 phone31 apartment f1email_21 alt_fid3 other_child_id_3 other_child3_birthday other_child3_gender alt_fid2 email21 alt_fid1 zipcode"

foreach v of varlist `vars' {
label var `v' "`v'"
}


*qid79
label var qid79 "If parent works for pay now"
*qid80
label var qid80 "If parent ever worked"
*q875
label var q875_1 "Length of not working for pay"
label var q875_5 "Length of not working for pay"
*qid81
label var qid81 "Reason for not working"
label var qid81_9_text "Reason for not working"
*qid82
label var qid82 "Months of work in 1 year"
*qid83
label var qid83 "Primary job"
*qid695
label var qid695 "Name of Company of Primary job"
*qid84
label var qid84 "Main duties at job"
*qid85
label var qid85_1 "Hours per week at work"
*qid1536
label var qid1536 "Time length for Pre-tax income for primary job"
*qid1537
label var qid1537_1 "Post-tax income of primary job"
*qid1539
label var qid1539 "Time length for Post-tax income for primary job"
*qid87
label var qid87_7 "Length parent has been working at primary job"
label var qid87_2 "Length parent has been working at primary job"
*qid728
label var qid728 "Same hours of work"
*qid736
label var qid736_1 "Previous hours per week and duration at primary job"
label var qid736_2 "Previous hours per week and duration at primary job"
label var qid736_3 "Previous hours per week and duration at primary job"
*qid91
label var qid91 "Have Side job(s)"
*qid92
label var qid92 "Number of side jobs"
*qid94
label var _qid94 "Type of Side job"

	
