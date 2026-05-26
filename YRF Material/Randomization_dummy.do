/******************************************************************************************************************
	*Title: ECC Randomizaiton
	*Created by: Johirul Islam
	*Created on: STATA17
	*Last Modified on: 06/05/24
	*Last Modified by: Johirul Islam 
	*Purpose : Cluster level Randomization  
	*Edits 
		- [MM/DD/YY] - [editor's initials]: Added / Changed....
		
	Note: Initial- Seed for cluster randomization: 989897 and for individual = 256648	
	*****************************************************************************************************************/

		clear all
		clear matrix 
		*Directories
		**Appropriate directory based on user
		
		if "`c(username)'"== "User" {
			global base_dir "K:"
		}	
		
			if "`c(username)'"== "MJI" {
			global base_dir "C:\Users\MJI\Dropbox\BIGD Works\Care Model Brac BD" //mji's dir 
			
		}
			
			else if "`c(username)'"=="Personal" { /*Munshi*/			
			global base_dir "D:\Dropbox\Care Model Brac BD"
		}	
		
		
		*Baseline directories
		global data_dir				${base_dir}/4. Clean data
		global baseline_dir 		${data_dir}/Baseline
		global mother_base_dta		${baseline_dir}/Mothers
		global ent_base_dta			${baseline_dir}/Entrepreneurs
		
		global output				${base_dir}/5. Output
		global baseline_table 		${output}/01_Baseline/01_Tables
		global baseline_figure		${output}/01_Baseline/02_Figures
		
	
	*current date 
	local c_date=c(current_date)
		
		
		
	*use "Mother_Baseline_clean_20240606", clear
	
	use "Mother_Baseline_clean_20240607", clear
	
	*correct cluster ID by adding 0 before single-digit
	clonevar new_cluster1 = new_cluster
	replace new_cluster1 = "01" if new_cluster1=="1"
	replace new_cluster1 = "02" if new_cluster1=="2"
	replace new_cluster1 = "03" if new_cluster1=="3"
	replace new_cluster1 = "04" if new_cluster1=="4"
	replace new_cluster1 = "05" if new_cluster1=="5"
	replace new_cluster1 = "06" if new_cluster1=="6"
	replace new_cluster1 = "07" if new_cluster1=="7"
	replace new_cluster1 = "08" if new_cluster1=="8"
	replace new_cluster1 = "09" if new_cluster1=="9"
	
	
	
	egen cls_id = concat(zone_code new_cluster1), punct("_")
	

		
	drop if consent==0 /* 1265 obs deleted*/
	drop if selected_ch_age==8|selected_ch_age==. /*18 observations deleted*/
	

	preserve
	
	bys cls_id: egen tot = total(consent)
	collapse (first) tot zone_code, by(cls_id)
	
	drop if cls_id=="3_68" /*this cluster has 10 eligible mothers*/
	
	/*Distribution of clusters
	tot	Freq.	
	14	2	
	15	10	
	16	176	
	17	23	
	18	8	
	Total 219 clusters included in randomization
	*/

	
	la var tot "Total number of mothers in each cluster"
	
	la define zn 1 "Dhaka" 2 "Savar" ///
				3 "Gazipur" 4 "Tongi"
	la value zone_code zn
	tab zone_code
	
	
	**#cluster level randomization: 150 treatment and the rest control
	
	set seed 1234
	sort cls_id, stable //cluster id sorting
	
	gen rand=uniform()

	sort zone_code rand, stable
	bys zone_code: gen strata_index = _n 

	bys zone_code: egen tot_st = max(strata_index)
	
	gen treatment = 0
	replace treatment=1 if strata_index <= 37 & (zone_code==2|zone_code==3) /*Savar and Gazipur*/
	replace treatment=1 if strata_index <= 38 & (zone_code==1|zone_code==4) /*Dhaka and Tongi */
	
	la define treat 1 "Treatment" 0 "Control"
	la value treatment treat
	
	tab treatment zone_code
	
	tempfile cluster_data
	save `cluster_data'
	
	restore
	
	/*
	
	**# Entrepreneurs data merge with treatment assignment
	preserve
	
	
	use "C:\Users\MJI\Dropbox\BIGD Works\BIGD_Misc\Entrepreneur_Baseline_clean_24 Jun 2024.dta", clear 
	
	merge m:1 cls_id using `cluster_data', keepusing(treatment)
	
	
	
	keep if _merge==3 | _merge==2
	drop _merge
	
	save "Entrepreneur_Baseline_with_treatment.dta", replace
	
	restore

	*/
	
	**#Individual level randomization: T2=4, T3=4, T1=Rest (6-10 obs)
	
	merge m:1 cls_id using `cluster_data', keepusing(treatment tot)
	
	
	keep if _merge==3
	drop _merge
	

	
	
	preserve
	
	keep if treatment==1
	
	set seed 1234
	sort cls_id id, stable
	gen rand=uniform()
	
	sort cls_id rand, stable
	bys cls_id: gen rank = _n 
	
	recode rank (1/4=1 "Cash") ///
				(5/8=2 "Fees") ///
				(9/18=3 "Only info"), gen(ind_treatment)
				
	
	tempfile ind_data
	save `ind_data'
	
	
	restore
	
	merge 1:1 id using `ind_data', keepusing(ind_treatment)
	drop _merge
	
	la var treatment "Cluster Treatment status"
	la var ind_treatment "Individual treatment status"
	replace ind_treatment = 4 if treatment==0
	
	la define ind_treatment 4 "Control", modify
	

	
	
	**# Balance table cleaning
	
	*child age
	fre selected_ch_age 
	la var selected_ch_age "Child's age"
	
	*mothers age 
	fre b6_1
	la var b6_1 "Mother's age"
	
	
	*res marriage 
	recode b8_1 (3=1 "Married") (2 4/6=0 "Divorced/Seprated/Widowed/Abandoned"), gen(res_marr_st)
	la var res_marr_st "Mother's marital status [1=Currently married]"
	
	*mother's edu 
	recode b11_1 (5/14=1 "Class 5 and Above") (0/4 15 50 51=0 "Below class five"), gen(mother_edu)
	la var mother_edu "Mother's education [1= Class five and above]"
	
	*food security-year
	recode d11 (1/2=0 "Not available") (3/4=1 "Available"), gen(food_yr)
	la var food_yr "HH food availbility in the last year [1=Available]"
	
	*food security-month
	fre d12
	recode d12 (1=1 "Available") (2/4=0 "Not available"), gen(food_month)
	la var food_month "HH food availbility in the last month [1=Available]"
	
	*Long-term sickness of mother
	fre d21 
	la var d21 "Mother has long term sickness [1=Yes]"
	
	*Age at the time of first child birth
	fre d25
	la var d25 "Mother's age at the time of first child birth"
	
	recode d25 (15/18=1 "Below or at 18") (19/36=0 "Above 18"), gen(mother_preg)
	la var mother_preg "First child bearing [1=Below or at the age of 18]"
	
	*Amount willing to pay for daycare
	fre e111
	recode e111 (-666=.)
	
	*hh income
	fre i8
	
	winsor2 i8, cuts(1 99)
	fre i8_w
	
	*hh_per capita inc
	gen hh_pc_inc = i8_w/totmem
	la var hh_pc_inc "HH per capita income"
	
	*hh total member under 9
	fre hhmm9
	destring hhmm9, replace
	la var hhmm9 "HH Total number of members under age 9"

	*hh total member under 15
	fre hhmm_15
	destring hhmm_15, replace
	la var hhmm_15 "HH Total number of members under age 15"
	
	*hh total member 
	fre totmem
	
	*hh total monthly expenditure 
	egen hh_exp = rowtotal(i21 i22 i23 i24 i25 i26 i27 i28 i29 i210 i211 i212 i213 i214 i215 i216 i217 i218 i219 i220)
	
	la var hh_exp "HH monthly expenditure"
	
	winsor2 hh_exp, cuts(1 99)
	fre hh_exp_w
	
	*have savings 
	fre j1
	
	*have loan
	fre j5
	
	*asset index
	factor k_item_1 k_item_2 k_item_3 k_item_4 k_item_5 k_item_6 k_item_7 k_item_8 k_item_9 k_item_10 k_item_11 k_item_12 k_item_13, pcf
	
	
	predict asset_index 
	xtile asset_index_cat = asset_index, n(2) //based on median
	la var asset_index_cat "Asset Index Category [1= Non-Poor]"
	recode asset_index_cat (1=0) (2=1)
	
	
	*involve in any income generating activity
	recode b13_1 (26 28 27 = 0 "Not employed") ///
				(1/25 555 = 1 "Employed"), gen(occu_res)
	la var occu_res "Respondent's involve in any income generating activities [1=Yes]"
	
	
	recode c11 (1/3 7/9= 1 "Currently employed") (6=2 "Stopped working") (4/5 = 3 "Never worked"), gen(current_emp)
	
	
	cd "C:\Users\Lenovo\Dropbox\BIGD Works\BIGD_Misc"
	
	merge 1:1 id using "ECC_Census_2024_ 24 Apr 2024_sample", keepusing(qd91 qd91a qd92)
	keep if _merge==3
	drop _merge 
	
	

	
	**#balance table 
	
	des selected_ch_age b6_1 res_marr_st occu_res mother_edu  food_yr food_month d21 d25 mother_preg e111 i8_w hh_pc_inc hhmm9 hhmm_15 totmem hh_exp_w j1 j5 asset_index_cat
	
	*destring cluster id
	encode cls_id, gen(cls_id_float)
	
	*joint significant f test: balance checks across all treatment types
		iebaltab selected_ch_age b6_1 res_marr_st occu_res mother_edu food_yr food_month d21 d25 mother_preg e111 i8_w hh_pc_inc hhmm9 hhmm_15 totmem hh_exp_w j1 j5 asset_index_cat, grpvar(ind_treatment) feqtest savexlsx("ecc_overall_balance`c_date'.xlsx") replace vce(cluster cls_id_float) rowvarlabels fixedeffect(zone_code)
		
	ex
	
		
	*make uniform cluster name 
	preserve
	collapse (first) cls_name, by(cls_id)
	clonevar cluster_name = cls_name
	
	tempfile cls_name
	save `cls_name'
	restore
	
	merge m:1 cls_id using `cls_name', keepusing(cluster_name)
	drop _merge
	
	
	
	

	
	
	preserve
	*make the same uniform cluster id in entr data 
	
	use "$ent_base_dta/Entrepreneur_Baseline_clean_24 Jun 2024", clear 
	drop cls_id new_cluster1 tot_ent 
	
	clonevar new_cluster1 = new_cluster
	replace new_cluster1 = "01" if new_cluster1=="1"
	replace new_cluster1 = "02" if new_cluster1=="2"
	replace new_cluster1 = "03" if new_cluster1=="3"
	replace new_cluster1 = "04" if new_cluster1=="4"
	replace new_cluster1 = "05" if new_cluster1=="5"
	replace new_cluster1 = "06" if new_cluster1=="6"
	replace new_cluster1 = "07" if new_cluster1=="7"
	replace new_cluster1 = "08" if new_cluster1=="8"
	replace new_cluster1 = "09" if new_cluster1=="9"

	egen cls_id = concat(zone_code new_cluster1), punct("_")

	*correct entr rank 
	bys cls_id: egen tot_ent = total(ent_rank)
	replace ent_rank=. if inlist(tot_ent, 0,1,2,4)
	
	save "$ent_base_dta/Entrepreneur_Baseline_clean_24 Jun 2024", replace
	restore
	
	
	
	
	preserve
	
	**# Export cluster level list
	collapse (first) zone_code cluster_name q8 treatment, by(cls_id)
		
	
	merge 1:m cls_id using "$ent_base_dta/Entrepreneur_Baseline_clean_24 Jun 2024.dta", keepusing(cls_add entr_name ent_rank)
	drop if _merge==2 //drop unselected cluster entrepreneur
	drop _merge
	

	sort zone_code cls_id ent_rank entr_name, stable
	order zone_code cls_id cluster_name entr_name ent_rank cls_add q8
	
	la define zn1 1 "Dhaka" 2 "Savar" 3 "Gazipur" 4 "Tongi"
	la value zone_code zn1
	
	la define treat1 1 "Treatment" 0 "Control"
	la value treatment treat1
	drop if treatment==0
	
	export excel using "$data_dir/ECC_cluster_and_entrepreneur_treatment_list.xlsx", firstrow(variables) replace 
	
	restore 
	
	
	
	preserve
	*entrepreneur info 
	
	use "$ent_base_dta/Entrepreneur_Baseline_clean_24 Jun 2024", clear 
	
	keep cls_id cls_add entr_name entr_contact ent_rank
	
	sort cls_id ent_rank entr_name, stable
	bys cls_id: gen sl = _n 
	drop ent_rank
	
	reshape wide cls_add entr_name entr_contact, i(cls_id) j(sl)
	
	tempfile ent_data 
	
	save `ent_data'

	restore	

	
	
	
	
	**#Export mother list for mail merge
	
	preserve
	
	drop if ind_treatment==4
	
	*tretament variable to create serial
	recode ind_treatment (2=1 "Info + Fees") (1=2 "Info + Cash") (3=3 "Only Info"), gen(ind_treat)
	
	sort zone_code cls_id ind_treat id, stable
	bys cls_id: gen sl = _n 
	
	egen idno = concat(cls_id sl), punct("_")
	
	clonevar mother_name = b2_1
	

	
	
	

	
	
	
	/*preserve
	
	*calculate total number of children from the roster in HH
	reshape long b2_ b4_ b6_, i(id) j(mem_lino)
	keep if inlist(b4_,3,4)
	drop if b6_>7
	
	rename b2_ child_name 
	rename b6_ child_age
	
	keep id mem_lino 
	
	restore
	*/
	
	
	keep zone_code cls_id cluster_name q8 idno sl mother_name child_name selected_ch_age q2 ind_treatment

	
	*replace as blank for duplicates cls_name 
	
	
	sort zone_code cls_id ind_treat id, stable
	

	*replace cls_name= "" if inlist(idno, 1782, 1799, 1815, 1831, 1863, 1879, 1896, 1912, 1929, 1945, 1961, 1977, 2171, 2495, 2623, 3415, 3447)

	save "ecc_randomization.dta", replace
	
	
	
	
	reshape wide q8 idno mother_name child_name selected_ch_age q2 ind_treatment, i(cls_id) j(sl)
	
	
	
	
	merge 1:1 cls_id using `ent_data'
	drop if _merge==2
	drop _merge
	
	
	export excel using "$data_dir/ECC_mother_treatment_list_for_mailmerge.xlsx", firstrow(variables) replace
	
	
	
	restore
	
	
	
	
	
	
	