*! Current version: 1.4 07Feb23
*! Author: Annalivia Polselli (email: annalivia[dot]polselli[at]essex.ac.uk)
*! Title: Influence Analysis for Linear Panel Data with Fixed Effects
*! Description: Influence analysis for panel data displaying the measures and effects of unit j against unit i. 
*! The size of the symbols is proportional to the magnitude of the calculated measures.
*  Version records:
*1.0 21Mar22: first version of the program; deals w/missing vars using same method used in xtreg
*1.1 21Jul22: added lines to construct adjacency matrix and relative .dta;
* [added colors]
* removed 2D (measure-unit) scatter plots with multiple cutoffs
*1.2 16Jan23: added FIGure(string) to plot values in a network manner (unit j vs unit i) using scatter plots and heat plots (the data sets are generated to use igraph in R as the nwplot does not allow to build the graphs); check if 'heatplot' is installed otherwise release an error message to ask to install it;
*1.3 25Jan23 Deleted lines for creation of datasets for network analysis
*1.4 07Feb23	Added table that summarises output
*1.5 06May23 the title is not passed through the function
*1.6 16May23 Added !missing(M) and !missing(K) for cut-offs; added list of j with K>=p99 and M>=1
*1.7 21Jul23 Added newid next to oldid; modified `panel prep' following xtlvr2plot v.1.6. 
*To do: add `preserveid' option, and add title of combined graphs.
********************************************************************************
cap program drop xtinfluence
 
program define xtinfluence, rclass

version 13

local options "FIGure(string) SAVing(passthru)"
	
