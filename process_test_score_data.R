#install.packages("tidyverse", "ggplot2", "lubridate", "reshape2", "tidyr", "janitor", "scales", "knitr","aws.s3", "htmltools", "rmarkdown", "readxl", "DT", "kableExtra", "ggthemes", "RMySQL")

#install.packages("tidylog")
  
#BEFORE RUNNING THIS:
#Make sure SchoolList table is up-to-date
#poverty data -- public version
#poverty data - private version

options(scipen=999)


# load required packages
library(tidyverse)
library(lubridate) #date functions
library(reshape2) #use this for melt function to create one record for each team
library(janitor) #use this for doing crosstabs
library(scales) #needed for stacked bar chart axis labels
library(knitr) #needed for making tables in markdown page
library(aws.s3)
library(htmltools)#this is needed for Rstudio to display kable and other html code
library(rmarkdown)
library(readxl)
library(DT) #needed for making  searchable sortable data tble
library(kableExtra)
library(ggthemes)
library(RMySQL)
library(stringr)
#library(tidylog) #this needs to be loaded last





# START HERE --------------------------------------------------------------

#VARIABLES THAT NEED TO BE CHANGED

thisyear <- '19-20'
endingyr <-  '2020'
previous_endingyr <-  '2019'
lastyear <-  '18-19'
firstyear <-  '12-13' #this shouldn't need to change
race_groups_start_year <-  '13-14'  #this shouldn't need to change; this is when MDE changed race groupings

#this is where to find the old private poverty data file (which gets generated as part of this script)
poverty_olderyrs <- paste('W:/private_poverty_MDE/private_poverty_through', previous_endingyr, '.csv', sep='')

#set this path for the new PUBLIC enrollment file
public_enroll_file <-  './data/enrollment_public_file_2019_v2.xlsx'

#set this path for the new PRIVATE poverty/enrollment file
new_private_poverty_file <-  'W:/private_poverty_MDE/Star Tribune Media Request - Free and Reduced Price Meal Eligible Enrollment.xlsx'

#IMPORT STARTS HERE------------------



#import public version of poverty data for new year

public_enrollment <- read_excel(public_enroll_file, sheet="School", range="A2:AX13905") %>%
  clean_names() %>% mutate(schoolid=paste(district_number, district_type, school_number, sep="-"))

enrollment <-  public_enrollment %>% select(data_year, schoolid, grade, total_enrollment)


public_poverty <-  public_enrollment %>% filter(grade=='All Grades')  %>% 
  select(schoolid ,total_enrollment, pct_poverty=total_students_eligible_for_free_or_reduced_priced_meals_percent)




#PRIVATE poverty numbers (includes older years)
#these cannot be published
#they must be stored on the NewsCARdata server that only I have access to
#data must deleted within 6 months after agreement signed


#in this file, the pctpoverty comes in as a fraction



private_poverty_olderyrs <-  read_csv(poverty_olderyrs) 


#this file the pctpoverty comes across as a whole number
private_poverty_thisyear <- read_excel(new_private_poverty_file, sheet="School", range="A1:P13904") %>%
  clean_names() %>% filter(grade=='All Grades') %>% select(district_number, district_type, school_number, district_name,
                                                                 school_name, pctpoverty=unfiltered_total_students_eligible_for_free_or_reduced_priced_meals_percent,
                                                                 datayear=data_year, freelunch=unfiltered_total_students_eligible_for_free_or_reduced_priced_meals_count) %>% 
  mutate(schoolid=paste(district_number, district_type, school_number, sep="-"),
         pctpoverty = pctpoverty/100,
         povertycategory = case_when(pctpoverty>=.5 ~ 'High',
                                     pctpoverty<.25 ~ 'Low',
                                     pctpoverty<.5 & pctpoverty>=.25 ~ 'Medium'))

private_poverty_thisyear <- left_join(private_poverty_thisyear, public_poverty %>% select(schoolid, total_enrollment), by=c("schoolid"="schoolid")) %>% rename(k12enr=total_enrollment)




#put all private poverty data in one file
private_poverty <- bind_rows(private_poverty_thisyear, private_poverty_olderyrs)



#need to save the full file off to a csv for next year
write.csv(private_poverty, paste('W:/private_poverty_MDE/private_poverty_through', endingyr, '.csv', sep=''), row.names = FALSE)


#uSE THIS Original import the first time
#it creates csv files that can be used for repeating the analysis

# Original import ---------------------------------------------------------

#connect to the database;




con <- dbConnect(RMySQL::MySQL(), host = Sys.getenv("host"), dbname="Schools",user= Sys.getenv("userid"), password=Sys.getenv("pwd"))

