Minnesota Comprehensive Assessment data

This is the code for processing the MCA data that comes out each year, and for running the "Beating the Odds" analysis that we do with that data. 

# Data source 

Minnesota Department of Education; typically released in late summer (usually the week the State Fair starts). Sometimes they provide embargo access to the media (but they did not in 2018; in 2023, we got about half a day)
Contact: MDE media office


## Downloading data
If there's an embargo, the links will be sent via email. 

If not, 
You can find the data files in the [MDE data center](http://w20.education.state.mn.us/MDEAnalytics/Data.jsp).

under "Assessment"

Starting in 2018-19, they combined the MCA and MTAS tests into one sets of Excel files (one for Reading, one for Math). In 2023, I asked if they could return to releasing tab-delimited text files, but they refused.

I've had to export the sheets (state, district, school) out of each Excel file in order to run them through my R script. Be wary of changes to columns each year.

## About the data
There are separate files for the math results and reading results.

The data is reported for many sub-groups within each school. For example, you will find one record for all 3rd graders. Then other records for 3rd graders broken down by racial groups, socio-economic groups (on free lunch or not on free lunch), and some other groupings. These groupings have changed over the years, BTW.

If a sub-group doesn't have enough students taking the test (less than 10), the results will not be displayed. It will show the number of students in that group who took the test, but not anything about how they did.

There is a field called "filter" that is a "y" if that record was redacted. As a result, it's really important to include filter="n" for all analysis to make sure you don't count up the test takers who don't have corresponding results.



## Data storage

Data starting in 2000-01, going forward, are stored on the DataDrop MySQL Amazon server in the `Schools` database.

The mca table has 2000-01 through 2017-18. The newer data is in a table called mca2019_present.

Also on the mySQL server are tables that I created, called schoollist and districtlist, that are lookup tables with one record for each school (or district);

This is where I've added some additional info that we find useful, such as whether the school/district is in the 7-county metro and things like that; Each year those tables need to be updated to add new schools/district. Would also be useful going forward to flag any schools/districts that are in those lists that are no longer operating. (I usually do this update when enrollment data is released in February)



## R script

In 2023, I revised my process. but there are still some older scripts lingering around just in case. 

There are R scripts such as "import_mca_2023.R" that were customized to fit each year and the data ends up standardized at the end of each script. 

So for the next year, a new script will need to be written to deal with any (potential) changes. It spits out a csv file that you can then import into mySQL and append it to the mca2019_present table. 

Once that is done, then you can run the R file "test_scores_day_one" that pulls the data from mySQL, appends standardized school/district names and poverty data. Then it spits out a file that can be used for an online lookup tool and also runs some high-level analysis for a day one story, and then runs a regression analysis to use for Beating the Odds. 


Then it identifies schools as being "better than expected", "about as expected" or "below expected" based on the results of the regression analyses.
Some schools are listed as not having enough students tested (schools testing less than 25 students are excluded from teh analysis)
Schools that were better than expected for either math or reading (or both) are identifed as "beating the odds"


