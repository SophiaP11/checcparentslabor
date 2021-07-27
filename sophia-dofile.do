/* -----------------------------------------------------------------------------
PROJECT: CHECC Parents Labor Supply
TOPIC: CLEANING DATASET 
AUTHOR: Sophia
DATE CREATED: 30/06/2021
LAST MODIFIED: 22/07/2021 

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
	cd $path
}
else if "`c(username)'"=="louisauxenfans" {
	gl path "/Users/louisauxenfans/Desktop/Internship/Cleaning CHECC Labor_Supply"
}
else if "`c(username)'"=="jonathanlambrinos" {
	gl path "/Users/jonathanlambrinos/Desktop/CHECC_parentslabor_cleaning"
	cd $path
}

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
drop if progress <= 2
drop if q711 != "Now is fine"

* droping empty/unneeded variables
quietly nmissing, min(_N) piasm trim " "
quietly drop `r(varlist)'
drop q1024

* getting rid of starting _ from variable names
rename _* *

* renaming variables that start with v as their label (which contains qid)
local vnames "v*" 
foreach v of varlist `vnames' { 
	local x: variable label `v' 
	local y= strlower("`x'") 
rename `v' q`y' //renaming v variables to their lowercase label with a q in front
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

/*----------------------------------------------------------------*/
* q875* - standardize responses to match simple numeric format
/*----------------------------------------------------------------*/
use temp, clear
keep uniqueid enddate q875*

* fixing specific errors
replace q875_1 = "2.5" if strtrim(strlower(q875_1)) == "2 1/2"
replace q875_1 = "3" if q875_1 == "3 weeks" | strtrim(strlower(q875_1)) == "march 31st"
replace q875_1 = ".5" if strtrim(strlower(q875_1)) == "12 1/2 months" //obs 23 assuming they meant a year and half a month
replace q875_5 = "1" if q875_5 == "1 and half" //obs 23 based on previous, assuming they meant a year and half a month
replace q875_5 = "0" if strtrim(strlower(q875_1)) == "july"
replace q875_1 = "6" if inlist(strtrim(strlower(q875_1)), "july" "june")
replace q875_1 = "0" if strtrim(strlower(q875_1)) == "march"

* changing to numeric
destring q875_1 q875_5, replace force

* replacing listed year with subtraction of it from enddate year listed
replace q875_5 = real(substr(enddate, strrpos(enddate,"/")+1, 4))-q875_5 if inlist(q875_5, 2007, 2008, 2016, 2017, 2020, 2021)

* making # of years = 0 if # of months is listed, but not # of years
replace q875_5 = 0 if q875_1 >= 0 & missing(q875_5) == 1 & missing(q875_1) == 0
/*----------------------------------------------------------------*/
 
/*----------------------------------------------------------------*/
* qid87*- standardize responses to match simple numeric format - NEEDS TO BE CHECKED
/*----------------------------------------------------------------*/
use temp, clear
keep uniqueid enddate qid87*

* fixing specific errors
replace qid87_1 = "2" if strtrim(strlower(qid87_1)) == "august"
replace qid87_1 = "1" if strtrim(strlower(qid87_1)) == "november"
replace qid87_1 = "4" if strtrim(strlower(qid87_1)) == "9-aug"
replace qid87_2 = "3" if strtrim(strlower(qid87_1)) == "feb"
replace qid87_1 = "11" if strtrim(strlower(qid87_1)) == "feb"
replace qid87_1 = "5" if strtrim(strlower(qid87_1)) == "10-aug"
replace qid87_2 = "1" if strtrim(strlower(qid87_1)) == "september"
replace qid87_2 = "2" if strtrim(strlower(qid87_1)) == "may"
replace qid87_1 = "8" if strtrim(strlower(qid87_1)) == "may" | strtrim(strlower(qid87_1)) == "september"
replace qid87_1 = "0" if strtrim(strlower(qid87_1)) == "2 days"

* changing to numeric
destring qid87_1 qid87_2, replace force

