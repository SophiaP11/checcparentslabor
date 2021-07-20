/* -----------------------------------------------------------------------------
PROJECT: CHECC Parents Labor Supply
TOPIC: CLEANING DATASET 
AUTHOR: Sophia
DATE CREATED: 30/06/2021
LAST MODIFIED: 19/07/2021 

NOTES: 
need month_key.csv file for experimenting section
------------------------------------------------------------------------------*/

*--------* BASIC SETUP *-------*

clear all 
ssc install nmissing 
set maxvar 30000 

*creating personal pathway to data file
if "`c(username)'"=="sophi" {
	gl path "/Users/sophi/desktop/stata"
}
else if "`c(username)'"=="louisauxenfans" {
	gl path "/Users/louisauxenfans/Desktop/Internship/Cleaning CHECC Labor_Supply"
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
*-------* DATA CLEANING *-------*

*creating a temp file to manipulate data and test code
save temp, replace
use temp, clear

*droping empty variables
quietly nmissing, min(_all) piasm trim " " // finding variables missing all obs
quietly drop `r(varlist)' // dropping them

*getting rid of starting _ from variable names
rename _* *

*renaming variables that start with v as their label
local vnames "v*" 
foreach v of varlist `vnames' { 
	local x: variable label `v' 
	local y= strlower("`x'") 
rename `v' q`y' //renaming v variables to the lowercase label with a q in front
}

