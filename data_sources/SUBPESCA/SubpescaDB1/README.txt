Base de datos: Subpesca

La carpeta que se adjunta sobre esta base de datos contiene 3 archivos:
1.- #BDSubpesca original
Este archivo contiene los datos de las observaciones de peces dentro del área de interés en su estado original desde la base de datos adquirida. Además, se agregó una pestaña llamada "Glosario" que contiene la nomenclatura original de la base de datos adquirida.

2.- #BDSubpesca campos modificados
Este archivo contiene los mismos datos que el archivo original pero con la primera fila diferente.
Esta fila #1 son los nombres de los campos que se utilizaron en el archivo homologado a formato Darwin Core.
La fila #2 (letras en rojo) son los nombres de los campos originales. Por lo tanto los últimos campos que tienen el guíon "-" significa que no venían en el archivo original y fueron añadidos para la homologación.

3.- #BDSubpesca homologado
Este archivo es la base de datos resultante luego de la homologación de campos a formato Darwin Core.
Por lo tanto, todos los campos que no fueron homologados se excluyeron.

**A continuación se detallan los campos homologados uno a uno:

Campo orginal	/ 	Campo final homologado
ID			/	catalogNumber
FUENTE_BBDD		/	rightsHolder
AUTOR/EJECUTOR	/	recordedBy
MANDANTE		/	ownerInstitutionCode
MES			/	month
AÑO			/	year
HORA			/	eventTime
COD_EST		/	locationRemarks
ESTE			/	verbatimLatitude
NORTE			/	verbatimLongitude
UTM			/	verbatimCoordinateSystem
DATUM			/	verbatimSRS
PHYLLUM			/	phylum
CLASE			/	class
ORDEN			/	order
FAMILIA		/	family
GENERO		/	genus
Especie		/	specificEpithet
NOMBRE_CIE		/	scientificName
NOMBRE_COM		/	vernacularName
ORIGEN		/	establishmentMeans
ABUNDACIA		/	individualCount
UNIDAD_ABUN		/	organismQuantityType
TIPO_ARTE		/	samplingProtocol
CPUE			/	sampleSizeValue
UNIDAD_CPUE		/	sampleSizeUnit
NOM_REG		/	county
NOM_PROV		/	stateProvince
NOM_COM		/	municipality

**A continuación se detallan los campos añadidos:

decimalLatitude
decimalLongitude
institutionCode
datasetName
basisOfRecord
kingdom
country
countryCode
bibliographicCitation

#Cabe señalar que para rellenar el campo "bibliographicCitation", se utilizaron de referencia la información contenida en los campos originales: TITULO_PRO, LINK, CITA (APA) y TIPOLOGIA.


**A continuación se detallan los campos eliminados:
OBJECTID (este campo se eliminó porque era igual al campo ID que fue homologado)
R_EX_PINV
TITULO_PRO
PRO_SEIA
FUENTE
REVISTA
AÑO_PUBLIC
HUSO
GRUPO
EST_CONSERVACION
REF_DS_EST_CONSERV
DENSIDAD
TIPO_MUESTREO
Nº SACRIFICADOS
DIDYMO VISUAL
MUESTRA
REPLICA
PINV
OBSERVACION
ID_REGION
COD_COM
CALIDAD_INFO
TIPO_SISTEMA
MUESTREO
ERROR
MET_TAMAÑO_MUESTRA
TIPO DISTRIBUCION
ESTADISTICA
FREC_MUESTREO
DET_MUESTREO
FIJADOR
SUSTRATO
EPP
MESO_MICRO_HABITAT
FOTOGRAFIA
CARTOGRAFIA
BIOSEGURIDAD
COD_CUEN
NOM_CUEN
COD_SUBC
NOM_SUBC
