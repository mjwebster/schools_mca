library(tidyverse)
library(janitor)
library(readxl)
library(lubridate) #date functions


#I had to export the big sets (county, district school) as csv files. Read_xlsx was having trouble loading because of so many numeric columns that were NULL. Read_CSV had no problems with them, though. My syntax for setting the column types is kinda nuts cause I couldn't figure out a simpler solution on deadline. 


math_state21 <-  read_xlsx('./data/2021PublicMCAMTASMath.xlsx', sheet='State', skip=1, col_type = c(rep("text", 16), "numeric", "text", "numeric", "text", "numeric", "text", rep("numeric",4), rep("text",5), rep("numeric",25))) %>% clean_names() %>% mutate(level = 'state', district_number=as.character(district_number), district_type=as.character(district_type), school_number='999')



math_district21 <-  read_csv('./data/math_district_2021.csv', col_types=cols("c","c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c",  "i", "c", "i", "c", "i", "c", "i", "i", "i", "i", "c", "c", "c", "c", "c",  "i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i")) %>% clean_names() %>%
  mutate(level = 'district',
         district_number=as.character(str_pad(district_number, 4, pad = "0")),
         district_type=as.character(str_pad(district_type, 2, pad = "0")),
         school_number='000') %>% filter(data_year!='NA')


math_school21 <-  read_csv('./data/math_school_2021.csv', col_types=cols("c","c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c",  "i", "c", "i", "c", "i", "c", "i", "i", "i", "i", "c", "c", "c", "c", "c",  "i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i")) %>% clean_names() %>%
  mutate(level = 'school',
         district_number=as.character(str_pad(district_number, 4, pad = "0")),
         district_type=as.character(str_pad(district_type, 2, pad = "0")),
         school_number=as.character(str_pad(school_number, 3, pad="0"))) %>% 
  filter(data_year!='NA')


########

read_state21 <-  read_xlsx('./data/2021PublicMCAMTASReading.xlsx', sheet='State', skip=1, 
                           col_type = c(rep("text", 16), "numeric", "text", "numeric", "text", "numeric", "text", rep("numeric",4), rep("text",5), rep("numeric",23))) %>%
  clean_names() %>%
  mutate(level = 'state', district_number=as.character(district_number), district_type=as.character(district_type),school_number='999')




read_district21 <-  read_csv('./data/reading_district_2021.csv', col_types=cols("c","c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c",  "i", "c", "i", "c", "i", "c", "i", "i", "i", "i", "c", "c", "c", "c", "c",  "i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i")) %>% clean_names() %>% mutate(level = 'district',
                                                                                                                                                                                                                                                                                                                                                                       district_number=as.character(str_pad(district_number, 4, pad = "0")),
                                                                                                                                                                                                                                                                                                                                                                       district_type=as.character(str_pad(district_type, 2, pad = "0")),
                                                                                                                                                                                                                                                                                                                                                                       school_number='000') %>% 
  filter(data_year!='NA')


read_school21 <-  read_csv('./data/reading_school_2021.csv', col_types=cols("c","c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c",  "i", "c", "i", "c", "i", "c", "i", "i", "i", "i", "c", "c", "c", "c", "c",  "i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i")) %>% clean_names() %>%
  mutate(level = 'school',
         district_number=as.character(str_pad(district_number, 4, pad = "0")),
         district_type=as.character(str_pad(district_type, 2, pad = "0")),
         school_number=as.character(str_pad(school_number, 3, pad="0"))) %>% 
  filter(data_year!='NA')



mca_2021 <-  bind_rows(math_state21, read_state21, math_district21, read_district21, math_school21, read_school21) %>% 
  mutate(idnumber = paste(district_number, district_type, school_number, sep='-'))

mca_2021 <-  mca_2021 %>% filter(data_year!='End of Worksheet')

rm(read_school21, math_school21, read_state21, math_state21, read_district21, math_district21)

write.csv(mca_2021, "./data/mca2021_output.csv", row.names=FALSE)