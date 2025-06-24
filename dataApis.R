

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
if (!require("pacman")) install.packages("pacman")
pacman::p_load(dplyr, jsonlite, httr, purr)


font_add_google("Montserrat")
showtext_auto()


# Script _________________________________________________________________________________________________

# Cosas por atender:
# - Universalizar las funciones y hacerlas un poco más eficientes
# - Introducir alguna capacidad para cargar por chunks
# - Arreglar el api_all para que acepte directamente el csv 
# - Ajustar el api_all para crear directo el DF o mantener la lista (debe
# considerar los valores faltantes
# - Agregar más API's: FMI, Banco Mundial, OCDE, BID, etc...
# - Crear API's para python
# - Agregar docstrings a las funciones para explicar su uso



#################################################################################################

# API Banxico



api_one.banxico <- function(id, from = "2000-01-01", to = "2025-06-23"){
  
  token_banxico <- "cdd1fb5cef5f5c4302cd2fac0b9bb1518866008fc6c8d09d297548d56d00e2dd"
  
  url <- paste0("https://www.banxico.org.mx/SieAPIRest/service/v1/series/", id
                , "/datos/", from, "/", to,"?token=", token_banxico)
  
  response <- GET(url)
  
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


api_one.inegi_bie <- function(id, temporalidad="m", from = "2000-01-01", to = "2024-11-01"){
  
  token_inegi <- "88cf3fd3-4f88-4448-98dd-d4c505b9c6f4"
  
  
  serie_pib <- id
  
  
  url <- paste0("https://www.inegi.org.mx/app/api/indicadores/desarrolladores/jsonxml/INDICATOR/", 
                serie_pib, "/es/0700/false/BIE/2.0/", token_inegi, "?type=json")
  
  # 🔹 Hacer la petición a la API
  response <- GET(url)
  
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



api_one.inegi_bise <- function(id){
  
  token_inegi <- "88cf3fd3-4f88-4448-98dd-d4c505b9c6f4"
  
  
  serie_pib <- id
  
  
  url <- paste0("https://www.inegi.org.mx/app/api/indicadores/desarrolladores/jsonxml/INDICATOR/", 
                serie_pib, "/es/0700/false/BISE/2.0/", token_inegi, "?type=json")
  
  # 🔹 Hacer la petición a la API
  response <- GET(url)
  
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
  
  df_temp <- df_temp %>% arrange(fecha)
  
  return(df_temp)
  
}




# Yahoo finanzas


api_one.yahoo <- function(id, from = "2000-01-01", to = "2024-11-30", adjusted = T){
  
  df <- getSymbols(id, src = "yahoo", from = from, to = to, auto.assign = FALSE)
  
  if (adjusted){
    df <- Ad(df)
  }
  
  df_temp <- data.frame(fecha = index(df), valor = as.numeric(coredata(df)))
  
  return(df_temp)
}



# FRED


api_one.fred <- function(id, from = "2000-01-01", to = "2024-11-30"){
  
  token.fred <- "cd961dd4a15107e7dc6bdf663faf1f0f"
  
  url <- paste0("https://api.stlouisfed.org/fred/series/observations?",
                "series_id=", id,
                "&observation_start=", from,
                "&observation_end=", to,
                "&api_key=", token.fred,
                "&file_type=json")
  
  response <- GET(url)
  
  if (http_status(response)$category == "Success") {
    data_json <- content(response, as = "text", encoding = "UTF-8")
    data_parsed <- fromJSON(data_json)
    
    # Convertir en DataFrame
    df <- as.data.frame(data_parsed$observations) %>%
      mutate(value = as.numeric(value))  # Convertir valores a numérico
    
    df2 <- data.frame(fecha = df$date,
                      valor = df$value)
    
    return(df2)
  } else {
    print("Error al obtener datos de FRED")
    return(NULL)
  }
  
}




# Cargar todas de un archivo

do_all_api <- function(df_serie, from = "2000-01-01", to = "2024-11-30"){
  
  lista_temp <- list()
  
  date.2 <- as.Date(from)
  
  date.3 <- as.Date(to)
  
  for (i in 1:nrow(df_serie)){
    
    seriecoso <- df_serie[i, 1]
    
    name <- df_serie[i, 2]
    
    type <- df_serie[i, 4]
    
    temp <- df_serie[i, 5]
    
    
    if (type == "BANXICO"){
      
      df_temp <- do_one_api.banxico(seriecoso, to = to) %>%
        filter(fecha >= date.2)
      
    } else if (type == "BIE"){
      
      df_temp <- do_one_api.inegi_bie(seriecoso, temporalidad = temp) %>%
        filter(fecha >= date.2)
      
    } else if (type == "BISE"){
      
      df_temp <- do_one_api.inegi_bise(seriecoso, temporalidad = temp) %>%
        filter(fecha >= date.2)
      
    } else if (type == "FRED"){
      
      
      df_temp <- do_one_api.fred(seriecoso, to = to) 
      
      df_temp$fecha <- as.Date(df_temp$fecha)
      
      df_temp <- df_temp %>%
        filter(fecha >= date.2)
      
    } else if (type == "yahoo"){
      
      df_temp <- do_one_api.yahoo(seriecoso, to = to)
      
      df_temp <- df_temp %>%
        filter(fecha >= date.2)
      
      
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
  
  return(lista_temp)
  
}