* replacing listed year with subtraction of it from enddate year listed
replace qid87_2 = real(substr(enddate, strrpos(enddate,"/")+1, 4))-qid87_2 if inlist(qid87_2, 2001, 2011, 2013, 2014, 2017, 2018, 2019, 2020)

* making # of years = 0 if # of months is listed, but not # of years
replace qid87_2 = 0 if qid87_1 >= 0 & missing(qid87_1) == 0 & missing( qid87_2) == 1

* subtracting more than a year of months and adding to year column
replace qid87_2 = qid87_2+1 if qid87_1 >= 12  & missing(qid87_1) == 0
replace qid87_1 = qid87_1-12 if qid87_1 >= 12  & missing(qid87_1) == 0
/*----------------------------------------------------------------*/
 
/*----------------------------------------------------------------*/
* qid83 qid84  qid695 *qid94* - standardizing/simplifying free responses
/*----------------------------------------------------------------*/
use temp, clear
keep uniqueid qid83 qid84 qid695 *qid94*

rename q2_qid94 qid94_2
rename qid94 qid94_1

*getting rid of trailing spaces and capitalization
quietly replace qid83 = strtrim(strlower(qid83))
quietly replace qid84 = strtrim(strlower(qid84))
quietly replace qid695 = strlower(strtrim(qid695))
quietly replace qid94_1 = strtrim(strlower(qid94_1))
quietly replace qid94_2 = strtrim(strlower(qid94_2))

*--* qid695 *--*
quietly replace qid695 = "" if inlist(qid695, "11-jul")
quietly replace qid695 = "at&t" if inlist(qid695, "at&t", "atand t", "at and t")
quietly replace qid695 = "addus healthcare" if inlist(qid695, "addis", "addus homecare", "addus health care", "addus home health care", "addus healthhcare" )
quietly replace qid695 = "aunt martha's" if strpos(qid695, "aunt martha") != 0
quietly replace qid695 = "blue cross" if strpos(qid695, "blue cross") != 0
quietly replace qid695 = "chicago public schools" if strpos(qid695, "chicago public schools") != 0
quietly replace qid695 = "dcfs" if strpos(qid695, "dcfs") != 0 | qid695 == "department of child and family services"
quietly replace qid695 = "elisabeth ludeman center" if strpos(qid695, "ludeman") != 0
quietly replace qid695 = "fifth third bank" if strpos(qid695, "fifth third") != 0
quietly replace qid695 = "franciscan health olympia fields" if strpos(qid695, "franciscan health") != 0
quietly replace qid695 = "harvey school district 152" if strpos(qid695, "harvey") != 0 & strpos(qid695, "152") != 0
quietly replace qid695 = "prairie hills school district 144" if strpos(qid695, "prairie hills") != 0 & strpos(qid695, "144") != 0
quietly replace qid695 = "prefer not to answer" if strpos(qid695, "prefer not to") != 0
quietly replace qid695 = "sd 170" if strpos(qid695, "sd") != 0 & strpos(qid695, "170") != 0
quietly replace qid695 = "sd 194" if strpos(qid695, "sd") != 0 & strpos(qid695, "194") != 0
quietly replace qid695 = "self-employed" if strpos(qid695, "self") != 0 & strpos(qid695, "employ") != 0
quietly replace qid695 = "speciality physicians of illinois" if strpos(qid695, "speciality physicians of") != 0
quietly replace qid695 = "state of illinois" if inlist(qid695, "state if il", "state of illinois")
quietly replace qid695 = "university of illinois chicago" if inlist(qid695, "uic", "u of illinois chicago")
/*----------------------------------------------------------------*/
  
/*----------------------------------------------------------------*/
* qid85 - standardize responses to match simple numeric format
/*----------------------------------------------------------------*/
use temp, clear
keep uniqueid qid85_1

rename qid85_1 qid85
quietly replace qid85 = strtrim(strlower(qid85))

