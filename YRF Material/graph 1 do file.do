/******************************************************************************************************************
*Title: YRF 2024 STATA Class 5: Frequently used graphs (basics)
*Created by: Johirul Islam
*Created on: STATA17
*Last Modified on: October 8, 2024
*Last Modified by: -
*Purpose :   
*Edits 
	- [MM/DD/YY] - [editor's initials]: Added / Changed....
	
*****************************************************************************************************************/

	**# Current direcyories
	cd "H:\My Drive\YRF 24 Classes\YRF Class Graph 1"
	
	**# Setting scheme
	
	ssc install schemepack
	
	**# Setting colors
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
	*global qual3 "77 175 74" 
	global qual4 "255 127 0"
	
	*global cgd1 "0 105 112"
	global cgd2 "243 246 247"
	global cgd3 "57 70 73"
	global cgd1 "228 147 147" //light pink
	
	**sequential color
	global blue1 "158 202 225"
	global blue2 "66 146 198"
	global blue3 "8 81 156"
	
	global purple1 "188 189 220"
	*global purple2 "128 125 186"
	global purple3 "84 39 143"
	global purple2 "152 184 211" //"144 238 144" (light green) 
	
	*IJED Colours
	global ijed1 "165 42 42"
	global ijed2 "95 158 160"
	global ijed3 "144 238 144"
	global ijed4 "105 105 105"
	*global ijed5 "230 159 0" //yellow is there 
	*global ijed6 "210 180 140"
	global ijed5  "144 238 144" //light green 
	global qual3  "205 92 92" //ijed5  
	global ijed6 "230 188 94" //yellow
	
	
	*cgd alt 
	global cgdalt "128 180 184"
	global cgdalt2 "0 128 128"

	
	global red1 "180 55 87"
	global red2 "210 31 60"
	global red3 "250 128 114"


	global green1 "46 139 87"

	
	*BIGD color palette (selected shades of blue)
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
	global bigd12 "77 175 74" //qual3
	global bigd13 "19 39 79"
	global bigd14 "0 142 151"
	global bigd15 "24 119 242" 
	global bigd16 "128 152 220"
	global bigd17 "15 98 146"
	
	*Learning level colours
	global l0 "205 92 92"
	global l1 "228 147 147"
	global l2 "230 188 94" 
	global l3 "152 184 211"
	global l4  "144 238 144"
	global l5 "77 175 74" 
		
	
	
	**# Load data 
	use "prepare_data_example", clear 
	
	**horizontal bar graph
	tab Bangla, gen(b)
	tab English, gen(e)
	tab Math, gen(m)
	recode b1-m5 (1=100)
	
	
	clonevar str=strata
	la def str 0 "U" 1 "R", modify
	la val str str
	
	clonevar sch=sch_type
	la def sch 1 "Public" 2 "Private" 3 "Madrasa", modify
	la val sch sch
	clonevar m11=m1
	replace m11=. if sch==2 & str==0
	
		
		
	graph hbar b1 b2 b3 b4 b5, over(str, gap(15)) ///
			over(sch, gap(55)) ///
			stack asyvars ///
			legend (label(1 "L0: Beginner") label(2 "L1: Letter") label(3 "L2: Word") label(4 "L3: Paragraph") label(5 "L4: Story") row(2) pos(6) size(small)) ///
			ysca() ylabel(none) yline(0, lcolor(black)) ///
			blabel(bar, format(%4.0f) size(small)color (black) ///
			position(center)) bar(1, bcolor("$l0")) bar(2, bcolor("$l1")) bar(3, bcolor("$l2")) bar(4, bcolor("$l3")) ///
			bar(5, bcolor("$l4")) /// 
			title("Bangla (% of the students)", justification(left) margin(b+1 t-1 l-1) bexpand size(small) ///
			color (black)) ///
			ytitle("", size(small)) ///
			note("",size(small)) plotregion(fcolor(white)) ///
			graphregion(fcolor(white) margin(r=8 l=8)) ///
			name(blg1, replace) scheme(white_tableau)
	
	
	graph export "horizontal_bar.png", replace
	
	
	
	
	
	**# Connected line graph to show trend
	
	levelsof bang_5, local(ban5)
foreach m of local ban5 {
    gen bang_5_`m' = 100*`m'.bang_5
}


	levelsof eng_6, local(eng6)
	foreach c of local eng6 {
		gen eng_6_`c' = 100*`c'.eng_6
	}
	
	
	levelsof math_5, local(math5)
