/* -----------------------------------------------------------------------------
PROJECT: CHECC Parents Labor Supply
TOPIC: CLEANING DATASET 
AUTHOR: Louis
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

cd $path //Do not need if Louis

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

*assigning more specific naming to _numbers
local vars "employment_type start_month end_month title status start_year end_year" 
replace job_entry = "job " + substr(job_entry, 2, length(job_entry)-3) + " " + word("`vars'", real(substr(job_entry, -1, .))) 
****************************************************

****combining date variables into mm/yyyy format****
/*Notes: 
-column values 1994 and 2010 for qid671_1_2 need to swap with qid671_1_6 column values
-column value 15-march needs to just say mar
*/
use temp, clear
quietly keep uniqueid qid671_1_2 qid671_1_6 

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

MONEY/HOURS VALUES:
	qid1535_1 qid85_1 qid736_1 qid1560_1 qid737_1 qid96_1

DATES:
	***number of months/years* 
		q875_1 q875_5 qid87_1 qid87_2  
	***start-end month/year* 
		qid736_2 qid736_3 
	***mm/yyyy
		q1738_1 q1738_2 q1740_1 q1740_2 q1742_1 tab q1742_2

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



------OLD STUFF From Louis CODE-----
* Labelling variables

local questions "_q* v*"
foreach v of varlist `questions'  {
local x: variable label `v' 
local y=lower(subinstr("`x'", " ", "", .))
label var `v' "q`y'"

}

foreach v of varlist _all {
local x: variable label `v' 
local y=lower(subinstr("`x'", " ", "", .))
label var `v' "`y'"

}

local vars "enddate ipaddress progress durationinseconds finished externalreference locationlatitude locationlongitude distributionchannel fid child_name address city phone1 phone2 email2 child_race interview_date location interviewer parent_name otherguardian otherguardian_relation other_child1 livewith_child marital_status parent_education job_title hours_week income income_period otherguardian_job_title otherguardian_hours_week otherguardian_income otherguardian_income_period email3 phone3 phone4 penr_id other_child2 other_adult1 other_adult2 other_child3 other_child4 multiple other_adult3 phone5 adult1 adult2 previous_address child_birthday child_gender district1 other_child_id_1 other_child1_birthday other_child1_gender double_child1 missingf1name1 missingf1email1 other_child_id_2 other_child2_birthday other_child2_gender missingf1phone1 phone21 missingf1address1 f1_home1 phone31 apartment f1email_21 alt_fid3 other_child_id_3 other_child3_birthday other_child3_gender alt_fid2 email21 alt_fid1 startdate status recordeddate responseid recipientlastname recipientfirstname recipientemail state time tag2 test zipcode"
foreach v of varlist `vars' {
label var `v' "`v'"

}

foreach v of varlist _all {
   local x : variable label `v'
   rename `v' `x'
}


order responseid, first
tempfile tempfile1
save "tempfile1", replace
/*
Clean up basic demographic info 

*/

use temporary.dta, clear

keep enddate ipaddress progress durationinseconds finished externalreference locationlatitude locationlongitude distributionchannel fid child_name address city phone1 phone2 email2  interview_date location interviewer parent_name otherguardian otherguardian_relation other_child1 livewith_child marital_status parent_education job_title hours_week income income_period otherguardian_job_title otherguardian_hours_week otherguardian_income otherguardian_income_period email3 phone3 other_child2 other_child3 multiple adult1 adult2 previous_address child_birthday child_gender district1 other_child_id_1 other_child1_birthday other_child1_gender double_child1 missingf1name1 missingf1email1 other_child_id_2 other_child2_birthday other_child2_gender missingf1phone1 phone21 f1_home1 phone31 apartment alt_fid3 other_child_id_3 other_child3_birthday other_child3_gender alt_fid2 email21 alt_fid1 startdate status recordeddate responseid recipientemail userlanguage state zipcode time tag2  test

encode finished, generate(finished_n)
drop finished

*keep 

/*
Clean up question answers 
*/

/*use temporary.dta, clear
foreach v of varlist _all {
	local capture count if missing(`v')
	
} */

		
/*
THis is from Lina's code - Just tinkering
local b=1
local i=1
use tempfile1, clear
keep if !missing(qid`i'`b'1)
keep qid`i'`b'*  responseid
reshape long q`i'_qb`b'_, i(responseid) j(questions)
rename q`i'_qb`b'_ correct 
rename (q`i'_qt`b'_firstclick q`i'_qt`b'_lastclick q`i'_qt`b'_pagesubmit q`i'_qt`b'_clickcount) (firstclick lastclick pagesubmit clickcount)

gen key="q`i'_qb`b'" 
		replace addressnum=addressnum+(`b'-1)*5 if `b'>1

		merge m:1 addressnum key using addresses_key.dta, nogen keep(3)
		sort mturkcode addressnum
		order key addressnum id_group batch, after(mturkcode)

		tempfile q`i'_qb`b'
		save `q`i'_qb`b''

		capture append using `temporal'
		tempfile temporal 
		save `temporal'

		sort mturkcode addressnum	
				
				}

}
		tempfile first 
		save `first'
	

*keep enddate ipaddress progress durationinseconds finished externalreference locationlatitude locationlongitude distributionchannel fid child_name address city phone1 phone2 email2 child_race interview_date location interviewer parent_name otherguardian otherguardian_relation other_child1 livewith_child marital_status parent_education job_title hours_week income income_period otherguardian_job_title otherguardian_hours_week otherguardian_income otherguardian_income_period email3 phone3 phone4 penr_id other_child2 other_adult1 other_adult2 other_child3 other_child4 multiple other_adult3 phone5 adult1 adult2 previous_address child_birthday child_gender district1 other_child_id_1 other_child1_birthday other_child1_gender double_child1 missingf1name1 missingf1email1 other_child_id_2 other_child2_birthday other_child2_gender missingf1phone1 phone21 missingf1address1 f1_home1 phone31 apartment f1email_21 alt_fid3 other_child_id_3 other_child3_birthday other_child3_gender alt_fid2 email21 alt_fid1 zipcode 
