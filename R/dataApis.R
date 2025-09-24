

# ______________________________________________________________________________
#
# Proyecto:       API's para análisis de datos en R
#
#
# Autor:          Rodrigo Aldrette
# Email:          raaldrettes@colmex.mx
#
# Fecha:          16/02/2025
#
# ______________________________________________________________________________


# Paquetes

#' @importFrom dplyr %>% filter mutate rename arrange full_join
#' @importFrom httr GET content http_status
#' @importFrom jsonlite fromJSON
#' @importFrom quantmod getSymbols Ad
#' @importFrom purrr reduce
#' @importFrom zoo as.yearqtr
#' @importFrom rlang sym
NULL

# Script _________________________________________________________________________________________________

# Cosas por atender:
# - Introducir alguna capacidad para cargar por chunks
# - Arreglar el api_all para que acepte directamente el csv
# - Agregar más API's: FMI, Banco Mundial, OCDE, BID, etc...
# - Crear API's para python
# - Agregar docstrings a las funciones para explicar su uso
# - Incorporar transformaciones directo en api_all





#################################################################################################

# API Banxico


#' API Banxico
#'
#' Obtén serie de la API de banxico
#'
#' *Recuerda primero introducir tu token de Banxico con set_api_tokens()
#'
#' @param id El id de la serie de Banxico
#' @param from Fecha inicial que nos interesa escrita en string, ej. "2022-01-01"
#' @param to Fecha final que nos interesa escrita en string
#' @return Un DataFrame con dos columnas: "fecha" y "valor"
#' @examples
#' inflacion <- api_one.banxico("SP1", from="2000-01-01", to="2020-01-01");
#' DeudaPub <- api_one.banxico("SR2632");
#' @export
api_one.banxico <- function(id, from = "2000-01-01", to = "2025-06-01"){

  token_banxico <- if (!is.null(.pkg_env$config$banxico_token)) {
                   .pkg_env$config$banxico_token
                 } else {
                   Sys.getenv("BANXICO_API_TOKEN", unset = "")
                 }

  if (is.null(token_banxico) || token_banxico == "") {
    stop("Banxico API token not configured. Please set it using set_api_tokens() or BANXICO_API_TOKEN environment variable.")
  }

  url <- paste0("https://www.banxico.org.mx/SieAPIRest/service/v1/series/", id
                , "/datos/", from, "/", to,"?token=", token_banxico)

  response <- httr::GET(url)

  data_temp <- content(response, as = "text", encoding = "UTF-8") %>% fromJSON()

  df_temp <- as.data.frame(data_temp$bmx$series$datos)

  df_temp$dato <- as.numeric(gsub(",", "", df_temp$dato))

  df_temp$fecha <- as.Date(df_temp$fecha, format = "%d/%m/%Y")


  df_temp2 <- data.frame(
    fecha = df_temp$fecha,
    valor = df_temp$dato
  )

  return(df_temp2)

}




# API's INEGI

# BIE



