********************************************************************************
*                                                                              *
*         DIFFERENCE-IN-DIFFERENCES (DiD) AND REGRESSION DISCONTINUITY         *
*                        DESIGN (RDD) WITH STATA                               *
*                                                                              *
*  Course Material — Prepared as Lecture Notes                                 *
*  References:                                                                 *
*    1. Cunningham, S. (2021). Causal Inference: The Mixtape.                  *
*       https://mixtape.scunning.com/                                          *
*    2. Huntington-Klein, N. (2021). The Effect: An Introduction to Research   *
*       Design and Causality. https://theeffectbook.net/                       *
*                                                                              *
*  Datasets: All datasets used are publicly available online.                  *
*                                                                              *
********************************************************************************


clear all                                   // Clear all data from memory
set more off                                // Disable --more-- pause in output
set scheme s2color                          // Set a clean graph scheme
cap log close                               // Close any open log file
log using "DiD_RDD_Lecture.log", replace     // Start a new log file


**# PART I: DIFFERENCE-IN-DIFFERENCES (DiD)
********************************************************************************
*=============================================================================*
*                                                                              *
*                    PART I: DIFFERENCE-IN-DIFFERENCES (DiD)                   *
*                                                                              *
*=============================================================================*
********************************************************************************

/*
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║  WHAT IS DIFFERENCE-IN-DIFFERENCES (DiD)?                                    ║
║                                                                              ║
║  DiD is a quasi-experimental research design used to estimate the causal     ║
║  effect of a treatment (policy, intervention, program) by comparing the      ║
║  change in outcomes over time between a group that is exposed to the         ║
║  treatment (treatment group) and a group that is not (control group).        ║
║                                                                              ║
║  The KEY IDEA:                                                               ║
║  If we observe two groups over two periods—one group gets treated between    ║
║  the periods and one does not—the DiD estimator is:                          ║
║                                                                              ║
║    DiD = (Y_treat,post - Y_treat,pre) - (Y_control,post - Y_control,pre)    ║
║                                                                              ║
║  The first difference removes time-invariant unobserved heterogeneity.       ║
║  The second difference removes common time trends.                           ║
║                                                                              ║
║  CRITICAL ASSUMPTION: Parallel Trends                                        ║
║  In the absence of treatment, the treated and control groups would have      ║
║  followed the same trend in outcomes over time. We CANNOT test this          ║
║  directly (it's about a counterfactual), but we can check if pre-treatment   ║
║  trends were parallel.                                                       ║
║                                                                              ║
║  The regression form of DiD (2x2 case):                                      ║
║    Y_it = β0 + β1*Treat_i + β2*Post_t + β3*(Treat_i × Post_t) + ε_it       ║
║                                                                              ║
║  Where:                                                                      ║
║    β0 = mean outcome for control group in pre-period                         ║
║    β1 = baseline difference between treatment and control groups             ║
║    β2 = common time trend (change from pre to post for control)              ║
║    β3 = THE DiD ESTIMATOR — the causal effect of treatment                   ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
*/


**# Section 1: Basic 2x2 DiD Regression
********************************************************************************
*  SECTION 1: BASIC 2x2 DiD REGRESSION                                        *
*  Dataset: Card & Krueger (1994) — Minimum Wage and Employment                *
********************************************************************************

/*
CONTEXT: Card & Krueger (1994) — A Classic DiD Study

In 1992, New Jersey raised its minimum wage from $4.25 to $5.05 per hour.
Neighboring Pennsylvania did NOT raise its minimum wage.

Card & Krueger surveyed fast-food restaurants in both states before (Feb 1992)
and after (Nov 1992) the wage increase.

  Treatment group: New Jersey restaurants (affected by wage increase)
  Control group:   Pennsylvania restaurants (no wage change)
  Outcome:         Full-time equivalent (FTE) employment

This is the canonical example of a "natural experiment" analyzed with DiD.
*/

* --- Simulate the Card-Krueger (1994) data ---
/*
The original Card-Krueger data is available from David Card's Berkeley page
(http://davidcard.berkeley.edu/data_sets/njmin.zip). Here we simulate a
simplified version that replicates the key features for pedagogical use.
The actual estimates from the paper: NJ FTE went from 20.44 to 21.03 (+0.59),
PA FTE went from 23.33 to 21.17 (-2.16), DiD ≈ 2.76.
*/

clear all
set seed 1994                               // Seed for reproducibility
set obs 794                                 // ~400 restaurants × 2 periods

* Generate restaurant IDs and state assignment
gen restaurant = mod(_n - 1, 397) + 1       // 397 restaurants
bysort restaurant: gen after = _n - 1       // 0 = before, 1 = after
gen state = (restaurant <= 309)             // 309 NJ restaurants, 88 PA restaurants

* Generate FTE employment mimicking Card-Krueger means
gen fte = .
* PA before: mean ≈ 23.33
replace fte = 23.33 + rnormal(0, 8) if state == 0 & after == 0
* PA after: mean ≈ 21.17
replace fte = 21.17 + rnormal(0, 8) if state == 0 & after == 1
* NJ before: mean ≈ 20.44
replace fte = 20.44 + rnormal(0, 8) if state == 1 & after == 0
* NJ after: mean ≈ 21.03
replace fte = 21.03 + rnormal(0, 8) if state == 1 & after == 1
replace fte = max(0, fte)                   // FTE cannot be negative

