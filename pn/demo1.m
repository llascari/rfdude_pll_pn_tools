clear
close all
clc

disp("walking through some phase noise anaysis/manipulationtoos")

disp("run a script to generate some PLL data files to be used in analysis")
make_pn_datfiles

disp("hit any key to view the data files generated")
pause
plot_array_test

disp("Next you'll be prompted to pick a phase noise data fille ->look in datfiles_local");

disp("hit any key")
pause

pn_simple_analysis_1a