if replay() {
	if "`e(cmd)'" != "xtinfluence" {
		error 301
	}
 	syntax [, `options' *]
 
}

else {	
	syntax varlist(fv ts numeric min=2) [if] [in]	 /// minimum two vars - i.e., y&x 
	[, `options' *]	
	
	_get_gropts , graphopts(`options') getallowed(plot addplot)  getcombine
	local options `"`s(graphopts)'"'
	local plot `"`s(plot)'"'
	local addplot `"`s(addplot)'"'
		
	//tokenize saving
    tokenize "`saving'", parse("("")")	
	loc newsaving "`3'"
	*loc title "`title'"
	
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
	
	*tempvar newid	
	sort `panelvar' `missing_obs'
	egen _newid = group(`panelvar') if `missing_obs' == 0 
		
	mata : diagnose("`depvar'","`indepvars'","_newid","`timevar'","`touse'",`sizeofb')


********************************************************************************
*** Construct adjacency matrix                                           
********************************************************************************
	preserve

	di "Constructing the adjacency matrix ..."
	
	**for versions prior to Stata 16
	mat C  = r(C)
	mat K  = r(K)
	mat cC = r(cC)
	mat M  = r(M)
	sca k  = r(df)
	
	cap drop Cij_names
	gen Cij_names = ""

	tokenize "`: rownames C'"
	loc Nc = `= rowsof(C)'

	gen i =.	//for reshape long
	
	qui{ 
		forvalues j = 1/`Nc'{
			
			/* joint influence */
			gen C`j' = .   
			gen K`j' = .  	
			
			matrix C`j' = C[1..`Nc',`j']
			matname C`j' C`j', col(1) explicit

			matrix K`j' = K[1..`Nc',`j']
			matname K`j' K`j', col(1) explicit
						
			/* conditional influence */
			gen cC`j' = .   
			gen M`j' = .  
			
			matrix cC`j' = cC[1..`Nc',`j']
			matname cC`j' cC`j', col(1) explicit

			
			matrix M`j' = M[1..`Nc',`j']
			matname M`j' M`j', col(1) explicit

			forvalues i = 1/`Nc' {
				replace i = `i'  in `i'	
				
				//added in .dta
				matname C`j' C`i'C`j', r(`i') explicit
				matname K`j' K`i'K`j', r(`i') explicit

				matname cC`j' cC`i'cC`j', r(`i') explicit
				matname M`j' M`i'M`j', r(`i') explicit
			
				replace C`j' = C`j'[`i',1] in `i'
				replace K`j' = K`j'[`i',1] in `i'
				
				replace cC`j' = cC`j'[`i',1] in `i'
				replace M`j' = M`j'[`i',1] in `i'							
			}
		}	
	}

	qui drop if i==.
	qui keep * i 
	qui reshape long C K cC M, i(i) j(j)

	keep i j C K cC M

	qui replace K = 1 if i==j
	sum C K cC M

	** cut-off values
	loc v1 = `sizeofb'+1
	loc v2 = `NT'-`Nc'-`v1'
	loc c1 = 4/`Nc'
	loc c2 = invF(`v1',`v2', 0.5)
	
	qui levelsof i if C>=`c1' & i==j	
	loc n_c1 = r(r)
	loc l_c1 = r(levels)
	
	qui levelsof i if C>=`c2' & i==j
	loc n_c2 = r(r)
	loc l_c2 = r(levels)
	
	qui levelsof i if M>=1 & !missing(M)
	loc n_m = r(r)
	loc l_m = r(levels)	
	qui levelsof j if M>=1 & !missing(M)
	loc nj_m = r(r)
	loc lj_m = r(levels)	
	
	qui sum K, det
	loc k_p99 = r(p99)
	qui levelsof i if K>=`k_p99' & !missing(M)
	loc n_k = r(r)
	loc l_k = r(levels)
	qui levelsof j if K>=`k_p99' & !missing(M)
	loc n_kj = r(r)
	loc l_kj = r(levels)
	
	di as txt "__________________________________________________"
	di as txt " 		 Influence analysis						 "	
	di as txt "__________________________________________________"
	di as txt " v1 = k+1 =  `v1' "
	di as txt " v2 = NT-N-k-1 = `v2' "
	di as txt " c1 = 4/N = `c1' "
	di as txt " c2 = F(v1,v2,.5) =" %9.4f `c2' 
	di as txt "__________________________________________________"	
	di as txt " Cii >= c1 "
	di as txt "  - Count : " `n_c1'	
	di as txt "  - List  : `l_c1'"
	di as txt " Cii >= c2 " 
	di as txt "  - Count : " `n_c2'
	di as txt "  - List  : `l_c2'"
	di as txt " i with K >= p99 "
	di as txt "  - Count : " `n_k'
	di as txt "  - List  : `l_k'"
	di as txt " j with K >= p99 "
	di as txt "  - Count : " `nj_k'
	di as txt "  - List  : `lj_k'"	
	di as txt " i with M >= 1 "
	di as txt "  - Count : " `n_m'
	di as txt "  - List  : `l_m'"	
	di as txt " j with M >= 1 "
	di as txt "  - Count : " `nj_m'
	di as txt "  - List  : `lj_m'"	
	di as txt "__________________________________________________"				
	save "`newsaving'_adj_mtx", replace
		
	restore			
}

	preserve
		**Generate FIGure(string)
		u "`newsaving'_adj_mtx", clear

		if ("`figure'"=="scatter" | "`figure'"==""){		//scatter plot
		
			two (scatter j i if i!=j [aw = C], msize(tiny))  					   ///
				(scatter j i if i==j [aw = C], mc(red) msize(tiny)), 			   ///
				`options' legend(off) 										  	   ///
				xtitle("Unit i", size(medsmall))   								   ///
				ytitle("Unit j", size(medsmall))  								   ///
				title("Joint influence", size(medsmall)) 						   ///
				saving("`newsaving'_C.gph", replace)  							   
				

			scatter j i [aw = cC], msize(tiny) 									   ///
					`options' legend(off) 										   ///
					xtitle("Unit i", size(medsmall)) 							   ///
					ytitle("Unit j", size(medsmall)) 							   ///
					title("Conditional influence", size(medsmall)) 				   ///
					saving("`newsaving'_cC.gph", replace) 						   
							
			scatter j i [aw = K], msize(tiny) 									   ///
					`options' legend(off) 										   ///			
					xtitle("Unit i", size(medsmall)) 							   /// 
					ytitle("Unit j", size(medsmall)) 							   ///
					title("Joint Effects", size(medsmall)) 					       ///
					saving("`newsaving'_K.gph", replace)						   

			scatter j i [aw = M^(1.5)], msize(tiny) 							   ///
					`options' legend(off) 										   ///
					xtitle("Unit i", size(medsmall))  							   ///
					ytitle("Unit j", size(medsmall)) 							   ///
					title("Conditional Effects", size(medsmall)) 				   ///
					saving("`newsaving'_M.gph", replace)						   
		}
		else if ("`figure'"=="heat"){		//heat plot
		
			**check if command is installed
			cap which heatplot
			if (_rc==111) {
				di as error "Command not found. Type 'ssc install heatplot' to install the command.'"
				di as error "Type 'ssc install palettes, replace' for color palette"
				di as error "Type 'ssc install colrspace, replace' for color space."
				exit(111)
			}
			else{
				
				heatplot C j i, `options'  										   ///
					xtitle("Unit i", size(medsmall))  							   ///
					ytitle("Unit j", size(medsmall))  							   /// 
					title("Joint influence", size(medsmall)) 					   ///
					saving("`newsaving'_C.gph", replace)

					
				heatplot cC j i, `options' 										   ///
					xtitle("Unit i", size(medsmall))  							   ///
					ytitle("Unit j", size(medsmall))  							   /// 
					title("Conditional influence", size(medsmall))				   ///
					saving("`newsaving'_cC.gph", replace)

				//qui gen lnK = ln(K)
				heatplot K j i, `options' 										   ///
					xtitle("Unit i", size(medsmall))  							   ///
					ytitle("Unit j", size(medsmall))  							   /// 
					title("Joint Effects", size(medsmall)) 						   ///
					saving("`newsaving'_K.gph", replace)
				//qui drop lnK
					
				heatplot M j i, `options' 										   ///
					xtitle("Unit i", size(medsmall))  							   ///
					ytitle("Unit j", size(medsmall))  							   /// 
					title("Conditional Effects", size(medsmall)) 				   ///
					saving("`newsaving'_M.gph", replace)				
				}	
			}
				
			loc plots "`newsaving'_C.gph `newsaving'_K.gph `newsaving'_cC.gph `newsaving'_M.gph"
			graph combine `plots', iscale(.5) cols(2) `title'
			graph export "`newsaving'.pdf", replace	