* Generate chain type (1=BK, 2=KFC, 3=Wendy's, 4=Roy Rogers)
gen chain = ceil(runiform() * 4)



* --- Explore the data ---
describe                                    // Show variable names, types, labels
summarize                                   // Summary statistics for all variables
tab state                                   // Check the state variable (NJ vs PA)
tab after                                   // Check the time variable (before/after)

/*
KEY VARIABLES:
  - state:        1 = New Jersey (treated), 0 = Pennsylvania (control)
  - after:        1 = After min wage increase (Nov 1992), 0 = Before (Feb 1992)
  - fte:          Full-time equivalent employment (outcome variable)
  - state*after:  The interaction term = DiD estimator
*/

* --- Generate the interaction term manually ---
gen treat_post = state * after              // Interaction: =1 only for NJ after treatment


* --- Label variables for clarity ---
label variable state "Treatment (1=NJ, 0=PA)"
label variable after "Post-period (1=After, 0=Before)"
label variable treat_post "DiD interaction (Treat × Post)"
label variable fte "FTE Employment"


* --- METHOD 1: Manual 2x2 Table Calculation ---
/*
Let's compute the DiD estimate by hand using group means.
This is pedagogically important to understand what the regression does.
*/

tabstat fte, by(state) stat(mean)           // Mean FTE by state (ignoring time)

* More detailed: means by state AND time period
table state after, stat(mean fte)           // 2x2 table of mean FTE

/*
READING THE 2x2 TABLE:
                    Before (after=0)    After (after=1)    Difference
  PA (state=0):         Y_00                Y_01            ΔY_control
  NJ (state=1):         Y_10                Y_11            ΔY_treat
                                                            
  DiD = ΔY_treat - ΔY_control = (Y_11 - Y_10) - (Y_01 - Y_00)
*/


* --- METHOD 2: DiD Regression ---
/*
The standard DiD regression:
  fte = β0 + β1*state + β2*after + β3*(state*after) + ε

β3 is identical to the manual DiD calculation above!
*/

reg fte state after treat_post              // Basic DiD regression

/*
INTERPRETING THE OUTPUT:
  - _cons (β0):       Mean FTE for PA before the min wage increase
  - state (β1):       Difference between NJ and PA BEFORE the policy
  - after (β2):       Change in FTE for PA (control) from before to after
  - treat_post (β3):  THE DiD ESTIMATE — the causal effect of the min wage
                      increase on FTE employment in NJ
                      
If β3 > 0: employment INCREASED in NJ relative to PA after the wage hike
If β3 < 0: employment DECREASED in NJ relative to PA after the wage hike
*/


* --- METHOD 3: Using Stata's factor variable notation (preferred) ---
/*
Stata's ## operator automatically creates interaction terms.
i.state = treat indicator; i.after = post indicator
i.state##i.after creates: state + after + state*after
*/

reg fte i.state##i.after                    // DiD with factor variables (cleaner)

* --- METHOD 4: With robust standard errors ---
reg fte i.state##i.after, robust            // Heteroskedasticity-robust SEs

/*
WHY ROBUST SEs?
Standard OLS assumes homoskedastic errors (constant variance).
In practice, this is rarely true. Robust (Huber-White) standard errors
are consistent even when errors are heteroskedastic.

In DiD, we often also want to CLUSTER standard errors at the group level
(e.g., state) because outcomes within the same group are correlated.
With only 2 clusters (NJ and PA), clustering is problematic — we need
many clusters (typically 30+) for cluster-robust SEs to work well.
*/


* --- METHOD 5: With control variables ---
/*
Adding covariates can improve precision and reduce omitted variable bias,
but covariates should be PRE-TREATMENT characteristics (not affected by
the treatment itself — the "bad control" problem).
*/

reg fte i.state##i.after chain, robust      // Adding chain type as a control


/*
╔══════════════════════════════════════════════════════════════════════════════╗
║  KEY TAKEAWAYS — Basic DiD:                                                  ║
║                                                                              ║
║  1. DiD compares changes (not levels) across groups                          ║
║  2. The interaction term β3 is the causal estimate                           ║
║  3. Always use robust or clustered standard errors                           ║
║  4. Only add pre-treatment covariates as controls                            ║
║  5. The validity of DiD hinges on the parallel trends assumption             ║
╚══════════════════════════════════════════════════════════════════════════════╝
*/



********************************************************************************
**# SECTION 2: PARALLEL TRENDS ASSUMPTION — GRAPHICAL CHECK                     *
********************************************************************************

/*
╔══════════════════════════════════════════════════════════════════════════════╗
║  THE PARALLEL TRENDS ASSUMPTION                                              ║
║                                                                              ║
║  DiD is only valid if, in the absence of treatment, the treated and          ║
║  control groups would have followed PARALLEL trends in the outcome.          ║
║                                                                              ║
║  We can NEVER test this directly (it involves a counterfactual), but we      ║
║  can examine whether pre-treatment trends were parallel. If they were,       ║
║  it's more plausible (though not guaranteed) they would have continued       ║
║  to be parallel.                                                             ║
║                                                                              ║
║  GRAPHICAL CHECK: Plot the outcome variable over time for both groups.       ║
║  If the lines move in parallel before the treatment, the assumption is       ║
║  more credible.                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
*/

* --- Load a panel dataset with multiple pre-treatment periods ---
* We use a simulated dataset inspired by the Mixtape for illustration

* First, let's create a simulated panel dataset for illustration
clear all
set seed 12345                              // Set seed for reproducibility
set obs 1000                                // 1000 observations

* Generate panel structure
gen id = mod(_n - 1, 100) + 1              // 100 units
bysort id: gen time = _n                    // 10 time periods per unit
gen treat_group = (id <= 50)                // First 50 units are treated
gen post = (time >= 6)                      // Treatment occurs at period 6
gen treat_post = treat_group * post         // DiD interaction

* Generate outcome with parallel pre-trends and treatment effect
gen y = 10 + 2*treat_group + 0.5*time + 3*treat_post + rnormal(0, 2)
/*
  y = 10              (baseline)
    + 2*treat_group   (level difference between groups — this is fine)
    + 0.5*time        (common time trend — same for both groups)
    + 3*treat_post    (treatment effect = 3 — only for treated, post)
    + noise
*/

label variable y "Outcome"
label variable time "Time Period"
label variable treat_group "Treatment Group"

* --- Compute group means by time period ---
collapse (mean) y, by(time treat_group)     // Average y by time and group

* --- Plot parallel trends ---
twoway (connected y time if treat_group == 1, lcolor(cranberry) mcolor(cranberry)   ///
            lpattern(solid) msymbol(circle) lwidth(medthick))                       ///
       (connected y time if treat_group == 0, lcolor(navy) mcolor(navy)             ///
            lpattern(dash) msymbol(square) lwidth(medthick)),                       ///
       xline(5.5, lcolor(gs8) lpattern(dash))                                      ///
       legend(order(1 "Treatment Group" 2 "Control Group")                          ///
              ring(0) pos(11) col(1) size(small))                                   ///
       title("Parallel Trends Check", size(medium))                                 ///
       subtitle("Treatment occurs between period 5 and 6")                          ///
       xtitle("Time Period") ytitle("Mean Outcome")                                 ///
       xlabel(1(1)10) note("Dashed vertical line = treatment timing")               ///
       graphregion(color(white)) plotregion(color(white)) name(parall_assum, replace)

graph export "parallel_trends_check.png", replace width(1200)



/*
HOW TO READ THIS GRAPH:
  - Look at the lines BEFORE the dashed vertical line (pre-treatment periods)
  - If they move roughly in parallel, the assumption is supported
  - After the treatment line, divergence = treatment effect
  - If pre-treatment lines are NOT parallel, DiD may be biased!

WARNING: Parallel pre-trends do NOT guarantee parallel counterfactual trends.
It's necessary but not sufficient. See Roth (2022) for a discussion of
pre-testing and its limitations.
*/



********************************************************************************
**# SECTION 3: EVENT STUDY / LEADS-AND-LAGS — FORMAL PARALLEL TRENDS TEST      *
********************************************************************************

/*
╔══════════════════════════════════════════════════════════════════════════════╗
║  EVENT STUDY DESIGN (LEADS AND LAGS)                                         ║
║                                                                              ║
║  The most rigorous way to check parallel trends is the "event study"         ║
║  or "leads-and-lags" specification:                                          ║
║                                                                              ║
║  Y_it = α_i + λ_t + Σ_k β_k * (Treat_i × 1(t = k)) + ε_it                 ║
║                                                                              ║
║  Where k indexes time periods relative to treatment.                         ║
║  We include leads (pre-treatment dummies) and lags (post-treatment).         ║
║  One period is omitted as the reference (usually t = -1).                    ║
║                                                                              ║
║  INTERPRETATION:                                                             ║
║  - Pre-treatment β_k (leads): Should be ≈ 0 and insignificant               ║
║    → Supports parallel trends                                                ║
║  - Post-treatment β_k (lags): Capture dynamic treatment effects              ║
║                                                                              ║
║  We plot the β_k coefficients with confidence intervals — this is the        ║
║  "event study plot."                                                         ║
╚══════════════════════════════════════════════════════════════════════════════╝
*/

* --- Reload the simulated panel ---
clear all
set seed 12345
set obs 1000
gen id = mod(_n - 1, 100) + 1
bysort id: gen time = _n
gen treat_group = (id <= 50)
gen post = (time >= 6)
gen treat_post = treat_group * post
gen y = 10 + 2*treat_group + 0.5*time + 3*treat_post + rnormal(0, 2)

* --- Create relative time variable ---
gen rel_time = time - 6                     // Relative to treatment at t=6
label variable rel_time "Periods Relative to Treatment"

* --- Create dummies for each relative time period, interacted with treatment ---
* We omit rel_time == -1 as the reference category
forvalues k = -5/4 {                        // 5 pre-periods, 4 post-periods
    if `k' != -1 {                          // Skip the reference period
        gen D`=`k'+10' = (rel_time == `k') * treat_group
        * Name: D5 = rel_time=-5, D6=-4, ..., D9=-1(omitted), D10=0, ..., D14=4
    }
}

* --- Rename for clarity ---
rename D5  lead5                            // 5 periods before treatment
rename D6  lead4                            // 4 periods before treatment
rename D7  lead3                            // 3 periods before treatment
rename D8  lead2                            // 2 periods before treatment
* D9 (lead1 / rel_time=-1) is OMITTED as reference
rename D10 lag0                             // Treatment period (t=0)
rename D11 lag1                             // 1 period after
rename D12 lag2                             // 2 periods after
rename D13 lag3                             // 3 periods after
rename D14 lag4                             // 4 periods after

* --- Event Study Regression ---
* Include unit FE (i.id) and time FE (i.time)
reghdfe y lead5 lead4 lead3 lead2 lag0 lag1 lag2 lag3 lag4, ///
    absorb(id time) vce(cluster id)         // Two-way FE with clustered SEs

/*
NOTE: We use reghdfe (install with: ssc install reghdfe) for high-dimensional
fixed effects. If not available, use:
  areg y lead5 lead4 lead3 lead2 lag0 lag1 lag2 lag3 lag4 i.time, absorb(id) cluster(id)
  
Or install it:
  ssc install reghdfe
  ssc install ftools    (required by reghdfe)
*/