#Pull MCA data summarized by school
#this will only be for all years since 2012-13
#only schools with classification code between 10-40 & 46 (distance learning)
#mca_for_analysis table is created as part of the mca_import script in mySQL

data1 <- dbSendQuery(con, "select * from mca_for_analysis")
mca <- fetch(data1, n=-1)
mca <-  mca %>% clean_names()
dbClearResult(data1)

#populate null values with zeros
#mca$count_refused[is.na(mca$count_refused)] <- 0
#mca$count_refused_parent[is.na(mca$count_refused_parent)] <- 0
#mca$count_refused_student[is.na(mca$count_refused_student)] <- 0

#mca <-  mca %>% mutate(optout = count_refused+count_refused_parent+count_refused_student,
#                                   pct_optout_per10k = (optout/grade_enrollment)*10000)


#create a separate file of schoolID numbers that show up in this year's data

data_schools <-  dbSendQuery(con, "select * from mca_thisyear_schools")
mca_schools_this_year <-  fetch(data_schools, n=-1)
mca_schools_this_year <- mca_schools_this_year %>% clean_names()
dbClearResult(data_schools)


#Pull schools that don't have a math and/or reading record due to suppression
#need to add these into the dataviz file at the end of the script

data2 <- dbSendQuery(con, "select * from mca_missing_schools")
missingschools <- fetch(data2, n=-1)
missingschools <-  missingschools %>% clean_names()
dbClearResult(data2)

