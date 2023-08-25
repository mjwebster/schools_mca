Minnesota Comprehensive Assessment data

This is the code for processing the MCA data that comes out each year, and for running the "Beating the Odds" analysis that we do with that data. 

# Data source 

Minnesota Department of Education; typically released in late summer. Sometimes they provide embargo access to the media (but they did not in 2018)
Contact: MDE media office


## Downloading data

You can find the data files in the [MDE data center](http://w20.education.state.mn.us/MDEAnalytics/Data.jsp).

1. Go to the "Assessment and Growth Files" section: http://w20.education.state.mn.us/MDEAnalytics/DataTopic.jsp?TOPICID=1
1. For "Test Name" choose: `MCA`
1. A list will appear, for your relevant year, probably the most recent, download where:
   - Public schools
   - Subject is Math or Reading
   - `Tab` format data file

For example purposes, we will download these to the following locations relative to this project folder.

- `sources/2018MCA3MathPublicFilter9.tab`
- `sources/2018MCA3ReadingPublicFilter9.tab`



## About the data
There are separate files for the math results and reading results. Within each one, there are multiple rows of data for each school, each district, and then county-level and state-level results, too.

The data is reported for many sub-groups within each school. For example, you will find one record for all 3rd graders. Then other records for 3rd graders broken down by racial groups, socio-economic groups (on free lunch or not on free lunch), and some other groupings.

If a sub-group doesn't have enough students taking the test (less than 10), the results will not be displayed. It will show the number of students in that group who took the test, but not anything about how they did.
There is a field called "filter" that is a "y" if that record was redacted. As a result, it's really important to include filter="n" for all analysis to make sure you don't count up the test takers who don't have corresponding results.



## Data storage

Data starting in 2000-01, going forward, are stored on the DataDrop MySQL Amazon server in the `Schools` database.

The main table where this data is stored is the `mca` table.

Also on the mySQL server are tables that I created, called schoollist and districtlist, that are lookup tables with one record for each school (or district);

This is where I've added some additional info that we find useful, such as whether the school/district is in the 7-county metro and things like that; Each year
those tables need to be updated to add new schools/district. Would also be useful going forward to flag any schools/districts that are in those lists that are no longer operating.

Before the new data arrives, be sure to get updated files on special population enrollment from MDE and import those to the "specialenroll" table
You can also use this to figure out which schools/districts need to be added to the schoollist and districtlist tables. Also check for any name changes.


## R script

The R script called "process_test_score_data" pulls the MCA data (and other data) from the mySQL server. 
It spits out data that is summarized at the school level. 

It joins the data to data on the number of kids on free/reduced price lunch (poverty), calculates the percentage proficient, and then runs regression analyses on the math results and reading results.

Then it identifies schools as being "better than expected", "about as expected" or "below expected" based on the results of the regression analyses.
Some schools are listed as not having enough students tested (schools testing less than 25 students are excluded from teh analysis)
Schools that were better than expected for either math or reading (or both) are identifed as "beating the odds"

There are other scripts that run regressions by grade level (regression_by_grade) and by grade and district level (regression_by_grade_bydistrict)

The RMarkdown page, "beatingodds.RMD" has some tables showing the beating the odds results to share with reporters. This is not very sophisticated
and could be improved in future years.