* --- Store coefficients for plotting ---
* Create a dataset of coefficients
preserve
    matrix b = e(b)'                        // Extract coefficients as column vector
    matrix V = vecdiag(e(V))'               // Extract diagonal of variance matrix
    
    clear
    svmat b, names(coef)                    // Convert coefficient matrix to data
    svmat V, names(var)                     // Convert variance matrix to data
    
    gen se = sqrt(var1)                     // Standard error = sqrt(variance)
    gen ci_lo = coef1 - 1.96 * se           // Lower 95% CI
    gen ci_hi = coef1 + 1.96 * se           // Upper 95% CI
    
    * Add relative time periods
    gen rel_time = .
    replace rel_time = -5 in 1
    replace rel_time = -4 in 2
    replace rel_time = -3 in 3
    replace rel_time = -2 in 4
    replace rel_time = 0  in 5
    replace rel_time = 1  in 6
    replace rel_time = 2  in 7
    replace rel_time = 3  in 8
    replace rel_time = 4  in 9
    
    drop if rel_time == .                   // Drop the constant row if any
    
    * Add the omitted reference period (coefficient = 0 by construction)
    local new_obs = _N + 1
    set obs `new_obs'
    replace rel_time = -1 in `new_obs'
    replace coef1 = 0 in `new_obs'
    replace ci_lo = 0 in `new_obs'
    replace ci_hi = 0 in `new_obs'
    
    sort rel_time                           // Sort by relative time
    
    * --- Event Study Plot ---
    twoway (rcap ci_lo ci_hi rel_time, lcolor(navy) lwidth(medium))             ///
           (scatter coef1 rel_time, mcolor(cranberry) msymbol(circle)           ///
                msize(medlarge)),                                               ///
           yline(0, lcolor(gs8) lpattern(dash))                                ///
           xline(-0.5, lcolor(red) lpattern(dash))                             ///
           legend(off)                                                          ///
           title("Event Study Plot", size(medium))                              ///
           subtitle("Reference period: t = -1 (one period before treatment)")   ///
           xtitle("Periods Relative to Treatment")                              ///
           ytitle("Estimated Coefficient (β{sub:k})")                           ///
           xlabel(-5(1)4)                                                       ///
           note("Bars = 95% confidence intervals. Red dashed line = treatment timing.") ///
           graphregion(color(white)) plotregion(color(white))
    
    graph export "event_study_plot.png", replace width(1200)
restore



/*
HOW TO READ THE EVENT STUDY PLOT:
  1. Look at the PRE-TREATMENT coefficients (left of the red dashed line):
     - They should be close to zero and statistically insignificant
     - This supports the parallel trends assumption
     
  2. Look at the POST-TREATMENT coefficients (right of the red line):
     - These show the dynamic treatment effect over time
     - If they jump up at t=0 and stay elevated → immediate, persistent effect
     - If they grow over time → effect builds gradually
     - If they decay → effect is temporary

  3. The reference period (t = -1) is fixed at zero by construction.
     All other coefficients are relative to this period.
     
COMMON PITFALLS:
  - Pre-trends that slope upward/downward → parallel trends violated!
  - Very wide CIs pre-treatment → insufficient power to detect violations
  - See Roth (2022) "Pre-test with Caution" for discussion of pre-testing bias
*/


********************************************************************************
**# SECTION 4: FALSIFICATION / PLACEBO TESTS                                    *
********************************************************************************

/*
╔══════════════════════════════════════════════════════════════════════════════╗
║  FALSIFICATION (PLACEBO) TESTS FOR DiD                                       ║
║                                                                              ║
║  Beyond graphical checks, we can conduct formal placebo tests:               ║
║                                                                              ║
║  1. FAKE (PLACEBO) TREATMENT TIMING                                          ║
║     - Pretend the treatment happened earlier (in the pre-period)             ║
║     - If we find a "significant effect," it suggests pre-existing trends     ║
║     - We should find NO significant effect                                   ║
║                                                                              ║
║  2. FAKE (PLACEBO) OUTCOME VARIABLE                                          ║
║     - Use an outcome that should NOT be affected by the treatment            ║
║     - If we find a significant effect, something else is going on            ║
║     - We should find NO significant effect                                   ║
║                                                                              ║
║  3. FAKE (PLACEBO) CONTROL GROUP                                             ║
║     - Compare the treatment group to a different group that was also         ║
║       NOT treated but might be less comparable                               ║
║     - Or compare two untreated groups to each other                          ║
║     - We should find NO significant effect                                   ║
╚══════════════════════════════════════════════════════════════════════════════╝
*/


* ============================================================================
**# TEST 1: PLACEBO (FAKE) TREATMENT TIMING
* ============================================================================

/*
LOGIC: If we move the treatment date to a time BEFORE the actual treatment,
we should find NO significant effect. If we do find one, it means the
treated group was already diverging from the control group before the
real treatment — violating parallel trends.
*/

* --- Reload the panel data ---
clear all
set seed 12345
set obs 1000
gen id = mod(_n - 1, 100) + 1
bysort id: gen time = _n
gen treat_group = (id <= 50)
gen post = (time >= 6)                      // Real treatment at t=6
gen treat_post = treat_group * post
gen y = 10 + 2*treat_group + 0.5*time + 3*treat_post + rnormal(0, 2)

* --- Restrict to PRE-TREATMENT period only ---
preserve
    keep if time <= 5                       // Only keep pre-treatment data

    * --- Create a FAKE treatment at time period 3 ---
    gen fake_post = (time >= 3)             // Pretend treatment happened at t=3
    gen fake_treat_post = treat_group * fake_post   // Fake DiD interaction

    * --- Run the placebo DiD regression ---
    reg y treat_group fake_post fake_treat_post, robust

    /*
    INTERPRETATION:
    - The coefficient on fake_treat_post should be SMALL and INSIGNIFICANT
    - If it IS significant → evidence of differential pre-trends
    - This is a RED FLAG for the parallel trends assumption
    
    In our simulated data, since we built in true parallel pre-trends,
    the fake treatment effect should be close to zero.
    */
restore


* ============================================================================
**# TEST 2: PLACEBO (FAKE) OUTCOME VARIABLE
* ============================================================================

/*
LOGIC: If the treatment only affects employment (the real outcome), it
should NOT affect other outcomes like, say, the price of french fries.
If we find that the treatment "affects" an unrelated outcome, this
suggests our identification strategy may be picking up something
other than the true treatment effect (e.g., a common shock that
differentially affects the treatment group).

Example from Card & Krueger: If NJ's minimum wage increase affected
employment, it should NOT affect, say, the number of cash registers
per store (a structural feature unlikely to change in the short run).
*/

* --- Generate a fake outcome that is NOT affected by treatment ---
gen y_fake = 5 + 1.5*treat_group + 0.3*time + rnormal(0, 1.5)


/*
Notice: y_fake does NOT include a treat_post term!
So there is genuinely no treatment effect on this variable.
*/

label variable y_fake "Placebo Outcome (not affected by treatment)"

* --- Run DiD on the fake outcome ---
reg y_fake i.treat_group##i.post, robust

/*
INTERPRETATION:
- The interaction coefficient (treat_group#post) should be ≈ 0
- If significant → suggests our DiD setup has problems
  (perhaps an omitted variable correlated with treatment timing)
*/


* ============================================================================
**# TEST 3: PLACEBO (FAKE) CONTROL GROUP
* ============================================================================

/*
LOGIC: Compare TWO UNTREATED groups using DiD. If we find a "treatment effect"
between two groups that were both untreated, something is wrong with
our assumption that the control group provides a valid counterfactual.

Alternatively: use the treatment group but compare to a DIFFERENT
control group. The estimate should be similar if the parallel trends
assumption holds across different comparison groups.
*/

* --- Create a third group (another control group) ---
gen group3 = (id > 50 & id <= 75)          // Units 51-75: control group A
gen group4 = (id > 75)                     // Units 76-100: control group B

* --- Compare two UNTREATED groups ---
preserve
    keep if treat_group == 0                // Keep only control units
    
    gen fake_treat = (id <= 75)             // Arbitrary split of control group
    gen fake_interaction = fake_treat * post // Fake DiD interaction
    
    reg y fake_treat post fake_interaction, robust
    
    /*
    INTERPRETATION:
    - fake_interaction should be ≈ 0 and insignificant
    - If significant → the two halves of the control group have different
      trends, suggesting that "control group" is heterogeneous
    - This raises concerns about whether ANY single control group is valid
    */
restore


/*
╔══════════════════════════════════════════════════════════════════════════════╗
║  SUMMARY OF PLACEBO TESTS:                                                   ║
║                                                                              ║
║  Test                    What you should find     What a failure means       ║
║  ──────────────────────  ─────────────────────    ──────────────────────     ║
║  Fake treatment timing   No significant effect    Pre-trends are different   ║
║  Fake outcome variable   No significant effect    Omitted confounders exist  ║
║  Fake control group      No significant effect    Control group is invalid   ║
║                                                                              ║
║  All three tests should produce NULL results if DiD is valid.                ║
╚══════════════════════════════════════════════════════════════════════════════╝
*/



********************************************************************************
**# SECTION 5: STAGGERED DIFFERENCE-IN-DIFFERENCES                              *
********************************************************************************

/*
╔══════════════════════════════════════════════════════════════════════════════╗
║  STAGGERED DiD (TWFE AND ITS PROBLEMS)                                       ║
║                                                                              ║
║  In many real-world settings, treatment is NOT adopted simultaneously.       ║
║  Different units (states, firms, individuals) adopt treatment at different   ║
║  times. This is called "staggered adoption" or "staggered DiD."             ║
║                                                                              ║
║  THE TRADITIONAL APPROACH: Two-Way Fixed Effects (TWFE)                      ║
║    Y_it = α_i + λ_t + β * D_it + ε_it                                       ║
║                                                                              ║
║  Where:                                                                      ║
║    α_i  = unit fixed effects (control for time-invariant differences)        ║
║    λ_t  = time fixed effects (control for common shocks)                     ║
║    D_it = treatment indicator (=1 when unit i is treated at time t)          ║
║    β    = "average" treatment effect                                         ║
║                                                                              ║
║  THE PROBLEM WITH TWFE (Goodman-Bacon 2021, de Chaisemartin & D'Haultfœuille ║
║  2020, Sun & Abraham 2021):                                                  ║
║                                                                              ║
║  When treatment effects are HETEROGENEOUS (varying across time or groups),   ║
║  TWFE can give BIASED and even WRONG-SIGNED estimates because:               ║
║    1. It uses already-treated units as controls (bad comparisons)            ║
║    2. It gives negative weights to some group-time effects                   ║
║    3. Early adopters get compared to late adopters and vice versa            ║
║                                                                              ║
║  MODERN SOLUTIONS:                                                           ║
║    - Callaway & Sant'Anna (2021): csdid / did_multiplegt                     ║
║    - Sun & Abraham (2021): eventstudyinteract                                ║
║    - Borusyak, Jaravel, & Spiess (2024): did_imputation                      ║
║    - Gardner (2022): did2s — two-stage DiD                                   ║
║                                                                              ║
║  We will demonstrate TWFE and then the Callaway-Sant'Anna approach.          ║
╚══════════════════════════════════════════════════════════════════════════════╝
*/


* --- Install necessary packages ---
* Run these once if not already installed:
* ssc install reghdfe
* ssc install ftools
* ssc install csdid
* ssc install drdid
* ssc install event_plot

* --- Load staggered DiD dataset from the Mixtape ---
* We use the castle doctrine dataset (Cheng & Hoekstra 2013)
use "https://github.com/scunning1975/mixtape/raw/master/castle.dta", clear

describe                                    // Explore the data
tab year                                    // Check time periods
tab state                                   // Check states

/*
CONTEXT: Castle Doctrine / Stand Your Ground Laws
Many US states adopted "castle doctrine" (stand your ground) laws at
different times. We want to estimate the effect on homicide rates.
This is a classic staggered adoption setting.

KEY VARIABLES:
  - state:      State identifier
  - year:       Year
  - post:       =1 if the state has adopted the law by that year
  - l_homicide: Log homicide rate (outcome)
*/

* --- Traditional TWFE approach ---
* WARNING: This may be biased with heterogeneous treatment effects!

xtset sid year                              // Declare panel: unit=sid, time=year

xtreg l_homicide post i.year, fe vce(cluster sid)   // TWFE regression
est store twfe                              // Store results

/*
INTERPRETATION:
The coefficient on 'post' is the TWFE estimate of the effect of castle
doctrine laws on log homicide rates. 

HOWEVER, this estimate may be contaminated by:
  - Negative weights on some group-time ATTs
  - Already-treated units serving as controls
  - Heterogeneous effects being averaged in misleading ways
*/


* --- Callaway & Sant'Anna (2021) Estimator ---
/*
The csdid command estimates group-time average treatment effects (ATT(g,t))
separately for each cohort (group defined by treatment timing), then
aggregates them properly.

Benefits:
  - Never uses already-treated units as controls
  - Allows for heterogeneous effects across groups and time
  - Provides clean event-study plots
*/

* Generate the treatment timing variable (year first treated; 0 if never)
gen first_treated = .                       // Initialize
* Note: In the castle dataset, we need to identify when each state adopted

* For illustration, let's identify the first year of treatment per state
bysort sid (year): egen ever_treated = max(post)    // Did the state ever adopt?
bysort sid (year): egen first_treat_year = min(cond(post==1, year, .))
replace first_treat_year = 0 if ever_treated == 0  // Never-treated → 0

tab first_treat_year                        // Check treatment cohorts

* --- Run Callaway & Sant'Anna ---
* Step 1: Estimate group-time ATTs (no aggregation at this stage)
csdid l_homicide, ivar(sid) time(year) gvar(first_treat_year) notyet

* Step 2: Aggregate using estat or csdid_stats
* Simple aggregation: weighted average of all group-time ATTs
estat simple                                // Simple average ATT

/*
INTERPRETING CSDID OUTPUT:
  - ATT: The average treatment effect on the treated
  - Group-time ATTs: effect for each treatment cohort at each time
  - estat simple: simple average of all group-time ATTs
  - estat event: event-study aggregation (by time relative to treatment)
  - estat group: average by treatment cohort
  - estat calendar: average by calendar time
*/

* --- Event Study with csdid ---
* Step 3: Dynamic (event-study) aggregation
estat event                                 // Event-study style aggregation

* --- Plot the event study from csdid ---
csdid_plot, title("Callaway & Sant'Anna Event Study")  ///
    xtitle("Periods Relative to Treatment")             ///
    ytitle("ATT Estimate")

graph export "csdid_event_study.png", replace width(1200)

/*
╔══════════════════════════════════════════════════════════════════════════════╗
║  WHY CSDID IS PREFERRED OVER TWFE:                                           ║
║                                                                              ║
║  1. Clean comparisons: Only uses not-yet-treated or never-treated as controls║
║  2. No negative weighting of treatment effects                               ║
║  3. Transparent: You can see each group-time effect                          ║
║  4. Aggregation is done properly after estimation                            ║
║  5. Built-in event study plot                                                ║
║                                                                              ║
║  See Goodman-Bacon (2021) "Difference-in-Differences with Variation in       ║
║  Treatment Timing" for the decomposition of TWFE bias.                       ║
╚══════════════════════════════════════════════════════════════════════════════╝
*/



********************************************************************************
**# SECTION 6: RING DIFFERENCE-IN-DIFFERENCES                                   *
********************************************************************************

/*
╔══════════════════════════════════════════════════════════════════════════════╗
║  RING DiD (GEOGRAPHIC / SPATIAL DiD)                                         ║
║                                                                              ║
║  Ring DiD exploits GEOGRAPHIC proximity to define treatment and control.     ║
║  The idea: when a policy or event is location-specific, nearby units that    ║
║  are JUST OUTSIDE the affected area serve as a natural control group.        ║
║                                                                              ║
║  WHY USE RING DiD?                                                           ║
║  - Units that are geographically close are likely more comparable than       ║
║    units far away (similar demographics, labor markets, etc.)                ║
║  - Reduces concerns about selection bias — geographic boundaries are         ║
║    often arbitrary (e.g., state borders, district lines)                     ║
║  - Can be combined with regression discontinuity in space                    ║
║                                                                              ║
║  STRUCTURE:                                                                  ║
║  - "Inner Ring" = Treatment group (within the policy boundary)               ║
║  - "Outer Ring" = Control group (just outside the boundary)                  ║
║  - Exclude units FAR from the boundary (less comparable)                     ║
║  - Apply standard DiD to the inner vs. outer ring                            ║
║                                                                              ║
║  EXAMPLE: A new factory opens. Inner ring = areas within 5km of factory.     ║
║  Outer ring = areas 5-10km from factory. Exclude areas beyond 10km.          ║
║                                                                              ║
║  Formally:                                                                   ║
║    Y_it = β0 + β1*InnerRing_i + β2*Post_t + β3*(InnerRing_i×Post_t)        ║
║           + f(distance_i) + X_it'γ + ε_it                                   ║
║                                                                              ║
║  Where f(distance) is a flexible function of distance to the boundary        ║
║  (optional, helps control for smooth spatial trends).                        ║
║                                                                              ║
║  ROBUSTNESS:                                                                 ║
║  - Vary the ring widths (e.g., 2km vs 5km vs 10km)                          ║
║  - If results are stable across different ring sizes → more credible         ║
║  - If results change dramatically → sensitive to comparison group choice     ║
╚══════════════════════════════════════════════════════════════════════════════╝
*/


* --- Simulate a Ring DiD dataset ---
clear all
set seed 54321
set obs 2000                                // 2000 spatial units

* --- Generate spatial locations ---
gen x_coord = runiform(0, 100)              // X coordinate (0-100 km)
gen y_coord = runiform(0, 100)              // Y coordinate (0-100 km)

* --- Treatment is location-based: new policy in a central district ---
* The "policy zone" is centered at (50, 50) with radius 20km
gen distance = sqrt((x_coord - 50)^2 + (y_coord - 50)^2) // Distance from center
gen in_policy_zone = (distance <= 20)       // Inside the policy area

* --- Define the RINGS ---
gen inner_ring = (distance <= 20)           // Treatment: within 20km
gen outer_ring = (distance > 20 & distance <= 35) // Control: 20-35km (buffer)
gen far_away = (distance > 35)              // Excluded: too far to be comparable

label variable inner_ring "Inner Ring (Treatment)"
label variable outer_ring "Outer Ring (Control)"

* --- Keep only the inner and outer rings ---
keep if inner_ring == 1 | outer_ring == 1   // Drop far-away units
gen ring_sample = 1                         // Flag for ring sample

* --- Create panel (2 time periods) ---
expand 2                                    // Duplicate each observation
bysort x_coord y_coord: gen time = _n       // time = 1 (pre) or 2 (post)
gen post = (time == 2)                      // Post-treatment indicator

* --- Generate outcome with treatment effect ---
gen y = 50 + 5*inner_ring - 0.2*distance + 3*post ///
        + 4*(inner_ring * post) + rnormal(0, 3)
/*
  Treatment effect (inner_ring × post) = 4
  Also includes: distance gradient, level difference, time trend
*/

label variable y "Outcome (e.g., House Prices in $1000s)"
label variable distance "Distance from Policy Center (km)"

* --- Ring DiD Regression ---
* Basic specification
reg y inner_ring post c.inner_ring#c.post, robust
est store ring1                             // Store results

/*
INTERPRETATION:
The coefficient on inner_ring#post is the Ring DiD estimate.
It compares the change in outcome for inner ring (treatment) vs.
outer ring (control) units before and after the policy.
*/

* --- Ring DiD with distance control ---
reg y inner_ring post c.inner_ring#c.post distance, robust
est store ring2                             // Store with distance control

* --- Ring DiD with flexible distance control ---
gen dist_sq = distance^2                    // Quadratic distance term
reg y inner_ring post c.inner_ring#c.post distance dist_sq, robust
est store ring3                             // Store with quadratic distance

* --- Compare specifications ---
est table ring1 ring2 ring3, stat(r2 N) b(%9.3f) se(%9.3f)

/*
ROBUSTNESS CHECK: Vary the ring width
If results are robust to different outer ring definitions, the estimate
is more credible.
*/

* --- Sensitivity to ring width ---
* We re-generate the data for each outer boundary width
* Note: We cannot use preserve/restore with clear all inside the loop
foreach outer_boundary in 25 30 35 40 {
    clear
    set seed 54321
    set obs 2000
    gen x_coord = runiform(0, 100)
    gen y_coord = runiform(0, 100)
    gen distance = sqrt((x_coord - 50)^2 + (y_coord - 50)^2)
    gen inner_ring = (distance <= 20)
    gen outer_ring = (distance > 20 & distance <= `outer_boundary')
    keep if inner_ring == 1 | outer_ring == 1
    expand 2
    bysort x_coord y_coord: gen time = _n
    gen post = (time == 2)
    gen y = 50 + 5*inner_ring - 0.2*distance + 3*post ///
            + 4*(inner_ring * post) + rnormal(0, 3)
    
    qui reg y i.inner_ring##i.post, robust
    di "Outer boundary = `outer_boundary' km: DiD = " _b[1.inner_ring#1.post]
}

