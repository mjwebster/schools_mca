library(tidyverse)
library(janitor)
library(readxl)
library(lubridate) #date functions


#this dataset has 1 additional column not in the earlier datasets

math_state22 <-  read_csv('./data/2022PublicMCAMTASMathState.csv', col_types=cols("c","c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c",  "i", "c", "i", "c", "i", "c", "i", "i", "i", "i", "d", "d", "d", "d", "d",  "d","d","d","d","d","d","d","d","d","d","d","d","i","i","i","i","i","i","i","i","i","i","i","i","i", "i")) %>% clean_names() %>%
  mutate(level = 'state',
         district_number=as.character(str_pad(district_number, 4, pad = "0")),
         district_type=as.character(str_pad(district_type, 2, pad = "0")),
         school_number='000') %>% filter(data_year!='NA')




math_district22 <-  read_csv('./data/2022PublicMCAMTASMathDistrict.csv', col_types=cols("c","c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c",  "i", "c", "i", "c", "i", "c", "i", "i", "i", "i", "d", "d", "d", "d", "d", "d","d","d","d","d","d","d","d","d","d","d","d","i","i","i","i","i","i","i","i","i","i","i","i","i", "i")) %>% clean_names() %>%
  mutate(level = 'district',
         district_number=as.character(str_pad(district_number, 4, pad = "0")),
         district_type=as.character(str_pad(district_type, 2, pad = "0")),
         school_number='000') %>% filter(data_year!='NA')



math_school22 <-  read_csv('./data/2022PublicMCAMTASMathSchool.csv', col_types=cols("c","c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c",  "i", "c", "i", "c", "i", "c", "i", "i", "i", "i",  "d", "d", "d", "d", "d", "d","d","d","d","d","d","d","d","d","d","d","d","i","i","i","i","i","i","i","i","i","i","i","i","i", "i")) %>% clean_names() %>%
  mutate(level = 'school',
         district_number=as.character(str_pad(district_number, 4, pad = "0")),
         district_type=as.character(str_pad(district_type, 2, pad = "0")),
         school_number=as.character(str_pad(school_number, 3, pad="0"))) %>% 
  filter(data_year!='NA')





read_state22 <-  read_csv('./data/2022PublicMCAMTASReadingState.csv', col_types=cols("c","c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c",  "i", "c", "i", "c", "i", "c", "i", "i", "i", "i", "d", "d", "d", "d", "d", "d","d","d","d","d","d","d","d","d","d","d","d","i","i","i","i","i","i","i","i","i","i","i","i","i", "i")) %>% clean_names() %>%
  mutate(level = 'state',
         district_number=as.character(str_pad(district_number, 4, pad = "0")),
         district_type=as.character(str_pad(district_type, 2, pad = "0")),
         school_number='000') %>% filter(data_year!='NA')




read_district22 <-  read_csv('./data/2022PublicMCAMTASReadingDistrict.csv', col_types=cols("c","c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c",  "i", "c", "i", "c", "i", "c", "i", "i", "i", "i",  "d", "d", "d", "d", "d", "d","d","d","d","d","d","d","d","d","d","d","d","i","i","i","i","i","i","i","i","i","i","i","i","i", "i")) %>% clean_names() %>%
  mutate(level = 'district',
         district_number=as.character(str_pad(district_number, 4, pad = "0")),
         district_type=as.character(str_pad(district_type, 2, pad = "0")),
         school_number='000') %>% filter(data_year!='NA')



read_school22 <-  read_csv('./data/2022PublicMCAMTASReadingSchool.csv', col_types=cols("c","c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c",  "i", "c", "i", "c", "i", "c", "i", "i", "i", "i",  "d", "d", "d", "d", "d", "d","d","d","d","d","d","d","d","d","d","d","d","i","i","i","i","i","i","i","i","i","i","i","i","i", "i")) %>% clean_names() %>%
  mutate(level = 'school',
         district_number=as.character(str_pad(district_number, 4, pad = "0")),
         district_type=as.character(str_pad(district_type, 2, pad = "0")),
         school_number=as.character(str_pad(school_number, 3, pad="0"))) %>% 
  filter(data_year!='NA')






mca_2022 <-  bind_rows(math_state22, math_district22,  math_school22,read_state22, read_district22, read_school22) %>% 
  mutate(idnumber = paste(district_number, district_type, school_number, sep='-'))

mca_2022 <-  mca_2022 %>% filter(data_year!='End of Worksheet')

rm(read_school22, math_school22, read_state22, math_state22, read_district22, math_district22)

write.csv(mca_2022, "./data/mca2022_output.csv", row.names=FALSE)