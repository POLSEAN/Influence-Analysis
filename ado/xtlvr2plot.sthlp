{smcl}

{hline}
help for {hi:xtlvr2plot}
{hline}

{hi: [XT] xtlvr2plot} —— Leverage-vs-residual plot for Panel Data with Fixed Effects

{title:Syntax}

{p 8 17 2}
{cmd:xtlvr2plot} {it:depvar} [{it:indepvar}] [{cmd:if}] [{cmd:in}] [, {it:options}]


{it:options} {col 20} Description
{hline}

{it:graph_options}{col 20} graph options allowed with {it:scatter} plots. See {cmd: graph twoway scatter}.


{title:Description}

{pstd}
{cmd:xtlvr2plot} is designed to detect and classify anomalous units in panel data using within-estimation (fixed effects). It computes the leverage and the normalised squared residual of each cross-sectional unit in the sample, and produces leverage-vs-residuals plots suitable for panel data investigation. 

{title:Examples}
{pstd}

An example of the use of the command using simulated data:

{p 4 8}Set up

	. clear 
	. set seed 1234
	. set obs 100
	. gen id = _n
	. expand 10
	. bys id: gen t = _n 
	. bys id: gen x = rnormal(0,1) 
	. bys id: gen a = runiform(0,20)
	. gen y = .

{p 4 8}Generate anomalous units
     
	. bys id: replace x = rnormal(10,1) if id==20 & t<=5 	  // good leverage 	
	. bys id: replace x = rnormal(10,1) if id==10 & t<=5      // bad leverage (X)
	. bys id: replace y = 1 + .5*x + a + runiform()           // original Y
	. bys id: replace y = y + rnormal(50,1) if id==10 & t<=5  // bad leverage (Y)
	. bys id: replace y = y + rnormal(50,1) if id==30 & t<=5  // vertical outlier

{p 4 8}Declare data to be panel data (no need to run {cmd:xtreg} regression) 

	. xtset id t

{p 4 8}Run command and export graph

	. xtlvr2plot y x, mlabel(id) xlabel(, format(%9.3fc)) ylabel(, angle(h) format(%9.3fc)) title("Unit-wise Evaluation", size(medsmall))
	. graph export "xtlvr2plot_example.pdf", replace

{title:Stored results}
{pstd}

    xtlvr2plot stores the following in r():	

	Matrices
	    r(Hi){col 20} individual influence
	    r(ui){col 20} normalised squared residuals

	Generated variables
	    _lev{col 10} individual leverage of {it:panelvar}
	    _normres2{col 10} individual normalised of {it:panelvar}


{title:Citation of xtinfluence}

{cmd:xtlvr2plot} is not an official Stata command. It is a free contribution to the research community, like a paper. Please cite it as such:

{pstd}
Polselli, A. (2023). {cmd:xtlvr2plot} (Version 1.8) [Computer software]. GitHub. {browse "https://github.com/POLSEAN/Influence-Analysis": https://github.com/POLSEAN/Influence-Analysis}.

{title:References}

{pstd}
Polselli, A. (2023). Influence Analysis with Panel Data. {browse "https://arxiv.org/abs/2312.05700":arXiv preprint arXiv:2312.05700}.


{title:Author}

{pstd}
Annalivia Polselli,  
Institute for Social and Economic Research (ISER), University of Essex. 
Email: annalivia[dot]polselli[at]essex.ac.uk

{title:Also see}

{psee}
Related commands: {help scatter}.


	