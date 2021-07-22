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
/*----------------------------------------------------------------------------*/

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

*cd $path

*Importing data
import delimited "$path/Final_Survey 2_Wave_3_Single_or_Multiple_June 30, 2021_12.52.csv", bindquote(strict) maxquotedrows(50000) varnames(1) clear
 
if "`c(username)'"=="jonathanlambrinos" {
	drop if inlist(_n, 1, 2)
}

/*----------------------------------------------------------------------------*/
						*-------* DATA CLEANING *-------*
/*----------------------------------------------------------------------------*/

*creating a temp file to manipulate data and test code
save temp, replace
use temp, clear

*droping empty variables
quietly nmissing, min(_all) piasm trim " " // finding variables missing all obs
quietly drop `r(varlist)' // dropping them
drop if _n == 63
drop if progress <= 2

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
numlist "1/623", ascending  // Changed from
egen uniqueid = fill(`r(numlist)') //creating unique numbering for each observation
order uniqueid, first 

save temp, replace 

/*----------------------------------------------------------------------------*/
					*---------*  EXPERIMENTING  *---------*
/*----------------------------------------------------------------------------*/

/*NOTES:
could possibly drop qid681 double_child1 missingf1name1 missingf1email1 missingf1phone1 test 
*/
use temp, clear

/*----------- Encoding Yes/No questions----------*/

local questions "qid79 qid80 qid728 qid91 qid99 q1734 q1737 q1739 q1741 q1743"
foreach v of varlist `questions' {
	encode `v', generate(`v'_n)
	drop `v'
	rename `v'_n `v'
}

/*-------------------------------------------------*/
* qid671 - standardize free responses and dates
/*-------------------------------------------------*/
/*use temp, clear
quietly keep uniqueid qid671*
drop uniqueid qid671_*_2 qid671_*_6 qid671_*_3 qid671_*_7 

*qid671_*_4

qid671_*_5 qid671_*_1

*need cleaning
forvalues i = 1/12 {
 tab qid671_`i'_5
 tab qid671_`i'_1
}

quietly tostring (qid671*), replace 
quietly reshape long qid671, i(uniqueid) j(job_entry) string 
quietly drop if missing(qid671) | qid671 == "." 

*assigning more specific naming to variables
local vars "employment_type start_month end_month title status start_year end_year" 
replace job_entry = "_job_" + substr(job_entry, 2, length(job_entry)-3) + "_" + word("`vars'", real(substr(job_entry, -1, .))) 
reshape wide
*need to merge changes with main dataset */


*-------*fixing date*-----*
/*Notes: 
-x or y options were rounded down
-for range of months chose average, rounded down
-seasons were transfered to a month range based on meteorological seasons {spring: mar-may summer: jun-aug fall: sep-nov winter: dec-feb} and then the above rule applied so spring=apr summer=jul fall=oct winter=jan
*/
use temp, clear 
quietly keep uniqueid qid671_*_2 qid671_*_6 qid671_*_3 qid671_*_7

* fixing specific errors
replace qid671_1_2 = "aug" if qid671_1_2 == "15-Aug"
replace qid671_1_3 = "may" if qid671_1_3 == "19-May"
replace qid671_1_3 = "present" if qid671_1_3 == "stlll working"
replace qid671_1_3 = "feb" if strlower(qid671_1_3) == "february or march"
replace qid671_1_6 = "2010" if qid671_1_6 == "prior to 2010"
replace qid671_1_6 = "sep" if qid671_1_6 == "setp" 
replace qid671_1_7 = "2021" if qid671_1_7 == "2121"
replace qid671_2_2 = "jun" if qid671_2_2 == "jume"
replace qid671_2_2 = "feb" if strlower(qid671_2_2) == "december-april"
replace qid671_2_3 = "feb" if strlower(qid671_2_3) == "december-april"
replace qid671_2_3 = "jan" if strlower(qid671_2_3) == "january or february"
replace qid671_2_6 = "2005" if qid671_2_6 == "2105"
replace qid671_2_6 = "2008" if qid671_2_6 == "2108"
replace qid671_2_7 = "2013" if qid671_2_7 == "20113"
replace qid671_2_7 = "2017" if qid671_2_7 == "2017 or 2018"
replace qid671_2_7 = "2020" if qid671_2_3 == "to 2020"
replace qid671_3_2 = "oct" if strlower(qid671_3_2) == "fall"
replace qid671_3_2 = "jul" if strlower(qid671_3_2) == "summer"
replace qid671_3_2 = "jan" if strlower(qid671_3_2) == "january or february"
replace qid671_3_3 = "jan" if strlower(qid671_3_3) == "january-february"
replace qid671_3_3 = "may" if strlower(qid671_3_3) == "15-may" | strlower(qid671_3_3) == "may or june"
replace qid671_3_3 = "may" if qid671_3_3 == "graduating in spring" //specific case (general rule not applied) because most graduations take place in may
replace qid671_3_7 = "2020" if qid671_3_3 == "until the pandemic" //same as below cited reason for change
replace qid671_3_3 = "mar" if qid671_3_3 == "until the pandemic" // "During March 2020, national, state, and local public health responses also intensified and adapted, augmenting case detection, contact tracing, and quarantine with targeted layered community mitigation measures." https://www.cdc.gov/mmwr/volumes/69/wr/mm6918e2.htm
replace qid671_3_7 = "2021" if qid671_3_7 == "graduating in 2021"
replace qid671_4_2 = "jan" if strpos(strlower(qid671_4_2), "january") != 0
replace qid671_4_3 = "oct" if strlower(qid671_4_3) == "fall"
replace qid671_4_3 = "mar" if qid671_4_3 == " until march"
replace qid671_5_2 = "jan" if strlower(qid671_5_2) == "winter"
replace qid671_5_3 = "jan" if strpos(strlower(qid671_5_3), "january") != 0
replace qid671_5_7 = "2003" if qid671_5_7 == "2103"
replace qid671_5_7 = "2002" if qid671_5_7 == "2022"


