#' @import wbstats
#' @import data.table
#' @export
#'


#### !!! need to change to just calls the data you want for each run of the function
#### rather than saving the whole big dataset but to get working using same set up as previous code

###### !!! need to find a way to call EMU + default list of iso3c code in one go
#### PPP exchange rate
ppp_exchange <- wb_data(indicator=c("PA.NUS.PPP"))
ppp_exchange <- as.data.table(ppp_exchange)
save(ppp_exchange, file="data/ppp_exchange.rda")

### Official exchange rate
wb_exchange <- wb_data(indicator=c("PA.NUS.FCRF"))
wb_exchange <- as.data.table(wb_exchange)
save(wb_exchange, file="data/wb_exchange.rda")

### GDP deflator data
gdpdeflator <- wb_data(indicator = "NY.GDP.DEFL.ZS")
gdpdeflator <- as.data.table(gdpdeflator)
save(gdpdeflator, file="data/gdpdeflator.rda")

#### PPP exchange rate for eurozone
ppp_exchange.eur <- wb_data(country="EMU",indicator=c("PA.NUS.PPP"))
ppp_exchange.eur <- as.data.table(ppp_exchange.eur)
save(ppp_exchange.eur, file="data/ppp_exchangeeur.rda")

### Official exchange rate for eurozone
wb_exchange.eur <- wb_data(country="EMU",indicator=c("PA.NUS.FCRF"))
wb_exchange.eur <- as.data.table(wb_exchange.eur)
save(wb_exchange.eur, file="data/wb_exchangeeur.rda")

### GDP deflator data for Euro area using % annual change (can be used in same way??)
gdpdeflator.eur <- wb_data(country="EMU", indicator = "NY.GDP.DEFL.KD.ZG")
gdpdeflator.eur <- as.data.table(gdpdeflator.eur)
save(gdpdeflator.eur, file="data/gdpdeflatoreur.rda")
