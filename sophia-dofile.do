/* -----------------------------------------------------------------------------
PROJECT: 
TOPIC: CLEANING DATASET 
AUTHOR: Sophia
DATE CREATED: 30/06/2021
LAST MODIFIED: 30/06/2021 

NOTES: 

- Complete the information here. Always comment your code so that it is replicable! 

- Useful commands to manipulate and clean the data: 
	- tab, des, rename, drop, gen, label var, codebook
	
- If you are stuck try these resources in order 
	1. Help from Stata: In the commmand line you can type h or help to get help (example: if you don't understand the command import delimited type h import delimited)
	2. Google: Type how to akdvnvkadjnsva in Stata, google always have good answers. 
	3. Me :) 
	
------------------------------------------------------------------------------*/

** Basic Setup **
clear all 

* Installing necessary packages:
ssc install nmissing

* Increasing the number of variables that Stata is able to read: 
set maxvar 30000 
 
* creating personal pathway to data file
*gl path "/Users/sophi/desktop/stata"
if "`c(username)'"=="sophi" {
	gl path "/Users/sophi/desktop/stata"
}
else if "`c(username)'"=="jonathanlambrinos" {
	gl path "/Users/jonathanlambrinos/Desktop/CHECC_parentslabor_cleaning"
}

cd $path

* Importing data:
import delimited "$path/Final_Survey 2_Wave_3_Single_or_Multiple_June 30, 2021_12.52.csv", bindquote(strict) //The bindquote(strict) makes sure it doesn't get scrambled in the process.

** Data cleaning **

*creating a temp file to manipulate data and test code
save temp, replace
use temp, clear

*droping empty variables
nmissing, min(_all) piasm trim " " // returns a list of all variables that are missing a minimun of all observations. This also saves this list of variables as r(varlist)
drop `r(varlist)' // dropping all the variables that are missing all observations

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

*fixing qid671
quietly keep uniqueid qid671*
quietly tostring (qid671*), replace
quietly reshape long qid671, i(uniqueid) j(job_entry) string 

drop if missing(qid671) | qid671 == "."
*destring job_entry , replace ignore("_")

local vars "employment_type start_month end_month title status start_year end_year"
*replace test = word("`vars'", 2)


*gen something = real(substr(job_entry, -1, .))
*replace temp = word("`vars'", 1)

replace TESTING_MAIN = "job " + substr(job_entry, 2, length(job_entry)-3) + " " + word("`vars'", real(substr(job_entry, -1, .)))



/*
label define job 1 "employment type" 2 "start month" 3 "end month" 4 "title" 5 "status" 6 "start year" 7 "end year"

egen jobaspect = ends(job_entry), punct(_) last

split(job_entry), generate(jobaspect) destring ignore("_")  
*/


forvalues i=1/12{
	label define job`i' `i'1 "job`i' employment type" `i'2 "job`i' start month" `i'3 "job `i' end month" `i'4 "job`i' title" `i'5 "job`i' status" `i'6 "job`i' start year" `i'7 "job`i' end year"
	label values job_entry job`i'
} //need to fix numbers so syntax works...

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

*renaming variables
foreach v of varlist _all {
   local x : variable label `v'
   rename `v' `x'
}
 
*merging variables
merge m:1 qid675_1_* using Final_Survey 2_Wave_3_Single_or_Multiple_June 30, 2021_12.52.csv, assert
if assert = true {merge m:1 qid675_1_* using Final_Survey 2_Wave_3_Single_or_Multiple_June 30, 2021_12.52.csv, replace}

r(varlist)


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

*Merge responses under one variable name **I have no idea if this will actually work, but I am just trying to think of possibilities**
	*create variablelmatrix[]
	*find each different variable name for [insert qid]
		*add each variable to variablelist[]
	*repeat the following until list has only one variable in it
		*for row i in variablelist[1] check for blank cells
			foreach i of variablelmatrix x
			*if cell is blank 
				*go to row i under variablelist[2]
				*set "response" = that cell
			*go back to blank cell
				*set current cell = response
		*delete variablelist[2] 
	*rename variablelist[1] to [insert qid]
	*erase variablelist
	*start over
	