*replacing responses with averages if ranges
quietly replace qid85 = "" if missing(real(substr(qid85, -2, 2))) & strpos(qid85, "-") != 0 
quietly replace qid85 = strofreal((real(substr(qid85, 1, 2))+real(substr(qid85, -2, 2)))/2) if strpos(qid85, "-") != 0 | strpos(qid85, "to") != 0 & !missing(real(substr(qid85, -2, 2)))

*getting rid of extra characters assuming only 2 digits at most
quietly replace qid85 = strtrim(substr(qid85, 1, 2)) if missing(real(qid85))

quietly destring qid85 , replace force
/*-------------------------------------------------*/
 
/*----------------------------------------------------------------*/
* *qid96*- standardize responses to match simple numeric format
/*----------------------------------------------------------------*/
use temp, clear
keep uniqueid qid96_1 q2_qid96_1

rename q2_qid96_1 qid96_2 
quietly replace qid96_1 = strtrim(strlower(qid96_1))

*fixing specific errors
replace qid96_1 = "5" if qid96_1 == "2 days per month for total of 20 hours"
replace qid96_1 = "4.5" if strpos(qid96_1, "4-5") != 0
replace qid96_1 = "25" if strpos(qid96_1, "25 hours") != 0

*replacing responses with averages if ranges
quietly replace qid96_1 = "" if missing(real(substr(qid96_1, -2, 2))) & strpos(qid96_1, "-") != 0 
quietly replace qid96_1 = strofreal((real(substr(qid96_1, 1, 2))+real(substr(qid96_1, -2, 2)))/2) if strpos(qid96_1, "-") != 0 | strpos(qid96_1, "to") != 0 & !missing(real(substr(qid96_1, -2, 2)))

quietly destring qid96_1, replace force
/*----------------------------------------------------------------*/
 
/*----------------------------------------------------------------*/
* qid671* - standardize free responses and dates
/*----------------------------------------------------------------*/
use temp, clear
quietly keep uniqueid qid671*

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
*-----*fixing date columns: qid671_*_2 qid671_*_6 qid671_*_3 qid671_*_7*-----*
/*Notes: 
-x or y options were rounded down
-for range of months chose average, rounded down
-seasons were transfered to a month range based on meteorological seasons {spring: mar-may summer: jun-aug fall: sep-nov winter: dec-feb} and then the above rule applied so spring=apr summer=jul fall=oct winter=jan
--graduating in spring is specific case (general rule not applied) because most graduations take place in may
-"until the pandemic" == mar 2020 because "During March 2020, national, state, and local public health responses also intensified and adapted, augmenting case detection, contact tracing, and quarantine with targeted layered community mitigation measures." https://www.cdc.gov/mmwr/volumes/69/wr/mm6918e2.htm
*/
keep uniqueid qid671_*_2 qid671_*_3 qid671_*_6 qid671_*_7

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
	
	* fixing month year entry swaps 
	local mon "2 3"
	local year "6 7"
	local n : word count `mon'

	forvalues l = 1/`n' {
		local a : word `l' of `mon'
		local b : word `l' of `year'
		
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
/*----------------------------------------------------------------*/
 
/*----------------------------------------------------------------*/
* qid680* - standardize free responses and dates
/*----------------------------------------------------------------*/
/*NOTES:
- _1_* = job status (eg. working, unemployed, student)
- _2_* = employment type (eg. part time, full time)
- _3_* = job/degree title (eg. truck driver, factory worker, welder)
- _4_* = start month
- _5_* = start year
- _6_* = end month
- _7_* = end year
- where the * is, is the job number
 */
use temp, clear
quietly keep uniqueid qid680*

*---* fixing qid680_2_* *---*

