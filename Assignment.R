library(rJava)
library(AWR.Kinesis)
library(data.table)
library(logger)
library(rredis)
library(jsonlite)

records <- kinesis_get_records('crypto', 'eu-west-1')

records[1]

fromJSON(records[1])



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

symbols <- redisMGet(redisKeys('symbol:*'))
symbols <- data.frame(
  symbol = sub('^symbol:', '', names(symbols)),
  N = as.numeric(symbols))
symbols


library(ggplot2)
ggplot(symbols, aes(symbol, N)) + geom_bar(stat = 'identity')

library(rredis)
redisConnect()

redisKeys

keys <- redisKeys('symbol*')

redisDelete(keys)


