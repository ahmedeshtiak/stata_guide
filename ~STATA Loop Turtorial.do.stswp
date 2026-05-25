/*
================================================================================
  STATA LOOPS TUTORIAL
=============================================================================
*/



**# Data Generation

clear all          // drop everything in memory before starting
set more off       // prevent Stata from pausing output — always include this

* Enter the household dataset
input hhid age sex education income expenditure land_size family_size district
    1   35  1  10  25000  18000  0.50  5  1
    2   42  2   8  18000  15000  0.20  6  1
    3   29  1  12  30000  22000  1.00  4  2
    4   50  2   5  12000  10000  0.10  7  2
    5   38  1  16  45000  30000  1.50  3  3
    6   45  2   7  16000  14000  0.30  6  3
    7   31  1  14  35000  26000  0.80  4  1
    8   55  2   4  10000   9000  0.05  8  2
    9   27  1  15  40000  28000  1.20  3  3
   10   48  2   6  15000  13000  0.25  7  1
end

* Attach value labels so output is readable
label define sexlbl  1 "Male"    2 "Female"
label define distlbl 1 "Dhaka"   2 "Khulna"  3 "Rajshahi"
label values sex      sexlbl
label values district distlbl

* Quick look at the data
list

**# Local Macros
/* ─────────────────────────────────────────────────────────────────────────────
   * Define a list of variables once; reuse many times
   *a local macro lives only for the current do-file run (or -do- block).
   ────────────────────────────────────────────────────────────────────────────*/

   * Define a list of variables once; reuse many times
local demographic age sex education family_size
local economic income expenditure land_size
local all_vars `demographic' `economic'      // macros can contain macros

* summarize economic variables with macros
summarize `economic'

**# Foreach Loop
/* ─────────────────────────────────────────────────────────────────────────────
   2. FOREACH Loop — looping over list of variables
   ────────────────────────────────────────────────────────────────────────────*/

* Example 2a — summarize each variable individually
foreach var of varlist age education income expenditure {
    summarize `var', detail
}

* Example 2b — foreach loop with a local macro
local demo_vars age sex education family_size

foreach var of varlist `demo_vars' {
    tabulate `var'
}

******************************************************
**# Foreach Loop - looping over values within variable
******************************************************

   // counting cutoff within variable
foreach cutoff in 15000 20000 25000 {
    count if income < `cutoff'
}

   // Generating new variable
   // log transfromation
local economic income expenditure land_size

foreach var of local economic {
    generate ln_`var' = ln(`var')
    label variable ln_`var' "Log of `var'"
}

   // square 
foreach s in age land_size {
    gen sq_`s' = `s'^2
    label variable sq_`s' "Square of `s'"
}
summarize ln_income ln_expenditure ln_land_size


**************************************
**# 3. GENERATING VARIABLES Using Loop
**************************************

// log transfromation
local economic income expenditure land_size

foreach var of local economic {
    generate ln_`var' = ln(`var')
    label variable ln_`var' "Log of `var'"
}

   // square 
foreach s in age land_size {
    gen sq_`s' = `s'^2
    label variable sq_`s' "Square of `s'
}
summarize ln_income ln_expenditure ln_land_size

     //poverty dummy at multiple thresholds
foreach cutoff in 15000 20000 25000 {
    generate poor_`cutoff' = (income < `cutoff')   // parentheses = 0/1 dummy
    label variable poor_`cutoff' "Poor if income < `cutoff'"
}

list poor_15000 poor_20000 poor_25000



***************************************************
**# FORVALUES — looping over values within variable 
// subsample summarize
***************************************************

        //summary statistics by district 
forvalues d = 1/3 {
    display "District code: `d'"
    summarize income age land_size if district == `d'
}

        //summary statistics by sex 
forvalues g = 1/2 {
    summarize income expenditure if sex == `g'
}

       //custom step: every 5th age from 25 to 55
forvalues age_cut = 25(5)55 {
    quietly count if age >= `age_cut' & age < `age_cut' + 5
}

 //for each district, summarize each economic variable
local economic income expenditure land_size

forvalues d = 1/3 {
    foreach var of local economic {
    summarize `var' if district == `d'
    }
}

***********************
**# LOOPS IN REGRESSION
***********************


   // multiple outcomes, same control set
local outcomes  income expenditure        // dependent variables
local controls  age education family_size land_size  // predictors

foreach y of local outcomes {
    regress `y' `controls'
}

  // multiple control
local controls age education family_size land_size
foreach x of local controls {
    regress ln_income `x'           
}


