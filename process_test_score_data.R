#install.packages("tidyverse", "ggplot2", "lubridate", "reshape2", "tidyr", "janitor", "scales", "knitr","aws.s3", "htmltools", "rmarkdown", "readxl", "DT", "kableExtra", "ggthemes", "RMySQL")


  
#BEFORE RUNNING THIS:
#Make sure SchoolList table is up-to-date
#poverty data -- public version
#poverty data - private version

options(scipen=999)


# load required packages
library(readr) #importing csv files
library(dplyr) #general analysis 
library(ggplot2) #making charts
library(lubridate) #date functions
library(reshape2) #use this for melt function to create one record for each team
library(tidyr)
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



#bring in state level data

#bring in district level data

#bring in data for regression analysis (already summarized)




# START HERE --------------------------------------------------------------

thisyear <- '17-18'
lastyear <-  '16-17'

#import public version of poverty data

public_poverty <- read_excel("./data/enrollment_public_file_2019_v2.xlsx", sheet="School", range="A2:AX13905") %>%
  clean_names() %>% filter(grade=='All Grades') 


public_poverty <-  public_poverty %>% mutate(schoolid=paste(district_number, district_type, school_number, sep="-")) %>% 
  select(schoolid ,total_enrollment, pct_poverty=total_students_eligible_for_free_or_reduced_priced_meals_percent)





#uSE THIS Original import the first time
#it creates csv files that can be used for repeating the analysis

# Original import ---------------------------------------------------------

#connect to the database;




con <- dbConnect(RMySQL::MySQL(), host = Sys.getenv("host"), dbname="Schools",user= Sys.getenv("userid"), password=Sys.getenv("pwd"))
#list the tables in the database we've connected to
#dbListTables(con)

#list the fields in the table; change "mytablename" to the name of the table you're trying to connect to
#dbListFields(con,'mytablename')


#Pull MCA data summarized by school
data1 <- dbSendQuery(con, "select * from mca_for_analysis")
mca <- fetch(data1, n=-1)
mca <-  mca %>% clean_names()

dbClearResult(data1)

mca$count_refused[is.na(mca$count_refused)] <- 0
mca$count_refused_parent[is.na(mca$count_refused_parent)] <- 0
mca$count_refused_student[is.na(mca$count_refused_student)] <- 0

mca <-  mca %>% mutate(optout = count_refused+count_refused_parent+count_refused_student,
                                   pct_optout_per10k = (optout/grade_enrollment)*10000)




