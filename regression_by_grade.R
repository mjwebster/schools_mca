
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
#library(RMySQL)


bygrade <- read_csv("gradelevel_regression.csv")

math <-  bygrade %>% filter(subject=='M')

read <-  bygrade %>% filter(subject=='R')


# MATH REGRESSION ---------------------------------------------------------

#build model
math_model <- lm(PctProficient ~ PctPoverty, data=math)

#predicted scores
pred_math <- predict(math_model, math)



#add predicted value
math <-  math %>%  mutate(predicted=pred_math)



#add residual
math <-  math  %>% mutate(residual = PctProficient-predicted)

#summary(math_model)



# READING REGRESSION ------------------------------------------------------

#build model
read_model <- lm(PctProficient ~ PctPoverty, data=read)

#predicted scores
pred_read <- predict(read_model, read)

#add predicted value
read <-  read %>%  mutate(predicted=pred_read)

#add residual
read <-  read  %>% mutate(residual = PctProficient-predicted)

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


math %>% filter(grade=='3') %>% select(datayear, categoryname)

#write.csv(math, "math_bygrade.csv", row.names=FALSE)
#write.csv(read, "read_bygrade.csv", row.names=FALSE)

