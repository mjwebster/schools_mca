library(tidyverse)
library(janitor)
library(readxl)
library(lubridate) #date functions


math_state19 <-  read_xlsx('./data/2019PublicMCAMTASMath.xlsx', sheet='State',  col_type = c(rep("text", 16), "numeric", "text", "numeric", "text", "numeric", "numeric", "text", rep("numeric",5), rep("numeric", 26) )) %>% clean_names() %>% mutate(level = 'state', school_number='999')



math_district19 <-  read_csv('./data/2019PublicMCAMTASMathDistrict.csv', col_types=cols("c","c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c",  "i", "c", "i", "c", "i", "i", "c", "i", "i", "i", "i", "d", "d", "d", "d", "d",  "d","d","d","d","d","d","d","d","d","i","i","i","i","i","i","i","i","i","i","i","i","i")) %>% clean_names() %>%
  mutate(level = 'district',
         district_number=as.character(str_pad(district_number, 4, pad = "0")),
         district_type=as.character(str_pad(district_type, 2, pad = "0")),
         school_number='000') %>% filter(data_year!='NA')


math_school19 <-  read_csv('./data/2019PublicMCAMTASMathSchool.csv', col_types=cols("c","c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c",  "i", "c", "i", "c", "i", "i", "c", "i", "i", "i", "i", "d", "d", "d", "d", "d",  "d","d","d","d","d","d","d","d","d","i","i","i","i","i","i","i","i","i","i","i","i","i")) %>% clean_names() %>%
  mutate(level = 'school',
         district_number=as.character(str_pad(district_number, 4, pad = "0")),
         district_type=as.character(str_pad(district_type, 2, pad = "0")),
         school_number=as.character(str_pad(school_number, 3, pad="0"))) %>% 
  filter(data_year!='NA')


########

read_state19 <-  read_xlsx('./data/2019PublicMCAMTASReading.xlsx', sheet='State',  
                           col_type = c(rep("text", 16), "numeric", "text", "numeric", "text", "numeric", "numeric", "text", rep("numeric",4), rep("numeric",5), rep("numeric", 20))) %>%
  clean_names() %>%
  mutate(level = 'state', district_number=as.character(district_number), district_type=as.character(district_type),school_number='999')




read_district19 <-  read_csv('./data/2019PublicMCAMTASReadingDistrict.csv', col_types=cols("c","c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c",  "i", "c", "i", "c", "i", "i", "c", "i", "i", "i", "i", "d", "d", "d", "d", "d",  "d","d","d","d","d","d","d","d","d","i","i","i","i","i","i","i","i","i","i","i","i","i")) %>% clean_names() %>% mutate(level = 'district',
                                                                                                                                                                                                                                                                                                                                                                                   district_number=as.character(str_pad(district_number, 4, pad = "0")),
                                                                                                                                                                                                                                                                                                                                                                                   district_type=as.character(str_pad(district_type, 2, pad = "0")),
                                                                                                                                                                                                                                                                                                                                                                                   school_number='000') %>% 
  filter(data_year!='NA')


read_school19 <-  read_csv('./data/2019PublicMCAMTASReadingSchool.csv', col_types=cols("c","c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c",  "i", "c", "i", "c", "i", "i", "c", "i", "i", "i", "i", "d", "d", "d", "d", "d",  "d","d","d","d","d","d","d","d","d","i","i","i","i","i","i","i","i","i","i","i","i","i")) %>% clean_names() %>%
  mutate(level = 'school',
         district_number=as.character(str_pad(district_number, 4, pad = "0")),
         district_type=as.character(str_pad(district_type, 2, pad = "0")),
         school_number=as.character(str_pad(school_number, 3, pad="0"))) %>% 
  filter(data_year!='NA')



mca_2019 <-  bind_rows(math_state19, read_state19, math_district19, read_district19, math_school19, read_school19) %>% 
  mutate(idnumber = paste(district_number, district_type, school_number, sep='-'))

mca_2019 <-  mca_2019 %>% filter(data_year!='End of Worksheet')

rm(read_school19, math_school19, read_state19, math_state19, read_district19, math_district19)




write.csv(mca_2019, "./data/mca2019_output.csv", row.names=FALSE)

