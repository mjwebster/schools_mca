library(tidyverse)
library(janitor)
library(readxl)
library(lubridate) #date functions


#BEFORE RUNNING THIS SCRIPT

#put the original Excel files from MDE in the "data" subfolder
#Go into each of those Excel files and export the district and school level sheets out of the original Excel files and save as .csv
# (names should be "math_district", "math_school", "reading_district", "reading_school")
# the state sheets can be pulled directly from the Excel files
#do this for both reading and math
#put those csv files in the "data" subfolder
#change the file name references in the two lines below here


math_file_name <-  './data/PublicMCAMTASMath2024.xlsx'
reading_file_name <-  './data/PublicMCAMTASReading2024.xlsx'


math_state <-  read_xlsx(math_file_name, sheet='State',  
                         col_type = c(rep("text", 16), "numeric", "text", "numeric", "text", "numeric", "text", rep("numeric",4), rep("text",5), rep("numeric",25))) %>%
  clean_names() %>%
  mutate(level = 'state', district_number=as.character(district_number), district_type=as.character(district_type), school_number='999',
         grade= case_when(grade=='0' ~ '00',
                          TRUE ~ grade))


math_district <-  read_csv('./data/math_district.csv', col_types=cols("c","c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c",  "i", "c", "i", "c", "i", "c", "i", "i", "i", "i", "c", "c", "c", "c", "c",  "i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i")) %>% clean_names() %>%
  mutate(level = 'district',
         district_number=as.character(str_pad(district_number, 4, pad = "0")),
         district_type=as.character(str_pad(district_type, 2, pad = "0")),
         school_number='000') %>% filter(data_year!='NA')


math_school <-  read_csv('./data/math_school.csv', col_types=cols("c","c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c",  "i", "c", "i", "c", "i", "c", "i", "i", "i", "i", "c", "c", "c", "c", "c",  "i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i")) %>% clean_names() %>%
  mutate(level = 'school',
         district_number=as.character(str_pad(district_number, 4, pad = "0")),
         district_type=as.character(str_pad(district_type, 2, pad = "0")),
         school_number=as.character(str_pad(school_number, 3, pad="0"))) %>% 
  filter(data_year!='NA')


########

read_state <-  read_xlsx(reading_file_name, sheet='State',  
                           col_type = c(rep("text", 16), "numeric", "text", "numeric", "text", "numeric", "text", rep("numeric",4), rep("text",5), rep("numeric",23))) %>%
  clean_names() %>%
  mutate(level = 'state', district_number=as.character(district_number), district_type=as.character(district_type),school_number='999',
         grade= case_when(grade=='0' ~ '00',
                          TRUE ~ grade))




read_district <-  read_csv('./data/reading_district.csv', col_types=cols("c","c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c",  "i", "c", "i", "c", "i", "c", "i", "i", "i", "i", "c", "c", "c", "c", "c",  "i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i")) %>% clean_names() %>% mutate(level = 'district',
                                                                                                                                                                                                                                                                                                                                                                       district_number=as.character(str_pad(district_number, 4, pad = "0")),
                                                                                                                                                                                                                                                                                                                                                                       district_type=as.character(str_pad(district_type, 2, pad = "0")),
                                                                                                                                                                                                                                                                                                                                                                       school_number='000') %>% 
  filter(data_year!='NA')


read_school <-  read_csv('./data/reading_school.csv', col_types=cols("c","c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c",  "i", "c", "i", "c", "i", "c", "i", "i", "i", "i", "c", "c", "c", "c", "c",  "i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i")) %>% clean_names() %>%
  mutate(level = 'school',
         district_number=as.character(str_pad(district_number, 4, pad = "0")),
         district_type=as.character(str_pad(district_type, 2, pad = "0")),
         school_number=as.character(str_pad(school_number, 3, pad="0"))) %>% 
  filter(data_year!='NA')






mca <-  bind_rows(math_state, math_district,  math_school,read_state, read_district, read_school) %>% 
  mutate(idnumber = paste(district_number, district_type, school_number, sep='-'))

mca <-  mca %>% filter(data_year!='End of Worksheet')

rm(read_school, math_school, read_state, math_state, read_district, math_district)

write.csv(mca, "./data/mca_output.csv", row.names=FALSE)