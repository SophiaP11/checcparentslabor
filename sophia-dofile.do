/* -----------------------------------------------------------------------------
PROJECT: CHECC Parents Labor Supply
TOPIC: CLEANING DATASET 
AUTHOR: Sophia
DATE CREATED: 30/06/2021
LAST MODIFIED: 14/07/2021 

NOTES: 
need month_key.csv file for experimenting section
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
import delimited "$path/Final_Survey 2_Wave_3_Single_or_Multiple_June 30, 2021_12.52.csv", bindquote(strict) maxquotedrows(50000) varnames(1) clear
 
if "`c(username)'"=="jonathanlambrinos" {
	drop if inlist(_n, 1, 2)
}
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
numlist "1/635", ascending //generating numbers to match to each observation
egen uniqueid = fill(`r(numlist)') //creating new variable with unique numbering for each observation
order uniqueid, first //moving variable to the start of the dataset for enhanced visability

save temp, replace //saving cleaning changes to allow for experimenting

*---------*  Experimenting  *---------*
/*NOTES:
qid681 double_child1 missingf1name1 missingf1email1 missingf1phone1 test could possibly be dropped
*/
use temp, clear

****fixing qid671***********************************
use temp, clear
quietly keep uniqueid qid671* // dropping all other questions
quietly tostring (qid671*), replace // turning all variables to strings so I can reshape without different type errors
quietly reshape long qid671, i(uniqueid) j(job_entry) string //reshaping the data to extract the different parts of qid671 and rename properly
quietly drop if missing(qid671) | qid671 == "." //getting rid of missing values in data 
local vars "employment_type start_month end_month title status start_year end_year" //creating correct names for numbers in data
replace job_entry = "job " + substr(job_entry, 2, length(job_entry)-3) + " " + word("`vars'", real(substr(job_entry, -1, .))) //assigning more specific naming to values
****************************************************

****combining date variables into mm/yyyy format****
/*Notes: column values 1994 and 2010 for qid671_1_2 need to swap with qid671_1_6 column values
*/
use temp, clear

quietly keep uniqueid qid671_1_2 qid671_1_6 //dropping all other questions
gen month = strlower(substr(qid671_1_2,1,3)) //creating new variable with just first 3 characters of response to qid671_1_2

replace month = usubinstr(month, "0", "", 1) if month != "10"

local month_code = "jan feb mar apr may jun jul aug sep oct nov dec"
local n : word count `month_code'

* replace month with empty if input is invalid
* replace 1-12 with month values
gen temp = ""
forvalues i = 1/`n' {
	local a : word `i' of `month_code'
	replace month = "`a'" if month == "`i'"
	replace temp = "`a'" if month == "`a'"
}
replace month = temp
drop temp




/*replacing month values with month names in responses*
replace month = "jan" if month == "1"
replace month = "feb" if month == "2"
replace month = "mar" if month == "3"
replace month = "apr" if month == "4"
replace month = "may" if month == "5"
replace month = "jun" if month == "6"
replace month = "jul" if month == "7"
replace month = "aug" if month == "8" 
replace month = "sep" if month == "9"
replace month = "oct" if month == "10"
replace month = "nov" if month == "11"
replace month = "dec" if month == "12"

*replacing errors in responses to blank observations*
replace month = "" if month == "?"| month == "199" | month == "201"| month == "idk"| month == "n/a"| month == "not"| month == "doe"| month == "don"| month == "unk"| month == "x"| month == "can"

*numlist 1/12
*egen numbers = month if 

*| month == "15-" (response is 15-march so replace with mar)

*local mon "jan feb mar apr may jun jul aug sep oct nov dec"
*replace month = "" if !inlist(month, "`mon'")


*label define mkey 1 "jan" 2 "feb" 3 "mar" 4 "apr" 5 "may" 6 "jun" 7 "jul" 8 "aug" 9 "sep" 10 "oct" 11 "nov" 12 "dec"
*label values month


*month != "feb" | month != "mar"| month != "apr" | month != "may" | month != "jun" | month != "jul" | month != "aug" | month != "sep" | month != "oct" |  month != "nov" | month != "dec"

/*tostring(month), replace
save temp2, replace

import delimited "$path/month_key.csv", clear
save mkey, replace
use temp2, clear
merge m:1 month using mkey
drop _merge*/

****************************************************/

****fixing q1232***********************************
/*NOTES:
_1 = School Name _10 = School District _11 = School City 
_14 probably = same as previous grade
_15 probably = don't know
_14 and _15 meanings could be swapped
*/
use temp, clear
keep uniqueid q1232*
ds has(q1232)
drop if missing(`r(varlist)')
quietly reshape long q1232, i(uniqueid) j(grade_school) string //reshaping the data to extract the different parts of qid671 and rename properly
drop if missing(q1232) //getting rid of missing values in data 
 q1232 == "X" | q1232 == "x"
 reshape wide
****************************************************

***getting rid of general idk type of responses*****
use temp, clear

quietly ds , has(type string)
foreach var in `r(varlist)' {
replace `var' = "" if `var'== "Don't know" | `var' == "don't know" | `var' == "prefer not to answer" | `var' == "Prefer not to answer" | `var' == "don't remember" | `var' == "n/a" | `var' == "no comments" | `var' == "doesn't know" | `var' == "not sure" | `var' == "dont know" | `var' == "unsure" | `var' == "Doesn't know" | `var' == "doesn't know" | `var' == "can't remember" | `var' ==  "does not want to answer" | `var' == "don't want to answer" | `var' == "N/A"
}

quietly nmissing, min(_all) piasm trim " " // returns a list of all variables that are missing a minimun of all observations. This also saves this list of variables as r(varlist)
quietly drop `r(varlist)'
****************************************************


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

	
