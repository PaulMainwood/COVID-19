rm(list=ls())

library(tidyverse)
library(curl)
library(readxl)
library(extrafont)
library(ggtext)
library(ragg)
library(lubridate)
library(gganimate)

#Download data from PHE surveillance report
#https://www.gov.uk/government/statistics/national-flu-and-covid-19-surveillance-reports

url <- "https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/982284/Weekly_Influenza_and_COVID19_report_data_w17.xlsx"

temp <- tempfile()
temp <- curl_download(url=url, destfile=temp, quiet=FALSE, mode="wb")

data <- read_excel(temp, sheet="Figure 58&59 COVID Vac Age Sex", range="B13:N23", col_names=FALSE) %>% 
  select(`...1`, `...2`, `...3`, `...5`, `...6`, `...9`, `...12`)

colnames(data) <- c("Age", "Male_Pop", "Male_Vax1", "Female_Pop", "Female_Vax1", "Male_Vax2",
                     "Female_Vax2")

data <- data %>% 
  rowwise() %>% 
  mutate(Male_Unvax=Male_Pop-Male_Vax1,
         Female_Unvax=Female_Pop-Female_Vax1,
         Male_Vax1Only=Male_Vax1-Male_Vax2,
         Female_Vax1Only=Female_Vax1-Female_Vax2) %>% 
  ungroup() %>% 
  select(Age, Male_Unvax, Female_Unvax, Male_Vax1Only, Female_Vax1Only, Male_Vax2, Female_Vax2)

data_long <- pivot_longer(data, cols=c(2:7), names_to=c("Sex", "Measure"), names_sep="_", 
                          values_to="Value") %>% 
  mutate(Value=if_else(Sex=="Male", -Value, Value),
         Age=case_when(
           Age=="Under 20 years" ~ "<20",
           Age=="20 to 29 years" ~ "20-29",
           Age=="30 to 39 years" ~ "30-39",
           Age=="40 to 49 years" ~ "40-49",
           Age=="50 to 54 years" ~ "50-54",
           Age=="55 to 59 years" ~ "55-59",
           Age=="60 to 64 years" ~ "60-64",
           Age=="65 to 69 years" ~ "65-69",
           Age=="70 to 74 years" ~ "70-74",
           Age=="75 to 79 years" ~ "75-79",
           TRUE ~ "80+"),
         Age=factor(Age, levels=c("<20", "20-29", "30-39", "40-49", "50-54", "55-59", "60-64",
                                  "65-69", "70-74", "75-79", "80+")),
         SexMeasure=paste0(Sex, Measure))

agg_tiff("Outputs/COVIDVaxxAgexSex.tiff", units="in", width=8, height=7, res=800)
ggplot(data_long, aes(x=Value, y=Age, fill=SexMeasure))+
  geom_col(position="stack", show.legend=FALSE)+
  scale_x_continuous(breaks=c(-7500000, -5000000, -2500000, 0, 2500000, 5000000, 7500000),
                     labels=c("7.5m", "5m", "2.5m", "0", "2.5m", "5m", "7.5m"),
                     limits=c(-7500000, 7500000), name="")+
  scale_y_discrete(name="Age group")+
  scale_fill_manual(values=c("Grey80", "#7dffdd", "#00cc99", "Grey80", "#be7dff", "#6600cc"))+
  theme_classic()+
  theme(axis.line.y=element_blank(), text=element_text(family="Roboto"), 
        plot.title=element_text(face="bold", size=rel(1.4)), plot.subtitle=element_markdown())+
  labs(title="Vaccine delivery in England by age and sex",
       subtitle="The number of people who are <span style='color:Grey60;'>unvaccinated</span>, men with <span style='color:#be7dff;'>one</span> or <span style='color:#6600cc;'>two</span> doses and women with <span style='color:#7dffdd;'>one</span> or <span style='color:#00cc99;'>two</span> doses",
       caption="Data from PHE, population figures from NIMS\nPlot by @VictimOfMaths")+
  annotate("text", x=-4000000, y=9, label="Men", colour="#6600cc", size=rel(6), fontface="bold")+
  annotate("text", x=4000000, y=9, label="Women", colour="#00cc99", size=rel(6), fontface="bold")
dev.off()  

