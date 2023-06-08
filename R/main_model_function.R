########### main functionality

load("data/dummy_data_unit_cost.rda")
load("data/xch_inf.rda")

######## currently doesn't run

#### !!! to do: split out into country code adjustment into separate script
#### !!! to do: combine I$ work through and local currency work through into 1 function
#### !!! to do: add more functionality to account for more country/currency missmatches (e.g. CAD for a non-Canadian country)


#### !!! to do: add list of Eurozone countries to match in
#### !!! match year country joined eurozone to functionality - just add to tester to match
### for now add to dummy data by hand to get working
dummy_data_unit_cost[cost_currency_start=="EUR", eurozone := "YES"]
dummy_data_unit_cost[cost_country_start=="Senegal", eurozone := "NO"]


dummy_data_unit_cost$iso3c <-countrycode(dummy_data_unit_cost$cost_country_start,
                                         origin="country.name", destination="iso3c")

### europe not matched
dummy_data_unit_cost[cost_country_start=="Europe", iso3c := "EMU"]

######### !!! TO DO: update these functions into one function
####### currently just turning into USD
cost_adj_USD <- function(to_year,
                         cost_dt_row,
                         column_ref_cost,
                         xch_inf) {

  ## to_year is a numeric
  ## cost_dt_row a row of the literature extract
  ## column_ref_cost the column with the "to_cost" to be adjusted
  ## xch_inf is the exchange rate and inflation dataset created above

  #### first pulling out the data we need for conversions
  iso <- as.character(cost_dt_row$iso3c) ## country of study
  from_cost <- cost_dt_row[[column_ref_cost]] ## cost to be adapted
  from_year <- as.numeric(cost_dt_row$cost_year_start) ## base year
  ## see if dates in set
  from_year_data <- xch_inf[date == from_year] ## from year financial data
  to_year_data <- xch_inf[date == to_year] ## to year financial data
  temp_iso_dt <- xch_inf[iso3c==iso]  ## to be used in calculations below

  if(cost_dt_row$iso3c=="EMU"&cost_dt_row$cost_currency=="EUR"& cost_dt_row$eurozone=="YES"){
    ## inflate based on average GDP deflator growth
    gdp_i_av <- xch_inf[date<=to_year & date >= from_year & iso3c=="EMU"]
    gdp_i_av <- mean(gdp_i_av$NY.GDP.DEFL.KD.ZG) ## average Inflation, GDP deflator (annual %) over the period
    ## use compound interest formulae to adjust for annual inflation rate equal to the average
    to_index_est <- from_cost*(1+(gdp_i_av/100))^(to_year-from_year)
    ## convert to USD from EUR
    euro_exchange <- xch_inf[currency_code=="EUR"] #### !!! got to here, then realised need to go through an adapt whole function - reverting back to using old model
    ## get so just one per year
    euro_exchange <- euro_exchange %>%
      group_by(date, currency_code) %>%
      filter(row_number() == 1)%>% ## take just 1 per study + who.region/region combination
      as.data.table()
    eur_usd_xc <- euro_exchange[date==to_year,"PA.NUS.FCRF"]
    to_cost <- as.numeric(to_index_est*eur_usd_xc)
  }
  else if (cost_dt_row$iso3c=="EUSA"&cost_dt_row$cost_currency=="USD"& cost_dt_row$who.region=="EURO"){
    #### IF iso3 is NA & COST_CURRENCY = US AND REGION = EURO
    ## get euro exchange data
    ### could just use euro csv directly, but that adds another input into the function
    euro_exchange <- xch_inf[currency_code=="EUR"]
    ## get so just one per year
    euro_exchange <- euro_exchange %>%
      group_by(date, currency_code) %>%
      filter(row_number() == 1)%>% ## take just 1 per study + who.region/region combination
      as.data.table()

    from_year_index <- euro_exchange[date == from_year]
    ## convert to EUR
    from_index_est <- from_cost*from_year_index$PA.NUS.FCRF
    ## inflate based on average GDP deflator growth
    gdp_i_av <- euro_wb_gdp[date<=to_year & date >= from_year]
    gdp_i_av <- mean(gdp_i_av$eu_val) ## average GDP inflation for the euro zone over the period
    to_index_est <- from_index_est*(1+(gdp_i_av/100))^(to_year-from_year)
    ## convert to USD from EUR
    eur_usd_xc <- euro_exchange[date==to_year,"PA.NUS.FCRF"]
    to_cost <- as.numeric(to_index_est/eur_usd_xc)
  }

  else if (cost_dt_row$iso3c!="EUSA"&cost_dt_row$cost_currency!=cost_dt_row$currency_code& cost_dt_row$cost_currency=="EUR"){
    ### IF iso3 != na and cost_currency!=currency_code & (currency = EUR)
    ## convert to USD then to local currency
    euro_exchange <- xch_inf[currency_code=="EUR"]
    ## get so just one per year
    euro_exchange <- euro_exchange %>%
      group_by(date, currency_code) %>%
      filter(row_number() == 1)%>% ## take just 1 per study + who.region/region combination
      as.data.table()

    eur_usd_xc <- euro_exchange[date==from_year,"PA.NUS.FCRF"]
    usd_lcu_xc <- xch_inf[date==from_year &
                               iso3c==iso,"PA.NUS.FCRF"]
    xc_cost <- as.numeric(from_cost*(1/eur_usd_xc)*usd_lcu_xc)
    from_index <- temp_iso_dt[temp_iso_dt$date == from_year, "NY.GDP.DEFL.ZS"]
    to_index <-   temp_iso_dt[temp_iso_dt$date == to_year, "NY.GDP.DEFL.ZS"]
    to_cost <- xc_cost * (to_index/from_index)
    ## then convert back to USD 2019
    usd_xc <-   temp_iso_dt[date==to_year,"PA.NUS.FCRF"]
    to_cost <- as.numeric(to_cost/usd_xc)
  }
  else if (cost_dt_row$iso3c!="EUSA"& cost_dt_row$cost_currency!=cost_dt_row$currency_code&
           cost_dt_row$cost_currency=="USD"){
    ### IF iso3 != na and cost_currency!=currency_code & (currency = US)
    ## convert to local currency
    usd_lcu_xc <- xch_inf[date==from_year &
                               iso3c==iso,"PA.NUS.FCRF"]
    xc_cost <- as.numeric(from_cost*usd_lcu_xc)
    from_index <- temp_iso_dt[temp_iso_dt$date == from_year, "NY.GDP.DEFL.ZS"]
    to_index <-   temp_iso_dt[temp_iso_dt$date == to_year, "NY.GDP.DEFL.ZS"]
    to_cost <- xc_cost * (to_index/from_index)
    ## then convert back to USD 2019
    usd_xc <-   temp_iso_dt[date==to_year,"PA.NUS.FCRF"]
    to_cost <- as.numeric(to_cost/usd_xc)
  }
  else if (cost_dt_row$iso3c!="EUSA"&
           cost_dt_row$cost_currency==cost_dt_row$currency_code) {
    ### IF  iso3 != na and cost_currency==currency_code
    from_index <- temp_iso_dt[temp_iso_dt$date == from_year, "NY.GDP.DEFL.ZS"]
    to_index <-   temp_iso_dt[temp_iso_dt$date == to_year, "NY.GDP.DEFL.ZS"]
    to_cost <- from_cost * (to_index/from_index)
    ## then convert to USD 2019
    usd_xc <-   temp_iso_dt[date==to_year,"PA.NUS.FCRF"]
    to_cost <- as.numeric(to_cost/usd_xc)
  }
  else {
    is.na(to_cost)
  }
  return(to_cost)
}

###### picking up from I$ turning into USD
