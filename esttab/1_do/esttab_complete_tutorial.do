/*=============================================================================
  COMPLETE ESTTAB / ESTOUT TUTORIAL FOR STATA
  Using a Simulated Large-Scale RCT Household Survey Dataset

  Author  : Ahmed Eshtiak | BIGD, BRAC University
  Purpose : In-depth mastery of esttab (part of the estout package)
  Data    : Simulated RCT HH Survey — 5,000 households, 3 districts,
            treatment/control arms, baseline + endline structure
            (Same dataset as the outreg2 tutorial — run that first,
             or run Part 0–1 below to regenerate it.)

  SECTIONS:
  Part 0  — Install estout and Required Packages
  Part 1  — Generate (or Load) the Simulated RCT Dataset
  Part 2  — estout Ecosystem: eststo, estadd, esttab, estout
  Part 3  — esttab Fundamentals: Basic Syntax & Core Logic
  Part 4  — Multi-Column OLS Tables: Controls, Fixed Effects, Clustered SEs
  Part 5  — Displaying Alternative Statistics: SE, t, p-value, CI
  Part 6  — Binary Outcome Models: LPM, Probit (AME), Logit
  Part 7  — Adding Summary Statistics, Custom Scalars, and Notes
  Part 8  — Exporting to Excel (.csv), Word (.rtf), LaTeX (.tex)
  Part 9  — Advanced Options: keep/drop, order, refcat, mgroups, mtitles
  Part 10 — Publication-Ready Treatment Effect Table (Multiple Outcomes)
  Part 11 — Common Pitfalls and Debugging Tips
  Part 12 — Quick Reference: Most-Used esttab Options
  Part 13 — esttab vs outreg2: Side-by-Side Comparison

=============================================================================*/

clear all
set more off
**# Directory Setup
global PATH "D:\Ahmed Eshtiak\Local Disk D\STATA Github\stata_guide\esttab"
global RAW "$PATH\0_data"
global DO "$PATH\1_do"
global RESULT "$PATH\2_result"

*******************
**# INSTALL estout 
*******************
/*
  esttab is a command inside the estout package by Ben Jann.
  The package installs four commands:
    • eststo   — stores estimation results
    • estadd   — adds scalars/matrices to stored results
    • esttab   — produces formatted coefficient tables
    • estout   — lower-level table writer (esttab wraps it)

  Install once:
*/
* ssc install estout, replace

/*
  After installing, confirm:
    which esttab
    help esttab
    help estout
*/
**# Load Data
use "$RAW/rct_hh_survey",clear

/*=============================================================================
  PART 2 — THE estout ECOSYSTEM: eststo / estadd / esttab / estout

  The four commands work as a PIPELINE:

  Step 1 — Run your regression
  Step 2 — eststo: store results in memory with a name
  Step 3 — estadd: add extra scalars to stored results (optional)
  Step 4 — esttab: format and export the stored results to a table

  ┌──────────────────────────────────────────────────────────────────────┐
  │  COMMAND     │ PURPOSE                                               │
  ├──────────────┼───────────────────────────────────────────────────────┤
  │  eststo      │ Store estimation results (like saving a model)        │
  │  estadd      │ Add scalars/matrices to stored results                │
  │  esttab      │ Format stored results into a publication table        │
  │  estout      │ Lower-level, more flexible version of esttab          │
  │  estclear    │ Clear ALL stored results from memory                  │
  └──────────────┴───────────────────────────────────────────────────────┘

  KEY DIFFERENCE FROM outreg2:
  • esttab STORES results first (eststo), then writes them ALL at once.
  • You can run all your regressions, check them in Stata,
    THEN produce the table in one esttab call.
  • You can produce multiple different tables from the
    same set of stored estimates — e.g. a summary table AND a detailed
    table from the same regressions.

=============================================================================*/


************
**# Initiate
************
eststo clear  // always clear stored results first

regress income_el treat
eststo model1  // store with name "model1"

regress income_el treat hh_size hh_female_hh hh_age_head hh_edu_head
eststo model2  // store with name "model2"

