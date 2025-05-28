*---------------------------------
*   Analysis of PLFS 2022-23
*---------------------------------

* Loading and Preparing Data

clear all
set more off

global dir "G:\plfs\"
cd $dir
use "$dir\extracted\merged.dta", clear

* Defining Labels for General Education Level

destring b23, replace
recode b23 (2/6=2)

label define b23 ///
    1 "Not Literate" ///
    2 "Literate & Upto Primary" ///
    7 "Middle" ///
    8 "Secondary" ///
    10 "Higher Secondary" ///
    11 "Diploma/Certificate Course" ///
    12 "Graduate" ///
    13 "Postgraduate & Above"
label values b23 b23

* Defining Labels for Sector

destring b6, replace
label define b6 1 Rural 2 Urban
label values b6 b6

* Destring Age

destring b21, replace

* Generate Usual Status

destring b33 b44, replace

gen us_status = b33
replace us_status = b44 if (b33>81 & (b44==11 | b44 == 12 | ///
							b44 == 21 | b44 == 31 | ///
							b44 == 41 | b44 == 51))

* Create Indicator for Employed Individual

gen emp = 1 if inlist(us_status, 11, 12, 21, 31, 41, 51)
replace emp = 0 if emp == .

* Create Indicator for Unemployed Individual

gen unemp = 1 if (us_status == 81)
replace unemp = 0 if unemp == .

* Create Indicator for Self-Employment

gen self_emp = 1 if (us_status == 11 | us_status == 12 | us_status == 21)
replace self_emp = 0 if self_emp == .

* Create Indicator for Casual Labourer

gen casual = 1 if (us_status == 41 | us_status == 51)
replace casual = 0 if casual == .

* Create Indicator for Regular Salaried Individual

gen regu = 1 if (us_status == 31)
replace regu = 0 if regu == .

* Create Indicator for an Individual in the Labour Force

gen labforce = 1 if emp == 1 | unemp == 1
replace labforce = 0 if labforce == .

gen working_age = 1 if b21 >= 15 & b21 < 65
gen emp_working_age = 1 if emp == 1 & b21 >= 15 & b21 < 65

destring b135, replace
gen lwage = log(b135)

destring b21, replace
gen agesq = b21 * b21

* Marital Status

destring b22, replace
gen maritalst = b22 if b22 != 3 & b22 != 4
label define maritalst 1 "Unmarried" 2 "Married"
label values maritalst maritalst

* Defining Labels for Gender

destring b20, replace
gen gender = b20 if b20 != 3
label define gender 1 "Male" 2 "Female"
label values gender gender
drop if missing(gender)

* Marital Status * Gender - Interaction Term

gen maritalst_gender = maritalst * gender

* Social Groups

destring a25, replace
label define a25 1 SC 2 ST 3 OBC 4 Others
label values a25 a25

* Religion

destring a24, replace
recode a24 (5/6 = 5) (7/9 = 6)
label define a24 1 "Hinduism" 2 "Islam" 3 "Christianity" 4 "Sikhism" 5 "Buddhism/Jainism" 6 "Others"
label values a24 a24

* Age Groups

gen age_cat = b21 if b21 >= 15 & b21 <= 65
recode age_cat (15/25=1) (26/35=2) (36/45=3) (46/55=4) (56/65=5)
label define age_cat 1 "15-25" 2 "26-35" 3 "36-45" 4 "46-55" 5 "56-65"
label values age_cat age_cat

* Sector

destring a6, replace
label define a6 1 "Rural" 2 "Urban"
label values a6 a6

* State Labels