/*
╔══════════════════════════════════════════════════════════════════════════════╗
║  RING DiD KEY POINTS:                                                        ║
║                                                                              ║
║  1. Geographic proximity → better counterfactual                             ║
║  2. Inner ring = treated, Outer ring = control, Far = excluded               ║
║  3. Control for distance to boundary (smooth spatial confounders)            ║
║  4. Vary ring widths for robustness (donut-hole analysis)                    ║
║  5. Often combined with spatial fixed effects (e.g., county FE)              ║
║  6. Works well for location-specific policies: zoning, enterprise zones,     ║
║     school districts, environmental regulations, infrastructure projects     ║
╚══════════════════════════════════════════════════════════════════════════════╝
*/



********************************************************************************
**# SECTION 7: ADVANCED DiD APPLICATIONS                                        *
********************************************************************************

/*
╔══════════════════════════════════════════════════════════════════════════════╗
║  ADVANCED DiD TOPICS                                                         ║
║                                                                              ║
║  This section covers:                                                        ║
║    A. Triple Differences (DDD)                                               ║
║    B. DiD with Matching / Propensity Score Weighting                         ║
║    C. Goodman-Bacon Decomposition                                            ║
╚══════════════════════════════════════════════════════════════════════════════╝
*/


* ============================================================================
**# 7A: TRIPLE DIFFERENCES (DDD)
* ============================================================================

/*
DDD adds a THIRD difference to strengthen identification.

Example: A policy targets women (but not men) in state A (but not state B)
after year T. The three differences are:
  1. Before vs. After
  2. Treated state vs. Control state
  3. Affected subgroup (women) vs. Unaffected subgroup (men)

Y_it = β0 + β1*State + β2*Post + β3*Female + β4*State×Post 
       + β5*State×Female + β6*Post×Female 
       + β7*State×Post×Female + ε

β7 is the DDD estimate: it nets out:
  - Any general time trends
  - Any state-specific trends
  - Any gender-specific trends
  - Any state×time shocks (affecting both genders)
  - Any gender×time trends (affecting both states)
*/

* --- Simulate DDD data ---
clear all
set seed 11111
set obs 4000

gen id = _n
gen state = (id <= 2000)                    // 1 = treatment state
gen female = mod(id, 2)                     // 1 = female (affected subgroup)
expand 2                                    // Two time periods
bysort id: gen time = _n
gen post = (time == 2)

* DDD treatment effect: only for treated state × female × post
gen y = 20 + 3*state + 2*female + 1*post + 0.5*state*post ///
        + 1*state*female + 0.3*post*female ///
        + 5*(state * post * female) + rnormal(0, 2)
/*
The TRUE DDD effect = 5 (only women in the treated state are affected post)
*/

* --- DDD Regression ---
reg y i.state##i.post##i.female, robust