#Produce version with compressed age bands
#V1 10 year bands for >20
agg_tiff("Outputs/COVIDVaxxAgexSexv2.tiff", units="in", width=8, height=6, res=800)
data_long %>% 
  mutate(Age=case_when(
    Age %in% c("50-54", "55-59") ~ "50-59",
    Age %in% c("60-64", "65-69") ~ "60-69",
    Age %in% c("70-74", "75-79") ~ "70-79",
    TRUE ~ as.character(Age))) %>% 
  group_by(Age, SexMeasure) %>% 
  summarise(Value=sum(Value)) %>% 
  ungroup() %>% 
  ggplot(aes(x=Value, y=Age, fill=SexMeasure))+
  geom_col(position="stack", show.legend=FALSE)+
  scale_x_continuous(breaks=c(-7500000, -5000000, -2500000, 0, 2500000, 5000000, 7500000),
                     labels=c("7.5m", "5m", "2.5m", "0", "2.5m", "5m", "7.5m"),
                     limits=c(-7500000, 7500000), name="")+
  scale_y_discrete(name="Age group")+
  scale_fill_manual(values=c("Grey80", "#7dffdd", "#00cc99", "Grey80", "#be7dff", "#6600cc"))+
  theme_classic()+
  theme(axis.line.y=element_blank(), text=element_text(family="Roboto"), 
        plot.title=element_text(face="bold", size=rel(1.4)), plot.subtitle=element_markdown())+
  labs(title="Vaccine delivery in England by age and sex",
       subtitle="The number of people who are <span style='color:Grey60;'>unvaccinated</span>, men with <span style='color:#be7dff;'>one</span> or <span style='color:#6600cc;'>two</span> doses and women with <span style='color:#7dffdd;'>one</span> or <span style='color:#00cc99;'>two</span> doses",
       caption="Data from PHE, population figures from NIMS\nPlot by @VictimOfMaths")+
  annotate("text", x=-5000000, y=7.5, label="Men", colour="#6600cc", size=rel(6), fontface="bold")+
  annotate("text", x=5000000, y=7.5, label="Women", colour="#00cc99", size=rel(6), fontface="bold")
dev.off()  

#V2 20 year bands
agg_tiff("Outputs/COVIDVaxxAgexSexv3.tiff", units="in", width=8, height=5, res=800)
data_long %>% 
  mutate(Age=case_when(
    Age %in% c("20-29", "30-39") ~ "20-39",
    Age %in% c("40-49", "50-54", "55-59") ~ "40-59",
    Age %in% c("60-64", "65-69", "70-74", "75-79") ~ "60-79",
    TRUE ~ as.character(Age))) %>% 
  group_by(Age, SexMeasure) %>% 
  summarise(Value=sum(Value)) %>% 
  ungroup() %>% 
  ggplot(aes(x=Value, y=Age, fill=SexMeasure))+
  geom_col(position="stack", show.legend=FALSE)+
  scale_x_continuous(breaks=c(-7500000, -5000000, -2500000, 0, 2500000, 5000000, 7500000),
                     labels=c("7.5m", "5m", "2.5m", "0", "2.5m", "5m", "7.5m"),
                     limits=c(NA,NA), name="")+
  scale_y_discrete(name="Age group")+
  scale_fill_manual(values=c("Grey80", "#7dffdd", "#00cc99", "Grey80", "#be7dff", "#6600cc"))+
  theme_classic()+
  theme(axis.line.y=element_blank(), text=element_text(family="Roboto"), 
        plot.title=element_text(face="bold", size=rel(1.4)), plot.subtitle=element_markdown())+
  labs(title="Vaccine delivery in England by age and sex",
       subtitle="The number of people who are <span style='color:Grey60;'>unvaccinated</span>, men with <span style='color:#be7dff;'>one</span> or <span style='color:#6600cc;'>two</span> doses and women with <span style='color:#7dffdd;'>one</span> or <span style='color:#00cc99;'>two</span> doses",
       caption="Data from PHE, population figures from NIMS\nPlot by @VictimOfMaths")+
  annotate("text", x=-5000000, y=5, label="Men", colour="#6600cc", size=rel(6), fontface="bold")+
  annotate("text", x=5000000, y=5, label="Women", colour="#00cc99", size=rel(6), fontface="bold")
dev.off()  

#Animated versions
#Read in historic data
#Week 15
url <- "https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/979626/Weekly_Influenza_and_COVID19_report_data_w16.xlsx"

temp <- tempfile()
temp <- curl_download(url=url, destfile=temp, quiet=FALSE, mode="wb")

dataw15 <- read_excel(temp, sheet="Figure 58&59 COVID Vac Age Sex", range="B13:N23", col_names=FALSE) %>% 
  select(`...1`, `...2`, `...3`, `...5`, `...6`, `...9`, `...12`)

