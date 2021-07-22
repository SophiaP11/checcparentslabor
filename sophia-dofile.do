/* -----------------------------------------------------------------------------
PROJECT: CHECC Parents Labor Supply
TOPIC: CLEANING DATASET 
AUTHOR: Sophia
DATE CREATED: 30/06/2021
LAST MODIFIED: 21/07/2021 

NOTES: 

------------------------------------------------------------------------------*/

/*----------------------------------------------------------------------------*/
						*--------* BASIC SETUP *-------*
/*----------------------------------------------------------------------------*/

clear all 
ssc install nmissing 
set maxvar 30000 

* creating personal pathway to data file
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

* Importing data
import delimited "$path/Final_Survey 2_Wave_3_Single_or_Multiple_June 30, 2021_12.52.csv", bindquote(strict) maxquotedrows(50000) varnames(1) clear
 
if "`c(username)'"=="jonathanlambrinos" {
	drop if inlist(_n, 1, 2)
}

/*----------------------------------------------------------------------------*/
						*-------* DATA CLEANING *-------*
/*----------------------------------------------------------------------------*/

* creating a temp file to manipulate data and test code
save temp, replace
use temp, clear

* dropping incomplete surveys
drop if progress != 100

* droping empty variables
quietly nmissing, min(_all) piasm trim " "
quietly drop `r(varlist)'

* getting rid of starting _ from variable names
rename _* *

* renaming variables that start with v as their label (which contains qid)
local vnames "v*" 
foreach v of varlist `vnames' { 
	local x: variable label `v' 
	local y= strlower("`x'") 
rename `v' q`y' //renaming v variables to the lowercase label with a q in front
}

* generating key for potential merging
local obs = _N
numlist "1/`obs'", ascending 
egen uniqueid = fill(`r(numlist)') //creating unique numbering for each observation
order uniqueid, first 

save temp, replace 

/*----------------------------------------------------------------------------*/
					*---------*  EXPERIMENTING  *---------*
/*----------------------------------------------------------------------------*/

/*NOTES:
could possibly drop qid673 qid681 double_child1 missingf1name1 missingf1email1 missingf1phone1 test 
*/
use temp, clear

/*-------------------------------------------------*/
* q875* - standardize responses to match simple numeric format
/*-------------------------------------------------*/
use temp, clear

keep uniqueid enddate q875*

replace q875_1 = "2.5" if strtrim(strlower(q875_1)) == "2 1/2"
*replace q875_1 = "march" if strpos(strlower(q875_1), "march") != 0
replace q875_1 = "3" if q875_1 == "3 weeks"
replace q875_1 = ".5" if strtrim(strlower(q875_1)) == "12 1/2 months" //obs 23 assuming they meant a year and half a month
replace q875_5 = "1" if q875_5 == "1 and half" //obs 23 based on previous, assuming they meant a year and half a month
replace q875_1 = "6" if strtrim(strlower(q875_1)) == "june"
replace q875_1 = "6" if inlist(strtrim(strlower(q875_1)), "july", "june")
replace q875_1 = "0" if strtrim(strlower(q875_1)) == "march"
replace q875_1 = "3" if strtrim(strlower(q875_1)) == "march 31st"

destring q875_1 q875_5, replace force

replace q875_5 = real(substr(enddate, strrpos(enddate,"/")+1, 4))-q875_5 if inlist(q875_5, 2007, 2008, 2016, 2017, 2020, 2021)

/*-------------------------------------------------*/
 
  /*-------------------------------------------------*/
* qid87*- standardize responses to match simple numeric format
/*-------------------------------------------------*/
use temp, clear

keep uniqueid enddate qid87*

replace qid87_1 = "2" if strtrim(strlower(qid87_1)) == "august"
replace qid87_1 = "1" if strtrim(strlower(qid87_1)) == "november"
replace qid87_1 = "4" if strtrim(strlower(qid87_1)) == "9-aug"
replace qid87_1 = "11" if strtrim(strlower(qid87_1)) == "feb"
replace qid87_1 = "5" if strtrim(strlower(qid87_1)) == "10-aug"
replace qid87_1 = "8" if strtrim(strlower(qid87_1)) == "may" | strtrim(strlower(qid87_1)) == "september"
replace qid87_1 = "0" if strtrim(strlower(qid87_1)) == "2 days"

destring qid87_1 qid87_2, replace force

replace qid87_2 = real(substr(enddate, strrpos(enddate,"/")+1, 4))-qid87_2 if inlist(qid87_2, 2001, 2011, 2013, 2014, 2017, 2018, 2019, 2020)

 /*-------------------------------------------------*/
 
 /*-------------------------------------------------*/
* qid83*- standardizing similar responses
/*-------------------------------------------------*/
use temp, clear

keep uniqueid qid83

replace qid83 = strtrim(strlower(qid83))
/*-------------------------------------------------*/
 
/*-------------------------------------------------*/
* qid671 - standardize free responses and dates
/*-------------------------------------------------*/
use temp, clear
quietly keep uniqueid qid671*
drop qid671_*_2 qid671_*_6 qid671_*_3 qid671_*_7 qid671_*_4

*---* fixing qid671_*_1 *---*
gen qid671_12_1 = ""

* making all responses either part time, full time, or blank
forvalues i = 1/12 {
	quietly replace qid671_`i'_1 = "full time" if strpos(strlower(qid671_`i'_1), "full") != 0
	quietly replace qid671_`i'_1 = "part time" if strpos(strlower(qid671_`i'_1), "part") != 0
	quietly replace qid671_`i'_1 = "" if qid671_`i'_1 != "part time" & qid671_`i'_1 != "full time"
}

