library(httr)
library(jsonlite)

HANDLER <- Sys.getenv("_HANDLER")
AWS_LAMBDA_RUNTIME_API <- Sys.getenv("AWS_LAMBDA_RUNTIME_API")
args = commandArgs(trailingOnly = TRUE)
EVENT_DATA <- args[1]
REQUEST_ID <- args[2]

HANDLER_split <- strsplit(HANDLER, ".", fixed = TRUE)[[1]]
file_name <- paste0(HANDLER_split[1], ".R")
function_name <- HANDLER_split[2]
source(file_name)
params <- fromJSON(EVENT_DATA)
result <- do.call(function_name, params)
url <- paste0("http://",
              AWS_LAMBDA_RUNTIME_API,
              "/2018-06-01/runtime/invocation/",
              REQUEST_ID,
              "/response")
POST(url, body = list(result = result), encode = "json")