/*
INTERPRETATION:
The three-way interaction (state#post#female) = DDD estimate ≈ 5
This is robust to:
  - State-specific shocks affecting both genders
  - Gender-specific trends affecting both states
*/


* ============================================================================
**# 7B: DiD WITH MATCHING / PROPENSITY SCORE WEIGHTING
* ============================================================================

/*
When treatment and control groups differ in observable characteristics,
we can combine DiD with matching or inverse probability weighting (IPW)
to reweight the control group to look more like the treatment group.

This is the approach in Callaway & Sant'Anna (2021) with the 'dripw' option.
Sant'Anna & Zhao (2020) provide the doubly robust DiD estimator.

The idea: 
  1. Estimate propensity scores (probability of being treated)
  2. Reweight or match to balance pre-treatment characteristics
  3. Apply DiD to the balanced sample

This relaxes the parallel trends assumption to: parallel trends 
CONDITIONAL ON observables.
*/

* Load the NSW dataset from the root of the Mixtape repo
use "H:\My Drive\YRF 24 Classes\YRF 2025 DID and RDD class\nsw_mixtape.dta", clear

* Create the first-difference outcome for the DiD (Post - Pre)
* re78 is earnings in 1978 (post-treatment)
* re75 is earnings in 1975 (pre-treatment)
gen delta_re = re78 - re75

* 1. Baseline DiD (Unweighted / No Matching)
* ---------------------------------------------------------
reg delta_re treat, robust

* =========================================================
* 2. DiD with Propensity Score Matching (via IPW)
* =========================================================


* Estimate the propensity score using baseline covariates
* We include 1974 and 1975 earnings to capture pre-treatment economic trends
logit treat age educ black hisp married nodegree re74 re75
predict pscore, pr

* Generate Inverse Probability Weights (IPW) for the ATT 
* (Average Treatment Effect on the Treated)
gen ipw_att = .
replace ipw_att = 1 if treat == 1
replace ipw_att = pscore / (1 - pscore) if treat == 0

* Run the DiD regression using the IPW weights
* Using pweight is crucial here for correct standard error calculations
reg delta_re treat [pweight=ipw_att], robust

* =========================================================
* 3. DiD with Entropy Balancing
* =========================================================
* Note: You must install the ebalance package first if you haven't:
* ssc install ebalance, replace

* Run entropy balancing to find weights that equate the moments 
* of the covariates between the control and treatment groups.
* The targets(1) option ensures we are estimating the ATT by 
* balancing the control group's moments to match the treated group.
ebalance treat age educ black hisp married nodegree re74 re75, targets(1)

* ebalance automatically generates a weight variable called _webal.
* Ensure treated units have a weight of 1 (ebalance usually leaves them as missing or 1)
replace _webal = 1 if treat == 1 & missing(_webal)

* Run the DiD regression using the entropy balancing weights
* Using aweight or iweight is standard practice for ebalance outputs
reg delta_re treat [aweight=_webal], robust


* ============================================================================
**# 7C: GOODMAN-BACON DECOMPOSITION
* ============================================================================

/*
Goodman-Bacon (2021) showed that the TWFE DiD estimate is a weighted
average of ALL possible 2x2 DiD comparisons, including:
  - Treated vs. never-treated (good comparisons)
  - Treated vs. not-yet-treated (okay comparisons)
  - Early-treated vs. late-treated (potentially problematic)
  - Late-treated vs. already-treated (PROBLEMATIC — uses treated as control)

The bacondecomp command visualizes these weights and sub-estimates.
*/

* ssc install bacondecomp                   // Install if needed

use "https://github.com/scunning1975/mixtape/raw/master/castle.dta", clear

xtset sid year

bacondecomp l_homicide post, ddetail

/*
INTERPRETING BACONDECOMP:
  - Each point is a 2x2 DiD comparison
  - X-axis: weight in the overall TWFE estimate
  - Y-axis: the 2x2 DiD estimate
  - Colors/shapes: type of comparison
  - The weighted average of all points = TWFE estimate
  
If the "already treated vs. later treated" comparisons have very different
estimates or large weights, the TWFE estimate may be unreliable.
*/

graph export "bacon_decomposition.png", replace width(1200)



********************************************************************************
*=============================================================================*
*                                                                              *
**#                PART II: REGRESSION DISCONTINUITY DESIGN (RDD)                *
*                                                                              *
*=============================================================================*
********************************************************************************

/*
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║  WHAT IS REGRESSION DISCONTINUITY DESIGN (RDD)?                              ║
║                                                                              ║
║  RDD exploits situations where treatment assignment is determined            ║
║  (fully or partially) by whether a continuous "running variable" (also       ║
║  called "forcing variable" or "score") crosses a known CUTOFF.               ║
║                                                                              ║
║  Example: Students scoring ≥ 70 on an exam get a scholarship.               ║
║    Running variable = exam score                                             ║
║    Cutoff = 70                                                               ║
║    Treatment = receiving the scholarship                                     ║
║    Outcome = future earnings, GPA, etc.                                      ║
║                                                                              ║
║  KEY INTUITION:                                                              ║
║  Students scoring 69.9 and 70.1 are essentially identical in ability,        ║
║  but one gets the scholarship and the other doesn't. Near the cutoff,        ║
║  treatment assignment is "as good as random."                                ║
║                                                                              ║
║  This is often called "nature's experiment" or a "natural experiment."       ║
║                                                                              ║
║  TWO TYPES:                                                                  ║
║  1. SHARP RDD: Treatment is deterministic — everyone above the cutoff       ║
║     is treated, everyone below is not. Pr(D=1|X≥c) = 1, Pr(D=1|X<c) = 0    ║
║  2. FUZZY RDD: The cutoff creates a JUMP in the probability of treatment    ║
║     but not 100% compliance. Some above the cutoff don't get treated,        ║
║     some below do. This is like an IV/2SLS setup.                            ║
║                                                                              ║
║  The RDD estimator focuses on the LOCAL effect at the cutoff:                ║
║    τ_RDD = lim_{x→c⁺} E[Y|X=x] - lim_{x→c⁻} E[Y|X=x]                     ║
║                                                                              ║
║  This is the LATE (Local Average Treatment Effect) at the cutoff.            ║
║                                                                              ║
║  References:                                                                 ║
║    - Imbens & Lemieux (2008), "RDD in Economics"                             ║
║    - Lee & Lemieux (2010), "RDD in Economics"                                ║
║    - Cattaneo, Idrobo, & Titiunik (2020), "A Practical Introduction to RDD" ║
║    - The Effect, Chapter on RDD                                              ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
*/



********************************************************************************
**# SECTION 8: SHARP RDD — BASIC SETUP AND VISUALIZATION                        *
********************************************************************************

/*
EXAMPLE: Effect of class size on student achievement.

Maimonides' Rule (Angrist & Lavy, 1999):
In Israel, maximum class size is 40. When enrollment exceeds a multiple
of 40, an additional class is opened:
  - 40 students → 1 class of 40
  - 41 students → 2 classes of ~20
  
The running variable is enrollment, and the cutoff creates a sharp
change in class size. We'll simulate a simplified version.
*/


* --- Simulate a Sharp RDD dataset ---
clear all
set seed 42
set obs 1000                                // 1000 students

* --- Generate the running variable (exam score, centered at cutoff) ---
gen score = rnormal(0, 10)                  // Exam score, centered at 0

* --- Define treatment ---
* Treatment if score >= 0 (the cutoff is at 0)
gen treat = (score >= 0)                    // Sharp RDD: deterministic at cutoff
label variable treat "Treatment (Score ≥ Cutoff)"
label variable score "Running Variable (Score - Cutoff)"

* --- Generate potential outcomes ---
* Outcome depends on score (continuously) + treatment effect at cutoff
gen y = 50 + 3*score + 0.05*score^2 + 5*treat + rnormal(0, 5)
/*
  y = 50            (baseline)
    + 3*score       (linear relationship with score)
    + 0.05*score^2  (slight curvature)
    + 5*treat       (TRUE treatment effect = 5 at the cutoff)
    + noise
*/

label variable y "Outcome (e.g., GPA × 10)"


* --- VISUALIZATION: The RDD Plot ---
/*
The most important first step in any RDD analysis is to PLOT the data.
We want to see:
  1. Is there a visible JUMP at the cutoff?
  2. What is the functional form of Y as a function of the running variable?
*/

* Method 1: Scatter plot with fitted lines on each side
twoway (scatter y score if treat == 0, mcolor(navy%30) msize(tiny))             ///
       (scatter y score if treat == 1, mcolor(cranberry%30) msize(tiny))        ///
       (lfit y score if treat == 0, lcolor(navy) lwidth(thick))                 ///
       (lfit y score if treat == 1, lcolor(cranberry) lwidth(thick)),           ///
       xline(0, lcolor(gs8) lpattern(dash) lwidth(medium))                     ///
       legend(order(3 "Control fit" 4 "Treatment fit") ring(0) pos(11))         ///
       title("Sharp RDD: Jump at the Cutoff", size(medium))                    ///
       xtitle("Running Variable (Score - Cutoff)")                              ///
       ytitle("Outcome")                                                        ///
       note("Dashed line = cutoff. Visual jump = treatment effect.")            ///
       graphregion(color(white)) plotregion(color(white))

graph export "sharp_rdd_scatter.png", replace width(1200)


* Method 2: Binned scatter plot (RDD standard — less noisy)
/*
Binned scatter: divide the running variable into bins, compute the mean
outcome within each bin, and plot the bin means. This is cleaner than
plotting all individual data points.
*/

* Create bins
gen score_bin = round(score, 1)             // Bin width = 1 unit of score
collapse (mean) y_mean = y (count) n = y, by(score_bin treat)

twoway (scatter y_mean score_bin if treat == 0, mcolor(navy) msymbol(circle))   ///
       (scatter y_mean score_bin if treat == 1, mcolor(cranberry) msymbol(circle)) ///
       (lfit y_mean score_bin if treat == 0, lcolor(navy) lwidth(thick))        ///
       (lfit y_mean score_bin if treat == 1, lcolor(cranberry) lwidth(thick)),  ///
       xline(0, lcolor(gs8) lpattern(dash))                                    ///
       legend(order(1 "Control bins" 2 "Treatment bins") ring(0) pos(11))       ///
       title("Sharp RDD: Binned Scatter Plot", size(medium))                   ///
       xtitle("Running Variable (Score - Cutoff)")                              ///
       ytitle("Mean Outcome")                                                   ///
       graphregion(color(white)) plotregion(color(white))

