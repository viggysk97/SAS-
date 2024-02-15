
*Objective 1:
Create a new master file that is completely up to date, error-free, and includes the project
classification types.
� Incorrect values should not be kept in the new master file.
� Whenever a correction is made, it should be noted by a �Yes� in an appropriately named
additional variable.
� The new master file should be written to a .csv file named NewMaster.csv and should
contain appropriate headers. (You do not need to use SAS to supply the headers.)
� Any formatting should be done in SAS.
� The new master file should also be saved in a permanent SAS dataset named NewMaster.;

* Step 1: Since Assignment file doesn't contain a comprehensive list of assignments
 		  create a combined Assignment file using assignments from Master file and the assignments file. ;

*create dataset of given Assignments file ;
data orig_assignments;
infile '/folders/myfolders/project/Assignments.csv' dsd firstobs=2;
retain Consultant ProjNum;
length Consultant $10;
input Consultant ProjNum;
run; 
*create dataset of Assignments using the Master file ;
data master_assignments;
infile '/folders/myfolders/project/Master.csv' dsd firstobs=2;
retain Consultant ProjNum ;
length Consultant $10 ;
input Consultant ProjNum;
run;
proc sort data=orig_assignments;
by ProjNum;
run;
proc sort data=master_assignments;
by ProjNum;
run;
*stacking both assignment files;
data assignments_stacked;
set orig_assignments master_assignments;
run;
proc sort data=assignments_stacked;
by ProjNum;
run;
*create final assignments dataset with unique assignments since the stack creates duplicates;
data assignments_final;
set assignments_stacked;
by ProjNum;
if first.projNum;
run;

* Step 2: For the new forms - add assignments.

*create dataset of new forms;
data newforms;
infile '/folders/myfolders/project/NewForms.csv' dsd firstobs=2;
retain ProjNum Date Hours Stage Complete ;
length Date $10;
input ProjNum Date $ Hours Stage Complete ;
run; 
proc sort data=newforms;
by ProjNum;
run;
proc sort data=assignments_final;
by ProjNum;
run;
*add assignments to new forms and delete projnums that are not in new forms but present in assignments;
data newdata;
merge assignments_final newforms;
by ProjNum;
IF missing(Date) THEN DELETE;
run;

* Step 3: Combine newdata with masterdata;

data master;
infile '/folders/myfolders/project/Master.csv' dsd firstobs=2;
retain Consultant ProjNum Date Hours Stage Complete;
length Consultant $10 Date $10;
input Consultant ProjNum Date Hours Stage Complete;
run;
proc sort data=master;
by ProjNum;
run;
*stack master with new forms;
data master_new_1;
set newdata master;
run;

* Step 4: Update file with corrections ;

*create dataset corrections;
data corrections;
infile '/folders/myfolders/project/Corrections.csv' dsd firstobs=2;
retain ProjNum Date Hours Stage;
length Date $10;
input  ProjNum Date Hours Stage;
run;
proc sort data=corrections;
by ProjNum Date;
run;
proc sort data=master_new_1;
by ProjNum Date;
run;
* creating table with updated values only;
data master_new_3;
update master_new_1 corrections;
by ProjNum Date;
run;

*Step 5: Add Classifications to data.
*create dataset class;
data classifications;
infile '/folders/myfolders/project/ProjClass.csv' dsd firstobs=2;
retain Type ProjNum ;
length Type $25;
input Type $ ProjNum ;
run; 
proc sort data=classifications;
by ProjNum;
run;
proc sort data=master_new_3;
by ProjNum;
run;

*Our final dataset with date changed into date format;
data master_data_final;
merge classifications master_new_3;
by ProjNum;
format Date_upd mmddyy10.;
Date_upd = input(Date,mmddyy10.);
drop Date;
run;

* STEP 6 : saving dataset;

LIBNAME mydata '/folders/myfolders/project/';

proc sort data=master_data_final out=res_sort;
by Consultant ProjNum Date_upd;
run;

data mydata.NewMaster;
set res_sort;
run;

*============================================================================================================================================;

* Objective 2:
Starting with the new master file, generate a report of ongoing projects as of the last entry
date (November 4th). Ongoing projects are those that have not yet been completed. This
report should show only project numbers ;

data ongoing;
set master_data_final;
by ProjNum;
retain total 0;
if first.ProjNum then total = complete;
total + complete;
if last.ProjNum and total = 0 then output;
keep ProjNum;
label ProjNum = "Project Number";
run;

title1 'Objective 2';
title2 'Ongoing Projects';
proc print data = ongoing label;
run;

*============================================================================================================================================;