* creating empty variables to allow for loops (will be dropped after)
forvalues i = 1/7 {
gen qid680_`i'_6 = ""
}

* making all responses either part time, full time, or blank
forvalues i = 1/9 {
	replace qid680_3_`i' = qid680_2_`i' if inlist(qid680_2_`i', "Drafter", "Project Coordinator")
	replace qid680_1_`i' = qid680_2_`i' if strpos(qid680_2_`i', "Student") != 0
	replace qid680_2_`i' = "" if inlist(qid680_2_`i', "Drafter", "Project Coordinator")
	quietly replace qid680_2_`i' = "full time" if strpos(strlower(qid680_2_`i'), "ful") != 0 | strpos(strlower(qid680_2_`i'), "ft")
	quietly replace qid680_2_`i' = "part time" if strpos(strlower(qid680_2_`i'), "part") != 0 | strpos(strlower(qid680_2_`i'), "pt") |strpos(strlower(qid680_2_`i'), "pert")
	quietly replace qid680_2_`i' = "" if qid680_2_`i' != "part time" & qid680_2_`i' != "full time"
	tab qid680_2_`i'
}

*---* fixing qid680_1_* *---*

* making all responses either unemployed, working, student or blank
forvalues i = 1/9 {
	list qid680_1_`i' qid680_4_`i' qid680_5_`i' qid680_6_`i' qid680_7_`i' if strpos(strtrim(strlower(qid680_1_`i')), "april through dec") != 0
	replace qid680_3_`i' = strtrim(substr(qid680_1_`i', strpos(qid680_1_`i', "-")+1, .)) + "-" + qid680_3_`i' if strpos(strtrim(strlower(qid680_1_`i')), "assistant professor") != 0
	//list qid680_3_`i' if strpos(strtrim(strlower(qid680_1_`i')), "assistant professor") != 0
	//tab qid680_1_`i'
	replace qid680_1_`i' = "unemployed" if strpos(strlower(qid680_1_`i'), "unemploy") != 0 | strpos(strlower(qid680_1_`i'), "leave") != 0 | strpos(strlower(qid680_1_`i'), "home") != 0 | strpos(strlower(qid680_1_`i'), "not work") !=0 | strpos(strlower(qid680_1_`i'), "disabled") !=0 | inlist(strtrim(strlower(qid680_1_`i')), "furloughed", "layed off", "retired", "umnemployed") 
	
	replace qid680_1_`i' = "working" if strpos(strlower(qid680_1_`i'), "work") != 0 | strpos(strlower(qid680_1_`i'), "intern") != 0 | strpos(strlower(qid680_1_`i'), "self employ") != 0 | inlist(strtrim(strlower(qid680_1_`i')), "medical dealer", "truck driver", "employed", "military") 
	
	replace qid680_1_`i' = "student" if strpos(strlower(qid680_1_`i'), "student") != 0 | strpos(strlower(qid680_1_`i'), "school") != 0
	
	//replace qid671_`i'_5 = "" if !inlist(qid671_`i'_5, "student", "working", "unemployed")
	tab qid680_1_`i'
}
*-----* fixing date columns: qid680_4* qid680_5* qid680_6* qid680_7* *-----*
/*Notes: 
-x or y options were rounded down
-for range of months chose average, rounded down
-seasons were transfered to a month range based on meteorological seasons {spring: mar-may summer: jun-aug fall: sep-nov winter: dec-feb} and then the above rule applied so spring=apr summer=jul fall=oct winter=jan
--graduating in spring is specific case (general rule not applied) because most graduations take place in may
-"until the pandemic" == mar 2020 because "During March 2020, national, state, and local public health responses also intensified and adapted, augmenting case detection, contact tracing, and quarantine with targeted layered community mitigation measures." https://www.cdc.gov/mmwr/volumes/69/wr/mm6918e2.htm
*/
use temp, clear
keep uniqueid qid680_4* qid680_5* qid680_6* qid680_7*
forvalues i = 1/7 {
gen qid680_`i'_6 = ""
}