#Pull SchoolList (needs to use distinct because there are some duplicates)
data3 <- dbSendQuery(con, "select distinct schoolid, district_type, schoolnumber, district_name, school_name, 
                     school_classification, school_type, grades, metro7_strib, location_strib from schoollist")
school_list <- fetch(data3, n=-1)
school_list <-  school_list %>% clean_names()

dbClearResult(data3)




#pull statewide summaries
#leaves out the filtered categories
data5 <- dbSendQuery(con, "select dataYear, grade, subject, reportOrder, reportCategory, ReportDescription, filtered, countTested, countLevel1, 
countLevel2, countLevel3, countLevel4, CountRefused, CountRefusedParent, CountRefusedStudent, gradeEnrollment
from mca where summarylevel='state' and
                     filtered='n' and (subject='M' or subject='R') and datayear>='12-13'")
statewide <- fetch(data5, n=-1)
statewide <-  statewide %>% clean_names()
dbClearResult((data5))


#statewide$count_refused[is.na(statewide$count_refused)] <- 0
#statewide$count_refused_parent[is.na(statewide$count_refused_parent)] <- 0
#statewide$count_refused_student[is.na(statewide$count_refused_student)] <- 0

#statewide <-  statewide %>% mutate(optout = count_refused+count_refused_parent+count_refused_student,
#                                   pct_optout_per10k = (optout/grade_enrollment)*10000)

#pull  district-level results
#this is for 2015-16 to present
data6 <- dbSendQuery(con, "select schoolid as districtid, districtName, datayear, subject, reportCategory, ReportDescription, sum(counttested) as tot_tested, sum(countlevel3) as lev3, sum(countlevel4) as lev4 from mca where summarylevel='district' and reportOrder='1' and filtered='N' and datayear>='15-16' group by schoolid, districtname, datayear, subject, reportCategory, ReportDescription")
districts_mca <- fetch(data6, n=-1)
districts_mca <-  districts_mca %>% clean_names()
dbClearResult((data6))



#opt out data for all schools and all categories
data7 <- dbSendQuery(con, "select * from mca_opt_outs")
optouts <- fetch(data7, n=-1)
optouts <-  optouts %>% clean_names()
dbClearResult((data7))
#disconnect connection
dbDisconnect(con)

optouts <-  optouts %>% mutate(total_kids = counttested+optout+other_incomplete)



data8 <- dbSendQuery(con, "select * from DistrictList")
district_list<- fetch(data8, n=-1)
district_list <-  district_list %>% clean_names()
dbClearResult((data8))

#disconnect connection
dbDisconnect(con)

#writing data frames out to csv for alternate import
#write.csv(mca, "./data/mca_original.csv", row.names=FALSE)
#write.csv(race, "./data/race.csv", row.names=FALSE)
#write.csv(school_list, "./data/school_list.csv", row.names=FALSE)
#write.csv(poverty, "./data/poverty.csv", row.names=FALSE)
#write.csv(statewide, "./data/statewide.csv", row.names=FALSE)
#write.csv(districts_mca, "./data/districts_mca.csv", row.names=FALSE)

rm(data1)
rm(data2)
rm(data5)
rm(data6)
rm(data8)
rm(data7)


# END HERE ----------------------------------------------------------------

#need to fix uppercase and some other problems with the names
write.csv(mca_schools_this_year, 'mca_schools_this_year.csv', row.names=FALSE)


# Alternate import --------------------------------------------------------
#For repeating the analysis after doing the original import
#First uncomment these import lines, then run all code below


#mca_original <- read_csv("./data/mca_original.csv")
#race <-  read_csv("./data/race.csv")
#school_list <-  read_csv("./data/school_list.csv")
#poverty <-  read_csv("./data/poverty.csv")
#statewide <-  read_csv("./data/statewide.csv")
#districts_mca <- read_csv("./data/districts_mca.csv")



# ANALYSIS SECTION --------------------------------------------------------



#join PRIVATE poverty to mca for this year
private_poverty <-  private_poverty %>% mutate(schoolid= str_trim(schoolid), datayear=str_trim(datayear))
mca <-  mca %>% mutate(schoolid=str_trim(schoolid), datayear=str_trim(data_year))



mca <- left_join(mca, private_poverty %>% select(schoolid, datayear, pctpoverty, povertycategory), by=c("schoolid"="schoolid","data_year"="datayear"))

#ARE THERE ANY SCHOOLS THAT DO NOT HAVE POVERTY DATA???
#mca %>% filter(is.na(pctpoverty)) %>% select(schoolid, data_year, districtname, schoolname, cnt_tested)


#make reading and math subsets for regression
#exclude schools that tested fewer than 25 students
#calculate proficiency percentages


math <-  mca %>% filter(subject=='M', cnt_tested>=25 , pctpoverty!='NA') %>%
  mutate(numproficient=cntlev3+cntlev4, pctprof= (cntlev3+cntlev4)/cnt_tested, notes='Included')

read <- mca %>% filter(subject=='R', cnt_tested>=25, pctpoverty!='NA') %>% mutate(numproficient=cntlev3+cntlev4, pctprof= (cntlev3+cntlev4)/cnt_tested, notes='Included')


#create two files of the schools excluded from the analysis
#these need to be added back to the final data file
math_excluded <-  mca %>% filter(subject=='M', cnt_tested<25 | is.na(pctpoverty))%>%
  mutate(numproficient=cntlev3+cntlev4, pctprof= (cntlev3+cntlev4)/cnt_tested, 
         notes='Less than 25 students tested', predicted=NA_real_,  residual=NA_real_)


read_excluded <- mca %>% filter(subject=='R', cnt_tested<25 | is.na(pctpoverty)) %>%
  mutate(numproficient=cntlev3+cntlev4, pctprof= (cntlev3+cntlev4)/cnt_tested, 
         notes='Less than 25 students tested', predicted=NA_real_,  residual=NA_real_)



# MATH REGRESSION ---------------------------------------------------------

#build model
math_model <- lm(pctprof ~pctpoverty, data=math)

#predicted scores
pred_math <- predict(math_model, math)



#add predicted value
math <-  math %>%  mutate(predicted=pred_math)



#add residual
math <-  math  %>% mutate(residual = pctprof-predicted)

summary(math_model)



# READING REGRESSION ------------------------------------------------------

#build model
read_model <- lm(pctprof ~ pctpoverty, data=read)

#predicted scores
pred_read <- predict(read_model, read)

#add predicted value
read <-  read %>%  mutate(predicted=pred_read)

#add residual
read <-  read  %>% mutate(residual = pctprof-predicted)

summary(read_model)




# COMBINE REGRESSION RESULTS ----------------------------------------------

#union math, read, math_excluded, read_excluded -- call new table testscores
testscores <- bind_rows(read, math, read_excluded, math_excluded)


#add in dummy records for schools that tested less than 10 kids in a grade per subject (or both subjects) and MDE suppressed the results
missingschools <-  missingschools %>% select(data_year=datayear, schoolid, districtnumber, districttype, school_number=schoolnumber,
                                             districtname, schoolname, schoolclassification, subject) %>% mutate(notes='Less than 10 students tested')



### add in POVERTY AND ENROLLMENT NUMBERS
missingschools <-  left_join(missingschools, private_poverty_thisyear %>% select(schoolid, pctpoverty), by=c("schoolid"="schoolid"))


testscores <- bind_rows(testscores, missingschools)



#join testscores with school_list
testscores <- left_join(testscores, school_list %>% 
                          select(schoolid, school_type, grades, metro7_strib, location_strib), by=c("schoolid"="schoolid"))





#add uniqueID, adjust datayear and grades fields
testscores <- testscores %>% mutate(uniqueID=paste(schoolid,'-',substr(data_year,1,2),' to ',substr(data_year,4,6),'-',subject), 
                                    datayear_new=paste(substr(data_year,1,2),' to ',substr(data_year,4,6)), 
                                    grades = str_trim(grades),
                                    grades_new= case_when(str_length(grades)==1 ~ grades, TRUE~str_replace(grades, '-', ' to ')))


#add category number and description fields - falling short, about as expected, better than expected

testscores <- testscores %>% mutate(categorynum= case_when(residual==NA_real_ ~0, 
                                                           residual<  -0.0951 ~1,
                                                           between(residual, -.0951, .09509)~2,
                                                           residual>  0.09509 ~3, 
                                                           TRUE ~99))

testscores <-  testscores %>% mutate(categoryname= case_when(categorynum==99~"Not enough students tested", categorynum==1~"Falling short", categorynum==2~"As expected", categorynum==3~"Better than expected", TRUE~"99"))







testscores <- testscores%>% mutate(school_type= case_when(schoolclassification=='10'~'Elementary (PK-6)',
                                                         schoolclassification=='20'~ 'Middle School (5-8)',
                                                         schoolclassification=='31'~'Junior High (7-8 or 7-9)',
                                                          schoolclassification=='33'~'Secondary (7-12)',
                                                          schoolclassification=='32'~'Senior High (9-12)',
                                                         schoolclassification=='40'~'Elem/Sec Combo (K-12)',
                                                         schoolclassification=='46'~'Distance learning'))





# CREATE DATAVIZ FILE -----------------------------------------------------


#only keep schools that were in operation in the current year

#bring in the fixed version of mca_schools_this_year
mca_schools_this_year <- read_csv('mca_schools_this_year_fixed.csv')

testscores_public <-  left_join(mca_schools_this_year, testscores, by=c("schoolid"="schoolid")) %>% 
  select(-districtname.y, -schoolname.y) %>% 
  rename(pct_pov_private = pctpoverty,
         districtname=districtname.x,
         schoolname=schoolname.x)  
  
  



#join with the public poverty file
#this also brings in the total enrollment 
testscores_public <-   left_join(testscores_public, public_poverty, by=c("schoolid"="schoolid"))





#uppercase district and school names
#fix missing school types
#adjust the public-facing pct poverty figure to deal with nulls and reduce decimals
testscores_public <- testscores_public %>% mutate(pct_pov_public = case_when(is.na(pct_poverty)~'Not public',
                                                            str_length(pct_poverty)==5~pct_poverty,
                                                            str_length(pct_poverty)==6 ~ paste(str_sub(pct_poverty,1,4),'%', sep=''),
                                                                                              TRUE~'unk')) %>% 
  select(uniqueID, schoolid, districtnumber, districttype, school_number, districtname, schoolname, schoolclassification, school_type,
         grades_new, metro7_strib, location_strib, datayear_new, subject, cnt_tested, cntlev1, cntlev2, cntlev3,
         cntlev4, numproficient, pctprof, total_enrollment, pct_pov_private, pct_pov_public, predicted, residual, notes, categorynum, 
         categoryname, povertycategory)



#export CSV for data visualization
write.csv(testscores_public, "./output/mca_dataviz_rerun_Nov2019.csv", row.names = FALSE)


#write.csv(testscores_public %>% filter(districtnumber=='0709'), "./output/duluth.csv", row.names=FALSE)


# need these numbers to draw the lines in scatterplots on web page
#coef(math_model)
#coef(read_model)



# FILES FOR REPORTER ------------------------------------------------------



#these generate files that show schools that did better than expected this year and how they've done in previous years
#these are used in the beatingodds.RMD file



beatingodds_math <- testscores %>% filter(data_year==thisyear, categoryname=='Better than expected', 
                                             subject=='M', povertycategory=='High', metro7_strib=='YES')

beatingodds_read <- testscores %>% filter(data_year==thisyear, categoryname=='Better than expected', 
                                             subject=='R', povertycategory=='High', metro7_strib=='YES')


#pull all math data for the beating the odds schools (regardless if they beat the odds that particular year)
math_over_time <-  inner_join(beatingodds_math %>% select(schoolid, subject), testscores, by=c("subject"="subject", "schoolid"="schoolid"))

#historical read data for beating the odds schools
read_over_time <-  inner_join(beatingodds_read %>% select(schoolid, subject), testscores, by=c("subject"="subject", "schoolid"="schoolid"))

#write.csv(beatingodds_math, './data/beatingodds_math.csv', row.names=FALSE)

#write.csv(beatingodds_read, './data/beatingodds_read.csv', row.names=FALSE)

#write.csv(math_over_time, './data/math_over_time.csv', row.names=FALSE)

#write.csv(read_over_time, './data/read_over_time.csv', row.names=FALSE)



# Opt outs ----------------------------------------------------------------




#write.csv(enrollment, './output/grade_enrollment_1819.csv', row.names=FALSE)


