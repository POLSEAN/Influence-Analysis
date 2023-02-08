********************************************************************************
*** Title: Influence Analysis for Panel Data with Fixed Effects
*** Author: Annalivia Polselli (email: annalivia[dot]polselli[at]essex.ac.uk)
*** Date: February 8, 2023
*** Descritption: Demonstration of the use of 'xtlvr2plot' and 'xtinfluence'commands
********************************************************************************
clear all
set more off

gl wd "~ working directory here"
cd "$wd"

adopath ++ "$wd/ado"

*ssc install grstyle
grstyle init
grstyle set plain
grstyle set legend, nobox 

***********
*** DGP ***
***********
clear 
set seed 1408
loc numobs 100
set obs `numobs'
gen id = _n
expand 20													
bys id: generate t = _n 
bys id: gen z = rnormal() 

gen y =.
gen a  =.

** GL
bys id: replace z = rnormal(15,1) if id==20 & t<=10 		
bys id: replace z = rnormal(15,1) if id==50 & t<=5 		

** BL
bys id: replace z =	rnormal(10,1) if id==10 & t<=10 
bys id: replace z =	rnormal(10,1) if id==40 & t<=5 

** individual effects and output variable
bys id: replace a = runiform(0,20)
bys id: replace y = 1 + .5*z + a + runiform() 

** BL
bys id: replace y = y + rnormal(50,1) if id==10 & t<=10  
bys id: replace y = y + rnormal(50,1) if id==40 & t<=5  

** VO
bys id: replace y = y + rnormal(50,1) if id==30 & t<=10	
bys id: replace y = y + rnormal(50,1) if id==60 & t<=5	


******************
*** xtlvr2plot ***
******************
xtset id t

xtlvr2plot y z, ///
	mlabel(id)  ///
	text(.009 .0001 "GL units", place(se) box fc(gs16) size(medsmall))  ///
	text(.009 .0035 "BL units", place(se) box fc(gs16) size(medsmall))  ///
	text(.0005 .0035 "VO units", place(ne) box fc(gs16) size(medsmall)) ///	
	ylabel(, angle(h) format(%9.3fc)) xlabel(, format(%9.3fc))          ///
	title("Unit-wise Evaluation with xtlvr2plot", size(medsmall))       ///
	saving("xtlvr2plot_example.gph", replace) 
	
gr export "xtlvr2plot_example.pdf", replace


*******************
*** xtinfluence ***
*******************
xtset id t

** scatter plot
xtinfluence y z,    ///
	xlabel(5(10)100, angle(h) labsize(small)) xmtick(##10) xmlabel(##2, angle(h))  ///
	ylabel(5(10)100, angle(h))  ymtick(##10) ymlabel(##2, angle(h))  			   ///
	sav("xtinfluence_scatter")
		
** heat plot
xtdiagnostics y z, 	///
		fig(heat) keylabels(all) color(RdBu, reverse)  								   ///
		xlabel(5(10)100, angle(h) labsize(small)) xmtick(##10) xmlabel(##2, angle(h))  ///
		ylabel(5(10)100, nogrid angle(h))  ymtick(##10) ymlabel(##2, angle(h)) 		   ///
		sav("xtinfluence_heat"") 
		
		
********************************************************************************