#' API INEGI BIE
#'
#' Obtén series de la API de INEGI del Banco de Indicadores Económicos
#'
#' *Recuerda primero introducir tu token de INEGI con set_api_tokens()
#'
#' @param id El id de la serie del BIE
#' @param from Fecha inicial que nos interesa escrita en string, ej. "2022-01-01"
#' @param to Fecha final que nos interesa escrita en string
#' @param temporalidad Acepta "m" (month) o "q" (quarter) dependiendo de la serie,
#' por defecto está en "m", ya que es la más común en el BIE.
#' @return Un DataFrame con dos columnas: "fecha" y "valor"
#' @examples
#' consumo <- api_one.inegi_bie("740933", from="2000-01-01", to="2020-01-01",
#'                               temporalidad="m");
#' @export
api_one.inegi_bie <- function(id, temporalidad="m", from = "2000-01-01", to = "2024-11-01"){

  token_inegi <- if (!is.null(.pkg_env$config$inegi_token)) {
    .pkg_env$config$inegi_token
  } else {
    Sys.getenv("INEGI_API_TOKEN", unset = "")
  }

  if (is.null(token_inegi) || token_inegi == "") {
    stop("INEGI API token not configured. Please set it using set_api_tokens() or INEGI_API_TOKEN environment variable.")
  }

  serie <- id


  url <- paste0("https://www.inegi.org.mx/app/api/indicadores/desarrolladores/jsonxml/INDICATOR/",
                serie, "/es/0700/false/BIE/2.0/", token_inegi, "?type=json")

  # 🔹 Hacer la petición a la API
  response <- httr::GET(url)

  # 🔹 Convertir la respuesta a texto y luego a JSON
  data <- content(response, "text")
  flujoDatos<-paste(data ,collapse = " ")

  flujoDatos<-fromJSON(flujoDatos)
  flujoDatos<-flujoDatos$Series
  flujoDatos<-flujoDatos$OBSERVATIONS[[1]]

  date <- flujoDatos$TIME_PERIOD
  value <- as.numeric(flujoDatos$OBS_VALUE)

  df_temp <- data.frame(
    fecha = date,
    valor = value
  )

  df_temp <- df_temp[nrow(df_temp):1, ]

  if (temporalidad == "q"){

    date_temp <- as.yearqtr(df_temp$fecha, format = "%Y/%q")

    df_temp$fecha <- as.Date(date_temp, frac = 0)

    df_temp$fecha_quarter <- paste0(format(df_temp$fecha, "%Y"), "-", quarters(df_temp$fecha))

  } else if (temporalidad == "m"){

    df_temp$fecha <- as.Date(paste0(df_temp$fecha, "/01"), format = "%Y/%m/%d")

  }

  df_temp <- df_temp %>% arrange(fecha)

  df_temp <- df_temp %>%
    filter(fecha >= as.Date(from)) %>%
    filter(fecha <= as.Date(to))

  return(df_temp)
}





# BISE


#' API INEGI BISE
#'
#' Obtén series de la API de INEGI del Banco de Indicadores Socio-Económicos
#'
#' *Recuerda primero introducir tu token de INEGI con set_api_tokens()
#'
#' @param id El id de la serie del BIE
#' @param from Fecha inicial que nos interesa escrita en string, ej. "2022-01-01"
#' @param to Fecha final que nos interesa escrita en string
#' @param temporalidad Acepta "m" (month) o "q" (quarter) dependiendo de la serie,
#' por defecto está en "m", ya que es la más común en el BIE.
#' @return Un DataFrame con dos columnas: "fecha" y "valor"
#' @examples
#' consumo <- api_one.inegi_bise("740933", from="2000-01-01", to="2020-01-01",
#'                               temporalidad="m");
#' @export
api_one.inegi_bise <- function(id, temporalidad="m", from = "2000-01-01", to = "2024-11-01"){

  token_inegi <- if (!is.null(.pkg_env$config$inegi_token)) {
    .pkg_env$config$inegi_token
  } else {
    Sys.getenv("INEGI_API_TOKEN", unset = "")
  }

  if (is.null(token_inegi) || token_inegi == "") {
    stop("INEGI API token not configured. Please set it using set_api_tokens() or INEGI_API_TOKEN environment variable.")
  }

  serie_pib <- id


  url <- paste0("https://www.inegi.org.mx/app/api/indicadores/desarrolladores/jsonxml/INDICATOR/",
                serie_pib, "/es/0700/false/BISE/2.0/", token_inegi, "?type=json")

  # Hacer la petición a la API
  response <- httr::GET(url)

  # Convertir la respuesta a texto y luego a JSON
  data <- content(response, "text")
  flujoDatos<-paste(data ,collapse = " ")

  flujoDatos<-fromJSON(flujoDatos)
  flujoDatos<-flujoDatos$Series
  flujoDatos<-flujoDatos$OBSERVATIONS[[1]]

  date <- flujoDatos$TIME_PERIOD
  value <- as.numeric(flujoDatos$OBS_VALUE)

  df_temp <- data.frame(
    fecha = date,
    valor = value
  )

  df_temp <- df_temp[nrow(df_temp):1, ]


  if (temporalidad == "q"){

    date_temp <- as.yearqtr(df_temp$fecha, format = "%Y/%q")

    df_temp$fecha <- as.Date(date_temp, frac = 0)

    df_temp$fecha_quarter <- paste0(format(df_temp$fecha, "%Y"), "-", quarters(df_temp$fecha))

  } else if (temporalidad == "m"){

    df_temp$fecha <- as.Date(paste0(df_temp$fecha, "/01"), format = "%Y/%m/%d")

  }

  df_temp <- df_temp %>% arrange(fecha)

  df_temp <- df_temp %>%
    filter(fecha >= as.Date(from)) %>%
    filter(fecha <= as.Date(to))


  return(df_temp)

}