esttab model1 model2 // display in results window (no file)

* alternative method
eststo clear
eststo m1: regress income_el treat
eststo m2: regress income_el treat hh_size hh_female_hh
esttab m1 m2


****************************
**# BASIC SYNTAX & STRUCTURE
****************************
eststo clear
eststo b1: regress income_el treat

esttab b1 // shows in Results window only
esttab b1, se label  // with SEs and variable labels

esttab using "$RESULT/basic.csv" replace se label nocons

**********************
**# Multi-Column Table
**********************
eststo clear
eststo m1: regress income_el treat
eststo m2: regress income_el treat hh_size hh_female_hh hh_age_head hh_edu_head hh_land_owned
eststo m3: regress income_el treat hh_size hh_female_hh hh_age_head hh_edu_head hh_land_owned i.district
eststo m4: regress income_el treat hh_size hh_female_hh hh_age_head hh_edu_head hh_land_owned i.district, vce(cluster village_id)

// Add "District FE" and "Covariates" flags to each stored model
estadd local distFE "No",  replace : m1
estadd local covars "No",  replace : m1

estadd local distFE "No",  replace : m2
estadd local covars "Yes", replace : m2

estadd local distFE "Yes", replace : m3
estadd local covars "Yes", replace : m3

estadd local distFE "Yes", replace : m4
estadd local covars "Yes", replace : m4

// export to table
esttab m1 m2 m3 m4 using "$RESULT/0_excel/multiple_column.xls", ///
    replace ///
    label ///  variable labels
    nocons ///  hide constant
    se ///  SE in parentheses
    star(* 0.10 ** 0.05 *** 0.01) ///  significance stars
    mtitles("No Control" "With Controls" "District FE" "SE Clustered") ///  column headers
    drop(*.district)   ///  hide FE dummies
    stats(distFE covars N r2, labels("District FE" "Covariates" "Observations" "R-squared")) ///  bottom rows
    addnotes("Standard errors in parentheses." "* p<0.10, ** p<0.05, *** p<0.01")

********************************************************
**# DISPLAYING ALTERNATIVE STATISTICS BELOW COEFFICIENTS
********************************************************
eststo clear
eststo m1: regress income_el treat hh_size hh_female_hh hh_age_head hh_edu_head hh_land_owned i.district, vce(cluster village_id)
esttab m1 using "$RESULT/0_excel/stats_se.xls", replace label nocons drop(*.district) se //coef & se
esttab m1 using "$RESULT/0_excel/stats_t.xls", replace label nocons drop(*.district) t // t 
esttab m1 using "$RESULT/0_excel/stats_pval.csv", replace label nocons drop(*.district) p // p value
esttab m1 using "$RESULT/0_excel/stats_ci.csv", replace label nocons drop(*.district) ci // 95% confidence intervals


**# Side-by-side: p-values across four models 
eststo clear
eststo m1: regress income_el treat
eststo m2: regress income_el treat hh_size hh_female_hh hh_age_head hh_edu_head hh_land_owned
eststo m3: regress income_el treat hh_size hh_female_hh hh_age_head hh_edu_head hh_land_owned i.district
eststo m4: regress income_el treat hh_size hh_female_hh hh_age_head hh_edu_head hh_land_owned i.district, vce(cluster village_id)

estadd local distFE "No"  : m1
estadd local distFE "No"  : m2
estadd local distFE "Yes" : m3
estadd local distFE "Yes" : m4
estadd local covars "No"  : m1
estadd local covars "No"  : m2
estadd local covars "Yes" : m3
estadd local covars "Yes" : m4
estadd local clustSE "No" : m1
estadd local clustSE "No" : m2
estadd local clustSE "No" : m3
estadd local clustSE "Village" : m4

esttab m1 m2 m3 m4 using "$RESULT/0_excel/pvalue_table.csv", replace label nocons drop(*.district) p star(* 0.10 ** 0.05 *** 0.01) mtitles("No Control" "With Controls" "District FE" "SE Clustered") stats(distFE covars clustSE N r2, labels("District FE" "Covariates" "SE Clustered" "Observations" "R-squared")) addnotes("p-values in parentheses." "* p<0.10, ** p<0.05, *** p<0.01")

