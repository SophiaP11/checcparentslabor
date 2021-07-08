


/* -----------------------------------------------------------------------------
PROJECT: CHECC parent's survey 
TOPIC: CLEANING DATASET 
AUTHOR: Louis Auxenfans
DATE CREATED: 06/30/2021
LAST MODIFIED: 06/30/2021 

NOTES: 

- Complete the information here. Always comment your code so that it is replicable! 
------------------------------------------------------------------------------*/

* The star (*) is for commenting one line of the dofile. 

/* 

/* */ 
slash-star star-slash are to begin and end long comments (with more than one line like this one)

To run all the dofile click on the arrow pointing to the right that says "Do". To run only one line, highlight the line you want to run and click the arrow. 

*/

*Increase the number of variables that Stata is able to read: 
clear all 
set maxvar 30000 

***** Installs a code package *****
ssc install nmissing 

*** INSTRUCTIONS ***
* 1. Save the dataset in a folder in your computer. 
* 2. Change the path in the command below to the folder in your computer and run it: 

*import delimited "/Users/louisauxenfans/Desktop/Internship/Final_Survey 2_Wave_3_Single_or_Multiple_June 30, 2021_12.52.csv", varnames(1) bindquote(nobind) clear   

import delimited "/Users/louisauxenfans/Desktop/Internship/Final_Survey 2_Wave_3_Single_or_Multiple_June 30, 2021_12.52.csv", bindquote(strict) clear 

*3.  Useful commands to manipulate and clean the data 

* tab, des, rename, drop, gen, label var, codebook. 

/* If you are stuck try these resources in order 
1. Help from Stata: In the commmand line you can type h or help to get help (example: if you don't understand the command import delimited type h import delimited)
2. Google: Type how to akdvnvkadjnsva in Stata, google always have good answers. 
3. Me :
*/

*** Will drop variables that have all observations missing ****
quietly nmissing, min(_N)
drop `r(varlist)'


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
		


*/ 


*labeling variables


/*
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
label var qid87_1 "Length parent has been working at primary job"
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
*qid95
label var _qid_95 "Main duties at side job"
*qid96
label var _qid96_1 "Hours per week at side job"
*qid97 
label var _qid97_1 "Length parent has been working at side job"
label var _qid97_2 "Length parent has been working at side job"
*qid99
label var _qid99 "whether same hours per week for side job"
*qid1734
label var q1734 "Was primary job affected by Covid"
label var q1735
drop v*
/*

*keep enddate ipaddress progress durationinseconds finished externalreference locationlatitude locationlongitude distributionchannel fid child_name address city phone1 phone2 email2 child_race interview_date location interviewer parent_name otherguardian otherguardian_relation other_child1 livewith_child marital_status parent_education job_title hours_week income income_period otherguardian_job_title otherguardian_hours_week otherguardian_income otherguardian_income_period email3 phone3 phone4 penr_id other_child2 other_adult1 other_adult2 other_child3 other_child4 multiple other_adult3 phone5 adult1 adult2 previous_address child_birthday child_gender district1 other_child_id_1 other_child1_birthday other_child1_gender double_child1 missingf1name1 missingf1email1 other_child_id_2 other_child2_birthday other_child2_gender missingf1phone1 phone21 missingf1address1 f1_home1 phone31 apartment f1email_21 alt_fid3 other_child_id_3 other_child3_birthday other_child3_gender alt_fid2 email21 alt_fid1 zipcode 