*---* fixing qid671_`i'_5 *---*

* making all responses either unemployed, working, student or blank
forvalues i = 1/12 {
	replace qid671_`i'_5 = "unemployed" if strpos(strlower(qid671_`i'_5), "unemploy") != 0 | strpos(strlower(qid671_`i'_5), "leave") != 0 | strpos(strlower(qid671_`i'_5), "home") != 0 | strpos(strlower(qid671_`i'_5), "not work") !=0 | strpos(strlower(qid671_`i'_5), "disabled") !=0 | inlist(strtrim(strlower(qid671_`i'_5)), "furloughed", "retired", "on workman's comp due to injury", "notworking", "umemployed", "uneployed") 
	
	replace qid671_`i'_5 = "working" if strpos(strlower(qid671_`i'_5), "work") != 0 | strpos(strlower(qid671_`i'_5), "intern") != 0 | strpos(strlower(qid671_`i'_5), "self employ") != 0 | inlist(strtrim(strlower(qid671_`i'_5)), "first student bus company", "dsp/progressive housing", "restoration", "fifth third bank", "fitness trainer", "customer service", "car warehouse", "teacher", "radio shack") | inlist(strtrim(strlower(qid671_`i'_5)), "real estate", "data analyst/scientist", "employed", "military", "woking")
	
	replace qid671_`i'_5 = "student" if strpos(strlower(qid671_`i'_5), "student") != 0 | strpos(strlower(qid671_`i'_5), "school") != 0
	
	replace qid671_`i'_5 = "" if !inlist(qid671_`i'_5, "student", "working", "unemployed")
	tab qid671_`i'_5
}

quietly tostring (qid671*), replace 
quietly reshape long qid671, i(uniqueid) j(job_entry) string 
quietly drop if missing(qid671) | qid671 == "." 

*assigning more specific naming to variables
local vars "employment_type start_month end_month title status start_year end_year" 
replace job_entry = "_job_" + substr(job_entry, 2, length(job_entry)-3) + "_" + word("`vars'", real(substr(job_entry, -1, .))) 
reshape wide
*need to merge changes with main dataset */


*-------*fixing date columns: qid671_*_2 qid671_*_6 qid671_*_3 qid671_*_7*-----*
/*Notes: 
-x or y options were rounded down
-for range of months chose average, rounded down
-seasons were transfered to a month range based on meteorological seasons {spring: mar-may summer: jun-aug fall: sep-nov winter: dec-feb} and then the above rule applied so spring=apr summer=jul fall=oct winter=jan
--graduating in spring is specific case (general rule not applied) because most graduations take place in may
-"until the pandemic" == mar 2020 because "During March 2020, national, state, and local public health responses also intensified and adapted, augmenting case detection, contact tracing, and quarantine with targeted layered community mitigation measures." https://www.cdc.gov/mmwr/volumes/69/wr/mm6918e2.htm
*/
use temp, clear 
quietly keep uniqueid qid671_*_2 qid671_*_6 qid671_*_3 qid671_*_7

* fixing specific errors
quietly replace qid671_1_2 = "aug" if qid671_1_2 == "15-Aug"
quietly replace qid671_1_3 = "present" if qid671_1_3 == "stlll working"
quietly replace qid671_1_6 = "2010" if qid671_1_6 == "prior to 2010"
quietly replace qid671_1_6 = "sep" if qid671_1_6 == "setp" 
quietly replace qid671_2_6 = "2005" if qid671_2_6 == "2105"
quietly replace qid671_2_6 = "2008" if qid671_2_6 == "2108"
quietly replace qid671_2_7 = "2013" if qid671_2_7 == "20113"
quietly replace qid671_2_7 = "2017" if qid671_2_7 == "2017 or 2018"
quietly replace qid671_5_7 = "2003" if qid671_5_7 == "2103"
quietly replace qid671_5_7 = "2002" if qid671_5_7 == "2022"

