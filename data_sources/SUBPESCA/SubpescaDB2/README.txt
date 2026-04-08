Base de datos: Registros de Permisos de Pesca de Investigación Subpesca 2012-2023

Estos datos fueron adquiridos mediante solicitud bajo Ley de Transparencia a la Subsecretaría de Pesca y Acuicultura (SUBPESCA), como respuesta a consulta de acceso a la información pública CI: AH002T-0005627, solicitada por Marilyn Aguilar González. Dicha solicitud requirió de un proceso de subsanación (gestionado por Macarena Covarrubias), acotando el período de Permisos de Pesca de Investigación a los resultados de proyectos desde el año 2012 a la fecha (2023).

Por otra parte, de las 113 carpetas recibidas organizadas por resolución de aceptación de cada permiso de pesca, sólo 12 correspondían con el área y especies de estudio.
Al respecto, cabe indicar que esta base de datos no estaba consolidada y por ende, el ID de cada dato fue otorgado manualmente al final, una vez traspasados todos los datos respectivos.

La carpeta que se adjunta sobre esta base de datos contiene 3 archivos:
1.- #BD_Subpesca_PINV_2012_2023_original
Este archivo contiene los datos de las observaciones de peces dentro del área de interés en su estado original desde la base de datos adquirida. Además, se agregó una pestaña llamada "Glosario" que contiene la nomenclatura original de la base de datos adquirida.

2.- #BD_Subpesca_PINV_2012_2023_modificaciones
Este archivo contiene los mismos datos que el archivo original pero con la primera fila diferente.
Esta fila #1 son los nombres de los campos que se utilizaron en el archivo homologado a formato Darwin Core.
La fila #2 (letras en rojo) son los nombres de los campos originales. Por lo tanto los últimos campos que tienen el guíon "-" significa que no venían en el archivo original y fueron añadidos para la homologación.
Cabe señalar que, todos los campos que tiene el guión en la fila 2 fueron rellenados considerando la información otorgada por medio de los archivos contenidos en las respectivas carpetas de cada resolución. A excepción de "decimalLatitud" y decimalLongitude", ya que estos fueron transformados a grados decimales mediante la herramienta "Convert Coordinate Notation (Data Management)" en ArcGIS.

3.- #BD_Subpesca_PINV_2012_2023_homologado
Este archivo es la base de datos resultante luego de la homologación de campos a formato Darwin Core.
Por lo tanto, todos los campos que no fueron homologados se excluyeron.

**A continuación se detallan los campos homologados uno a uno:

Campo orginal			/ 	Campo final homologado
N° DE RESOLUCIÓN SUBPESCA	/	associatedReferences
EJECUTOR			/	recordedBy
MANDANTE O TITULAR		/	ownerInstitutionCode
AÑO				/	year
HORA DE MUESTREO		/	eventTime
ESTACIÓN			/	locationRemarks
LATITUD 			/	verbatimLatitude
LONGITUD 			/	verbatimLongitude
NOMBRE CIENTÍFICO		/	scientificName
NOMBRE COMÚN			/	vernacularName
N° INDIVIDUOS			/	individualCount
TIPO DE ARTE			/	samplingProtocol
VALOR CPUE			/	sampleSizeValue
UNIDAD CPUE			/	sampleSizeUnit
NOMBRE CIENTÍFICO		/	scientificName
NOMBRE COMÚN			/	vernacularName
N° DE INDIVIDUOS		/	individualCount
N° DE INDIVIDUOS		/	individualCount


**A continuación se detallan los campos añadidos:

catalogNumber
datasetName
institutionCode
decimalLatitude
decimalLongitude
verbatimEventDate
eventDate
day
month
samplingEffort
continent
country
countryCode
stateProvince
county
municipality
locality

**A continuación se detallan los campos eliminados:
TITULO PROYECTO
FUENTE 
CUENCA
MES 
GRUPO TAXONÓMICO
Nº SACRIFICADOS
DIDYMO VISUAL
MUESTRA
PESO_MIN_GR
PESO_MAX_GR
PESO_PROMEDIO
PESO D.S.
LONG_MIN_CM
LONG_MAX_CM
LONG_PROMEDIO
LONG_D.S.