**BINARY OUTCOME MODELS: LPM, PROBIT (AME), LOGIT
eststo clear

eststo lpm: regress child_school_el treat hh_size hh_female_hh hh_age_head hh_edu_head hh_land_owned i.district, vce(cluster village_id)
estadd local model_type "LPM"

eststo probit: probit child_school_el treat hh_size hh_female_hh hh_age_head hh_edu_head hh_land_owned i.district, vce(cluster village_id)
estadd local model_type "Probit"

probit child_school_el treat hh_size hh_female_hh hh_age_head hh_edu_head hh_land_owned i.district, vce(cluster village_id)
margins, dydx(*) post          // post overwrites e() with marginal effects
eststo probit_ame
estadd local model_type "Probit AME"

eststo logit: logistic child_school_el treat hh_size hh_female_hh hh_age_head hh_edu_head hh_land_owned i.district, vce(cluster village_id)
estadd local model_type "Logit (OR)"

esttab lpm probit probit_ame logit using "$RESULT/0_excel/binary_models.csv", replace label nocons se star(* 0.10 ** 0.05 *** 0.01) drop(*.district) mtitles("LPM" "Probit" "Probit AME" "Logit")  stats(model_type N, labels("Model" "Observations"))  addnotes("Standard errors clustered at village level in parentheses." "Logit column reports odds ratios." "* p<0.10, ** p<0.05, *** p<0.01")


**# ADDING SUMMARY STATISTICS, CUSTOM SCALARS, AND NOTES
summarize income_el if treat == 0
local ctrl_mean = r(mean)

eststo m1: regress income_el treat hh_size hh_female_hh hh_age_head hh_edu_head hh_land_owned i.district, vce(cluster village_id)