* fixing specific errors
replace qid680_5_5 = "1989" if qid680_4_5 == "May-89"
replace qid680_5_1 = "2002" if qid680_5_1 == "2002/2003"
replace qid680_5_3 = "2011" if qid680_5_3 == "6 months in 2011"
replace qid680_5_5 = "2010" if qid680_5_5 == "2011/2010"
replace qid680_7_1 = "2020" if strpos(strtrim(strlower(qid680_6_1)), "pandemic") != 0
replace qid680_6_1 = "mar" if strpos(strtrim(strlower(qid680_6_1)), "pandemic") != 0
replace qid680_7_1 = "2019" if strpos(strtrim(strlower(qid680_7_1)), "2019 (worked this job") != 0

//forvalues j = 1/9{
	//tab1 qid680_4_`j' qid680_5_`j' qid680_6_`j' qid680_7_`j'
//}

* general fixing of dates
forvalues j = 1/9 {
	tab1 qid680_4_`j' qid680_5_`j' qid680_6_`j' qid680_7_`j'
	quietly tostring  qid680_4_`j' qid680_5_`j' qid680_6_`j' qid680_7_`j', replace
	
	* making all "present" type responses the same
	quietly replace qid680_6_`j' = strlower(qid680_6_`j')
	quietly replace qid680_6_`j' = "present" if strpos(strlower(qid680_6_`j'), "current") != 0 | strpos(strlower(qid680_6_`j'), "still") != 0 | strpos(strlower(qid680_6_`j'), "present") != 0 | strpos(strlower(qid680_6_`j'), "continu") != 0 | strpos(strlower(qid680_6_`j'), "there") != 0 
	quietly replace qid680_7_`j' = qid680_6_`j' if qid680_6_`j' == "present"
	quietly replace qid680_7_`j' = "present" if strpos(strlower(qid680_7_`j'), "current") != 0 | strpos(strlower(qid680_7_`j'), "still") != 0 | strpos(strlower(qid680_7_`j'), "present") != 0 | strpos(strlower(qid680_7_`j'), "continu") != 0 | strpos(strlower(qid680_7_`j'), "there") != 0
	quietly replace qid680_6_`j' = qid680_7_`j' if qid680_7_`j' == "present"
	
	
	local mon "4 6"
	local year "5 7"
	local n : word count `mon'
	
	* fixing month year entry swaps 
	forvalues l = 1/`n' {
		local a : word `l' of `mon'
		local b : word `l' of `year'
		
		quietly gen tempq = qid680_`a'_`j' if strlen(qid680_`a'_`j') == 4 & missing(real(qid680_`a'_`j')) == 0 
		quietly replace qid680_`a'_`j' = qid680_`b'_`j' if strlen(qid680_`a'_`j') == 4 & missing(real(qid680_`a'_`j')) == 0 
		quietly replace qid680_`b'_`j' = tempq if missing(tempq) == 0
		drop tempq
	}
	
	forvalues l = 1/`n' {
		local k : word `l' of `mon'
	* making all month entries in same format
		quietly gen pres = qid680_`k'_`j' if qid680_`k'_`j' == "present"
		quietly gen month = strlower(substr(qid680_`k'_`j',1,3)) //creating new variable with just first 3 characters of response

		quietly replace month = usubinstr(month, "0", "", 1) if month != "10" | month != "11"| month != "12"

		local month_code = "jan feb mar apr may jun jul aug sep oct nov dec"
		local p : word count `month_code'

			* replace month with empty if input is invalid
			* replace 1-12 with month values
		quietly gen tempq = ""
		forvalues i = 1/`p' {
			local a : word `i' of `month_code'
			quietly replace month = "`a'" if month == "`i'"
			quietly replace tempq = "`a'" if month == "`a'"
		}
		quietly replace month = tempq
		quietly replace qid680_`k'_`j' = month
		quietly replace qid680_`k'_`j' = pres if missing(pres) == 0
		drop tempq month pres
	}
	
	* getting rid of responses that aren't years or present
	forvalues l = 1/`n' {
		local b : word `l' of `year'
		quietly replace qid680_`b'_`j' = "" if strlen(qid680_`b'_`j') != 4 & qid680_`b'_`j' != "present"
		quietly replace qid680_`b'_`j' = "" if missing(real(qid680_`b'_`j')) == 1 & qid680_`b'_`j' != "present" 
		}
	tab1 qid680_4_`j' qid680_5_`j' qid680_6_`j' qid680_7_`j'
}
/*----------------------------------------------------------------*/

/*----------------------------------------------------------------*/
* All 1-3 response options questions - encode responses
/*----------------------------------------------------------------*/
use temp, clear
/*quietly ds, has(type string)
foreach v in `r(varlist)' {
	tab `v' if strlower(strtrim(`v')) == "yes" | strlower(strtrim(`v')) == "no"
}*/
keep uniqueid q711 qid636 qid24 qid673 qid681 qid131 qid134 qid140 qid690 q801* q813* q814* q1231* q1866

