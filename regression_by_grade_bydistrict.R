#install.packages("tidyverse", "ggplot2", "lubridate", "reshape2", "tidyr", "janitor", "scales", "knitr","aws.s3", "htmltools", "rmarkdown", "readxl", "DT", "kableExtra", "ggthemes", "RMySQL")



#BEFORE RUNNING THIS:
#Make sure SchoolList table is up-to-date





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




bydistrict_bygrade <- read_csv("bygrade_bydistrict_regression.csv")

names(bydistrict_bygrade)

# ANALYSIS SECTION --------------------------------------------------------



math <-  bydistrict_bygrade %>% filter(subject=='M', TotTested>=25, datayear>='12-13') %>%
  mutate(numproficient=cntlev3+cntlev4, PctProf= (cntlev3+cntlev4)/TotTested, PctPoverty=(Free+Reduced)/K12E)

read <- bydistrict_bygrade %>% filter(subject=='R', TotTested>=25, datayear>='12-13') %>%
  mutate(numproficient=cntlev3+cntlev4, PctProf= (cntlev3+cntlev4)/TotTested, PctPoverty=(Free+Reduced)/K12E)


math %>% filter(is.na(location)) %>% group_by(schoolid) %>% summarise(count=n()) %>% arrange(desc(count))



# MATH REGRESSION ---------------------------------------------------------

#build model
math_model <- lm(PctProf ~ PctPoverty, data=math)

#predicted scores
pred_math <- predict(math_model, math)



#add predicted value
math <-  math %>%  mutate(predicted=pred_math)



#add residual
math <-  math  %>% mutate(residual = PctProf-predicted)

#summary(math_model)



# READING REGRESSION ------------------------------------------------------

#build model
read_model <- lm(PctProf ~ PctPoverty, data=read)

#predicted scores
pred_read <- predict(read_model, read)

#add predicted value
read <-  read %>%  mutate(predicted=pred_read)

#add residual
read <-  read  %>% mutate(residual = PctProf-predicted)

#summary(read_model)




math <-  math %>% mutate(categorynum= case_when(residual==NA_real_ ~0, 
                                                residual<  -0.0951 ~1,
                                                between(residual, -.0951, .09509)~2,
                                                residual>  0.09509 ~3, 
                                                TRUE ~99))

math <-  math %>% mutate(categoryname= case_when(categorynum==1~"Falling short", categorynum==2~"As expected", categorynum==3~"Better than expected", TRUE~"99"))



read <-  read %>% mutate(categorynum= case_when(residual==NA_real_ ~0, 
                                                residual<  -0.0951 ~1,
                                                between(residual, -.0951, .09509)~2,
                                                residual>  0.09509 ~3, 
                                                TRUE ~99))

read <-  read %>% mutate(categoryname= case_when(categorynum==1~"Falling short", categorynum==2~"As expected", categorynum==3~"Better than expected", TRUE~"99"))




#write.csv(math, "math_bygrade_bydistrict.csv", row.names=FALSE)
#write.csv(read, "read_bygrade_bydistrict.csv", row.names=FALSE)
