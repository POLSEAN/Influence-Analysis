{smcl}
{* *! version 1.4  07Feb2023}{...}
{hline}
help for {hi:xtinfluence}
{hline}

{hi: [XT] xtinfluence} —— Influence Analysis for Linear Panel Data with Fixed Effects

{title:Syntax}

{p 8 17 2}
{cmd:xtinfluence} {it:depvar} [{it:indepvar}] [{cmd:if}] [{cmd:in}] [, {it:options}]


{it:options} {col 20} Description
{hline}

{opt fig:ure(string)}{col 20} generates plots of influence measures from unit j to unit i. Allowed {it:string} are {it:scatter} or {it:heat} plots; default is {it:scatter}. 
{col 20} If the {it:heat} is specified and the {it:heatplot} package is not installed, the user is prompted to install it.

{opt sav:ing(filename)}{col 20} saves .dta and .pdf file with the specified name and location.

{it:graph_options}{col 20} graph options allowed with {it:scatter} and {it:heat} plots. See {cmd: graph twoway scatter} and {cmd:heatplot}.


{title:Description}

{pstd}
{cmd:xtinfluence} is designed to detect influential observations in panel data using within-estimation (fixed effects). It computes various influence metrics between unit pairs (i,j), constructs an adjacency matrix, and produces data files for further analysis or graphical inspection. The default graph type is {cmd:scatter} plot, where the size of the symbols is proportional to the magnitude of the calculated measures. Optional output includes a {cmd:heat} plot visualizing the directional influence of one unit on another.


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

{p 4 8}Example with scatter plot

{p 8 12}. xtinfluence y x, figure(scatter) xlabel(5(10)100, angle(h) labsize(small)) xmtick(##10) xmlabel(##2, angle(h)) ylabel(5(10)100, angle(h)) ymtick(##10) ymlabel(##2, angle(h)) saving(xtinfluence_scatter)

{p 4 8}Example with heat plot

{p 8 12}. xtinfluence y x, figure(heat) keylabels(all, interval) color(RdBu, reverse) lev(30) statistic(max) xlabel(5(10)100, angle(h) labsize(small)) xmtick(##10) xmlabel(##2, angle(h)) ylabel(5(10)100, angle(h)) ymtick(##10) ymlabel(##2, angle(h)) saving(xtinfluence_heat)


{title:Stored results}
{pstd}

    xtinfluence stores the following in r():
	
	Matrices
		r(C){col 20}  joint influence
		r(K){col 20}  joint effects
		r(cC){col 20} conditional influence
		r(M){col 20}  masking effect
		
	Scalars
		r(df){col 20} number of covariates

	Generated variable
	    _newid{col 20} assigns a new numeric identifier to specified {it:panelvar}
		
{pstd}
In addition, {cmd:xtinfluence} saves the following in memory and as external files:
	
	{it:filename_{cmd:adj_mtx.dta}} adjacency matrix saved as .dta file, suitable for network analysis. If {it:filename} is unspecified, {it:} is used.
	
	{it:filename}{cmd:.pdf} name of the saved graph file. If {it:filename} is unspecified, the final graph is saved as {it:.pdf}.
		
	{it:filename}{cmd:_C.gph} name of the saved graph file with the joint influence. If {it:filename} is unspecified, the final graph is saved as {it:_C.gph}.
	
	{it:filename}{cmd:_K.gph} name of the saved graph file with the joint effects. If {it:filename} is unspecified, the final graph is saved as {it:_K.gph}.
		
	{it:filename}{cmd:_cC.gph} name of the saved graph file with the conditional influence. If {it:filename} is unspecified, the final graph is saved as {it:_cC.gph}.
		
	{it:filename}{cmd:_M.gph} name of the saved graph file with the masking effects. If {it:filename} is unspecified, the final graph is saved as {it:_M.gph}.
		
{title:Requirements}

{pstd}
Requires the {cmd:heatplot} package for visualizations. Install it via:

{phang2}{cmd:. ssc install heatplot}


{title:Citation of xtinfluence}

{cmd:xtinfluence} is not an official Stata command. It is a free contribution to the research community, like a paper. Please cite it as such:

{pstd}
Polselli, A. (2023). {cmd:xtinfluence} (Version 1.7) [Computer software]. GitHub. {browse "https://github.com/POLSEAN/Influence-Analysis": https://github.com/POLSEAN/Influence-Analysis}.

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
Related commands: {help scatter}, {help heatplot}.


	