* Objective 3:
Starting with the new master file, generate a report of the consulting activity of each consultant
on each project as of the last entry date (November 4th). There should be three separate
reports, each showing the project numbers on which the consultant has worked. For each
project the following information should be given: the total number of hours worked, the
project type, whether the project has been completed, the start date of the project, and the
end date of the project (determined by the last form submitted for the project).;


proc sort data = master_data_final out = master;
by Consultant ProjNum Date_upd;
run;

data brown1 jones1 smith1;
set master ;                                       /* use sorted file */
if complete = 0  then proj_status = 'Incomplete';  /*format : proj status and remove complete*/
else proj_status = 'Complete';
if missing(hours) then hours = 0;                  /* replace missing with 0 since we will be summing later */
retain total_hours;
if stage = 1 then total_hours = 0;
total_hours = total_hours + hours; 
if consultant = "Brown" then do;
    output brown1;
    end;
else if consultant = "Jones" then do;
    output jones1;
    end;
else output smith1;
run;

/*Generate Report for Smith*/
data smith_report;
do until (last.ProjNum);		/* do until loop - tests condition after exiting loop; mainly to allocate dates */
set smith1;
by ProjNum;
start_date = min(start_date,date_upd);
end_date = max(end_date,date_upd);
end;
drop consultant date_upd hours complete;	
format start_date mmddyy10. end_date mmddyy10.;
run;

title1 'Objective 3';
title2 'Report for Smith';
proc print data=smith_report noobs label;
var type projnum total_hours proj_status start_date end_date ;
label 
type = 'Type' projnum = 'Project Number' total_hours = 'Total Hours Spent' 
proj_status = 'Project Status' start_date = 'Start Date' end_date = 'End Date'; 
run;

/*Generate Report for Brown*/
data brown_report;
do until (last.ProjNum);
set brown1;
by ProjNum;
start_date = min(start_date,date_upd);
end_date = max(end_date,date_upd);
end;
drop consultant date_upd hours complete;	
format start_date mmddyy10. end_date mmddyy10.;
run;

title2 'Report for Brown';
proc print data=brown_report noobs label;
var type projnum total_hours proj_status start_date end_date ;
label 
type = 'Type' projnum = 'Project Number' total_hours = 'Total Hours Spent' 
proj_status = 'Project Status' start_date = 'Start Date' end_date = 'End Date'; 
run;

/*Generate Report for Jones*/
data jones_report;
do until (last.ProjNum);
set jones1;
by ProjNum;
start_date = min(start_date,date_upd);
end_date = max(end_date,date_upd);
end;
drop consultant date_upd hours complete;	
format start_date mmddyy10. end_date mmddyy10.;
run;

title2 'Report for Jones';
proc print data=jones_report noobs label;
var type projnum total_hours proj_status start_date end_date ;
label 
type = 'Type' projnum = 'Project Number' total_hours = 'Total Hours Spent' 
proj_status = 'Project Status' start_date = 'Start Date' end_date = 'End Date'; 
run;

*Objective 4 :

Starting with the new master file, generate one (or more) additional report that you think
offers useful information to the LC. This report should summarize the data in some meaningful
way and should make use of a PROC procedure other than PROC PRINT (and PROC
SQL). Graphical reports are acceptable, but not required.
Notes for the reports:
� Each report should be given an appropriate title.
� Each report should look professional (ie. more complete and descriptive headers are
used for columns instead of the variable names).;

/* Relationship between Time and Project Type */

data smith_rep;
set smith_report;
Name = "Smith";
run;
data brown_rep;
set brown_report;
Name = "Brown";
run;
data jones_rep;
set jones_report;
Name = "Jones";
run;
data temp;
set smith_rep jones_rep brown_rep;
run;

title1 'Objective 4';
title2 'Avg Hour per Project type';
proc means data = temp mean;
class Type;
var total_hours;
run;

title2 'Avg Hour per Project type per consultant';
proc means data = temp mean;
class Type Name;
var total_hours;
run;

/* Graphics - Plotting workload over time for each consultant */

title2 'Workload over Time';
proc means nway data = master_data_final sum noprint;
class Date_upd Consultant;
var Hours;
output out = consul_work (drop = _type_ rename=(_freq_= Projects)) sum(Hours) = HrsPerDay;
run;
proc sgplot data=consul_work;
 styleattrs datacontrastcolors=(purple green orange)
             datasymbols=(circlefilled trianglefilled squarefilled )
             datalinepatterns=(solid);
xaxis label = "Month";
yaxis label = "Hours Worked in a Day";
styleattrs datacolors=(orange purple cyan);
scatter x=Date_upd y=HrsPerDay / group = Consultant groupdisplay=cluster markerattrs=(symbol=CircleFilled)  ; 
run;


