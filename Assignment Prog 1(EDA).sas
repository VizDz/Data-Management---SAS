FILENAME REFFILE '/home/u59388928/sasuser.v94/Listings.xls';
/*GET THE DATASET TO LIBRARIES & PRINT THE DATA*/
PROC IMPORT DATAFILE=REFFILE
	DBMS=XLS
	OUT=WORK.Listings;
	GETNAMES=YES;
RUN;

PROC CONTENTS DATA=WORK.Listings; 
RUN;

PROC PRINT DATA=WORK.Listings; 
RUN;

TITLE "Statistical Information";
PROC MEANS DATA=WORK.Listings NMISS MEAN MODE MEDIAN STD;
RUN;



/*SUMMARY STATISTICS TABLE*/
ods noproctitle;
ods graphics / imagemap=on;

proc means data=WORK.LISTINGS chartype mean std min max median n nmiss stderr 
		var mode range vardef=df q1 q3 qrange qmethod=os;
	var 'Last Review'n 'Reviews Per Month'n 'Availability 365'n 
		'Calculated Host Listings Count'n Latitude Longitude 'Minimum Nights'n 
		'Number Of Reviews'n Price;
run;



/*FREQ TABLE*/
proc freq data=WORK.LISTINGS;
	tables Neighbourhood 'Neighbourhood Group'n 'Room Type'n 
		'Calculated Host Listings Count'n / plots=(freqplot cumfreqplot);
run;



/*BAR CHART* for neigbourhood_group, neigbourhood*/
ods graphics / reset width=7in height=5in imagemap;

proc sgplot data=WORK.LISTINGS;
	hbar Neighbourhood /;
	xaxis grid;
run;

ods graphics / reset;


ods graphics / reset width=7in height=5in imagemap;

proc sgplot data=WORK.LISTINGS;
	hbar 'Neighbourhood Group'n /;
	xaxis grid;
run;

ods graphics / reset;


/*SCATTER MAP for latitude & longitude*/
ods graphics / reset width=6.4in height=4.8in;

proc sgmap plotdata=WORK.LISTINGS;
	openstreetmap;
	title 'Latitude & Longitude';
	scatter x=Longitude y=Latitude/ markerattrs=(size=7);
run;

ods graphics / reset;
title;



/*PIE CHART for Room_type*/
proc template;
	define statgraph SASStudio.Pie;
		begingraph;
		entrytitle "Room Type" / textattrs=(size=14);
		layout region;
		piechart category='Room Type'n / stat=pct;
		endlayout;
		endgraph;
	end;
run;

ods graphics / reset width=6.4in height=4.8in imagemap;

proc sgrender template=SASStudio.Pie data=WORK.LISTINGS;
run;

ods graphics / reset;



/*HISTOGRAM for price, min night, num of rev, last rev, rev per month, calculated host lst, availability*/
ods noproctitle;
ods graphics / imagemap=on;

/* Graph template to construct combination histogram/boxplot */
proc template;
	define statgraph histobox;
		dynamic AVAR ByVarInfo;
		begingraph;
		entrytitle AVAR ByVarInfo;
		layout lattice / rows=2 columndatarange=union rowgutter=0 rowweights=(0.75 
			0.25);
		layout overlay / yaxisopts=(offsetmax=0.1) xaxisopts=(display=none);
		histogram AVAR /;
		endlayout;
		layout overlay /;
		BoxPlot Y=AVAR / orient=horizontal;
		endlayout;
		endlayout;
		endgraph;
	end;
run;

/* Macro to subset data and create a histobox for every by group */
%macro byGroupHistobox(data=, level=, num_level=, byVars=, num_byvars=, avar=);
	%do j=1 %to &num_byvars;
		%let varName&j=%scan(%str(&byVars), &j);
	%end;

	%do i=1 %to &num_level;

		/* Get group variable values */
		data _null_;
			i=&i;
			set &level point=i;

			%do j=1 %to &num_byvars;
				call symputx("x&j", strip(&&varName&j), 'l');
			%end;
			stop;
		run;

		/* Build proc sql where clause */
        %let dsid=%sysfunc(open(&data));
		%let whereClause=;

		%do j=1 %to %eval(&num_byvars-1);
			%let varnum=%sysfunc(varnum(&dsid, &&varName&j));

			%if(%sysfunc(vartype(&dsid, &varnum))=C) %then
				%let whereClause=&whereClause.&&varName&j.="&&x&j"%str( and );
			%else
				%let whereClause=&whereClause.&&varName&j.=&&x&j.%str( and );
		%end;
		%let varnum=%sysfunc(varnum(&dsid, &&varName&num_byvars));

		%if(%sysfunc(vartype(&dsid, &varnum))=C) %then
			%let whereClause=&whereClause.&&varName&num_byvars.="&&x&num_byvars";
		%else
			%let whereClause=&whereClause.&&varName&num_byvars.=&&x&num_byvars;
		%let rc=%sysfunc(close(&dsid));

		/* Subset the data set */
		proc sql noprint;
			create table WORK.tempData as select * from &data
            where &whereClause;
		quit;

		/* Build plot group info */
        %let groupInfo=;

		%do j=1 %to %eval(&num_byvars-1);
			%let groupInfo=&groupInfo.&&varName&j.=&&x&j%str( );
		%end;
		%let groupInfo=&groupInfo.&&varName&num_byvars.=&&x&num_byvars;

		/* Create histogram/boxplot combo plot */
		proc sgrender data=WORK.tempData template=histobox;
			dynamic AVAR="&avar" ByVarInfo=" (&groupInfo)";
		run;

	%end;
%mend;

proc sgrender data=WORK.LISTINGS template=histobox;
	dynamic AVAR="'Last Review'n" ByVarInfo="";
run;

proc sgrender data=WORK.LISTINGS template=histobox;
	dynamic AVAR="'Reviews Per Month'n" ByVarInfo="";
run;

proc sgrender data=WORK.LISTINGS template=histobox;
	dynamic AVAR="'Availability 365'n" ByVarInfo="";
run;

proc sgrender data=WORK.LISTINGS template=histobox;
	dynamic AVAR="'Calculated Host Listings Count'n" ByVarInfo="";
run;

proc sgrender data=WORK.LISTINGS template=histobox;
	dynamic AVAR="'Minimum Nights'n" ByVarInfo="";
run;

proc sgrender data=WORK.LISTINGS template=histobox;
	dynamic AVAR="'Number Of Reviews'n" ByVarInfo="";
run;

proc sgrender data=WORK.LISTINGS template=histobox;
	dynamic AVAR="Price" ByVarInfo="";
run;

proc datasets library=WORK noprint;
	delete tempData;
	run;




/*HISTOGRAM FOR PAIR*/
/*price group by room_type*/
ods graphics / reset width=6.4in height=4.8in imagemap;

proc sgplot data=WORK.LISTINGS;
	vbox Price / category='Room Type'n;
	yaxis grid;
run;

ods graphics / reset;



/*price group by neighbourhood_type*/
ods graphics / reset width=6.4in height=4.8in imagemap;

proc sgplot data=WORK.LISTINGS;
	vbox Price / category='Neighbourhood Group'n;
	yaxis grid;
run;

ods graphics / reset;