estadd scalar ctrl_mean = `ctrl_mean' // numeric scalar
estadd scalar r2_a_val  = e(r2_a) // adj R-sq (e() still live here)
estadd scalar F_stat  = e(F) // F-statistic
estadd local  distFE "Yes"
estadd local  covars "Yes"

esttab m1 using "$RESULT/0_excel/custom_scalars.csv", replace label nocons drop(*.district) se star(* 0.10 ** 0.05 *** 0.01) b(%9.1f) se(%9.1f) stats(distFE covars ctrl_mean r2_a_val F_stat N, labels("District FE" "Covariates" "Control Mean (BDT)" "Adj. R²" "F-statistic" "Observations")) addnotes("Standard errors clustered at village level." "* p<0.10, ** p<0.05, *** p<0.01")

**# Export to CSV WORD LaTeX HTML

eststo clear

eststo m1: regress income_el treat
estadd local distFE "No"
estadd local covars "No"

eststo m2: regress income_el treat hh_size hh_female_hh hh_age_head hh_edu_head hh_land_owned
estadd local distFE "No"
estadd local covars "Yes"

esttab m1 m2 using "$RESULT/0_excel/export_excel.csv", replace label nocons se star(* 0.10 ** 0.05 *** 0.01) mtitles("No Control" "With Controls") stats(distFE covars N r2, labels("District FE" "Covariates" "Observations" "R-squared")) addnotes("Standard errors in parentheses." "* p<0.10, ** p<0.05, *** p<0.01")

esttab m1 m2 using "$RESULT/1_doc/export_word.rtf", replace label nocons se star(* 0.10 ** 0.05 *** 0.01) mtitles("No Control" "With Controls") stats(distFE covars N r2, labels("District FE" "Covariates" "Observations" "R-squared")) addnotes("Standard errors in parentheses." "* p<0.10, ** p<0.05, *** p<0.01")

esttab m1 m2 using "$RESULT/2_latex/export_latex.tex", replace label nocons se star(* 0.10 ** 0.05 *** 0.01) mtitles("No Control" "With Controls") booktabs fragment stats(distFE covars N r2, labels("District FE" "Covariates" "Observations" "R-squared")) addnotes("Standard errors in parentheses." "* p<0.10, ** p<0.05, *** p<0.01")

esttab m1 m2 using "$RESULT/3_html/export_html.html", replace label nocons se star(* 0.10 ** 0.05 *** 0.01) mtitles("No Control" "With Controls") stats(N r2, labels("Observations" "R-squared")) addnotes("Standard errors in parentheses.")






*()****************************************************************************************
/*=============================================================================
  PART 9 — ADVANCED OPTIONS: keep / drop / order / refcat / mgroups / mtitles

  These are the options that give esttab its edge over outreg2 for
  complex publication tables.
=============================================================================*/

use "$DATA_DIR/rct_hh_survey.dta", clear

*──────────────────────────────
**# 9.1 order() — reorder coefficient rows
*──────────────────────────────
/*
  order() is esttab's version of outreg2's sortvar().
  It forces treat to appear first regardless of model specification order.
*/

eststo clear
eststo: regress income_el hh_land_owned hh_female_hh treat hh_age_head hh_edu_head hh_size

esttab using "$TABLE_DIR/order_demo.csv",                        ///
    replace label nocons se                                       ///
    order(treat hh_size hh_female_hh hh_age_head hh_edu_head hh_land_owned) ///
    stats(N r2, labels("Observations" "R-squared"))               ///
    addnotes("Rows ordered via order() option.")

*──────────────────────────────
**# 9.2 mtitles() — column titles (outreg2: ctitle)
*──────────────────────────────
eststo clear
eststo m1: regress income_el treat
eststo m2: regress income_el treat hh_size hh_female_hh

esttab m1 m2 using "$TABLE_DIR/mtitles_demo.csv",  ///
    replace label nocons se                          ///
    mtitles("(1) No Controls" "(2) With Controls")

*──────────────────────────────
**# 9.3 mgroups() — spanning headers above columns (unique to esttab)
*──────────────────────────────
/*
  mgroups() adds a row of group labels that span multiple columns.
  pattern(1 0 1 0) means: group label starts at column 1, continues
  to column 2 (the 0), starts a new group at column 3, continues to 4.
  This creates the double-header effect seen in journals.
  outreg2 cannot do this natively — esttab advantage!
*/

eststo clear
eststo m1: regress income_el treat
eststo m2: regress income_el treat hh_size hh_female_hh
eststo m3: regress pce_el treat
eststo m4: regress pce_el treat hh_size hh_female_hh

esttab m1 m2 m3 m4 using "$TABLE_DIR/mgroups_demo.csv",          ///
    replace label nocons se                                        ///
    mgroups("Monthly Income (BDT)" "Per-Capita Expenditure (BDT)", ///
            pattern(1 0 1 0))                                      ///
    mtitles("No Controls" "Controls" "No Controls" "Controls")    ///
    stats(N r2, labels("Observations" "R-squared"))

*──────────────────────────────
**# 9.4 refcat() — section dividers within the coefficient block
*──────────────────────────────
/*
  refcat() inserts a text label ABOVE a specified variable row.
  This creates "grouped" coefficient tables common in applied papers.
  outreg2 cannot do this — esttab advantage!
*/

eststo clear
eststo m1: regress income_el treat hh_size hh_female_hh hh_age_head hh_edu_head hh_land_owned

esttab m1 using "$TABLE_DIR/refcat_demo.csv",                     ///
    replace label nocons se                                        ///
    order(treat hh_size hh_female_hh hh_age_head hh_edu_head hh_land_owned) ///
    refcat(treat "Treatment" hh_size "Household Characteristics", nolabel) ///
    stats(N r2, labels("Observations" "R-squared"))                ///
    addnotes("refcat() inserts section headers above variable rows.")

*──────────────────────────────
**# 9.5 Decimal control: b() and se() format specifiers
*──────────────────────────────
/*
  esttab uses Stata format strings:
    %9.1f  →  1 decimal   (for monetary values, BDT)
    %9.3f  →  3 decimals  (for proportions, indices)
    %9.0fc →  integer with commas (for large counts)
  outreg2 equivalent: dec(#) / bdec(#) / sdec(#)
*/

eststo clear
eststo m1: regress income_el treat hh_size hh_female_hh
esttab m1 using "$TABLE_DIR/decimal_demo.csv",     ///
    replace label nocons se                         ///
    b(%9.1f) se(%9.1f)                             ///
    stats(N r2, fmt(%9.0f %9.3f) labels("Observations" "R-squared"))

*──────────────────────────────
**# 9.6 nostar / nosig — suppress significance stars
*──────────────────────────────
/*
  nostar suppresses ALL stars. (outreg2: noaster)
  You might want this when reporting p-values separately.
*/

esttab m1 using "$TABLE_DIR/nostar_demo.csv", replace label nocons se p nostar
* Shows p-values but no stars

*──────────────────────────────
**# 9.7 nobs / nor2 — suppress N and R²
*──────────────────────────────
/*
  nobs → suppress observations row (outreg2: noni)
  nor2 → suppress R-squared (outreg2: nor2)
*/

esttab m1 using "$TABLE_DIR/nobs_nor2_demo.csv", replace label nocons se nobs nor2


/*=============================================================================
  PART 10 — PUBLICATION-READY TREATMENT EFFECT TABLE (Multiple Outcomes)

  This is the esttab equivalent of outreg2 tutorial Part 10.
  Same structure: 7 outcomes × 1 column each, with:
  - District FE + household controls
  - Clustered SEs at village level
  - Control group mean row
  - Custom footnote
  - All in one esttab call
=============================================================================*/

use "$DATA_DIR/rct_hh_survey.dta", clear
eststo clear

*─── (1) Per-capita consumption ───────────────────────────────────────────────
summarize pce_el if treat == 0
local ctrl1 = round(r(mean), 1)
eststo pce:    regress pce_el    treat hh_size hh_female_hh hh_age_head hh_edu_head hh_land_owned i.district, vce(cluster village_id)
estadd scalar ctrl_mean = `ctrl1'
estadd local  distFE "Yes"
estadd local  covars "Yes"

