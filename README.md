# Influence-Analysis
Method for visual detection of anomalous units in panel data models with fixed effects

# File Description
This repo includes the following files and folders:
  1. `ado/.` folder with the .ado files of the community-contributed commands
  2. `do/.` folder with an example of the use of the commands
  3. *Influence_analysis_explainer_Polselli.pdf*: Explainer of the paper 
  4. *presentation_Stata_Polselli.pdf*: Slides presented at the 20th German Stata Conference (Berlin, 16 June 2023) with an explanation of the community-contributed commands

>[!NOTE]
>Working paper available on [arXiv](https://arxiv.org/abs/2312.05700).

> Help files uploaded (August 2025)

# Instructions to access and use the commands
  1. Dowload the ado folder and locate it in the working directory
  2. After setting the work directory in the .do file, add the line
     ```
     adopath ++ "your_working_directory/ado"
     ```
  3. Replace  "your_working_directory" with the path containing the ado folder
  4. Run the code

# References
Polselli, A. (2023). Influence Analysis with Panel Data. (https://arxiv.org/abs/2312.05700)[arXiv preprint arXiv:2312.05700].

`xtlvr2plot` and `xtinfluence` are not an official Stata command, but community-contributed commands available for the research community. Please cite those as such:

Polselli, A. (2023). **xtlvr2plot** (Version 1.8) [Computer software]. GitHub. (https://github.com/POLSEAN/Influence-Analysis)[https://github.com/POLSEAN/Influence-Analysis].

Polselli, A. (2023). **xtinfluence** (Version 1.7) [Computer software]. GitHub. (https://github.com/POLSEAN/Influence-Analysis)[https://github.com/POLSEAN/Influence-Analysis].


