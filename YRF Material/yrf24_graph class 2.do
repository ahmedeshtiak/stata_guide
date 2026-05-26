/******************************************************************************************************************
*Title: YRF STATA Graph Class 2
*Created by: Md Johirul Islam 
*Created on: STATA17
*Last Modified on: 15 October, 2024
*Last Modified by: MJI
*Purpose : Twoway RCT graph, Twoway multiple response graph, line plot with CI, scatter plot, scatter plot with fitted line
*Edits 
	- [MM/DD/YY] - [editor's initials]: Added / Changed....
	
*****************************************************************************************************************/

**# Setting current directory
	cd "H:\My Drive\YRF 24 Classes\YRF Graph Class 2"


**# install graph scheme 
	*ssc install schemepack, replace

	


**#*Setting colorschemes for graphs 

	global skyblue "86 180 233"
	global blue "0 114 178"
	global teal "17 222 245"
	global orange "213 94 0"
	global green "0 158 115"
	global yellow "230 159 0"
	global purple "204 121 167"
	global lavendar "154 121 204"
	global cherry "200 0 0"
	global tangerine "255 86 29"
	global peach "251 162 127"
	global blueberry "64 105 166"
	global slate "106 90 205" 
	global peank "219 112 147"
	
	global qual1 "228 26 28" 
	global qual2 "55 126 184" 
	global qual3 "77 175 74" 
	global qual4 "255 127 0"
	
	global cgd1 "0 105 112"
	global cgd2 "243 246 247"
	global cgd3 "57 70 73"

	
**# **sequential color
	global blue1 "158 202 225"
	global blue2 "66 146 198"
	global blue3 "8 81 156"
	
	global purple1 "188 189 220"
	global purple2 "128 125 186"
	global purple3 "84 39 143"
	
	
**# *IJED Colours
	global ijed1 "165 42 42"
	global ijed2 "95 158 160"
	global ijed3 "144 238 144"
	global ijed4 "105 105 105"
	global ijed5 "205 92 92"
	global ijed6 "210 180 140"

	global cgd1 "0 105 112"
	global cgd2 "243 246 247"
	global cgd3 "57 70 73"
	global cgdalt "128 180 184"
	global cgdalt2 "0 128 128"

	
***BIGD color palette (selected shades of blue)
	global bigd_base "57 68 188"
	global bigd1 "0 48 143"
	global bigd2 "0 79 152"
	global bigd3 "70 130 180"
	global bigd4 "0 128 128" // 2 and 4 good combo 
	global bigd5 "100 149 237"
	global bigd6 "18 97 128"
	global bigd7 "0 127 255"
	global bigd8 "0 53 107" // 8 and 12 good combo 
	global bigd9 "0 49 83"
	global bigd10 "29 41 81"
	global bigd11 "0 90 146"
	global bigd12 "102 153 204" //2 and 12 good combo 
	global bigd13 "19 39 79"
	global bigd14 "0 142 151"
	global bigd15 "24 119 242" 
	