*─── (2) Monthly income ───────────────────────────────────────────────────────
summarize income_el if treat == 0
local ctrl2 = round(r(mean), 1)
eststo inc:    regress income_el treat hh_size hh_female_hh hh_age_head hh_edu_head hh_land_owned i.district, vce(cluster village_id)
estadd scalar ctrl_mean = `ctrl2'
estadd local  distFE "Yes"
estadd local  covars "Yes"

*─── (3) Food expenditure ─────────────────────────────────────────────────────
summarize food_exp_el if treat == 0
local ctrl3 = round(r(mean), 1)
eststo food:   regress food_exp_el  treat hh_size hh_female_hh hh_age_head hh_edu_head hh_land_owned i.district, vce(cluster village_id)
estadd scalar ctrl_mean = `ctrl3'
estadd local  distFE "Yes"
estadd local  covars "Yes"

*─── (4) Days worked ──────────────────────────────────────────────────────────
summarize days_work_el if treat == 0
local ctrl4 = round(r(mean), 2)
eststo work:   regress days_work_el treat hh_size hh_female_hh hh_age_head hh_edu_head hh_land_owned i.district, vce(cluster village_id)
estadd scalar ctrl_mean = `ctrl4'
estadd local  distFE "Yes"
estadd local  covars "Yes"

*─── (5) Savings ──────────────────────────────────────────────────────────────
summarize savings_el if treat == 0
local ctrl5 = round(r(mean), 1)
eststo sav:    regress savings_el   treat hh_size hh_female_hh hh_age_head hh_edu_head hh_land_owned i.district, vce(cluster village_id)
estadd scalar ctrl_mean = `ctrl5'
estadd local  distFE "Yes"
estadd local  covars "Yes"

