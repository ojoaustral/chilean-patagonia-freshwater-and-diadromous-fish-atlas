Esta carpeta contiene los datos y el output de los análisis para vincular dos versiones de la base de datos consolidada y deduplicada automáticamente, sin hacer uso del campo clave id_CC. Esto fue necesario porque si hizo un gran trabajo de revisión manual y anotación de correcciones necesarias en una versión de la base de datos que luego quedó reemplazada por una versión más nueva cuyo campo clave generado automáticamente era distinto a la versión revisada a mano. Ver más detalles de este proceso en el reporte archivo Matching_full_dedup_dataset_with_comments_2025-12-06_Done.pdf

El resultado de este análisis fue una tabla de correcciones (preparada a mano revisando mapas, tablas, estudios, etc.) incluyendo un campo llamado match_id que corresponde al id_CC de la versión X.filtered.dedup_2025-12-02.csv de la base de datos consolidada posterior a la remoción automática de duplicados. Esta tabla de correcciones actualizada con el match_id se usó el el script general para implementar cambios, remover duplicados identificados a mano, etc.: Table1_matched_strict_reviewed_2025-12-06.csv

En el contexto del flujo de trabajo principal Atlas_Ictiogeografico_2025-11-24.Rmd esta tabla fue renombrada para enfatizar su propósito: 

Table1_matched_strict_reviewed_2025-12-06.csv -> Cambios_a_implementar_2025-12-06.csv 

Nota: los caminos (paths) cambiaron desde la última vez que se ejecutaron estos códigos, pero todos los archivos de entrada y salida se encuentran en esta carpeta.  

Last update 2025-12-08
