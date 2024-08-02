library(tidyverse)
library(janitor)
library(readxl)
library(lubridate) #date functions




math_state23 <-  read_xlsx('./data/PublicMCAMTASMath2023 Embargoed.xlsx', sheet='State',  col_type = c(rep("text", 16), "numeric", "text", "numeric", "text", "numeric", "text", rep("numeric",4), rep("text",5), rep("numeric",25))) %>% clean_names() %>% mutate(level = 'state', district_number=as.character(district_number), district_type=as.character(district_type), school_number='999')



math_district23 <-  read_csv('./data/math_district_2023.csv', col_types=cols("c","c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c",  "i", "c", "i", "c", "i", "c", "i", "i", "i", "i", "c", "c", "c", "c", "c",  "i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i")) %>% clean_names() %>%
  mutate(level = 'district',
         district_number=as.character(str_pad(district_number, 4, pad = "0")),
         district_type=as.character(str_pad(district_type, 2, pad = "0")),
         school_number='000') %>% filter(data_year!='NA')


math_school23 <-  read_csv('./data/math_school_2023.csv', col_types=cols("c","c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c",  "i", "c", "i", "c", "i", "c", "i", "i", "i", "i", "c", "c", "c", "c", "c",  "i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i")) %>% clean_names() %>%
  mutate(level = 'school',
         district_number=as.character(str_pad(district_number, 4, pad = "0")),
         district_type=as.character(str_pad(district_type, 2, pad = "0")),
         school_number=as.character(str_pad(school_number, 3, pad="0"))) %>% 
  filter(data_year!='NA')


########

read_state23 <-  read_xlsx('./data/PublicMCAMTASReading2023 Embargoed.xlsx', sheet='State',  
                           col_type = c(rep("text", 16), "numeric", "text", "numeric", "text", "numeric", "text", rep("numeric",4), rep("text",5), rep("numeric",23))) %>%
  clean_names() %>%
  mutate(level = 'state', district_number=as.character(district_number), district_type=as.character(district_type),school_number='999')




read_district23 <-  read_csv('./data/reading_district_2023.csv', col_types=cols("c","c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c",  "i", "c", "i", "c", "i", "c", "i", "i", "i", "i", "c", "c", "c", "c", "c",  "i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i")) %>% clean_names() %>% mutate(level = 'district',
                                                                                                                                                                                                                                                                                                                                                                       district_number=as.character(str_pad(district_number, 4, pad = "0")),
                                                                                                                                                                                                                                                                                                                                                                       district_type=as.character(str_pad(district_type, 2, pad = "0")),
                                                                                                                                                                                                                                                                                                                                                                       school_number='000') %>% 
  filter(data_year!='NA')


read_school23 <-  read_csv('./data/reading_school_2023.csv', col_types=cols("c","c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c", "c",  "i", "c", "i", "c", "i", "c", "i", "i", "i", "i", "c", "c", "c", "c", "c",  "i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i","i")) %>% clean_names() %>%
  mutate(level = 'school',
         district_number=as.character(str_pad(district_number, 4, pad = "0")),
         district_type=as.character(str_pad(district_type, 2, pad = "0")),
         school_number=as.character(str_pad(school_number, 3, pad="0"))) %>% 
  filter(data_year!='NA')






mca_2023 <-  bind_rows(math_state23, math_district23,  math_school23,read_state23, read_district23, read_school23) %>% 
  mutate(idnumber = paste(district_number, district_type, school_number, sep='-'))

mca_2023 <-  mca_2023 %>% filter(data_year!='End of Worksheet')

rm(read_school23, math_school23, read_state23, math_state23, read_district23, math_district23)

write.csv(mca_2023, "./data/mca2023_output.csv", row.names=FALSE)