*─── (6) Child schooling (LPM) ────────────────────────────────────────────────
summarize child_school_el if treat == 0
local ctrl6 = round(r(mean), 3)
eststo school: regress child_school_el treat hh_size hh_female_hh hh_edu_head hh_land_owned i.district, vce(cluster village_id)
estadd scalar ctrl_mean = `ctrl6'
estadd local  distFE "Yes"
estadd local  covars "Yes"

*─── (7) Women's empowerment ──────────────────────────────────────────────────
summarize women_emp_el if treat == 0
local ctrl7 = round(r(mean), 2)
eststo womemp: regress women_emp_el  treat hh_size hh_female_hh hh_age_head hh_edu_head hh_land_owned i.district, vce(cluster village_id)
estadd scalar ctrl_mean = `ctrl7'
estadd local  distFE "Yes"
estadd local  covars "Yes"

*──────────────────────────────────────────────────────────────────────────────
* PRODUCE THE FULL PUBLICATION TABLE IN ONE CALL
*──────────────────────────────────────────────────────────────────────────────
esttab pce inc food work sav school womemp using "$TABLE_DIR/treatment_effects.csv", ///
    replace                                                                           ///
    label                                                                             ///
    nocons                                                                            ///
    se                                                                                ///
    star(* 0.10 ** 0.05 *** 0.01)                                                    ///
    keep(treat)                                                                       ///  show ONLY the treatment coefficient
    order(treat)                                                                      ///
    mtitles("(1) PCE" "(2) Income" "(3) Food Exp" "(4) Days Worked"                  ///
            "(5) Savings" "(6) Child School" "(7) Women Empower.")                   ///
    stats(distFE covars ctrl_mean N r2,                                              ///
          labels("District FE" "Covariates" "Control Mean" "Observations" "R-squared") ///
          fmt(%9.0f %9.0f %9.1f %9.0f %9.3f))                                       ///
    addnotes("All specifications include district fixed effects and household"        ///
             "controls (HH size, female-headed, age and education of head, land)."   ///
             "Standard errors clustered at village level in parentheses."            ///
             "* p<0.10  ** p<0.05  *** p<0.01")

/*
  KEY OPTION USED HERE:
  keep(treat) → shows ONLY the treat row (outreg2 equivalent: keep(treat))
  This is the standard for publication-ready RCT tables where
  you only want to display the treatment coefficient, not all controls.
*/