#Pull race data
data2 <- dbSendQuery(con, "select distinct schoolid, datayear, pct_minority as pctminority
from enroll_cleaned where year>=2013")
race <- fetch(data2, n=-1)
race <-  race %>% clean_names()
dbClearResult(data2)

#Pull SchoolList
data3 <- dbSendQuery(con, "select distinct schoolid, district_type, schoolnumber, district_name, school_name, 
                     school_classification, school_type, grades, metro7_strib, location_strib from schoollist")
school_list <- fetch(data3, n=-1)
school_list <-  school_list %>% clean_names()

dbClearResult(data3)


#pull poverty data
data4 <-  dbSendQuery(con, "select * from schools_freelunch_qry")
poverty <- fetch(data4, n=-1)
poverty <-  poverty %>% clean_names()
dbClearResult(data4)


#pull statewide summaries
#leaves out the filtered categories
data5 <- dbSendQuery(con, "select dataYear, grade, subject, reportOrder, reportCategory, ReportDescription, filtered, countTested, countLevel1, 
countLevel2, countLevel3, countLevel4, CountRefused, CountRefusedParent, CountRefusedStudent, gradeEnrollment
from mca where summarylevel='state' and
                     filtered='n' and (subject='M' or subject='R') and datayear>='12-13'")
statewide <- fetch(data5, n=-1)
statewide <-  statewide %>% clean_names()
dbClearResult((data5))


statewide$count_refused[is.na(statewide$count_refused)] <- 0
statewide$count_refused_parent[is.na(statewide$count_refused_parent)] <- 0
statewide$count_refused_student[is.na(statewide$count_refused_student)] <- 0

statewide <-  statewide %>% mutate(optout = count_refused+count_refused_parent+count_refused_student,
                                   pct_optout_per10k = (optout/grade_enrollment)*10000)

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


optouts$count_refused[is.na(optouts$count_refused)] <- 0
optouts$count_refused_parent[is.na(optouts$count_refused_parent)] <- 0
optouts$count_refused_student[is.na(optouts$count_refused_student)] <- 0

optouts <-  optouts %>% mutate(optout = count_refused+count_refused_parent+count_refused_student,
                                   pct_optout_per10k = (optout/grade_enrollment)*10000)


optouts <-  left_join(optouts, school_list %>% select(schoolid, school_type, metro7_strib, location_strib), by=c("schoolid"="schoolid"))



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
rm(data3)
rm(data4)
rm(data5)
rm(data7)
rm(data6)
rm(data7)



# END HERE ----------------------------------------------------------------



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


#join poverty to mca
#eliminates any schools that don't have poverty data
mca_original <- left_join(mca, poverty, by=c("schoolid"="schoolid","data_year"="data_year")) %>% filter(pct_poverty!='NA')



#make reading and math subsets for regression
#exclude schools that tested fewer than 25 students
#calculate proficiency percentages


math <-  mca_original %>% filter(subject=='M', cnt_tested>=25) %>%
  mutate(numproficient=cntlev3+cntlev4, pctprof= (cntlev3+cntlev4)/cnt_tested, notes='Included')

read <- mca_original %>% filter(subject=='R', cnt_tested>=25) %>% mutate(numproficient=cntlev3+cntlev4, pctprof= (cntlev3+cntlev4)/cnt_tested, notes='Included')


#create two files of the schools excluded from the analysis
#these need to be added back to the final data file
math_excluded <-  mca_original %>% filter(subject=='M', cnt_tested<25)%>%
  mutate(numproficient=cntlev3+cntlev4, pctprof= (cntlev3+cntlev4)/cnt_tested, 
         notes='Less than 25 students tested', predicted=NA_real_,  residual=NA_real_)


read_excluded <- mca_original %>% filter(subject=='R', cnt_tested<25) %>%
  mutate(numproficient=cntlev3+cntlev4, pctprof= (cntlev3+cntlev4)/cnt_tested, 
         notes='Less than 25 students tested', predicted=NA_real_,  residual=NA_real_)




# MATH REGRESSION ---------------------------------------------------------

#build model
math_model <- lm(pctprof ~pct_poverty, data=math)

#predicted scores
pred_math <- predict(math_model, math)



#add predicted value
math <-  math %>%  mutate(predicted=pred_math)



#add residual
math <-  math  %>% mutate(residual = pctprof-predicted)

#summary(math_model)



# READING REGRESSION ------------------------------------------------------

#build model
read_model <- lm(pctprof ~ pct_poverty, data=read)

#predicted scores
pred_read <- predict(read_model, read)

#add predicted value
read <-  read %>%  mutate(predicted=pred_read)

#add residual
read <-  read  %>% mutate(residual = pctprof-predicted)

#summary(read_model)




# COMBINE REGRESSION RESULTS ----------------------------------------------

#union math, read, math_excluded, read_excluded -- call new table testscores
testscores <- bind_rows(read, math, read_excluded, math_excluded)



#join testscores with race
testscores <-  left_join(testscores, race %>% select(schoolid, datayear, pctminority), by=c("schoolid"="schoolid", "data_year"="datayear"))

#join testscores/race with school_list
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




# CREATE DATAVIZ FILE -----------------------------------------------------


#remove the enrollment and poverty variables that were used in the analysis (can't make the poverty number public)
testscores_public <- testscores %>% select(-k12enr, -pct_poverty)

#join with the public poverty file  
testscores_public <-   left_join(testscores_public, public_poverty, by=c("schoolid"="schoolid"))

#uppercase district and school names
#fix missing school types
#adjust the public-facing pct poverty figure to deal with nulls and reduce decimals
testscores_public <- testscores_public %>% mutate(districtname=toupper(districtname),
                                    schoolname=toupper(schoolname),
                                    school_type= case_when(schoolclassification=='10'~'Elementary (PK-6)',
                                                           schoolclassification=='20'~ 'Middle School (5-8)',
                                                           schoolclassification=='31'~'Junior High (7-8 or 7-9)',
                                                           schoolclassification=='33'~'Secondary (7-12)',
                                                           schoolclassification=='32'~'Senior High (9-12)',
                                                           schoolclassification=='40'~'Elem/Sec Combo (K-12)'),
                                    pct_poverty = case_when(is.na(pct_poverty)~'Not public',
                                                            str_length(pct_poverty)==5~pct_poverty,
                                                            str_length(pct_poverty)==6 ~ paste(str_sub(pct_poverty,1,4),'%', sep=''),
                                                                                              TRUE~'unk'))




dataviz_export <-  testscores_public %>%
  select(uniqueID, schoolid, districtnumber, districttype, school_number, districtname, schoolname, schoolclassification, school_type,
         grades_new, metro7_strib, location_strib, datayear_new, subject, cnt_tested, cntlev1, cntlev2, cntlev3,
         cntlev4, numproficient, pctprof, total_enrollment, pct_poverty, pctminority, predicted, residual, notes, categorynum, 
         categoryname, poverty_category)




#export CSV for data visualization
write.csv(dataviz_export, "./output/mca_dataviz.csv", row.names = FALSE)



# need these numbers to draw the lines in scatterplots on web page
#coef(math_model)
#coef(read_model)



# FILES FOR REPORTER ------------------------------------------------------


#these generate files that show schools that did better than expected this year and how they've done in previous years
#be sure to update the datayear filters
#these are used in the beatingodds.RMD file



beatingodds_math <- testscores %>% filter(data_year==thisyear, categoryname=='Better than expected', 
                                             subject=='M', poverty_category=='High', metro7_strib=='YES')

beatingodds_read <- testscores %>% filter(data_year==thisyear, categoryname=='Better than expected', 
                                             subject=='R', poverty_category=='High', metro7_strib=='YES')


#pull all math data for the beating the odds schools (regardless if they beat the odds that particular year)
math_over_time <-  inner_join(beatingodds_math %>% select(schoolid, subject), testscores, by=c("subject"="subject", "schoolid"="schoolid"))

#historical read data for beating the odds schools
read_over_time <-  inner_join(beatingodds_read %>% select(schoolid, subject), testscores, by=c("subject"="subject", "schoolid"="schoolid"))

#write.csv(beatingodds_math, './data/beatingodds_math.csv', row.names=FALSE)

#write.csv(beatingodds_read, './data/beatingodds_read.csv', row.names=FALSE)

#write.csv(math_over_time, './data/math_over_time.csv', row.names=FALSE)

#write.csv(read_over_time, './data/read_over_time.csv', row.names=FALSE)



# Opt outs ----------------------------------------------------------------


optouts_by_grade_m <- optouts %>% filter(data_year==thisyear, report_order=='1', subject=='M') %>% 
  group_by(grade, report_category) %>%
  summarise(tot_optout=sum(optout), tot_enroll=sum(grade_enrollment)) %>% 
  mutate(per10k = (tot_optout/tot_enroll)*10000) %>% 
  rename(variable=grade)

optouts_by_category_m <-  optouts %>% filter(data_year==thisyear, subject=='M') %>% 
  group_by(report_description, report_category) %>%
  summarise(tot_optout=sum(optout), tot_enroll=sum(grade_enrollment)) %>% 
  mutate(per10k = (tot_optout/tot_enroll)*10000) %>% 
  rename(variable = report_description)

math_optouts <-  bind_rows(optouts_by_category_m, optouts_by_grade_m)


optouts_by_grade_r <- optouts %>% filter(data_year==thisyear, report_order=='1', subject=='R') %>% 
  group_by(grade, report_category) %>%
  summarise(tot_optout=sum(optout), tot_enroll=sum(grade_enrollment)) %>% 
  mutate(per10k = (tot_optout/tot_enroll)*10000) %>% 
  rename(variable=grade)

optouts_by_category_r <-  optouts %>% filter(data_year==thisyear, subject=='R') %>% 
  group_by(report_description, report_category) %>%
  summarise(tot_optout=sum(optout), tot_enroll=sum(grade_enrollment)) %>% 
  mutate(per10k = (tot_optout/tot_enroll)*10000) %>% 
  rename(variable = report_description)

read_optouts <-  bind_rows(optouts_by_category_r, optouts_by_grade_r)