# Yahoo finanzas

#' API INEGI BIE
#'
#' Obtén series de la API de Yahoo Finanzas
#'
#' * No necesita token, lo hace a través del paquete quantmod
#' * Si necesitas mayor precisión (apertura, cierre, etc..) recomiendo usar directamente
#' quantmod, ofrece mayor personalización y accesibilidad a datos financieros
#'
#' @param id El id de la serie de yahoo
#' @param from Fecha inicial que nos interesa escrita en string, ej. "2022-01-01"
#' @param to Fecha final que nos interesa escrita en string
#' @return Un DataFrame con dos columnas: "fecha" y "valor"
#' @examples
#' consumo <- api_one.yahoo("MXN=X", from="2005-01-01", to="2008-01-01")
#' @export
api_one.yahoo <- function(id, from = "2000-01-01", to = "2024-11-30", adjusted = T){

  df <- quantmod::getSymbols(id, src = "yahoo", from = from, to = to, auto.assign = FALSE)

  if (adjusted){
    df <- Ad(df)
  }

  df_temp <- data.frame(fecha = index(df), valor = as.numeric(coredata(df)))

  return(df_temp)
}



# FRED


#' API FRED
#'
#' Obtén series de la API de la Federal Reserve Economic Data
#'
#' *Recuerda primero introducir tu token de la FRED con set_api_tokens()
#'
#' @param id El id de la serie de Banxico
#' @param from Fecha inicial que nos interesa escrita en string, ej. "2022-01-01"
#' @param to Fecha final que nos interesa escrita en string
#' @return Un DataFrame con dos columnas: "fecha" y "valor"
#' @examples
#' us_inpc <- api_one.fred("CPIAUCNS", from="2000-01-01", to="2020-01-01")
#' @export
api_one.fred <- function(id, from = "2000-01-01", to = "2024-11-30"){

  token_fred <- if (!is.null(.pkg_env$config$fred_token)) {
    .pkg_env$config$fred_token
  } else {
    Sys.getenv("FRED_API_TOKEN", unset = "")
  }

  if (is.null(token_fred) || token_fred == "") {
    stop("FRED API token not configured. Please set it using set_api_tokens() or FRED_API_TOKEN environment variable.")
  }

  url <- paste0("https://api.stlouisfed.org/fred/series/observations?",
                "series_id=", id,
                "&observation_start=", from,
                "&observation_end=", to,
                "&api_key=", token_fred,
                "&file_type=json")

  response <- httr::GET(url)

  if (http_status(response)$category == "Success") {
    data_json <- content(response, as = "text", encoding = "UTF-8")
    data_parsed <- fromJSON(data_json)

    # Convertir en DataFrame
    df <- as.data.frame(data_parsed$observations) %>%
      mutate(value = as.numeric(value))

    df2 <- data.frame(fecha = df$date,
                      valor = df$value)

    return(df2)
  } else {
    print("Error al obtener datos de FRED")
    return(NULL)
  }

}