/*=============================================================================
  PART 11 — COMMON PITFALLS AND DEBUGGING TIPS

  ┌──────────────────────────────────────────────────────────────────────────┐
  │ PITFALL 1: Not clearing stored estimates (eststo clear)                  │
  │   If you run new regressions without eststo clear, old models             │
  │   accumulate in memory and appear in your table unexpectedly.            │
  │   Rule: ALWAYS start a new table block with: eststo clear                │
  └──────────────────────────────────────────────────────────────────────────┘

  ┌──────────────────────────────────────────────────────────────────────────┐
  │ PITFALL 2: estadd after summarize clears r()                             │
  │   Compute control mean BEFORE the regression and store in a local.       │
  │                                                                          │
  │   BAD:                                                                   │
  │     eststo m1: regress income_el treat                                   │
  │     summarize income_el if treat == 0                                    │
  │     estadd scalar ctrl_mean = r(mean)   ← r() from summarize is fine    │
  │     ← BUT: if you add another r-class command here, r() clears           │
  │                                                                          │
  │   GOOD:                                                                  │
  │     summarize income_el if treat == 0                                    │
  │     local ctrl_mean = r(mean)            ← save to local FIRST           │
  │     eststo m1: regress income_el treat                                   │
  │     estadd scalar ctrl_mean = `ctrl_mean'  ← safe                       │
  └──────────────────────────────────────────────────────────────────────────┘

  ┌──────────────────────────────────────────────────────────────────────────┐
  │ PITFALL 3: estadd scalars not showing in esttab                          │
  │   You must list the scalar name in stats() for it to appear.             │
  │   estadd just stores it; stats() displays it.                            │
  │                                                                          │
  │   estadd scalar ctrl_mean = 1500        ← stores scalar                  │
  │   esttab, stats(N r2)                   ← ctrl_mean NOT shown (missing!) │
  │   esttab, stats(ctrl_mean N r2)         ← correct                        │
  └──────────────────────────────────────────────────────────────────────────┘

  ┌──────────────────────────────────────────────────────────────────────────┐
  │ PITFALL 4: fmt() order must match stats() order                          │
  │   stats(distFE ctrl_mean N r2, fmt(%9.0f %9.1f %9.0f %9.3f))            │
  │   → 4 stats → 4 fmt codes, in exact order                               │
  │   If you have text locals (like "Yes"/"No"), their fmt is ignored,       │
  │   but you must still include a placeholder format for them.              │
  └──────────────────────────────────────────────────────────────────────────┘

  ┌──────────────────────────────────────────────────────────────────────────┐
  │ PITFALL 5: keep() vs order()                                             │
  │   keep(varlist)  → ONLY show these variables (hides all others)          │
  │   order(varlist) → reorder rows, but show ALL variables                  │
  │   For a treatment-only table: use keep(treat)                            │
  │   For reordering controls:    use order(treat hh_size ...)               │
  └──────────────────────────────────────────────────────────────────────────┘

  ┌──────────────────────────────────────────────────────────────────────────┐
  │ PITFALL 6: Probit/Logit with AME — e() is overwritten by margins         │
  │   After: probit y x, then: margins, dydx(*) post                        │
  │   e() now holds the margins results, NOT the probit results.             │
  │   eststo AFTER margins captures the AME, which is usually what you want. │
  │   If you want BOTH probit coefs AND AME: run probit → eststo probit_coef  │
  │   then run margins → eststo probit_ame (two separate stored results)     │
  └──────────────────────────────────────────────────────────────────────────┘

  ┌──────────────────────────────────────────────────────────────────────────┐
  │ PITFALL 7: File open in another program                                  │
  │   If the .csv or .rtf is open in Excel/Word, esttab cannot write to it.  │
  │   Close the file, re-run. (Same as outreg2's .xls pitfall.)             │
  └──────────────────────────────────────────────────────────────────────────┘

  USEFUL DEBUGGING COMMANDS:
  ──────────────────────────────────────────────────────────────────────────
    eststo dir         → list all currently stored models
    eststo clear       → clear all stored models
    ereturn list       → see all e() scalars for the LAST regression
    estadd , using m1  → show what is stored in model m1
    help esttab        → full option reference
    which esttab       → confirm esttab is installed
    help estout        → lower-level reference
*/


/*=============================================================================
  PART 12 — QUICK REFERENCE: MOST-USED esttab OPTIONS

  ┌──────────────────────────────────────────────────────────────────────────┐
  │  File control:                                                           │
  │    replace             overwrite existing file                           │
  │    append              add to existing file                              │
  │    using "file.csv"    output filename (.csv .rtf .tex .html)            │
  │                                                                          │
  │  Column appearance:                                                      │
  │    mtitles("c1" "c2") column headers      [outreg2: ctitle()]           │
  │    mgroups("g" ..., pattern(1 0 1)) spanning group headers               │
  │    label               use variable labels [outreg2: label]              │
  │    nocons              hide constant       [outreg2: nocons]             │
  │    keep(varlist)       show only these rows [outreg2: keep()]            │
  │    drop(varlist)       hide these rows      [outreg2: drop()]            │
  │    order(varlist)      reorder rows         [outreg2: sortvar()]         │
  │    refcat(var "lbl")   insert section header above row                   │
  │                                                                          │
  │  Stats below coefficients:                                               │
  │    se                  standard errors (default) [outreg2: stats(coef se)]│
  │    t                   t-statistics       [outreg2: stats(coef tstat)]   │
  │    p                   p-values           [outreg2: stats(coef pval)]    │
  │    ci                  confidence intervals (no outreg2 equivalent)      │
  │                                                                          │
  │  Formatting:                                                             │
  │    b(%9.2f)            coefficient format  [outreg2: bdec(2)]           │
  │    se(%9.2f)           SE format           [outreg2: sdec(2)]           │
  │    star(* .10 ** .05 *** .01)  significance stars                        │
  │    nostar              no significance stars [outreg2: noaster]          │
  │    nolz                no leading zero (p-values: .05 not 0.05)          │
  │                                                                          │
  │  Bottom-of-table:                                                        │
  │    stats(N r2 ...)     built-in + custom scalars to show                 │
  │    fmt(...)            format for each stats row                         │
  │    labels("lbl" ...)   friendly names for stats rows                     │
  │    addnotes("note")    footnotes [outreg2: addnote]                     │
  │    nobs                suppress N [outreg2: noni]                       │
  │    nor2                suppress R² [outreg2: nor2]                      │
  │                                                                          │
  │  Output format:                                                          │
  │    (auto from extension) .csv / .rtf / .tex / .html                     │
  │    booktabs            LaTeX with professional rules                     │
  │    fragment            LaTeX without table wrapper                       │
  │    compress            remove blank lines                                │
  │    wide                coefficients and SE on same row                   │
  │    eform               exponentiate coefs (OR, IRR, HR) [outreg2: eform]│
  └──────────────────────────────────────────────────────────────────────────┘
*/


