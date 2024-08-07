*! Current version: 1.3, 07Feb23
*! Author: Annalivia Polselli (email: annalivia[dot]polselli[at]essex.ac.uk)
*! Title: Leverage-vs-Residual Plot for Panel Data with Fixed Effects
*! Descritption: lv2plot for panel data with fixed effects
* Version record: 
* 1.0 26Oct21: first version of the program
* 1.1 16Jan23: added PERcentile(integer 95) to allow the practitioner to choose the distributional cutoff for the average individual leverage and residual; changed cutoff
* 1.3 07Feb23	Added table that summarises output
* 1.4 27Feb23 Swaped order `yval' and `xval'; added `touse' in scatter and levelsof
* 1.5 06May23 removed "if `touse'" from scatter
* 1.6 06July23 the graph displays `panelvar' instead of `newid'; add variable `newid' to avoid confusion when ID number differs; missing obs are removed and then `newid' is generated; added line to remove units observed in one period
*******************************************************************************
cap program drop xtlvr2plot

program define xtlvr2plot, rclass

	version 13	

	syntax varlist(min=1 fv ts) [if] [in] [, * ]		
	
	_get_gropts , graphopts(`options') getallowed(plot addplot)
	local options `"`s(graphopts)'"'
	local plot `"`s(plot)'"'
	local addplot `"`s(addplot)'"'
	
	cap drop _lev _normres2	
		
	*****************************************
	********* COLLECT KEY INFO  *************
	********* Panel preparation *************	
	*****************************************		
 
	**Check if xtset and collect panelvar and timevar
	qui xtset 								// issues error(459) if panel not set
	local panelvar = r(panelvar)				
	local timevar  = r(timevar)				
	loc Tbar = r(Tbar)
	if "`timevar'"=="." local timevar = ""	// for unbalanced panel
	local balance = r(balanced)				
	
	qui sum `panelvar' `if' `in' `touse'
	loc NT = r(N)
	
	marksample touse
	markout `touse' `varlist'	

	tokenize "`saving'", parse("()")	
	loc newsaving "`3'"
	
	gettoken depvar indepvars: varlist
	tokenize `indepvars'
		
	_fv_check_depvar `depvar'
	_rmcoll `indepvars' if 	`touse'		
	loc indepvars_nocoll `r(varlist)'		
	fvexpand `indepvars_nocoll' 
	local cnames `r(varlist)'		
	
	local sizeofb: list sizeof local indepvars  	
	
	**Remove individuals with Ti=1
	tempvar Ti_remove
	tempname Ti_removeis1
	qui bysort `panelvar': gen `Ti_remove' = _N if `touse'
	
	qui count if (`Ti_remove'==1 & `touse')			
	scalar `Ti_removeis1' = r(N)
	if `Ti_removeis1'>0 {
		di as text "{bf:Warning}: " `Ti_removeis1' " units with Ti=1 have been excluded"
	}
	
	qui replace `Ti_remove'=. if (`Ti_remove'==1 & `touse')
	markout `touse' `Ti_remove'

	**Remove individuals with missing yvar and xvars
	tempvar missing_obs
	tempname missing_obs1
	
	**Parse indepvars
	forvalues i = 1/`sizeofb' {
		loc indepvar: word `i' of `indepvars'
		loc xmissing `xmissing' | `indepvar' ==. 
	}		
	loc missing_vars `" `depvar'==. `xmissing' "'
	qui bys `panelvar': gen `missing_obs' = cond(`missing_vars',1,0) if `touse'
	
	tempvar newid	
	sort `panelvar' `missing_obs'
	egen `newid' = group(`panelvar') if `missing_obs' == 0 //`if' `in' `touse' 
		
	mata: lev2res("`depvar'","`indepvars'","`newid'","`timevar'","`touse'", `sizeofb')

	sca  hbar = r(hbar)
	sca  ubar = r(ubar)
	
	
	*********************
	** Dataset to merge**                                              
	*********************		
qui{			
	preserve
		 
		gen _lev = . 
		gen _normres2 = . 
	
		keep  _lev _normres2
		
		loc Nc = `= rowsof(r(Hibar))'
		gen `newid' =.	               //for reshape long
		
		**Rename cols
		matrix Hibar = r(Hibar)[1..`Nc',1]
		matrix Uibar = r(Uibar)[1..`Nc',1]

		matname Hibar Hibar, col(1) explicit		
		matname Uibar Uibar, col(1) explicit		
		
		forvalues i = 1/`Nc' {
			replace `newid' = `i'  in `i'				
			replace _lev = Hibar[`i',1] in `i'
			replace _normres2 = Uibar[`i',1] in `i'	
		}

		drop if `newid' ==.
		save lev2res.dta, replace	
				
	restore
		
		sort `newid' 
		merge m:1 `newid' using lev2res.dta 
		
		drop _merge
		cap erase lev2res.dta
}	

	*** Cut-off values
	loc xval = 2/`NT'
	loc yval = (`sizeofb'+1)*`xval'  //e(df_b)
		
	*** Leverage-vs-residual plot                                              	
	scatter _lev _normres2, 								           ///
				`options'										       ///
				xline(`xval') 										   ///
				yline(`yval')  										   ///
				ytitle("Leverage", size(medsmall))					   ///
				xtitle("Normalised residuals squared", size(medsmall)) 
	
	
	*** Table that displays main info in terms of points
	** GL
	qui levelsof `panelvar' if (_lev>=`yval' & _normres2<`xval') & `touse'	
	loc n_gl = r(r)
	loc l_gl = r(levels)
	** BL
	qui levelsof `panelvar' if (_lev>=`yval' & _normres2>=`xval') & `touse'	
	loc n_bl = r(r)
	loc l_bl = r(levels)
	** VO
	qui levelsof `panelvar' if  (_lev<`yval' & _normres2>=`xval') &  `touse'						
	loc n_vo = r(r)
	loc l_vo = r(levels)

	di as txt "__________________________________________________"
	di as txt " 		 Anomalous units						 "	
	di as txt "__________________________________________________"	
	di as txt " x-cutoff =" %9.3f `xval'
	di as txt " y-cutoff =" %9.3f `yval'
	di as txt "__________________________________________________"
	di as txt " Good leverage units "
	di as txt "  - Count : " `n_gl'	
	di as txt "  - List  : `l_gl'"
	di as txt " Bad leverage units " 
	di as txt "  - Count : " `n_bl'
	di as txt "  - List  : `l_bl'"
	di as txt " Vertical outliers "
	di as txt "  - Count : " `n_vo'
	di as txt "  - List  : `l_vo'"
	di as txt "__________________________________________________"		


end 



////////////////////////////////////////////////////////////////////////////////
/// Start Mata session ///
////////////////////////////////////////////////////////////////////////////////
mata:
mata clear
mata set matastrict on

function lev2res(string scalar depvar,
		 	  string scalar indepvar,
			  string scalar panelvar,
			  string scalar timevar,
			  string scalar touse,			  
			  numeric scalar sizeofb)
{
		  

		  real matrix id, X, Xi, X_wg, iXX, iXX_wg, Hi, Hibar, Uibar, I_n		  
		  real vector info, y, yi, y_wg, Time, Timei,  beta, u_wg, resi, frac, iotat	  
		  real scalar NT, Nc, Ti, k, i, toprow, botrow, hbar, ubar, den_u2, k0
			  
		  st_view(y,.,tokens(depvar),touse) 		
		  st_view(X,.,tokens(indepvar),touse)
		  st_view(Time,.,tokens(timevar),touse)	
		  st_view(id,.,tokens(panelvar),touse) 
					  
		  X = X,J(rows(X),1,1) 
		  iXX = invsym(quadcross(X,X))
		  
		  k0  = sizeofb    
		  k   = cols(X)
		  NT  = rows(X) 
		  
		  /* group-specific */
		  info = panelsetup(id,1)
		  Nc   = rows(info)  					
	  
		  /* Define new quantities */		
		  y_wg = J(NT,  1, 0) 
		  X_wg = J(NT, k, 0)
		  u_wg = J(NT,  1, 0) 
	  		 
		  Hibar  = J(Nc,1,.)	
		  Uibar  = J(Nc,1,.)	

		  /* WG transformation */
		  for (i=1; i<=Nc; i++){ 
			 panelsubview(yi, y, i, info) 
			 panelsubview(Xi, X, i, info) 

			 toprow = info[i,1] 		  
			 botrow = info[i,2] 		
			 
			 y_wg[toprow..botrow, .] = yi :- mean(yi, 1) 
			 X_wg[toprow..botrow, .] = Xi :- mean(Xi, 1)
		  }

		  y_wg = y_wg :+ mean(y, 1) 
		  X_wg = X_wg :+ mean(X, 1)  	  
		  iXX_wg   = invsym(quadcross(X_wg,X_wg))     
		  beta = invsym(quadcross(X_wg,X_wg))*quadcross(X_wg,y_wg) 
		  
		  u_wg = y_wg - (X_wg*beta)						
	  
		  den_u2 = sqrt(u_wg'*u_wg) 		
		  frac   = (u_wg:/den_u2):^2				 
		 
		  I_n = I(NT)
		 
		  for(i=1;i<=Nc; i++){	
			 panelsubview(Xi, X_wg, i, info) 		
			 panelsubview(resi, frac, i, info)	
			 panelsubview(Timei, Time, i, info)				 			 
			 
			//individual time periods $Ti\ne T$ - allow for unbalanced panels
			 Ti  = rows(Timei) 	 
			 iotat = J(Ti,1,1)

			//Define Leverage Matrices
			 Hi  = Xi * iXX_wg * Xi'					
			 Hibar[i] = trace(Hi)/Ti	  //average leverage of unit i
			 Uibar[i] = sum(resi):/Ti    //average norm res squared of unit
				 		
		}
		
		hbar = 1/Nc*sum(Hibar)			
		ubar = 1/Nc*sum(Uibar)			
		
		st_numscalar("r(hbar)",hbar)
		st_numscalar("r(ubar)",ubar)			
		st_matrix("r(Hibar)",Hibar)	
		st_matrix("r(Uibar)",Uibar)	

}	

end

exit