local questions "q711 qid636 qid24 qid673 qid681 qid131 qid134 qid140 qid690 q801* q813* q814* q1231* q1866"
foreach v of varlist `questions' {
	encode `v', generate(`v'_n)
	drop `v'
	rename `v'_n `v'
}
/*----------------------------------------------------------------*/

/*----------------------------------------------------------------*/
*qid109 - convert to numeric
/*----------------------------------------------------------------*/
use temp, clear
keep uniqueid qid109

destring qid109, replace force

/*----------------------------------------------------------------*/
////////////////////////////////////////////////////////////////////
*-/-/-/-/-/-/-/-/-/-/-/-* JONATHAN CLEANING*-/-/-/-/-/-/-/-/-/-/-/-*
////////////////////////////////////////////////////////////////////

/*----------------------------------------------------------------*/
*q1232 -INCOMPLETE
/*----------------------------------------------------------------*/
/*NOTES:
_1 = School Name _10 = School District _11 = School City 
_14 probably = same as previous grade
_15 probably = don't know
_14 and _15 meanings could be swapped
*/
use temp, clear
keep uniqueid q1232*
/*----------------------------------------------------------------*/

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
* Income variables - 
/*----------------------------------------------------------------*/
use temp, clear
keep uniqueid qid15*
local value_col = "qid1535_1 qid1548_1 qid1560_1"
local freq_col = "qid1536 qid1549 qid1561" 
local additional_col = "qid1540 qid1550 qid1562"
local m: word count `freq_col'
local pay_code = "annually bi-weekly hourly monthly weekly daily"
*Assuming working 8 hours a day, 5 days a week, every day
local annual_constant = "1 26 2080 12 52 365"
local n : word count `pay_code'
*Drop every value that is not a pay_code
forvalues i = 1/`m' {
	local b : word `i' of `freq_col'
	gen place_holder = 0
	forvalues j = 1/`n' {
		local a : word `j' of `pay_code'
		replace place_holder = 1 if lower(`b') == "`a'"
	}
	replace `b' = "" if place_holder == 0
	drop place_holder
}
forvalues j = 1/`m'{ 
	local c : word `j' of `value_col'
	local d : word `j' of `freq_col'
	local e : word `j' of `additional_col'
	gen stan_inc_`c' = .
	*remove commas
	replace `c' = subinstr(`c', ",", "",.) 
	replace `c' = subinstr(`c', ".00", "",.) 
	replace `c' = subinstr(`c', " plus", "",.) 
	replace `d' = "Daily" if strpos(`c', "day") | strpos(`e', "daily") | `e' == "flat rate"
	replace `c' = subinstr(`c', " day", "",.) 
	replace `c' = subinstr(`c', "/day", "",.) 
	replace `c' = trim(subinstr(`c', "$", "",.))
	*change the 8-10
	replace `c' = "9000" if `c' == "8-10000"
 
	*convert qid1535_1 to real()
	destring `c', replace force
  
	forvalues i = 1/`n'{
		local b : word `i' of `annual_constant'
		local a : word `i' of `pay_code'
		replace stan_inc_`c' = `b'*`c' if lower(`d') == "`a'"
	}
}
/*----------------------------------------------------------------*/
* All yes/no questions - encode responses
/*----------------------------------------------------------------*/
use temp, clear