do_df_fromlista <- function(lista_df){

  coso <- lista_df

  coso <- lapply(names(coso), function(name) {
    coso[[name]] %>%
      rename(!!name := valor)
  })

  combined <- coso %>%
    purrr::reduce(full_join, by = "fecha")


  return(combined)
}





#' API all
#'
#' Obtén múltiples series al mismo tiempo desde un df.
#'
#' * Recuerda primero introducir los tokens necesarios con set_api_tokens()
#' * Necesitas tener un dataframe con las siguientes columnas en el siguiente orden:
#'    * "id" (id de la serie)
#'    * "description" (nombre a usar para la serie),
#'    * "origen" (institución de la que viene) el origen tiene que estar escrito en mayusculas, ejemplo "BANXICO" o "BIE"
#'    * "temp" (este es para la API de INEGI que necesita estipular mes o trimestre) y
#'    * opcionalmente la columna "do" que aplica transformaciones con do_transform().
#'
#' Descripción más detallada para cargar varias series disponibles en el github del paquete: https://github.com/rojoaldrette/DataAPIs
#'
#' @param df_serie Un dataframe con las series a cargar
#' @param from Fecha inicial que nos interesa escrita en string, ej. "2022-01-01"
#' @param to Fecha final que nos interesa escrita en string
#' @param same.length Está puesto en False por defecto; sin embargo, si tus series son de la misma temporalidad
#' y longitud, puedes ponerlo en True para obtener un dataframe combinado con columnas nombradas según "description".
#' @return Si same.length=F regresará una lista con los dataframes de cada serie,
#' si es T, entonces regresará el dataframe combinado de todas las series (necesita misma longitud).
#' @examples
#' series <- read.csv("modelo_1.csv")
#' var_x <- api_one.banxico(series, from="2000-01-01", to="2020-01-01")
#' @export
api_all <- function(df_serie, from = "2000-01-01", to = "2024-11-30", same.length=F){

  lista_temp <- list()

  date.2 <- as.Date(from)

  date.3 <- as.Date(to)

  for (i in 1:nrow(df_serie)){

    seriecoso <- as.character(df_serie[i, 1])
    name      <- as.character(df_serie[i, 2])
    type      <- as.character(df_serie[i, 3])
    temp      <- as.character(df_serie[i, 4])

    if (type == "BANXICO"){

      df_temp <- api_one.banxico(seriecoso, from=from, to = to)

    } else if (type == "BIE"){

      df_temp <- api_one.inegi_bie(seriecoso, temporalidad = temp, from=from, to=to)

    } else if (type == "BISE"){

      df_temp <- api_one.inegi_bise(seriecoso, temporalidad = temp, from=from, to=to)

    } else if (type == "FRED"){

      df_temp <- api_one.fred(seriecoso, from=from, to = to)

    } else if (type == "YAHOO"){

      df_temp <- api_one.yahoo(seriecoso, from=from, to = to)


    } else if (type == "omit"){
      next
    } else {
      print("No se reconoce el tipo")
      next
    }

    df_temp <- df_temp %>%
      filter(fecha <= as.Date(date.3))

    lista_temp[[name]] <- df_temp

  }

  result <- lista_temp

  if (same.length){
    result <- do_df_fromlista(result)
  }

  return(result)

}





do_transformations <- function(df_lista, df_serie){

  for (i in 1:length(df_lista)) {

    df_lista[[i]]$valor <- as.numeric(gsub(",", "", df_lista[[i]]$valor))

    if (df_serie[i, 3] == 1) {
      next
    } else if (df_serie[i, 3] == 2){
      df_lista[[i]]$valor <- c(0, diff(df_lista[[i]]$valor))
    } else if (df_serie[i, 3] == 3){
      df_lista[[i]]$valor <- c(0, diff(log(df_lista[[i]]$valor)))
    } else if (df_serie[i, 3] == 4){
      df_lista[[i]]$valor <- c(0, diff(diff(log(df_lista[[i]]$valor))))
    } else{
      next
    }

  }

  return(df_lista)

}







