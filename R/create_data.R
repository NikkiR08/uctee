
#' @import tidyverse
#' @import data.table
#' @export
#'



######### create big data frame

load("data/gdpdeflator.rda")
load("data/gdpdeflatoreur.rda")

load("data/ppp_exchange.rda")
load("data/ppp_exchangeeur.rda")

load("data/wb_exchange.rda")
load("data/wb_exchangeeur.rda")

# ### create big data table of exchange and inflation info
# inf_xch_data <- merge(inflation_source,ppp_exchange,by=c("iso3c","date"),all=TRUE)
# inf_xch_data <- merge(inf_xch_data,wb_exchange,by=c("iso3c","date"), all=TRUE)
# inf_xch_data <- merge(inf_xch_data, currency_country, by="iso3c", allow.cartesian = TRUE)
# inf_xch_data <- inf_xch_data %>%
#   select(iso3c, date, NY.GDP.DEFL.ZS, PA.NUS.PPP, PA.NUS.FCRF, currency_code) %>%
#   as.data.table()

lst_dt = list(gdpdeflator,
               ppp_exchange,
               wb_exchange)

lst_dt_eur = list(gdpdeflator.eur,
              ppp_exchange.eur,
              wb_exchange.eur)

####### need to deal with calling "reduce"

countr_dt <- lst_dt %>% reduce(inner_join, by=c("iso3c","date"))
eur_dt <- lst_dt_eur %>% reduce(inner_join,by=c("iso3c","date") )

xch_inf <- rbind(countr_dt,eur_dt, fill=TRUE)

save(xch_inf, file="data/xch_inf.rda")