keep uniqueid qid22 qid698 qid79 qid80 qid728 qid91 *qid99* q1734 q1737 q1739 q1741 q1743 qid106 qid107 qid729 qid117 *qid125* q1751 q1754 q1756 q1758 q1760 qid132 qid688 qid135 qid139 qid158 qid730 qid149 *qid157* q756 q1791 q1792 q1815 q1833 q1835 q1850 q1867 q1869 q1870 q1874 q1891 q1797 q1896 q2003

local questions "qid22 qid698 qid79 qid80 qid728 qid91 *qid99* q1734 q1737 q1739 q1741 q1743 qid106 qid107 qid729 qid117 *qid125* q1751 q1754 q1756 q1758 q1760 qid132 qid688 qid135 qid139 qid158 qid730 qid149 *qid157* q756 q1791 q1792 q1815 q1833 q1835 q1850 q1867 q1869 q1870 q1874 q1891 q1797 q1896 q2003"
foreach v of varlist `questions' {
	encode `v', generate(`v'_n)
	drop `v'
	rename `v'_n `v'
}
/*----------------------------------------------------------------*/

///////////////////////////////////////////////////////////////////
*-/-/-/-/-/-/-/-/-/-/-/-* LOUIS CLEANING *-/-/-/-/-/-/-/-/-/-/-/-*
///////////////////////////////////////////////////////////////////

/*----------------------------------------------------------------*/
* child_gender - encode responses  (combine with yes/no questions cleaning)
/*----------------------------------------------------------------*/
use temp, clear
keep uniqueid child_gender other_child1_gender other_child2_gender other_child3_gender

replace child_gender = "Female" if child_gender == "F"
replace child_gender = "Male" if child_gender == "M"
local questions "child_gender other_child1_gender other_child2_gender other_child3_gender"
foreach v of varlist `questions' {
	encode `v', generate(`v'_n)
	drop `v'
	rename `v'_n `v'
}
/*----------------------------------------------------------------*/
  
/*----------------------------------------------------------------*/
* qid97*- labeling variable and converting to float format
/*----------------------------------------------------------------*/
use temp, clear
keep uniqueid *qid97*

replace qid97_1 = "2.5" if qid97_1 == "2 1/2" 
destring qid97_1, replace float

label var qid97_2 "Years parent working current SIDE JOB"
label var qid97_1 "Months parent working current SIDE JOB"
label var q2_qid97_2 "Years parent working current 2nd SIDE JOB"
label var q2_qid97_1 "Months parent working current 2nd SIDE JOB"
/*----------------------------------------------------------------*/
  
/*----------------------------------------------------------------*/
* qid737*- standardize responses to match simple numeric format
/*----------------------------------------------------------------*/
use temp, clear
keep uniqueid qid737*

replace qid737_1 = "" if qid737_1 == "Varies" | qid737_1 == "2-Jan" // Ambigious answer for number of hours worked and 2-Jan is a date but unsure if it applies to start or end 
replace qid737_1 = "50" if qid737_1 == "40-60"

destring qid737_1, replace 
/*----------------------------------------------------------------*/

/*----------------------------------------------------------------*/
*qid736*- INCOMPLETE
/*----------------------------------------------------------------*/
/*NOTES:
Question: How many hours per week used to be the job? Additionally, what are the start and end years for when you worked this number of hours per week?
_2 is start month, year of hours per week of primary job 
_3 is end month, year
*/
use temp, clear
keep uniqueid qid736*

replace qid736_1 = "" if qid736_1 == "Seasonal" | qid736_1 == "hours vary every week" 
replace qid736_1 = "30" if qid736_1 == "25 to 35 hours per week"
replace qid736_1 = "40" if qid736_1 == "40 or more"
replace qid736_1 = string((real(substr(qid736_1, 1, 2)) + real(substr(qid736_1, 4, .)))/2) if strpos(qid736_1, "-") > 0

destring qid736_1, replace

********** Now cleaning qid736_2 and qid736_3 *************