destring a7, replace
label define a7 ///
1 "Jammu & Kashmir" ///
2 "Himachal Pradesh" ///
3 "Punjab" ///
4 "Chandigarh" ///
5 "Uttarakhand" ///
6 "Haryana" ///
7 "Delhi" ///
8 "Rajasthan" ///
9 "Uttar Pradesh" ///
10 "Bihar" ///
11 "Sikkim" ///
12 "Arunachal Pradesh" ///
13 "Nagaland" ///
14 "Manipur" ///
15 "Mizoram" ///
16 "Tripura" ///
17 "Meghalaya" ///
18 "Assam" ///
19 "West Bengal" ///
20 "Jharkhand" ///
21 "Odisha" ///
22 "Chhattisgarh" ///
23 "Madhya Pradesh" ///
24 "Gujarat" ///
25 "D & N. Haveli & Daman & Diu" ///
27 "Maharashtra" ///
28 "Andhra Pradesh" ///
29 "Karnataka" ///
30 "Goa" ///
31 "Lakshadweep" ///
32 "Kerala" ///
33 "Tamilnadu" ///
34 "Puduchery" ///
35 "Andaman & N. Island" ///
36 "Telangana" ///
37 "Ladakh"
label values a7 a7

* Dividing States into Regions

decode a7, gen(state_name)
gen region = ""

replace region = "North" if inlist(state_name, "Haryana", "Punjab", "Rajasthan", "Himachal Pradesh")
replace region = "North-East" if inlist(state_name, "Arunachal Pradesh", "Assam", "Manipur", "Meghalaya", "Mizoram", "Nagaland", "Sikkim", "Tripura")
replace region = "East" if inlist(state_name, "Bihar", "Jharkhand", "Odisha", "West Bengal")
replace region = "Central" if inlist(state_name, "Chhattisgarh", "Madhya Pradesh", "Uttar Pradesh", "Uttarakhand")
replace region = "West" if inlist(state_name, "Goa", "Gujarat", "Maharashtra")
replace region = "South" if inlist(state_name, "Andhra Pradesh", "Karnataka", "Kerala", "Tamil Nadu", "Telangana")

* LFPR by States

gen lfpr = (labforce / working_age) * 100
preserve
collapse (mean) lfpr, by(a7)
list a7 lfpr, sep(0)
restore

* Gender Gap in LFPR by Region and States

preserve 
collapse (mean) lfpr, by(region a7 gender)  
reshape wide lfpr, i(a7 region) j(gender)  
gen gap = lfpr1 - lfpr2
export delimited using "gender_gap_lfpr.csv", replace
restore

* Workforce Distribution by Gender and Sector

gen emp_type = .
replace emp_type = 1 if casual == 1
replace emp_type = 2 if regu == 1
replace emp_type = 3 if self_emp == 1

label define emp_type ///
	1 "Casual" ///
	2 "Regular Salaried" ///
	3 "Self Employed"
label values emp_type emp_type

table ( gender ) ( a6 emp_type ) () [pweight = weight], ///
statistic(percent, across(emp_type))

* Share of Regular Salaried Workers by Region and State

preserve
keep if emp == 1
gen is_regu = emp_type == 2
gen weight_regu = is_regu * weight
gen weight_emp = weight
collapse (sum) weight_regu weight_emp, by(region state_name gender)
gen regu_share = (weight_regu / weight_emp) * 100
keep region state_name gender regu_share
list region state_name gender regu_share, sepby(region)
reshape wide regu_share, i(state_name region) j(gender)
export delimited using "regularworkers.csv", replace
restore

* Distribution of Workers by State

preserve
collapse (sum) ///
    casual_w = casual ///
    regu_w = regu ///
    self_emp_w = self_emp ///
    total_emp = emp [pweight = weight], ///
    by(state_name)

gen casual_pct     = (casual_w / total_emp) * 100
gen regular_pct    = (regu_w / total_emp) * 100
gen self_emp_pct   = (self_emp_w / total_emp) * 100

keep state_name casual_pct regular_pct self_emp_pct

rename casual_pct Casual
rename regular_pct Regular_Salaried
rename self_emp_pct Self_Employed

export delimited using "statewise_emp_type_pct.csv", replace
restore

* Unemployment Rate by State

preserve
keep if working_age == 1
keep if labforce == 1
collapse (sum) ///
	unemp_total = unemp ///
	labforce_total = labforce [pweight = weight], ///
	by(state_name)
gen unemp_rate = (unemp_total / labforce_total) * 100
keep state_name unemp_rate
export delimited using "unemployment_rate_by_state.csv", replace
restore