restore

end 


////////////////////////////////////////////////////////////////////////////////
///  MATA ///
////////////////////////////////////////////////////////////////////////////////
mata:
mata clear
mata set matastrict on

void diagnose(string scalar depvar,
		 	  string scalar indepvar,
			  string scalar panelvar,
			  string scalar timevar,
			  string scalar touse,			  
			  numeric scalar sizeofb)
{
		  
		  real matrix id, X, Xi, Xj, Xij, X_wg, iXX, iXX_wg, b, Mi, Mj, Hi, Hj, Hij,  
					  iMi, iMj, I_Ti, I_Tj, I_n, C, cC, K, M		  
		  real vector info, y, yi, y_wg, Time, Timei, Timej, beta, bij, bi, bj,
					  ui, uj, u_wg, diagC, ustari, ustarj
		  real scalar NT, Nc, Ti, Tj, k, k0, i, j, toprow, botrow, s2
					  
		  st_view(y,  ., tokens(depvar)  , touse) 		
		  st_view(X,  ., tokens(indepvar), touse)
		  st_view(Time, ., tokens(timevar), touse)	
		  st_view(id, ., tokens(panelvar), touse) 

		  X = X,J(rows(X),1,1)
		  NT  = rows(X) 
		  iXX = invsym(quadcross(X,X))
		  k0  = sizeofb                
		  k   = cols(X)
		  
		  /* group-specific */
		  info = panelsetup(id, 1)
		  Nc   = rows(info)  					
		  I_n  = I(NT)
		  
		  /* Define new quantities */		
		  y_wg = J(NT,  1, 0) 
		  X_wg = J(NT, k, 0)
		  u_wg = J(NT,  1, 0) 

		  bij  	 = J(k,1,.) 
		  bi  	 = J(k,Nc,.)		  
		  bj  	 = J(k,1,.)
		  
		  C  	 = J(Nc,Nc,.) 
		  diagC  = J(Nc,1,0) 		  
		  cC  	 = J(Nc,Nc,.)	  
		  K  	 = J(Nc,Nc,.)
		  M  	 = J(Nc,Nc,.)

		  /* WG transformation */
		  for (i=1; i<=Nc; i++) { 
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
		  s2 = quadcross(u_wg,u_wg)/(NT-Nc-k0)  //mse of regression
  
		 /*Start influence analysis*/		
		  for(i=1;i<=Nc; i++){  
			 panelsubview(Xi, X_wg, i, info) 
			 panelsubview(ui, u_wg, i, info)				 
			 panelsubview(Timei, Time, i, info)				 			 
		 
			//individual time periods $Ti\ne T$ - allow for unbalanced panels
			 Ti  = rows(Timei) 	 
			 I_Ti = I(Ti)
		 
			//Define Leverage Matrices
			 Mi  = J(Ti,Ti,0)	
			 ustari  = J(Ti,Ti,0)		

			 Hi  = Xi * iXX_wg * Xi'		
			 //Hbar[i,i] = trace(Hi)/Ti			 
			 Mi	 = Mi + I_Ti - Hi
			 iMi = invsym(Mi)
			 
			 //std formula for b[i,i]		
			 bi[.,i] = (beta - iXX_wg *  Xi' * iMi * ui)
			
			 C[i,i] = (ui'*iMi*Hi*iMi*ui)/(s2*k0)
			 cC[i,i] = 0
		
			 for(j=1; j<=Nc; j++){	
				if (i!=j){	
				 panelsubview(Xj, X_wg, j, info) 	
				 panelsubview(uj, u_wg, j, info)	
				 panelsubview(Timej, Time, j, info)	
		 
				 Tj  = rows(Timej)
				 I_Tj = I(Tj)					 
				 								  
				 //Define Leverage Matrices
				 Mj  = J(Tj,Tj,0)
				 ustarj  = J(Tj,Tj,0)							 
				 Hj  = Xj * iXX_wg * Xj'							
				 Mj	 = Mj + I_Tj - Hj	
				 iMj = invsym(Mj)			 
				 Hij = Xi * iXX_wg * Xj'
	
				 bj = (beta - iXX_wg *  Xj' * iMj * uj) //kx1		     
				
				 if (j==1){
					Xij = X_wg[j+1,.]	
				 }
				 else{
					Xij = X_wg[1..j-1,.]\X_wg[j+1,.]						
				 }
						
				bij = (bi[.,i] - iXX_wg *(Xi'*iMi*Hij+Xj')*invsym(Mj-Hij'*iMi*Hij)*(Hij'*iMi*ui+uj))
									
				C[i,j]  = (bij-beta)'*quadcross(X_wg,X_wg)*(bij-beta)/(s2*k0)
				cC[i,j] = (bij-bj)'*quadcross(Xij,Xij)*(bij-bj)/(s2*k0) 	
				
				K[i,j] = C[i,j]/C[i,i]
				M[i,j] = cC[i,j]/C[i,i]
				}	
			}			
		}
		
		//diagC = diagonal(C)
		//K = C:/diagC  
		//M = cC:/diagC 		
	
		st_matrix("r(C)",C)	
		st_matrix("r(K)",K)
		
		st_matrix("r(cC)",cC)
		st_matrix("r(M)",M)
		st_numscalar("r(df)",k)
	}	

end

exit