** Code is Format for method of seperating out month and year ** 
// Replacing a typing error //
replace qid736_2 = "11, 2020" if qid736_2 == "112,020"
replace qid736_3 = "1, 2021" if qid736_3 == "12,021"

// Replacing months with numbers with 3-letter abbreviation and extracting year for each observation for both qid736_2 and qid736_3 // 
forvalues x = 2/3 {
	// Starting/Ending Month and year of previous hours at primary job 
	gen primary_qid736_`x'_month = strlower(substr(qid736_`x',1,3))
	gen primary_qid736_`x'_year = usubinstr(qid736_`x', "-", "20", 1)
	quietly replace primary_qid736_`x'_year = substr(primary_qid736_`x'_year,-4,.)
	
	// removing prepended zeros in month 
	quietly replace primary_qid736_`x'_month = usubinstr(primary_qid736_`x'_month, "0", "", 1) if primary_qid736_`x'_month != "10" | primary_qid736_`x'_month != "11"| primary_qid736_`x'_month != "12" 
	// Now obtaining the 3-letter abbreviation for months that have numbers
	local month_code = "jan feb mar apr may jun jul aug sep oct nov dec"
	quietly gen temp`x'= ""
	forvalues i = 1/12 {
		local a : word `i' of `month_code'
			quietly replace primary_qid736_`x'_month= "`a'" if primary_qid736_`x'_month == "`i',"
			quietly replace temp = "`a'" if primary_qid736_`x'_month == "`a'"
			
		}
		quietly replace primary_qid736_`x'_month = temp`x'
		drop temp`x' 

}
// Replacing obs. that don't have any value for years 
replace primary_qid736_2_year = "" if primary_qid736_2_year == "arch" | primary_qid736_2_year == "ears" 
/*----------------------------------------------------------------*/
 look at *qid15*  
 
 needs to be cleaned q878* qid113_1 qid115* qid738* *qid122_1 *qid124* qid739* q1222 q879* qid145_1 qid147* qid740* qid689* other_child*_birthday q1233*

/*----------------------------------------------------------------*/
* Clean Questions - seeing what is left to clean
/*----------------------------------------------------------------*/
use temp, clear
drop startdate enddate status ipaddress progress durationinseconds finished recordeddate responseid recipientemail externalreference locationlatitude locationlongitude distributionchannel userlanguage time location interviewer parent_name otherguardian* other_child1 other_child2 other_child3 adult1 adult2 tag2 q_totalduration f1_home1 apartment alt_fid* test  previous_address district1 livewith_child marital_status parent_education job_title hours_week income income_period multiple qid597 q1026 q887 q1228 qid23 qid81* qid82 qid736* other_child_id_* qid92 *qid95 q875* qid87* qid83 qid84 q886 q883 qid108* qid109 qid110 qid696 qid111 qid118 *qid120 qid136 qid137 qid138 q885 qid141 qid142 qid697 qid143 qid741* *qid121 qid695 *qid94* qid85_1 *qid96* double_child1 missingf1name1 missingf1email1 missingf1phone1 qid671* q1232* child_birthday qid22 qid698 q827 fid child_name q1226 address city state zipcode phone* email* child_race interview_date qid79 qid80 qid728 qid91 *qid99* q1734 q1737 q1739 q1741 q1743 qid106 qid107 qid729 qid117 *qid125* q1751 q1754 q1756 q1758 q1760 qid132 qid688 qid135 qid139 qid158 qid730 qid149 *qid157* q756 q1791 q1792 q1815 q1833 q1835 q1850 q1867 q1869 q1870 q1874 q1891 q1797 q1896 q2003 child_gender other_child1_gender other_child2_gender other_child3_gender *qid97* qid737* qid680* q711 qid636 qid24 qid673 qid681 qid131 qid134 qid140 qid690 q801* q813* q814* q1231* q1895 q1898 q2001* q2002 q2005 q2117* q1866 qid15* q17*
/*----------------------------------------------------------------*/