forvalues j = 1/12 {

	* making all "present" type responses the same
	quietly tostring qid671_`j'_3 qid671_`j'_7, replace
	replace qid671_`j'_3 = strlower(qid671_`j'_3)
	quietly replace qid671_`j'_3 = "present" if strpos(strlower(qid671_`j'_3), "current") != 0 | strpos(strlower(qid671_`j'_3), "still") != 0 | strpos(strlower(qid671_`j'_3), "present") != 0 | strpos(strlower(qid671_`j'_3), "continu") != 0 | strpos(strlower(qid671_`j'_3), "there") != 0 
	
	quietly replace qid671_`j'_7 = qid671_`j'_3 if qid671_`j'_3 == "present"
	
	quietly replace qid671_`j'_7 = "present" if strpos(strlower(qid671_`j'_7), "current") != 0 | strpos(strlower(qid671_`j'_7), "still") != 0 | strpos(strlower(qid671_`j'_7), "present") != 0 | strpos(strlower(qid671_`j'_7), "continu") != 0 | strpos(strlower(qid671_`j'_7), "there") != 0
	
	local mon "2 3"
	local year "6 7"
	local n : word count `mon'

	forvalues l = 1/`n' {
		local a : word `l' of `mon'
		local b : word `l' of `year'
		
		*fixing month year entry swaps 
		quietly tostring qid671_`j'_`b' , replace
		quietly replace qid671_`j'_`b' = "" if qid671_`j'_`b' == "."
		quietly gen tempq = qid671_`j'_`a' if strlen(qid671_`j'_`a') == 4 & missing(real(qid671_`j'_`a')) == 0 
		quietly replace qid671_`j'_`a' = qid671_`j'_`b' if strlen(qid671_`j'_`a') == 4 & missing(real(qid671_`j'_`a')) == 0 
		quietly replace qid671_`j'_`b' = tempq if missing(tempq) == 0
		drop tempq
	}
	
	forvalues k = 2/3 {
	* making all month entries in same format
		quietly gen pres = qid671_`j'_`k' if qid671_`j'_`k' == "present"
		quietly gen month = strlower(substr(qid671_`j'_`k',1,3)) //creating new variable with just first 3 characters of response to qid671_1_2

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
		quietly replace qid671_`j'_`k' = month
		quietly replace qid671_`j'_`k' = pres if missing(pres) == 0
		drop tempq month pres
	}
	
	* getting rid of responses that aren't years or present
	forvalues k = 6/7 {
		quietly replace qid671_`j'_`k' = "" if strlen(qid671_`j'_`k') != 4 & qid671_`j'_`k' != "present"
		quietly replace qid671_`j'_`k' = "" if missing(real(qid671_`j'_`k')) == 1 & qid671_`j'_`k' != "present" 
		}
}

/*
forvalues j = 1/12 {
	tab qid671_`j'_2
	tab qid671_`j'_6
	tab qid671_`j'_3
	tab qid671_`j'_7
	}
*/
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

****************************************************

/*----------------------------------------------------------------*/
* child_birthday - standardize date and convert to stata data format
/*----------------------------------------------------------------*/
use temp, clear
keep uniqueid child_birthday
replace child_birthday = subinstr(child_birthday, "-", "/",.) 
gen birthday = date(child_birthday, "DMY")
replace birthday = date(substr(child_birthday, 1, strlen(child_birthday)-2) + "20" + substr(child_birthday, -2,.), "DMY") if birthday == .
format birthday %d
drop child_birthday
rename birthday child_birthday
/*----------------------------------------------------------------*/

*****qid96*****
rename q2_qid96_1 qid96_2 //clean already
***************

/******LIST OF QUESTIONS THAT NEED CLEANING*****
use temp, clear

MONEY/HOURS VALUES:
	qid1535_1 qid85_1 qid736_1 qid1560_1 qid737_1 qid96_1 q2_qid96_1 qid737_1

DATES:
	***number of months/years* 
keep uniqueid q875_1 q875_5 qid87_1 qid87_2 qid97_1 qid97_2 q2_qid97_2
	***start-end month/year* 
		qid736_2 qid736_3 
	***dd/mm
keep uniqueid q1738_1 q1738_2 q1740_1 q1740_2 q1742_1 q1742_2

FREE RESPONSE:
	qid671_*_5 qid671_*_1
	
OTHER:
	qid92 (if missing check if qid91 =="no", if so change to 0)
	q1736 depends on q1735 and q886 (q1736* are dates)
***CHECKED QUESTIONS UP TO AND INCLUDING q1743
	**only checked questions with more than one obs. (569 variables)
 
****************************************************/

***Cleaning qid736_2 and qid736_3 ***STILL WORKING ON IT*********/ 

use temp, clear
quietly keep uniqueid qid736_2 qid736_3

// Format for method of seperating out month and year

gen month = strlower(substr(qid736_2,1,3))
gen year = substr(qid736_2,-4,.)
gen m/y = month + "/" + year

// Other method of directly replacing month and year
gen qid736_new = strlower(substr(qid736_2,1,3)) + substr(qid736_2, -4,.) 
** In the end would just replace qid736 directly

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