**# *Learning level colours
	global l0 "205 92 92"
	global l1 "228 147 147"
	global l2 "230 188 94" 
	global l3 "152 184 211"
	global l4  "144 238 144"
	global l5 "77 175 74" 
		
		
		
	**# Treatment Control Disaggregation by Income ********

	*load data 
	use "panel_member.dta", clear

	*make a correction for the endline income since income is miscoded as monthly for endline 
	replace income = income*12 if year ==1 //convert inc to year level  


	*now preserve to make the main data unharmed 
	preserve

	*collapse to hh level first since we want hh analysis 
	collapse (sum) income (first) treatment , by(idno year)


	*collapse data by those category by which we want to make the graph 
	collapse (mean) income, by(treatment year)

	*we are creating a cat var based on the fact that year will be graphed in x-axis and treatment will be given to legend 
	egen year_treat = group(year treatment)

	*to have a gap between bars after basline year, we replace the value by adding one
	replace year_treat = year_treat +0.50 if year ==1 

	sort year_treat
	
	*we are cloning our dep var since we want to show the value at the top of the bar 
	clonevar yval_inc = income
	format yval_inc %9.0f  // because I want them to look pretty

	**#*** Graph codes

	twoway  (bar income year_treat if treatment==0, barwidth(0.80) color(gs10)) ///
			(bar income year_treat if treatment==1, barwidth(0.80) color("$bigd4")) ///
			(scatter income year_treat, msymbol(i) mlabel(yval_inc) mlabposition(12) mfcolor(black)) ///  change mlabposition if 6 if you want the values to be inside
			,xlabel(1.5 "Baseline" 4 "Follow-up",) ///
			legend(order(1 "Control" 2 "Treatment") row(1) pos(6) size(small)) ///
			ytitle("") subtitle("", justification(left) margin(b+1 t-1 l-1) bexpand size(1)) ///
			ylabel(0(20000)100000, labsize(small)) title("Avg. Income by Treatment and Control Group (in BDT)", justification(left) margin(b+1 t-1 l-1) bexpand size(small))  ///
			graphregion(color(white) fcolor(white) icolor(white) ifcolor(white) lcolor(white) ilcolor(white) margin(r = 20 l = 20 b = 10 t = 10)) ///
			plotregion(color(white) fcolor(white) icolor(white) ifcolor(white) lcolor(white) ilcolor(white)) xtitle("", size(small)) ///
			note("", size(vsmall)) ///
			name(f1, replace) ///
			caption(, size(vsmall)) scheme(white_tableau) 
			
			
	

	

	graph export "treat_disagg.png", replace

	restore

	
	

	
	**# Multiple response graphs
	/*
	This graph was made by Marjan Hossain, SRA, BIGD
	*/
	
	
	*load data 
	use "prepare_example_data2.dta", clear
	
	ren (saq_12_2 saq_12_4 saq_12_12 saq_12_6 saq_12_7 saq_12_9 saq_12_10 saq_12_14) (saq12_28 saq12_29  saq12_30 saq12_31 saq12_32 saq12_33 saq12_34 saq12_35)
	
	
	local i=1
	foreach var in saq12_1 saq12_2 saq12_3 saq12_4 saq12_5 saq12_6 saq12_7 saq12_8 saq12_9 saq12_10 saq12_11 saq12_12 saq12_13 saq12_14 saq12_15 saq12_16 saq12_17 saq12_18 saq12_19 saq12_20 saq12_21 saq12_22 saq12_23 saq12_24 saq12_25 saq12_26 saq12_27 saq12_28 saq12_29  saq12_30 saq12_31 saq12_32 saq12_33 saq12_34 saq12_35 {
	
	ren (`var') (r_`i')
	local `++i'

	}
	
	mrtab r_1-r_35, by(gender) col
	recode r_1-r_35 (1=100)
	
	*Generating a graph with gender and overall for reasons of nonenrolment
	preserve
	expand 2, generate(all)
	replace gender=9 if all==1
	la def gender 1 "Male" 2 "Female" 9 "Overall"
	la val gender gender
	drop all

	
	collapse (mean) r_1-r_35, by(gender)	
	
	
	keep r_1 r_2 r_3 r_4 r_13 r_14 gender

		
	ren (r_1 r_2 r_3 r_4 r_13 r_14 gender) (y1 y2 y3 y4 y5 y6 x)
	format y1-y6 %9.1f

	
	reshape long y, i(x) j(xvar)
	
	*sort xvar, stable
	*gen var1 = _n
	
	
	gen z=.
	
	
	
	replace z=1 if x==1 & xvar==2
	replace z=3 if x==2 & xvar==2
	replace z=5 if x==9 & xvar==2
	
	replace z=11 if x==1 & xvar==1
	replace z=13 if x==2 & xvar==1
	replace z=15 if x==9 & xvar==1
		
	replace z=21 if x==1 & xvar==3
	replace z=23 if x==2 & xvar==3
	replace z=25 if x==9 & xvar==3
	
	replace z=31 if x==1 & xvar==4
	replace z=33 if x==2 & xvar==4
	replace z=35 if x==9 & xvar==4
	
	replace z=41 if x==1 & xvar==6
	replace z=43 if x==2 & xvar==6
	replace z=45 if x==9 & xvar==6
	
	replace z=51 if x==1 & xvar==5
	replace z=53 if x==2 & xvar==5
	replace z=55 if x==9 & xvar==5
	

	
	sort z, stable
	
	
	linewrap , longstring(`"Financial constraints (before C-19)"') maxlength(15) stack name(firstbar)
	linewrap , longstring(`"Financial constraints (due to C-19)"') maxlength(15) stack name(secondbar) add
	linewrap , longstring(`"Child is working (before C-19)"') maxlength(15) stack name(thirdbar) add
	linewrap , longstring(`"Child is working (due to C-19)"') maxlength(15) stack name(fourthbar) add
	linewrap , longstring(`"No learning motivation (before C-19 school closures)"') maxlength(15) stack name(fifthbar) add
	linewrap , longstring(`"No learning motivation (due to C-19 school closures)"') maxlength(15) stack name(sixthbar) add

  
	
		twoway  (bar y z  if z==1, barwidth(1.75) color("$qual2")) ///
				(bar y z if z==3, barwidth(1.75) color("$peank")) ///
				(bar y z if z==5, barwidth(1.75) color("$cgd1"))  ///
				(bar y z if z==11, barwidth(1.75) color("$qual2"))  ///
				(bar y z if z==13, barwidth(1.75) color("$peank"))  ///
				(bar y z if z==15, barwidth(1.75) color("$cgd1"))  ///
				(bar y z if z==21, barwidth(1.75) color("$qual2"))  ///
				(bar y z if z==23, barwidth(1.75) color("$peank"))  ///
				(bar y z if z==25, barwidth(1.75) color("$cgd1"))  ///
				(bar y z if z==31, barwidth(1.75) color("$qual2"))  ///
				(bar y z if z==33, barwidth(1.75) color("$peank"))  ///
				(bar y z if z==35, barwidth(1.75) color("$cgd1")) ///
				(bar y z if z==41, barwidth(1.75) color("$qual2"))  ///
				(bar y z if z==43, barwidth(1.75) color("$peank"))  ///
				(bar y z if z==45, barwidth(1.75) color("$cgd1"))  ///
				(bar y z if z==51, barwidth(1.75) color("$qual2"))  ///
				(bar y z if z==53, barwidth(1.75) color("$peank"))  ///
				(bar y z if z==55, barwidth(1.75) color("$cgd1"))  ///
				(scatter y z, msymbol(i) mlabel(y) mlabcolor(black) mlabposition(12) mlabsize(vsmall)) ///
				,xlab(, val ang(45) labsize(vsmall)) xlabel(3 `"`r(firstbar)'"' 13 `"`r(secondbar)'"' 23 `"`r(thirdbar)'"' 33 `"`r(fourthbar)'"' 43 `"`r(fifthbar)'"' 53 `"`r(sixthbar)'"' ) ///
				legend( order(1 "Males" 2 "Females" 3 "Overall") row(1) pos(6) size()) ///
				ytitle("") subtitle("", justification(left) margin(b+1 t-1 l-1) bexpand size(1)) ///
				ylabel(0(10)50,labsize(small)) title("Reasons for non-enrolment in 2022 (% of cases)", justification(left) margin(b+1 t-1 l-1) bexpand size(small))  ///
				yline(0, extend lcolor("$cgd3")) ///
				graphregion(fcolor(white) margin(r=15 l=15)) ///
				plotregion(fcolor(white) icolor(white) ifcolor(white) lcolor(white) ilcolor(white)) xtitle("", size(small)) ///
				note(, size(vsmall)) ///
				scheme(white_tableau) name(f2, replace)
				


	graph export "figure2_new.png", replace

	restore
	

	
	
	
	
	
  **# Figure: Line plots witthed line with confidence interval
  
/*
	Data Source:
	---------------------
	Mock data and code based on
	Christian,Paul J.; Kondylis,Florence; Mueller,Valerie Martina; Zwager,Astrid Maria Theresia; Siegfried,Tobias.2018.
	Water when it counts : reducing scarcity through irrigation monitoring in Central Mozambique (English). 
	Policy Research working paper;no. WPS 8345;Impact Evaluation series Washington, D.C. : World Bank Group.
	http://documents.worldbank.org/curated/en/206391519136157728/Water-when-it-counts-reducing-scarcity-through-irrigation-monitoring-in-Central-Mozambique
*/
   
  use "https://github.com/worldbank/stata-visual-library/raw/master/Library/data/line-fit-text.dta", clear

	///  Treament effect
  reg     y_var x_var post x_var_post control 
  
  *predict y_hat 
   
	/// Saving coefficient
  local   beta_pre  = round(_b[x_var],0.001) 
  local	  beta_post = round(_b[x_var] + _b[x_var_post],0.001)
    
	/// Saving F Test  test    _b[x_var_post] = 1
  local   f_pre = round(r(p),0.001) 
  if		`f_pre' == 0 local f_pre = "0.000"
  
  test    _b[x_var_post] + _b[x_var_post] = 1
  local   f_post = round(r(p),0.001)
  

  twoway  (lfitci y_hat x_var if post == 1, color("222 235 247") lwidth(.05))     ///
          (lfitci y_hat x_var if post == 0, color(gs15))                          /// 
          (lfit   x_var x_var if post == 1, color(red) lwidth(.5))  ///
          (lfit   y_hat x_var if post == 0, color(gs8) lwidth(.5)),           ///
          text(5 9 "Pre-treatment" "Regression coefficent: 0`beta_pre'" "P-value of coefficent = 1: `f_pre'"        ///
               12 9 "Post-treatment" "Regression coefficent: 0`beta_post'" "P-value of coefficent = 1: 0`f_post'",  ///
               orient(horizontal) size(vsmall) justification(center) fcolor(white) box margin(small))               ///
          xtitle("Independent variable value")                                                                      ///
          ytitle("Predicted value of dependent variable")                                                           ///
          legend(order (6 "Pre-treatment" 7 "Post-treatment" 3 "Pre-treatment 95%CI" 1 "Pre-treatment 95%CI"))      ///
          graphregion(color(white)) bgcolor(white)                                                                  ///
		title("Line plots with fitted line with confidence interval", justification(left) color(black) span pos(11)) ///
		scheme(white_tableau) name(f3, replace)
	
	
	
	graph export "line_ci.png", replace

	
	
	
	
	
	
	
	**# Scatterplot with transparent points
	
	sysuse auto, clear
		
	scatter       ///
    price mpg   ///
		,           ///
		mcolor(midblue%50)        /// the value after % sets the transparency
		mlwidth(0)                /// set width of border to 0
		graphregion(color(white)) scheme(white_tableau) name(f4, replace) ///
		title("Scatter plot with transparent points", justification(center) color(black) span pos(17))
	
	
	graph export "scatter_plot.png", replace
	
	
	**# Scatter plot with fitted line

    * Load data
    * ---------
	   sysuse auto, clear
 
    * Set graph options
    * ----
	   local col_domestic 	midblue
	   local col_foreign  	red
	   local transparency   %30
	   local point_width	0
	   local point_size		small
	   
   
    * Plot
    * ----
    twoway  (scatter price mpg if foreign == 0, mfcolor(`col_domestic'`transparency') msize(`point_size') mlwidth(`point_width')) ///
            (lfit price mpg if foreign == 0, color(`col_domestic')) ///
            (scatter price mpg if foreign == 1, mfcolor(`col_foreign'`transparency') msize(`point_size')  mlwidth(`point_width')) ///
            (lfit price mpg if foreign == 1, color(`col_foreign')) ///
         , ///
            graphregion(color(white) margin(l=15 t=15 b=15 r=15)) name(f5, replace) ///
			legend(order(2 "Domestic" 4 "Foreign")) scheme(white_tableau) ///
			title("Relationship between price and mpg", justification(left) margin(b+1 t-1 l-1) bexpand size(small))  
            
		graph export "scatter_plot_withfit.png", replace

	