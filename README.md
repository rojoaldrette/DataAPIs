# DataAPIs
Este repositorio contiene la creación de funciones que permiten obtener bases de datos de las API's de distintas instituciones. Su uso principal es en series de tiempo, las cuales son dificiles de tratar. Planeo crear más funciones para obtener datos de encuestas en cortes específicos de tiempo

## Contenidos
Consiste en un solo archivo llamado dataApi.R el cual deberá usarse desde source() dentro de Rstudio para obtener dichas funciones.
Existen dos distintos tipos de funciones:
- api.institucion(id, from, to, temp) y,
- api_all(file, from, to, in_list)

La primera consiste en una función que obtiene una serie única a partir de su id en la institución objetivo; mientras que la segunda obtendrá todas las series que se indiquen en un DataFrame con el formato indicado. La primera regresará un DataFrame con dos columnas: "fecha" y "valor", en formato de fecha aceptado por R y en formato de número, respectivamente. La segunda va a regresará dos posibles resultados: 1) un DF com la columna "fecha" y múltiples columnas con el nombre asignado dentro de "file"; o 2) una lista de DFs como los de la primera función para su manipulación individual.

## Instituciones
Las instituciones a las que estas funciones tienen acceso son las siguientes (se incluye su id):
- Banco de México: BANXICO
- INEGI Banco de Indicadores Económicos: BIE
- INEGI BISE: BISE
- Federal Reserve Economic Data: FRED
- Yahoo Finance: YAHOO

# ¿Cómo instalar?
Este repositorio está hecho a partir de un proyecto en Rstudio usando devtools y roxygenise. 
para instalarlo simplemente debes correr lo siguiente en tu Rstudio:

`````
library(devtools)

devtools::install_github("rojoaldrette/DataAPIs")

library(dataAPIs)
`````