forvalues j = 1/12{
	local mon "2 3"
	local year "6 7"
	local n : word count `mon'

	forvalues l = 1/`n' {
		local a : word `l' of `mon'
		local b : word `l' of `year'
		
		quietly tostring qid671_`j'_`b' , replace
		quietly replace qid671_`j'_`b' = "" if qid671_`j'_`b' == "."
		
		quietly replace qid671_`j'_`a' = "may" if inlist(strtrim(strlower(qid671_`j'_`a')), "19-may", "15-may", "may or june", "graduating in spring")
		quietly replace qid671_`j'_`a' = "jan" if inlist(strtrim(strlower(qid671_`j'_`a')), "january or february", "january-february", "winter") | strpos(strlower(qid671_`j'_`a'), "january") !=0
		quietly replace qid671_`j'_`a' = "feb" if inlist(strtrim(strlower(qid671_`j'_`a')), "february or march", "december-april")
		quietly replace qid671_`j'_`a' = "mar" if inlist(strtrim(strlower(qid671_`j'_`a')), "until the pandemic", "until march")
		quietly replace qid671_`j'_`a' = "jun" if inlist(strtrim(strlower(qid671_`j'_`a')), "jume")
		quietly replace qid671_`j'_`a' = "jul" if inlist(strtrim(strlower(qid671_`j'_`a')), "summer")
		quietly replace qid671_`j'_`a' = "oct" if inlist(strtrim(strlower(qid671_`j'_`a')), "fall")

		quietly replace qid671_`j'_`b' = "2021" if inlist(strtrim(strlower(qid671_`j'_`b')), "2121", "graduating in 2021")
		quietly replace qid671_`j'_`b' = "2020" if inlist(strtrim(strlower(qid671_`j'_`a')), "to 2020", "until the pandemic")
		}
}

* general fixing of dates
forvalues j = 1/12 {

	* making all "present" type responses the same
	quietly tostring qid671_`j'_3 qid671_`j'_7, replace
	quietly replace qid671_`j'_3 = strlower(qid671_`j'_3)
	quietly replace qid671_`j'_3 = "present" if strpos(strlower(qid671_`j'_3), "current") != 0 | strpos(strlower(qid671_`j'_3), "still") != 0 | strpos(strlower(qid671_`j'_3), "present") != 0 | strpos(strlower(qid671_`j'_3), "continu") != 0 | strpos(strlower(qid671_`j'_3), "there") != 0 
	quietly replace qid671_`j'_7 = qid671_`j'_3 if qid671_`j'_3 == "present"
	quietly replace qid671_`j'_7 = "present" if strpos(strlower(qid671_`j'_7), "current") != 0 | strpos(strlower(qid671_`j'_7), "still") != 0 | strpos(strlower(qid671_`j'_7), "present") != 0 | strpos(strlower(qid671_`j'_7), "continu") != 0 | strpos(strlower(qid671_`j'_7), "there") != 0
	quietly replace qid671_`j'_3 = qid671_`j'_7 if qid671_`j'_7 == "present"
	
	
	local mon "2 3"
	local year "6 7"
	local n : word count `mon'

	forvalues l = 1/`n' {
		local a : word `l' of `mon'
		local b : word `l' of `year'
		
		*fixing month year entry swaps 
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

/*----------------------------------------------------------------*/
* All yes/no questions
/*----------------------------------------------------------------*/
use temp, clear
keep uniqueid qid22 qid698 qid79 qid80 qid728 qid91 qid99 q1734 q1737 q1739 q1741 q1743
local yes_no_q = "qid22 qid698 qid79 qid80 qid728 qid91 qid99 q1734 q1737 q1739 q1741 q1743"
local n : word count `yes_no_q'
label define label_temp 1 "yes" 0 "no"
forvalues i = 1/`n' {
	local a : word `i' of `yes_no_q'
	replace `a' = "1" if lower(`a') == "yes"
	replace `a' = "0" if lower(`a') == "no"
	destring `a', replace
	label values `a' label_temp
}
/*----------------------------------------------------------------*/
*****qid96*****
use temp, clear
rename q2_qid96_1 qid96_2 //clean already 
*label var qid96_2 //still needs label

keep uniqueid qid96_1 qid96_2

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