foreach c of local math5 {
    gen math_5_`c' = 100*`c'.math_5
}
	
	
	
	preserve
	
	collapse (mean) bang_5_* eng_6_* math_5_*, by(edu_level)
	drop if edu_level ==.
	
	twoway (connected bang_5_1 edu_level, lcolor("$darkgreen") mcolor("$darkgreen")) ///
			(connected eng_6_1 edu_level, lcolor(red) mcolor(red)) ///
			(connected math_5_1 edu_level, lcolor(purple) mcolor(purple)) ///
			, yline(2) ///
			xlabel(0 "Pre-Primary" 1 "Class 1" 2 "Class 2" 3"Class 3" 4"Class 4" 5 "Class 5" 6 "Class 6" 7 "Class 7" 8 "Class 8" 9 "Class 9-10" 10 "Class 11-12", angle(45) labsize(vsmall)) ///
			xtitle("", size()) ///
			legend (label(1 "Bangla") label(2 "English") label(3 "Math") row(1) cols() pos(bottom) size(small)) ///
			title("Class Progression and Learning Outcome (Overall)", justification(left) margin(b+1 t-1 l-1) bexpand size(small)) ///
			ytitle("", size(small)) ///
			note("",size(small)) plotregion(fcolor(white)) ///
			graphregion(margin(r = 8 l = 8 b = 8 t = 8)) ///
			scheme(white_tableau)
	
	
	graph export "l4_grade_progression.png", replace
	
	
	restore
	  
	 
	 
	 
	 **# Load data
	 use "H:\My Drive\YRF 24 Classes\YRF Class Graph 1\dfs_sample_data.dta", clear

	 graph set window fontface "Times New Roman" //font style
	 
	 
	 **# Vertical bar graphs and combining the grpahs
	clonevar savings = f1
	recode savings (1=100)
	egen tot_savings = rowtotal(f2 f3 f4)
	 
	 
	gen debt = 1 if f7==1 | f9 ==1 | f11==1
	replace debt = 0 if debt !=1 & f7 !=.
	
	clonevar debt_1 = debt
	recode debt_1 (1=100)
	
	egen tot_debt = rowtotal(f8 f10 f12)
	
	
	
	
	*debt and savings 
		graph bar savings debt_1, bargap(80) ///
	asyvars legend (label(1 "Saving") label(2 "Debt") label(3 "") label(4 "") label(5 "") row() size(small)) ///
	ysca(range(0, 100)) ylabel(#5) yline(0, lcolor(black)) ///
	blabel(bar, format(%4.0f) size(small) color (black) ///
	position(outside)) bar(1, bcolor("$yellow")) bar(2, bcolor("$qual2")) ///
	legend(cols(2) row(1) pos(6) size()) ///
	title("Savings and Debt (% of the respondents)", justification(left) margin(b+1 t-1 l-1) bexpand size(small) ///
	color (black)) ytitle("", size(small)) ///
	note("",size(medium)) plotregion(fcolor(white)) ///
	name(debtsav_1, replace) scheme(white_tableau) ///
	graphregion(margin( r = 38 l = 38 t = 7 b = 7)) 
	
	
	
	*avg debt vs avg. savings 
	
		graph bar (mean) tot_savings tot_debt, bargap(80) ///
	asyvars legend (label(1 "Savings") label(2 "Debt") label(3 "") label(4 "") label(5 "") row() size(small)) ///
	ysca(range(0, 100)) ylabel(#5) yline(0, lcolor(black)) ///
	blabel(bar, format(%4.0f) size(small) color (black) ///
	position(outside)) bar(1, bcolor("$yellow")) bar(2, bcolor("$qual2")) ///
	legend(cols(1) row(1) pos(6) size()) ///
	title("Avg. Savings vs Avg. Debt (in taka)", justification(left) margin(b+3 t+5 l-1) bexpand size(small) ///
	color (black)) ytitle("", size(small)) ///
	note("",size(medium)) plotregion(fcolor(white)) ///
	name(debtsav_2, replace) scheme(white_tableau) ///
	graphregion(margin( r = 38 l = 38 t = 7 b = 7)) 
	
	grc1leg debtsav_1 debtsav_2, rows(1) iscale(1) legendfrom(debtsav_2)  xcommon cols(2) ysize(5) xsize(5) imargin(0 0 0 0) graphregion(margin(r=10 l=10))
	
		 
	graph export "vertical_graph_combined.png", replace
	
	

	
	
	**# K-density graphs 
	
	use "https://github.com/worldbank/stata-visual-library/raw/master/Library/data/density-av.dta", clear
  
	sum     revenue if post == 0 
	local   pre_mean = r(mean) 
	sum     revenue if post == 1
	local   post_mean = r(mean)

	twoway  (kdensity revenue if post == 0, color(gs10)) ///
			(kdensity revenue if post == 1, color(emerald)) ///
    , ///
          xline(`pre_mean', lcolor(gs12) lpattern(dash)) ///
          xline(`post_mean', lcolor(eltgreen) lpattern(dash)) ///
          legend(order(1 "Pre-treatment" 2 "Post-treatment")) ///
          xtitle(Agriculture revenue (BRL thousands)) ///
          ytitle(Density) ///
          bgcolor (white) graphregion(color(white)) ///
		  scheme(cblind1) ///
		  graphregion(margin( r = 18 l = 18 t = 15 b = 15)) ///
		  title("Density Plot with Mean Maker", justification(center) size(small) color(black) span pos(12))	
	

	graph export "kdcombined.png", replace
	
	
	
	**# Coeff Plot
	
	*default is horizontal
	sysuse auto, clear
	regress price mpg trunk length turn
	coefplot, drop(_cons) xline(0) scheme(white_tableau)
	
	graph export "coeff1.png", replace
	
	*vertical? 
	coefplot, vertical drop(_cons) yline(0) scheme(white_tableau)
	graph export "coeff2.png", replace	
	
	
	
	*By group: heterogeneity 

	regress price mpg trunk length turn if foreign==0 //domestic
	estimates store D
	regress price mpg trunk length turn if foreign==1 //foreign
	estimates store F
	
	coefplot D F, drop(_cons) xline(0) msymbol(S) ///
    p1(label(Domestic Cars) pstyle(p3))  ///
    p2(label(Foreign Cars)  pstyle(p4)) ///
	scheme(white_tableau)
	
	graph export "coeff3.png", replace
		
		
		