graph export "sharp_rdd_binned.png", replace width(1200)



********************************************************************************
**# SECTION 9: SHARP RDD — REGRESSION APPROACHES                                *
********************************************************************************

* --- Reload the data ---
clear all
set seed 42
set obs 1000
gen score = rnormal(0, 10)
gen treat = (score >= 0)
gen y = 50 + 3*score + 0.05*score^2 + 5*treat + rnormal(0, 5)


/*
╔══════════════════════════════════════════════════════════════════════════════╗
║  RDD REGRESSION APPROACHES                                                   ║
║                                                                              ║
║  There are several ways to estimate the treatment effect at the cutoff:      ║
║                                                                              ║
║  1. PARAMETRIC: Global polynomial regression                                 ║
║     Y = β0 + β1*treat + f(score) + ε                                        ║
║     Where f() is a polynomial (linear, quadratic, cubic)                     ║
║     + Allow different slopes on each side of the cutoff                      ║
║                                                                              ║
║  2. NON-PARAMETRIC: Local polynomial regression (preferred)                  ║
║     Use only data NEAR the cutoff (within a bandwidth h)                     ║
║     Fit low-order polynomials (usually linear) within the bandwidth          ║
║     Use rdrobust for optimal bandwidth selection and inference               ║
║                                                                              ║
║  Modern best practice strongly favors the local polynomial approach          ║
║  with rdrobust (Cattaneo, Idrobo, & Titiunik 2019).                         ║
╚══════════════════════════════════════════════════════════════════════════════╝
*/


* --- APPROACH 1: Global Linear Regression ---
reg y treat score, robust                   // Linear, same slope both sides

/*
PROBLEM: This assumes the same linear slope on both sides of the cutoff.
If the true relationship is nonlinear, this can bias the estimate.
*/


* --- APPROACH 2: Allow Different Slopes (interacted model) ---
gen score_treat = score * treat             // Interaction: allows different slopes

reg y treat score score_treat, robust       // Different slopes on each side

/*
This model:
  Y = β0 + β1*treat + β2*score + β3*(score×treat) + ε

  For score < 0 (control): Y = β0 + β2*score
  For score ≥ 0 (treated): Y = (β0+β1) + (β2+β3)*score
  
  β1 = treatment effect at score = 0 (the cutoff)
*/


* --- APPROACH 3: Quadratic polynomial with different slopes ---
gen score_sq = score^2                      // Quadratic term
gen score_sq_treat = score_sq * treat       // Quadratic interaction

reg y treat score score_treat score_sq score_sq_treat, robust


* --- APPROACH 4: Local Linear Regression (restrict bandwidth manually) ---
/*
Use only observations near the cutoff. The "bandwidth" (h) determines
how far from the cutoff we look. Smaller h → less bias but more variance.
*/

* Bandwidth h = 5
reg y treat score score_treat if abs(score) <= 5, robust
est store bw5

* Bandwidth h = 3
reg y treat score score_treat if abs(score) <= 3, robust
est store bw3

* Bandwidth h = 10
reg y treat score score_treat if abs(score) <= 10, robust
est store bw10

est table bw3 bw5 bw10, stat(N) b(%9.3f) se(%9.3f)

/*
INTERPRETATION:
Compare the treatment effect across different bandwidths.
If the estimate is stable → robust to bandwidth choice.
If it changes a lot → sensitive; rely on formal bandwidth selection.
*/


* --- APPROACH 5: rdrobust (THE GOLD STANDARD) ---
/*
rdrobust implements:
  - Optimal bandwidth selection (Imbens & Kalyanaraman 2012,
    Cattaneo, Calonico, & Titiunik 2014)
  - Bias-corrected confidence intervals
  - Robust inference
  
Install: ssc install rdrobust
         ssc install rdlocrand
         ssc install rddensity
*/

* ssc install rdrobust                      // Install if needed

rdrobust y score, c(0)                      // Optimal bandwidth, local polynomial

/*
INTERPRETING RDROBUST OUTPUT:
  - Conventional: Standard local polynomial estimate
  - Bias-Corrected: Adjusts for bias from using a finite bandwidth  
  - Robust: Recommended — bias-corrected with robust standard errors
  
  The "Robust" row is what you should report.
  
  Also reports:
  - BW est. (h): Optimal bandwidth selected
  - BW bias (b): Bandwidth for bias correction
  - N_h: Number of observations within the bandwidth on each side
*/

* --- rdplot: The professional RDD plot ---
rdplot y score, c(0) graph_options(                                             ///
    title("RD Plot (rdplot)")                                                   ///
    xtitle("Running Variable (Score - Cutoff)")                                 ///
    ytitle("Outcome")                                                           ///
    graphregion(color(white)))

graph export "rdplot.png", replace width(1200)

/*
rdplot automatically:
  - Selects optimal bin widths (IMSE-optimal)
  - Fits local polynomials on each side
  - Shows bin means with fitted curves
  - Displays the discontinuity clearly
*/


* --- Sensitivity to bandwidth ---
rdrobust y score, c(0) h(3)                 // Narrow bandwidth
rdrobust y score, c(0) h(5)                 // Medium bandwidth
rdrobust y score, c(0) h(10)               // Wide bandwidth

/*
Report results for different bandwidths to show robustness.
The main result should use the data-driven optimal bandwidth.
*/


* --- Different polynomial orders ---
rdrobust y score, c(0) p(1)                 // Local linear (default, recommended)
rdrobust y score, c(0) p(2)                 // Local quadratic

/*
Local linear (p=1) is generally preferred because:
  1. Less overfitting near the boundary
  2. Better theoretical properties
  3. Recommended by Cattaneo, Idrobo, & Titiunik (2020)
*/



********************************************************************************
**# SECTION 10: FUZZY RDD                                                       *
********************************************************************************

/*
╔══════════════════════════════════════════════════════════════════════════════╗
║  FUZZY RDD                                                                   ║
║                                                                              ║
║  In a SHARP RDD, crossing the cutoff PERFECTLY determines treatment.         ║
║  In a FUZZY RDD, crossing the cutoff INCREASES the probability of           ║
║  treatment but not to 100%. There is "imperfect compliance."                ║
║                                                                              ║
║  Example: Students scoring ≥ 70 are ELIGIBLE for a scholarship, but:        ║
║    - Some eligible students don't apply (don't take up treatment)            ║
║    - Some ineligible students get the scholarship through appeals            ║
║                                                                              ║
║  This is analogous to an INSTRUMENTAL VARIABLES (IV) setting:               ║
║    - The instrument = being above the cutoff (Z = 1[X ≥ c])                 ║
║    - First stage: Z → Treatment (D)                                         ║
║    - Reduced form: Z → Outcome (Y)                                          ║
║    - IV/2SLS estimate: Reduced form / First stage = LATE                    ║
║                                                                              ║
║  Formally:                                                                   ║
║    τ_fuzzy = lim_{x→c⁺} E[Y|X=x] - lim_{x→c⁻} E[Y|X=x]                   ║
║              ─────────────────────────────────────────────                   ║
║              lim_{x→c⁺} E[D|X=x] - lim_{x→c⁻} E[D|X=x]                   ║
║                                                                              ║
║  This is the ratio of the jump in Y to the jump in D at the cutoff.         ║
║  It estimates the LATE for compliers at the cutoff.                          ║
╚══════════════════════════════════════════════════════════════════════════════╝
*/


* --- Simulate a Fuzzy RDD dataset ---
clear all
set seed 99
set obs 1000

gen score = rnormal(0, 10)                  // Running variable centered at cutoff

* --- Fuzzy treatment: probability jumps at cutoff but not from 0 to 1 ---
gen above = (score >= 0)                    // Indicator for above cutoff

* Treatment probability: 20% below cutoff, 80% above
gen prob_treat = 0.2 + 0.6 * above         // Jump in probability at cutoff
gen treat = (runiform() < prob_treat)       // Actual treatment (fuzzy!)

tab above treat                             // Cross-tab: imperfect compliance

* --- Generate outcome ---
gen y = 40 + 2*score + 8*treat + rnormal(0, 6)
/*
  TRUE treatment effect on treated = 8
  But not everyone above the cutoff is treated (fuzzy!)
*/

label variable score "Running Variable (Score - Cutoff)"
label variable treat "Actually Treated"
label variable above "Above Cutoff (Instrument)"
label variable y "Outcome"


* --- Visualize the Fuzzy RDD ---
* First Stage: Jump in treatment probability at the cutoff
gen score_bin = round(score, 1)

preserve
    collapse (mean) treat_mean = treat y_mean = y, by(score_bin above)
    
    * First stage plot: treatment probability
    twoway (scatter treat_mean score_bin if score_bin < 0, mcolor(navy))        ///
           (scatter treat_mean score_bin if score_bin >= 0, mcolor(cranberry))   ///
           (lfit treat_mean score_bin if score_bin < 0, lcolor(navy) lwidth(thick)) ///
           (lfit treat_mean score_bin if score_bin >= 0, lcolor(cranberry) lwidth(thick)), ///
           xline(0, lcolor(gs8) lpattern(dash))                                ///
           legend(off)                                                          ///
           title("Fuzzy RDD: First Stage", size(medium))                       ///
           subtitle("Jump in treatment probability at the cutoff")              ///
           xtitle("Running Variable") ytitle("Pr(Treatment)")                   ///
           graphregion(color(white)) plotregion(color(white)) name(fuzzy_1st)
    
    graph export "fuzzy_rdd_first_stage.png", replace width(1200)
    
    * Reduced form plot: jump in outcome
    twoway (scatter y_mean score_bin if score_bin < 0, mcolor(navy))            ///
           (scatter y_mean score_bin if score_bin >= 0, mcolor(cranberry))       ///
           (lfit y_mean score_bin if score_bin < 0, lcolor(navy) lwidth(thick)) ///
           (lfit y_mean score_bin if score_bin >= 0, lcolor(cranberry) lwidth(thick)), ///
           xline(0, lcolor(gs8) lpattern(dash))                                ///
           legend(off)                                                          ///
           title("Fuzzy RDD: Reduced Form", size(medium))                      ///
           subtitle("Jump in outcome at the cutoff")                            ///
           xtitle("Running Variable") ytitle("Outcome")                         ///
           graphregion(color(white)) plotregion(color(white)) name(fuzzy_reduced)
    
    graph export "fuzzy_rdd_reduced_form.png", replace width(1200)