colnames(dataw15) <- c("Age", "Male_Pop", "Male_Vax1", "Female_Pop", "Female_Vax1", "Male_Vax2",
                    "Female_Vax2")


#Week 14
dataw14 <- read_excel(temp, sheet="Figure 58&59 COVID Vac Age Sex", range="B31:N41", col_names=FALSE) %>% 
  select(`...1`, `...2`, `...3`, `...5`, `...6`, `...9`, `...12`)

colnames(dataw14) <- c("Age", "Male_Pop", "Male_Vax1", "Female_Pop", "Female_Vax1", "Male_Vax2",
                       "Female_Vax2")

mergeddata <- dataw15 %>% mutate(Week=15) %>% 
  bind_rows( dataw14 %>% mutate(Week=14)) %>% 
  rowwise() %>% 
  mutate(Male_Unvax=Male_Pop-Male_Vax1,
         Female_Unvax=Female_Pop-Female_Vax1,
         Male_Vax1Only=Male_Vax1-Male_Vax2,
         Female_Vax1Only=Female_Vax1-Female_Vax2) %>% 
  ungroup() %>% 
  select(Age, Week, Male_Unvax, Female_Unvax, Male_Vax1Only, Female_Vax1Only, Male_Vax2, Female_Vax2) %>% 
  bind_rows(data %>% mutate(Week=16))

mergeddata_long <- pivot_longer(mergeddata, cols=c(3:8), names_to=c("Sex", "Measure"), names_sep="_", 
                          values_to="Value") %>% 
  mutate(Value=if_else(Sex=="Male", -Value, Value),
         Age=case_when(
           Age=="Under 20 years" ~ "<20",
           Age=="20 to 29 years" ~ "20-29",
           Age=="30 to 39 years" ~ "30-39",
           Age=="40 to 49 years" ~ "40-49",
           Age=="50 to 54 years" ~ "50-54",
           Age=="55 to 59 years" ~ "55-59",
           Age=="60 to 64 years" ~ "60-64",
           Age=="65 to 69 years" ~ "65-69",
           Age=="70 to 74 years" ~ "70-74",
           Age=="75 to 79 years" ~ "75-79",
           TRUE ~ "80+"),
         Age=factor(Age, levels=c("<20", "20-29", "30-39", "40-49", "50-54", "55-59", "60-64",
                                  "65-69", "70-74", "75-79", "80+")),
         SexMeasure=paste0(Sex, Measure),
         date=as.Date("2021-04-11")+weeks(Week-14))

anim <- ggplot(mergeddata_long, aes(x=Value, y=Age, fill=SexMeasure))+
  geom_col(position="stack", show.legend=FALSE)+
  scale_x_continuous(breaks=c(-7500000, -5000000, -2500000, 0, 2500000, 5000000, 7500000),
                     labels=c("7.5m", "5m", "2.5m", "0", "2.5m", "5m", "7.5m"),
                     limits=c(-7500000, 7500000), name="")+
  scale_y_discrete(name="Age group")+
  scale_fill_manual(values=c("Grey80", "#7dffdd", "#00cc99", "Grey80", "#be7dff", "#6600cc"))+
  theme_classic()+
  theme(axis.line.y=element_blank(), text=element_text(family="Roboto"), 
        plot.title=element_text(face="bold", size=rel(1.4)), plot.subtitle=element_markdown())+
  labs(caption="Data from PHE, population figures from NIMS\nPlot by @VictimOfMaths")+
  annotate("text", x=-4000000, y=9, label="Men", colour="#6600cc", size=rel(6), fontface="bold")+
  annotate("text", x=4000000, y=9, label="Women", colour="#00cc99", size=rel(6), fontface="bold")+
  transition_states(date, transition_length=2, state_length=1, wrap=FALSE)+
  ggtitle("Vaccine delivery in England by age and sex up to {closest_state}",
          subtitle="The number of people who are <span style='color:Grey60;'>unvaccinated</span>, men with <span style='color:#be7dff;'>one</span> or <span style='color:#6600cc;'>two</span> doses<br>and women with <span style='color:#7dffdd;'>one</span> or <span style='color:#00cc99;'>two</span> doses")

animate(anim, units="in", width=8, height=5, res=500, 
        renderer=gifski_renderer("Outputs/COVIDVaxPyramidAnim.gif"), 
        device="ragg_png", end_pause=10, duration=5, fps=10)