## packages for plotting
library(treemap)
library(highcharter)

# records <- kinesis_get_records('crypto', 'eu-west-1')

## connect to Redis
library(rredis)
redisConnect()

records <- kinesis_get_records('crypto', 'eu-west-1')

txprocessor <- function(record) {
  symbol <- fromJSON(record)$s
  log_info(paste('Found 1 transaction on', symbol))
  redisIncr(paste('symbol', symbol, sep = ':'))
}


redisConnect()
for (record in records) {
  txprocessor(record)
}

keys <- redisKeys('symbol*')


library(shiny)
library(data.table)
ui     <- shinyUI(highchartOutput('treemap', height = '800px'))
server <- shinyServer(function(input, output, session) {
  
  symbols <- reactive({
    
    ## auto-update every 2 seconds
    reactiveTimer(2000)()
    
    ## get frequencies
    symbols <- redisMGet(redisKeys('symbol:*'))
    symbols <- data.table(
      symbol = sub('^symbol:', '', names(symbols)),
      N = as.numeric(symbols))
    
    ## color top 3
    symbols[, color := 1]
    symbols[symbol %in% symbols[order(-N)][1:3, symbol], color := 2]
    
    ## return
    symbols
  })
  
  output$treemap <- renderHighchart({
    tm <- treemap(symbols(), index = c('symbol'),
                  vSize = 'N', vColor = 'color',
                  type = 'value', draw = FALSE)
    N <- sum(symbols()$N)
    hc_title(hctreemap(tm, animation = FALSE),
             text = sprintf('Transactions (N=%s)', N))
  })
  
})
shinyApp(ui = ui, server = server, options = list(port = 8080))