restore


* --- Fuzzy RDD Estimation ---

* METHOD 1: Manual IV / 2SLS
gen score_above = score * above             // Interaction for different slopes

ivreg2 y score score_above (treat = above), robust first

/*
INTERPRETING IV/2SLS FOR FUZZY RDD:
  - Endogenous variable: treat (actual treatment)
  - Instrument: above (above cutoff indicator)
  - The coefficient on treat = Fuzzy RDD estimate (LATE at cutoff)
  - First stage: above → treat (should be strong; check F-statistic)
*/

* First stage explicitly
reg treat above score score_above, robust   // Check first stage F-statistic

/*
The F-statistic on 'above' should be well above 10 (rule of thumb).
If weak → weak instrument problem → biased Fuzzy RDD estimate.
*/


* METHOD 2: rdrobust with fuzzy option (PREFERRED)
rdrobust y score, c(0) fuzzy(treat)         // Fuzzy RDD with rdrobust

/*
rdrobust handles:
  - Optimal bandwidth selection (shared between first stage and reduced form)
  - Bias correction
  - Robust inference
  - The fuzzy estimate = reduced form jump / first stage jump
*/



********************************************************************************
**# SECTION 11: RDD VALIDITY TESTS AND ASSUMPTIONS                              *
********************************************************************************

/*
╔══════════════════════════════════════════════════════════════════════════════╗
║  RDD VALIDITY TESTS                                                          ║
║                                                                              ║
║  For RDD to be valid, we need:                                               ║
║                                                                              ║
║  1. NO MANIPULATION of the running variable near the cutoff                  ║
║     - If people can precisely control their score to be just above or        ║
║       below the cutoff, assignment is NOT random near the cutoff             ║
║     - Test: Density test (McCrary 2008, Cattaneo-Jansson-Ma 2020)            ║
║                                                                              ║
║  2. CONTINUITY of potential outcomes at the cutoff                            ║
║     - All confounders must vary smoothly through the cutoff                  ║
║     - Test: Check for jumps in PRE-DETERMINED covariates at the cutoff       ║
║                                                                              ║
║  3. NO OTHER TREATMENTS at the same cutoff                                   ║
║     - If multiple policies share the same cutoff, we can't separate effects  ║
║     - This is a design issue, not easily testable                            ║
╚══════════════════════════════════════════════════════════════════════════════╝
*/


* --- Reload the sharp RDD data ---
clear all
set seed 42
set obs 1000
gen score = rnormal(0, 10)
gen treat = (score >= 0)
gen y = 50 + 3*score + 0.05*score^2 + 5*treat + rnormal(0, 5)

* Add some pre-determined covariates (NOT affected by treatment)
gen age = 25 + 0.1*score + rnormal(0, 3)   // Smooth through cutoff
gen female = (runiform() < 0.5)             // Random, no jump at cutoff
gen income = 40000 + 500*score + rnormal(0, 5000) // Smooth through cutoff


**# RDD Test 1: McCrary Density Test
* ============================================================================
* TEST 1: McCrary Density Test (No Manipulation of Running Variable)
* ============================================================================

/*
If individuals can manipulate their score to be just above or below the
cutoff, we'd see a BUNCHING of observations on one side. The McCrary (2008)
test checks if the density of the running variable is continuous at the cutoff.

Modern version: Cattaneo, Jansson, & Ma (2020) — rddensity command
*/

* ssc install rddensity                     // Install if needed

rddensity score, c(0)                      // Density test at cutoff = 0

/*
INTERPRETING RDDENSITY:
  - H0: The density of the running variable is continuous at the cutoff
  - If p-value > 0.05: FAIL TO REJECT → no evidence of manipulation ✓
  - If p-value < 0.05: REJECT → evidence of bunching/manipulation ✗
  
  Also look at the estimated densities on each side.
  They should be approximately equal at the cutoff.
*/

* --- Density plot ---
rddensity score, c(0) plot                  // Plot the density
graph export "rddensity_plot.png", replace width(1200)

/*
The plot shows:
  - Estimated density from the left (below cutoff)
  - Estimated density from the right (above cutoff)
  - If there's a visible gap → manipulation concern
  - If they meet smoothly → no manipulation evidence
*/

* --- Alternative: Histogram visual check ---
histogram score, bin(40) xline(0, lcolor(red) lpattern(dash))                  ///
    fcolor(navy%50) lcolor(navy)                                                ///
    title("Distribution of Running Variable", size(medium))                     ///
    subtitle("Check for bunching at the cutoff")                                ///
    xtitle("Score (Running Variable)") ytitle("Density")                        ///
    graphregion(color(white)) plotregion(color(white))

graph export "rdd_histogram.png", replace width(1200)

/*
VISUAL CHECK: Is there an unusual spike (bunching) just to the right of
the cutoff (score = 0)? If yes, manipulation is likely.
*/


**# RDD Test 2: Covariate Balance at the Cutoff
* ============================================================================
* TEST 2: Covariate Balance / Continuity of Covariates at the Cutoff
* ============================================================================

/*
If treatment assignment is "as good as random" near the cutoff, then
pre-determined characteristics (age, gender, income, etc.) should NOT
show a discontinuity at the cutoff.

We test this by running RDD on each covariate as if it were the outcome.
Any significant jump → red flag.
*/

* --- Test each covariate ---
di as text "=== Covariate Balance Tests at the Cutoff ==="

* Test 1: Age
rdrobust age score, c(0)
di "Age: Robust p-value = " e(pv_rb)       // Should be > 0.05

* Test 2: Female
rdrobust female score, c(0)
di "Female: Robust p-value = " e(pv_rb)    // Should be > 0.05

* Test 3: Income
rdrobust income score, c(0)
di "Income: Robust p-value = " e(pv_rb)    // Should be > 0.05

/*
INTERPRETATION:
All p-values should be LARGE (> 0.05) → no significant jumps in covariates.
If any covariate shows a significant discontinuity:
  - The RDD may be invalid for that covariate dimension
  - There may be manipulation or a confounding policy at the same cutoff
  - You should include that covariate as a control in the main RDD regression
*/


* --- Graphical covariate balance check ---
rdplot age score, c(0) graph_options(                                           ///
    title("Covariate Balance: Age")                                             ///
    xtitle("Running Variable") ytitle("Age")                                    ///
    graphregion(color(white)))
graph export "rdd_balance_age.png", replace width(1200)

rdplot income score, c(0) graph_options(                                        ///
    title("Covariate Balance: Income")                                          ///
    xtitle("Running Variable") ytitle("Income")                                 ///
    graphregion(color(white)))
graph export "rdd_balance_income.png", replace width(1200)

/*
These plots should show NO visible jump at the cutoff for covariates.
If the fitted lines on each side connect smoothly → good.
If there's a gap → potential problem.
*/


**# RDD Test 3: Placebo Cutoffs
* ============================================================================
* TEST 3: Placebo Cutoffs
* ============================================================================

/*
Another robustness check: Run the RDD at FAKE cutoffs where there should
be no treatment effect. If we find significant effects at fake cutoffs,
the real result may be spurious.

This is analogous to the placebo treatment timing test in DiD.
*/

* --- Test at fake cutoffs ---
di as text "=== Placebo Cutoff Tests ==="

* Real cutoff is at 0. Test at -5 and +5
rdrobust y score if score < 0, c(-5)        // Fake cutoff at -5 (control side only)
di "Fake cutoff at -5: Robust p-value = " e(pv_rb)

rdrobust y score if score >= 0, c(5)         // Fake cutoff at +5 (treatment side only)
di "Fake cutoff at +5: Robust p-value = " e(pv_rb)

/*
INTERPRETATION:
  - At fake cutoffs, the estimate should be ≈ 0 and insignificant
  - If significant at fake cutoffs → suggests the functional form
    is not well-specified, or there are multiple discontinuities
*/


**# RDD Test 4: Sensitivity to Bandwidth Choice
* ============================================================================
* TEST 4: Sensitivity to Bandwidth Choice
* ============================================================================

/*
A credible RDD result should not be highly sensitive to the bandwidth.
We show results for a range of bandwidths around the optimal one.
*/

* --- Optimal bandwidth first ---
rdrobust y score, c(0)                      // Get optimal bandwidth
local opt_bw = e(h_l)                       // Store optimal bandwidth
di "Optimal bandwidth = `opt_bw'"