/*=============================================================================
  PART 13 — esttab vs outreg2: SIDE-BY-SIDE COMPARISON

  ┌─────────────────────────┬──────────────────────────┬─────────────────────────────┐
  │  TASK                   │  outreg2                 │  esttab                     │
  ├─────────────────────────┼──────────────────────────┼─────────────────────────────┤
  │ Write after each reg    │ YES (write immediately)  │ NO (store first, then write)│
  │ Store results           │ Not needed               │ eststo                      │
  │ Add custom scalars      │ addstat()                │ estadd scalar               │
  │ Add text indicator rows │ addtext()                │ estadd local + stats()      │
  │ Column title            │ ctitle()                 │ mtitles()                   │
  │ Spanning column header  │ Not supported            │ mgroups()                   │
  │ Section dividers        │ Not supported            │ refcat()                    │
  │ Reorder rows            │ sortvar()                │ order()                     │
  │ Suppress constant       │ nocons                   │ nocons (identical)          │
  │ Keep/drop variables     │ keep() / drop()          │ keep() / drop() (identical) │
  │ Show SE                 │ stats(coef se) [default] │ se (default)                │
  │ Show t-stat             │ stats(coef tstat)        │ t                           │
  │ Show p-value            │ stats(coef pval)         │ p                           │
  │ Show CI                 │ Not supported            │ ci                          │
  │ No stars                │ noaster                  │ nostar                      │
  │ No N                    │ noni                     │ nobs                        │
  │ No R²                   │ nor2                     │ nor2 (identical)            │
  │ Decimal control         │ dec() bdec() sdec()      │ b(%fmt) se(%fmt)            │
  │ Significance levels     │ alpha() symbol()         │ star()                      │
  │ Excel output            │ .xls (native)            │ .csv (opens in Excel)       │
  │ Word output             │ .doc (native)            │ .rtf (opens in Word)        │
  │ LaTeX output            │ tex option               │ auto from .tex extension    │
  │ LaTeX booktabs          │ Not supported            │ booktabs option             │
  │ HTML output             │ Not supported            │ .html extension             │
  │ Footnotes               │ addnote()                │ addnotes()                  │
  │ Actively maintained     │ Not since ~2015          │ YES (Ben Jann, 2024)        │
  └─────────────────────────┴──────────────────────────┴─────────────────────────────┘

  WHEN TO USE WHICH:
  ──────────────────────────────────────────────────────────────────────────
  Use outreg2 when:
    • You have existing scripts already written in outreg2
    • You need .doc output specifically
    • Your supervisor/collaborators use outreg2 templates

  Use esttab when:
    • Writing new code from scratch
    • You need booktabs LaTeX tables for journal submission
    • You want spanning headers (mgroups) or section dividers (refcat)
    • You want to store results and create multiple table variants
    • You need HTML output for reports

  Use BOTH when:
    • Sanity-checking (same regression, same table → outputs should match)
    • Your team uses mixed tools

=============================================================================*/

* END OF TUTORIAL
di "esttab tutorial complete. All output files written to:"
di "  Excel/CSV : $TABLE_DIR"
di "  Word/RTF  : $DOC_DIR"
di "  LaTeX     : $TEX_DIR"