*generating key for potential merging
numlist "1/635", ascending 
egen uniqueid = fill(`r(numlist)') //creating unique numbering for each observation
order uniqueid, first 

save temp, replace 

*---------*  EXPERIMENTING  *---------*
/*NOTES:
qid681 double_child1 missingf1name1 missingf1email1 missingf1phone1 test could possibly be dropped
*/
use temp, clear

****cleaning qid671***********************************
use temp, clear
quietly keep uniqueid qid671*

quietly tostring (qid671*), replace 
quietly reshape long qid671, i(uniqueid) j(job_entry) string 
quietly drop if missing(qid671) | qid671 == "." 

*assigning more specific naming to variables
local vars "employment_type start_month end_month title status start_year end_year" 
replace job_entry = "_job_" + substr(job_entry, 2, length(job_entry)-3) + "_" + word("`vars'", real(substr(job_entry, -1, .))) 
reshape wide
*need to merge changes with main dataset


****fixing date variables****
/*Notes: 
-column values 1994 and 2010 for qid671_1_2 need to swap with qid671_1_6 column values
*/
use temp, clear 
quietly keep uniqueid qid671_*_2 qid671_*_6 qid671_*_3 qid671_*_7

*fixing specific errors
replace qid671_1_2 = "sept" if qid671_1_2 == "setp" //assuming misspelling
replace qid671_1_2 = "aug" if qid671_1_2 == "15-Aug" //column value 15-aug needs to just say aug
replace qid671_1_3 = "may" if qid671_1_3 == "19-May"
replace qid671_1_3 = "present" if qid671_1_3 == "stlll working"

*making all "present" type responses the same
forvalues j = 1/12 {
	quietly tostring qid671_`j'_3 , replace
	replace qid671_`j'_3 = strlower(qid671_`j'_3)
	tab qid671_`j'_3
	replace qid671_`j'_3 = "present" if strpos(qid671_`j'_3, "current") != 0 | strpos(qid671_`j'_3, "still") != 0 | strpos(qid671_`j'_3, "present") != 0
	tab qid671_`j'_3
}




forvalues j = 1/12 {

	}

*fixing month year entry swaps 
forvalues j = 1/12 {
	quietly tostring qid671_`j'_6 , replace
	quietly replace qid671_`j'_6 = "" if qid671_`j'_6 == "."
	quietly gen tempq = qid671_`j'_2 if strlen(qid671_`j'_2) == 4 & missing(real(qid671_`j'_2)) == 0 
	quietly replace qid671_`j'_2 = qid671_`j'_6 if strlen(qid671_`j'_2) == 4 & missing(real(qid671_`j'_2)) == 0 
	quietly replace qid671_`j'_6 = tempq if missing(tempq) == 0
	drop tempq
}

*making all month entries in same format
forvalues j = 1/12 {
	quietly gen month = strlower(substr(qid671_`j'_2,1,3)) //creating new variable with just first 3 characters of response to qid671_1_2

	quietly replace month = usubinstr(month, "0", "", 1) if month != "10" | month != "11"| month != "12"

	local month_code = "jan feb mar apr may jun jul aug sep oct nov dec"
	local n : word count `month_code'

	* replace month with empty if input is invalid
	* replace 1-12 with month values
	quietly gen tempq = ""
	forvalues i = 1/`n' {
		local a : word `i' of `month_code'
		quietly replace month = "`a'" if month == "`i'"
		quietly replace tempq = "`a'" if month == "`a'"
	}
	quietly replace month = tempq
	quietly replace qid671_`j'_2 = month
	drop tempq month
	
	quietly replace qid671_`j'_6 = "" if strlen(qid671_`j'_6) != 4 | missing(real(qid671_`j'_6)) == 1 //getting rid of responses that aren't years
}

/*replacing errors in responses to blank observations*
replace month = "" if month == "?"| month == "199" | month == "201"| month == "idk"| month == "n/a"| month == "not"| month == "doe"| month == "don"| month == "unk"| month == "x"| month == "can"

tostring(month), replace
save temp2, replace

import delimited "$path/month_key.csv", clear
save mkey, replace
use temp2, clear
merge m:1 month using mkey
drop _merge

****************************************************/

****cleaning q1232***********************************
/*NOTES:
_1 = School Name _10 = School District _11 = School City 
_14 probably = same as previous grade
_15 probably = don't know
_14 and _15 meanings could be swapped
*/
use temp, clear
keep uniqueid q1232*
*ds has(q1232)
*drop if missing(`r(varlist)')
quietly reshape long q1232, i(uniqueid) j(grade_school) string 

drop if missing(q1232)
*q1232 == "X" | q1232 == "x"
*reshape wide
****************************************************

***getting rid of general idk type of responses*****
use temp, clear

quietly ds , has(type string)
foreach var in `r(varlist)' {
replace `var' = "" if `var'== "Don't know" | `var' == "don't know" | `var' == "prefer not to answer" | `var' == "Prefer not to answer" | `var' == "don't remember" | `var' == "n/a" | `var' == "no comments" | `var' == "doesn't know" | `var' == "not sure" | `var' == "dont know" | `var' == "unsure" | `var' == "Doesn't know" | `var' == "doesn't know" | `var' == "can't remember" | `var' ==  "does not want to answer" | `var' == "don't want to answer" | `var' == "N/A"
}

quietly nmissing, min(_all) piasm trim " "
quietly drop `r(varlist)'
****************************************************

/******LIST OF QUESTIONS THAT NEED CLEANING*****
use temp, clear

MONEY/HOURS VALUES:
	qid1535_1 qid85_1 qid736_1 qid1560_1 qid737_1 qid96_1

DATES:
	***number of months/years* 
keep uniqueid q875_1 q875_5 qid87_1 qid87_2  
	***start-end month/year* 
		qid736_2 qid736_3 
	***dd/mm
keep uniqueid q1738_1 q1738_2 q1740_1 q1740_2 q1742_1 q1742_2

FREE RESPONSE:

OTHER:
	qid92 (if missing check if qid91 =="no", if so change to 0)
	q1736 depends on q1735 and q886 (q1736* are dates)
***CHECKED QUESTIONS UP TO AND INCLUDING q1743
	**only checked questions with more than one obs. (569 variables)
 
****************************************************/

/*not sure if it is worth doing this below:
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