* --- Test a range of bandwidths ---
foreach mult in 0.5 0.75 1.0 1.25 1.5 2.0 {
    local bw = `opt_bw' * `mult'
    qui rdrobust y score, c(0) h(`bw')
    di "Bandwidth = " %5.2f `bw' ///
       "  Estimate = " %8.3f e(tau_cl) ///
       "  Robust p-value = " %6.4f e(pv_rb) ///
       "  N_left = " e(N_h_l) "  N_right = " e(N_h_r)
}

/*
INTERPRETATION:
  - The point estimate should be relatively stable across bandwidths
  - Confidence intervals will widen with narrower bandwidths (fewer obs)
  - If the estimate flips sign or changes dramatically → sensitivity concern
  - Present this table in your paper as a robustness check
*/


**# RDD Test 5: Donut Hole RDD
* ============================================================================
* TEST 5: Donut Hole RDD
* ============================================================================

/*
DONUT HOLE RDD: Exclude observations VERY close to the cutoff and
re-estimate. This addresses concerns about:
  1. Precise manipulation just at the cutoff
  2. Measurement error in the running variable near the cutoff
  3. Individuals with scores exactly at the cutoff being treated differently
*/

* --- Donut hole: exclude observations within ±1 of cutoff ---
rdrobust y score if abs(score) > 1, c(0)    // Donut of width 1

* --- Donut hole: exclude within ±0.5 ---
rdrobust y score if abs(score) > 0.5, c(0)  // Donut of width 0.5

/*
INTERPRETATION:
  - If results hold with the donut hole → manipulation near the exact cutoff
    is not driving the results
  - If results disappear → the effect was concentrated among observations
    very near the cutoff, possibly due to manipulation
*/



**# Section 12: RDD with Real Data — Lee (2008) Incumbency Advantage
********************************************************************************
*  SECTION 12: RDD WITH REAL DATA — Lee (2008) Incumbency Advantage            *
********************************************************************************

/*
╔══════════════════════════════════════════════════════════════════════════════╗
║  REAL DATA APPLICATION: LEE (2008)                                           ║
║                                                                              ║
║  David Lee (2008) "Randomized Experiments from Non-random Selection in      ║
║  U.S. House Elections" — one of the most cited RDD papers.                   ║
║                                                                              ║
║  Setting:                                                                    ║
║  - Running variable: Democratic vote margin in election t                    ║
║    (Democrat vote share - 50%)                                               ║
║  - Cutoff: 0 (50% vote share — win/lose threshold)                          ║
║  - Treatment: Winning election t (becoming the incumbent)                    ║
║  - Outcome: Democratic vote share in election t+1                            ║
║                                                                              ║
║  Question: Does winning a close election (incumbency) causally              ║
║  increase your vote share in the next election?                              ║
║                                                                              ║
║  The logic: Candidates who barely won vs. barely lost are essentially       ║
║  identical, but one gets incumbency advantages (name recognition,           ║
║  fundraising, pork barrel spending, etc.).                                   ║
╚══════════════════════════════════════════════════════════════════════════════╝
*/

* --- Load Lee (2008) data ---
use "https://github.com/scunning1975/mixtape/raw/master/lmb-data.dta", clear

describe                                    // Explore the dataset
summarize                                   // Summary statistics

/*
KEY VARIABLES (may vary by dataset version — adjust names as needed):
  - score / demvoteshare: Democratic vote margin (running variable)
  - democrat / lagdemvoteshare: outcome variable (next election vote share)
*/

* --- Rename for clarity (adjust based on actual variable names) ---
* The dataset from mixtape uses different variable names; explore first
ds                                          // List all variables

* --- RDD Analysis ---
* Generate the running variable centered at the cutoff
* The margin of victory centered at 0.5 (or already centered depending on data)

* Let's work with the data as-is
* The running variable is 'lagdemvoteshare' and outcome is 'demvoteshare'

* Explore
summarize demvoteshare lagdemvoteshare

* Center the running variable at 0.5 (the win/lose threshold)
gen margin = lagdemvoteshare - 0.5          // Centered at 0: positive = Dem won

* Treatment: Democrat won previous election
gen dem_won = (margin >= 0)

label variable margin "Democratic Vote Margin (centered at 0)"
label variable dem_won "Democrat Won Previous Election"
label variable demvoteshare "Dem Vote Share Next Election"


* --- RD Plot ---
rdplot demvoteshare margin, c(0)                                                ///
    graph_options(                                                              ///
        title("Lee (2008): Incumbency Advantage RDD", size(medium))             ///
        xtitle("Democratic Vote Margin (Previous Election)")                    ///
        ytitle("Democratic Vote Share (Next Election)")                         ///
        graphregion(color(white)))

graph export "lee2008_rdplot.png", replace width(1200)


* --- Sharp RDD Estimation ---
rdrobust demvoteshare margin, c(0)          // Main RDD estimate

/*
INTERPRETATION:
  - The Robust estimate = incumbency advantage
  - A positive coefficient means winning a close election INCREASES
    the Democratic vote share in the next election
  - This is one of the cleanest RDD applications because election
    outcomes near 50% are essentially random
*/


* --- Validity Tests on Lee (2008) Data ---

* Density test: no manipulation of vote margins
rddensity margin, c(0)

* Note: Lee (2008) data may show some bunching — this is a known issue
* and Lee discusses it in the paper. Elections are not perfectly random.


* --- Full results table ---
* Different specifications for robustness
* Note: rdrobust does not support est store. We display results sequentially.
di as text "=== Local Linear (p=1) ==="
rdrobust demvoteshare margin, c(0) p(1)     // Local linear

di as text "=== Local Quadratic (p=2) ==="
rdrobust demvoteshare margin, c(0) p(2)     // Local quadratic

* Different bandwidths
di as text "=== Narrow Bandwidth (h=0.05) ==="
rdrobust demvoteshare margin, c(0) h(0.05)  // Narrow

di as text "=== Medium Bandwidth (h=0.10) ==="
rdrobust demvoteshare margin, c(0) h(0.10)  // Medium

di as text "=== Wide Bandwidth (h=0.25) ==="
rdrobust demvoteshare margin, c(0) h(0.25)  // Wide



**# Section 13: Additional RDD Topics
********************************************************************************
*  SECTION 13: ADDITIONAL RDD TOPICS                                           *
********************************************************************************

/*
╔══════════════════════════════════════════════════════════════════════════════╗
║  ADDITIONAL RDD CONSIDERATIONS                                               ║
║                                                                              ║
║  1. RDD WITH COVARIATES                                                      ║
║     Adding covariates can improve precision but should NOT change the        ║
║     point estimate much (if it does, something may be wrong).                ║
║                                                                              ║
║  2. GEOGRAPHIC / MULTI-DIMENSIONAL RDD                                       ║
║     When the running variable is 2D (e.g., latitude & longitude),            ║
║     the cutoff is a boundary line, not a point.                              ║
║                                                                              ║
║  3. REGRESSION KINK DESIGN (RKD)                                             ║
║     Instead of a jump in the LEVEL of treatment, there's a kink in the      ║
║     SLOPE. Example: tax rate changes at an income threshold.                 ║
║                                                                              ║
║  4. RDD + DiD                                                                ║
║     Combine RDD (spatial discontinuity) with DiD (temporal comparison)       ║
║     for even more credible identification.                                   ║
╚══════════════════════════════════════════════════════════════════════════════╝
*/


* --- RDD with covariates ---
* Using the simulated data
clear all
set seed 42
set obs 1000
gen score = rnormal(0, 10)
gen treat = (score >= 0)
gen age = 25 + 0.1*score + rnormal(0, 3)
gen female = (runiform() < 0.5)
gen y = 50 + 3*score + 0.05*score^2 + 5*treat - 0.5*female + 0.1*age + rnormal(0, 5)

* Without covariates
rdrobust y score, c(0)

* With covariates (should improve precision, similar point estimate)
rdrobust y score, c(0) covs(age female)

/*
If the point estimate changes substantially when adding covariates,
this is a red flag — it suggests potential violations of the RDD
assumptions (e.g., discontinuities in covariates at the cutoff).
*/



**# Summary: DiD vs. RDD Comparison
********************************************************************************
*                                                                              *
*  COMPREHENSIVE SUMMARY TABLE: DiD vs. RDD                                    *
*                                                                              *
********************************************************************************

/*
╔══════════════════════════════════════════════════════════════════════════════╗
║                    DiD vs. RDD COMPARISON                                    ║
╠══════════════════════════════════════════════════════════════════════════════╣
║                                                                              ║
║  Feature              DiD                      RDD                           ║
║  ──────────────────   ─────────────────────    ─────────────────────         ║
║  Treatment            Before/after + groups    Cutoff on running var         ║
║  Key assumption       Parallel trends          Continuity at cutoff          ║
║  Estimand             ATT (group-level)        LATE (at cutoff)              ║
║  External validity    Moderate (treated pop)   Low (only near cutoff)        ║
║  Data requirement     Panel / repeated CS      Cross-section sufficient      ║
║  Manipulation test    N/A                      McCrary density test          ║
║  Placebo tests        Fake timing/outcome      Fake cutoffs                  ║
║  Graphical check      Pre-trend plot           RD plot (jump at cutoff)      ║
║  Modern methods       csdid, did_imputation    rdrobust, rddensity           ║
║  Common pitfall       Differential pre-trends  Manipulation of score         ║
║                                                                              ║
║  Both methods:                                                               ║
║  - Are quasi-experimental (no randomization required)                        ║
║  - Rely on continuity/smoothness assumptions                                 ║
║  - Can be combined with each other and with IV/matching                      ║
║  - Require careful visual inspection of the data                             ║
║  - Should include robustness checks and placebo tests                        ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
*/



**# Required Packages Installation
********************************************************************************
*  REQUIRED PACKAGES INSTALLATION BLOCK                                        *
*  (Run this block once before running the rest of the do-file)                *
********************************************************************************

/*
If you haven't installed the necessary packages, uncomment and run:

ssc install reghdfe                         // High-dimensional fixed effects
ssc install ftools                          // Required by reghdfe
ssc install csdid                           // Callaway & Sant'Anna DiD
ssc install drdid                           // Doubly robust DiD (required by csdid)
ssc install event_plot                      // Event study plots
ssc install bacondecomp                     // Goodman-Bacon decomposition
ssc install rdrobust                        // RDD estimation and plots
ssc install rddensity                       // McCrary/CJM density test
ssc install lpdensity                       // Required by rddensity for plotting
ssc install rdlocrand                       // Local randomization RDD

* Optional but useful:
ssc install estout                          // Nice regression tables
ssc install coefplot                        // Coefficient plots
ssc install grstyle                         // Graph styling
ssc install palettes                        // Color palettes for graphs
ssc install colrspace                       // Color space transformations
*/


log close                                   // Close the log file

/*
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║  END OF LECTURE NOTES                                                        ║
║                                                                              ║
║  For further reading:                                                        ║
║  - Cunningham (2021): https://mixtape.scunning.com/                          ║
║  - Huntington-Klein (2021): https://theeffectbook.net/                       ║
║  - Cattaneo, Idrobo, Titiunik (2020): A Practical Intro to RDD              ║
║  - Roth et al. (2023): "What's Trending in DiD?"                             ║
║  - Goodman-Bacon (2021): "DiD with Variation in Treatment Timing"            ║
║                                                                              ║
║  Stata resources:                                                            ║
║  - rdrobust: https://rdpackages.github.io/rdrobust/                          ║
║  - csdid:    https://friosavila.github.io/playingwithstata/main_csdid.html   ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
*/
