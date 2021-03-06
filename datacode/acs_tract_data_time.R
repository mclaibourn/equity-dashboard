####################################################
# Greater Charlottesville Region Equity Profile
####################################################
# Acquire ACS data
# Last updated: 01/17/2020
# Metrics from ACS/Census: Over time: 
# * Race/Ethnicity and Total population over time: Decennial 1990, 2000, 2010; ACS 2011-2017
#
# Geography: Tracts in Localities in Charlottesville region
#     Charlottesville, Albemarle, Greene, Louisa, 
#     Fluvanna, Nelson, Buckingham, Madison, Orange
#     (include Augusta, Waynesboro, Staunton?)
####################################################
# 1. Load libraries, provide api key (if needed), identify variables
# 2. Define localities
# 3. 2010 data
# 4. 2011-2016 data
# 5. 2017 data
# 6. Combine
# 7. Save
####################################################


# ....................................................
# 1. Load libraries, provide api key (if needed), identify variables ----

# Load libraries
library(tidyverse)
library(tidycensus)


# Census api key
# census_api_key("", install = TRUE, overwrite = TRUE) # add key

# Variable view helper
# acs_var <- load_variables(2017, "acs5", cache = TRUE)
# acs_var <- load_variables(2017, "acs5/subject", cache = TRUE)
# acs_var <- load_variables(2017, "acs5/profile", cache = TRUE)
# dec_var <- load_variables(2010, "sf1", cache = TRUE)

# Variable of interest -
##  - Total population -- B01003_001
##  - Percent white alone -- DP05_0077P
##  - Percent black or African American alone -- DP05_0078P
##  - Percent American Indian and Alaska Native alone -- DP05_0079P
##  - Percent Asian alone -- DP05_0080P
##  - Percent Native Hawaiian and Other Pacific Islander alone -- DP05_0081P
##  - Percent Some other race alone -- DP05_0082P
##  - Percent Two or more races -- DP05_0083P
##  - Percent Hispanic or Latino -- DP05_0071P


# ....................................................
# 2. Define localities, variables, pull tables ----
ccode <- read_csv("code/county_codes.csv")
region <- ccode$code # list of desired counties


# ....................................................
# 3. 2010: pop and race

varlist_10 <- c("P003001", "P005003", "P005004", "P005005", "P005006", "P005007", "P005008", "P005009", "P005010") 
# totalpop, white, black, indig, asian, oth1, oth2, multi, ltnx

tract_10 <- get_decennial(geography = "tract",
                           variables = varlist_10,
                           state = "VA", 
                           county = region,
                           year = 2010, 
                           output = "wide")

names(tract_10) <- c("GEOID", "NAME", "totalpopE", "white", "black", "indig", "asian", "oth1", "oth2", "multi", "ltnx")

tract_10 <- tract_10 %>% 
  mutate(whiteE = round((white/totalpopE)*100, 1),
         blackE = round((black/totalpopE)*100, 1),
         indigE = round((indig/totalpopE)*100, 1),
         asianE = round((asian/totalpopE)*100, 1),
         othraceE = round(((oth1 + oth2)/totalpopE)*100, 1),
         multiE = round((multi/totalpopE)*100, 1),
         ltnxE = round((ltnx/totalpopE)*100, 1),
         year = "2010") %>% 
  select(GEOID, NAME, year, totalpopE, whiteE, blackE, indigE, asianE, othraceE, multiE, ltnxE)


# ....................................................
# 4. 2011-2016 acs pop and race

year_list = c(2011, 2012, 2013, 2014, 2015, 2016)
varlist = c("DP05_0001", "DP05_0072P", "DP05_0073P", "DP05_0074P", "DP05_0075P", "DP05_0076P", "DP05_0077P", "DP05_0078P", "DP05_0066P")
# totalpop, white, black, indig, asian, oth1, oth2, multi, ltnx

tract_1116 <- map_df(year_list, function(x) {
  get_acs(geography = "tract",
          variables = varlist,
          state = "VA",
          county = region,
          survey = "acs5",
          year = x, 
          output = "wide")
})

# rename, add year, derive othrace
names(tract_1116) <- c("GEOID", "NAME", "totalpopE", "totalpopM",
                        "whiteE", "whiteM", "blackE", "blackM", 
                        "indigE", "indigM", "asianE", "asianM",
                        "oth1E", "oth1M", "oth2E", "oth2M",
                        "multiE", "multiM", "ltnxE", "ltnxM")

tract_1116 <- tract_1116 %>% 
  mutate(year = rep(year_list, each = 85)) %>% 
  mutate(year = as.character(year)) %>% 
  mutate(othraceE = oth1E + oth2E,
         othraceM = NA) %>% 
  select(GEOID, NAME, year, everything(), -c(oth1E:oth2M))


# ....................................................
# 5. 2017 acs pop and race (different variable names than above)

varlist_17 = c("DP05_0001", "DP05_0037P", "DP05_0038P", "DP05_0039P", "DP05_0044P", "DP05_0052P", "DP05_0057P", "DP05_0058P", "DP05_0071P")
# totalpop, white, black, indig, asian, oth1, oth2, multi, ltnx
tract_17 <- get_acs(geography = "tract",
                     variables = varlist_17,
                     state = "VA", 
                     county = region,
                     survey = "acs5", 
                     year = 2017, 
                     output = "wide")

# rename, add year, derive othrace
names(tract_17) <- c("GEOID", "NAME", "totalpopE", "totalpopM",
                      "whiteE", "whiteM", "blackE", "blackM", 
                      "indigE", "indigM", "asianE", "asianM",
                      "oth1E", "oth1M", "oth2E", "oth2M",
                      "multiE", "multiM", "ltnxE", "ltnxM")

tract_17 <- tract_17 %>% 
  mutate(year = "2017") %>% 
  mutate(othraceE = oth1E + oth2E,
         othraceM = NA) %>% 
  select(GEOID, NAME, year, everything(), -c(oth1E:oth2M))


# ....................................................
# 6. Reduce and combine ----

# bind each year's file
tract_data_10_17 <- bind_rows(tract_10, tract_1116, tract_17)

# add geo variables alrady in tract_data,  and round percents
tract_data_10_17 <- tract_data_10_17 %>% 
  mutate(geoid = GEOID) %>% 
  separate(geoid, into = c("state", "locality", "tract"), 
           sep = c(2,5)) 


# ....................................................
# 7. save ----
saveRDS(tract_data_10_17, file = "data/tract_data_time.RDS") 
# tract_data_time <- readRDS("data/tract_data_time.RDS")


