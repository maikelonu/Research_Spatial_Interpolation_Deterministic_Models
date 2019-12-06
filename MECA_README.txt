Precipitation Interpolation Methods
Instituto Tecnologico de Costa Rica (www.tec.ac.cr)
Maikel Mendez-M (mamendez@itcr.ac.cr);(maikel.mendez@gmail.com)
Luis Alexander Calvo-V (lcalvo@itcr.ac.cr);(lualcava.sa@gmail.com)
This script is structured in R (www.r-project.org)
General purpose: Generate temporal series of average precipitation for a waterbasin using deterministic interpolation methods.
Input files: "interpolation.dat","calibration.dat", "validation.dat",  "blank.asc"
Output files: "log.txt", "output_interpolation.csv","output_calibration.csv" and  "output_mae.csv", "output_rmse.csv"

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
INPUT FILE: attri.txt. File Name must be respected. TAB delimited.

DESCRIPTION: it contains spatial attributes needed to generate a georeference, plus an interpolation precipitation threshold.

Following is a brief description of the variables:

	Column1		Column2
Row0	ATTRIBUTE	VALUE
Row1	spa.res		value
Row2	xmin		value
Row3	xmax		value
Row4	ymin		value
Row5	ymax		value
Row6	goef.col	value
Row7	geof.row	value
Row8	threshold	value

Explanation:

Row0-Column1:	label "ATTRIBUTE" must be respected. Data class: character.
Row1-Column1:	label "spa.res" must be respected. Spatial resolution of the georeference. Metric geographical projection. e.g.: UTM. Data class: character.
Row2-Column1:	label "xmin" must be respected. Minimun X extension of the georeference. Metric geographical projection. e.g.: UTM. Data class: character.
Row3-Column1:	label "xmax" must be respected. Maximun X extension of the georeference. Metric geographical projection. e.g.: UTM. Data class: character.
Row4-Column1:	label "ymin" must be respected. Minimun Y extension of the georeference. Metric geographical projection. e.g.: UTM. Data class: character.
Row5-Column1:	label "ymax" must be respected. Maximun Y extension of the georeference. Metric geographical projection. e.g.: UTM. Data class: character.
Row6-Column1:	label "goef.col" must be respected. Number of columns in georeference. Data class: character.
Row7-Column1:	label "geof.row" must be respected. Number of rows in georeference. Data class: character.
Row8-Column1:	label "threshold" must be respected. Precipitation threshold to execute interpolation (mm/Time). Values below threshold are not interpolated. Data class: character.

Row0-Column2:	Value, Data class: Integer or Numeric. 
Row1-Column2:	Value, Data class: Integer or Numeric. 
Row2-Column2:	Value, Data class: Integer or Numeric. 
Row3-Column2:	Value, Data class: Integer or Numeric. 
Row4-Column2:	Value, Data class: Integer or Numeric. 
Row5-Column2:	Value, Data class: Integer or Numeric. 
Row6-Column2:	Value, Data class: Integer or Numeric. 
Row7-Column2:	Value, Data class: Integer or Numeric. 
Row8-Column2:	Value, Data class: Integer or Numeric. 

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
INPUT FILE: interpolation.txt. File Name must be respected. TAB delimited.

DESCRIPTION: it contains daily or sub-daily precipitation (or any other meteorological variable) observations (records) at specific X, Y and Z points (meteorological stations). Observations must be consistent through the modeled period and no missing values are allowed. A consistent georeference must be defined.
This file contains ALL STATIONS available (or selected) to generate a RasterLayer interpolated surface. Once interpolated, the average precipitation value is calculated and the RasterLayer itself is disregarded (not saved) within the main loop.

Following is a brief description of the variables:

	Column1	Column2		Column3		Columnn
Row0	Name	Name_EST1	Name_EST2	Name_ESTn
Row1	X	UTM		UTM		UTM
Row2	Y	UTM		UTM		UTM
Row3	Z	MASL		MASL		MASL
Row4	Date1	prec.value	prec.value	prec.value
Row5	Date2	prec.value	prec.value	prec.value
Rown	Daten	prec.value	prec.value	prec.value

Explanation:

Row0-Column1:	label "Name" must be respected. Data class: character.
Row1-Column1:	label "X" must be respected. Metric geographical projection. e.g.: UTM. Data class: character.
Row2-Column1:	label "Y" must be respected. Metric geographical projection. e.g.: UTM. Data class: character.
Row3-Column1:	label "Z" must be respected. Metres above sea level. WGS84 geoid. Data class: character.
Row4-Column1:	Julian date (day-month-year) e.g.: 01-01-90. So on up to Rown. Data class: character.

Row0-Column2:	Station name. No blank spaces allowed. Use only "-" or "_". e.g.: Agua_Caliente. So on up to Columnn. Data class: character.
Row1-Column2:	X coordinate. Data class: Integer or Numeric. 
Row2-Column2:	Y coordinate. Data class: Integer or Numeric.
Row3-Column2:	Z elevation. Data class: Integer or Numeric.
Row4-Column2:	Precipitation value. So on up to Columnn. Data class: Integer or Numeric. 

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
INPUT FILE: calibration.txt. File Name must be respected. TAB delimited.

DESCRIPTION: it contains daily or sub-daily precipitation (or any other meteorological variable) observations (records) at specific X, Y and Z points (meteorological stations). Observations must be consistent through the modeled period and no missing values are allowed. A consistent georeference must be defined.
This file contains ONLY a calibration SUBSET of the ALL STATIONS available (or selected) to GENERATE a RasterLayer interpolated surface. Usually 2/3 of the available stations, say 7 out of 10. The same georefence must be used for calibrated interpolation.
Once interpolated, the average precipitation value is calculated and saved (using ONLY the calibration SUBSET) AND the RasterLayer is KEPT for further comparison within the main loop (say validation).

Following is a brief description of the variables: SAME as interpolation.txt. 

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
INPUT FILE: validation.txt. File Name must be respected. TAB delimited.

DESCRIPTION: it contains daily or sub-daily precipitation (or any other meteorological variable) observations (records) at specific X, Y and Z points (meteorological stations). Observations must be consistent through the modeled period and no missing values are allowed. A consistent georeference must be defined.
This file contains ONLY a validation SUBSET of the ALL STATIONS available (or selected) to generate a RasterLayer interpolated surface. Usually 1/3 of the available stations, say 3 out of 10. The same georefence must be used for rasterization.
In this case, prec.values are NOT interpolated but ONLY rasterized. Once rasterized, these prec.values are confronted against the calibration RasterLayer interpolated surface (as same georeference has been used) and then, RMSE + MAE are calculated.

Following is a brief description of the variables: SAME as interpolation.txt. 

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
INPUT FILE: blank.asc. File Name must be respected. SPACE delimited.

DESCRIPTION: universal ESRI-ASCII Grid format used to "blank" the interpolation georeference. It may represent boundary conditions of a waterbasin or a specific sub-basin.
It can be generated by R libraries such as "sp" + "raster" or externally; using for example: ILWIS, QGIS, SAGA, GRASS, etc.

Following is a brief description of the variables: SAME as interpolation.txt. 

The file format is:xxx (Where xxx is a number.)
<NCOLS xxx>
<NROWS xxx>
<XLLCENTER xxx | XLLCORNER xxx>
<YLLCENTER xxx | YLLCORNER xxx>
<CELLSIZE xxx>
{NODATA_VALUE xxx}
row 1
row 2
row n

e.g.

ncols 138
nrows 95
xllcenter 461815
yllcenter 1124046
cellsize 100.00
nodata_value -32767
-32767 -32767 -32767 -32767 -32767 -3276

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
OUTPUT FILE: output_interpolation.csv. COMMA delimited.

DESCRIPTION: average interpolated precipitation value for the blanked georeference (mm/Time) according to included methods and using ALL STATIONS available.

Following is a brief description of the variables:

	Column1	Column2		Column3			Column4			Column5			Column6			Column7			Column8			Column9			Column10
Row0		date.charac	rounded.idw2.all	rounded.idw3.all	rounded.idw4.all	rounded.idw5.all	rounded.ok.all		rounded.ts2.all		rounded.ts2para.all	rounded.ts2linear.all
Row1	1	Date1		value			value			value			value			value			value			value			value
Row2	2	Date2		value			value			value			value			value			value			value			value

Explanation:

Row0-Column1:	Observation sequence number. Data class: Integer.
Row1-Column2:	Julian date (day-month-year). Data class: character.
Row2-Column3:	rounded.idw2.all. Rounded IDW value with EXP=2. Data class: numeric.
Row3-Column4:	rounded.idw3.all. Rounded IDW value with EXP=3. Data class: numeric.
Row4-Column5:	rounded.idw4.all. Rounded IDW value with EXP=4. Data class: numeric.
Row5-Column6:	rounded.idw5.all. Rounded IDW value with EXP=5. Data class: numeric.
Row6-Column7:	rounded.ok.all. Rounded Ordinary Kriging value with regional trend only. Data class: numeric.
Row7-Column8:	rounded.ts2.all. Rounded Trend Surface value with 2nd degree model. Data class: numeric.
Row8-Column9:	rounded.ts2para.all. Rounded Trend Surface value with 2nd degree parabolic model. Data class: numeric.
Row9-Column10:	rounded.ts2linear.all. Rounded Trend Surface value with 2nd degree Linear model. Data class: numeric.

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
OUTPUT FILE: output_calibration.csv. COMMA delimited.

DESCRIPTION: average interpolated precipitation value for the blanked georeference (mm/Time) according to included methods and and using ONLY a calibration SUBSET.

Following is a brief description of the variables: SAME as output_interpolation.csv.

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
OUTPUT FILE: output_rmse.csv. COMMA delimited.

DESCRIPTION: Root Mean Square Error values (mm) according to included methods and and using ONLY a validation SUBSET.

Following is a brief description of the variables:

	Column1	Column2		Column3			Column4			Column5			Column6			Column7			Column8			Column9			Column10
Row0		date.charac	rounded.rmse.idw2	rounded.rmse.idw3	rounded.rmse.idw4	rounded.rmse.idw5	rounded.rmse.ok		rounded.rmse.ts2	rounded.rmse.ts2para	rounded.rmse.ts2linear
Row1	1	Date1		value			value			value			value			value			value			value			value
Row2	2	Date2		value			value			value			value			value			value			value			value

Explanation:

Row0-Column1:	Observation sequence number. Data class: Integer.
Row1-Column2:	Julian date (day-month-year). Data class: character.
Row2-Column3:	rounded.rmse.idw2. Rounded IDW value with EXP=2. Data class: numeric.
Row3-Column4:	rounded.rmse.idw3. Rounded IDW value with EXP=3. Data class: numeric.
Row4-Column5:	rounded.rmse.idw4. Rounded IDW value with EXP=4. Data class: numeric.
Row5-Column6:	rounded.rmse.idw5. Rounded IDW value with EXP=5. Data class: numeric.
Row6-Column7:	rounded.rmse.ok. Rounded Ordinary Kriging value with regional trend only. Data class: numeric.
Row7-Column8:	rounded.rmse.ts2. Rounded Trend Surface value with 2nd degree model. Data class: numeric.
Row8-Column9:	rounded.rmse.ts2para. Rounded Trend Surface value with 2nd degree parabolic model. Data class: numeric.
Row9-Column10:	rounded.rmse.ts2linear. Rounded Trend Surface value with 2nd degree Linear model. Data class: numeric.

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
OUTPUT FILE: output_mae.csv. COMMA delimited.

DESCRIPTION: Mean Absolute Error values (mm) according to included methods and and using ONLY a validation SUBSET.

Following is a brief description of the variables: SAME as output_rmse.csv.

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
OUTPUT FILE: descri_interpolation.csv. COMMA delimited.

DESCRIPTION: Various descriptive statistics ABOUT the output_interpolation.csv data.frame

        Column1 Column2 Column3 Column4
Row0    numeric numeric numeric numeric
Row1    numeric numeric numeric numeric
Row2    numeric numeric numeric numeric
Row3    numeric numeric numeric numeric
Row4    numeric numeric numeric numeric
Row5    numeric numeric numeric numeric
Row6    numeric numeric numeric numeric
Row7    numeric numeric numeric numeric
Row8    numeric numeric numeric numeric
Row9    numeric numeric numeric numeric
Row10   numeric numeric numeric numeric
Row11   numeric numeric numeric numeric
Row12   numeric numeric numeric numeric
Row13   numeric numeric numeric numeric


Following is a brief description of the variables:

Row0-Column1:   nbr.val. Number of values. So on up to Columnn.
Row1-Column1:   nbr.null. Number of null values. So on up to Columnn.
Row2-Column1:   nbr.na. Number of missing values. So on up to Columnn.
Row3-Column1:   min. Minimal value. So on up to Columnn.
Row4-Column1:   max. Maximal value. So on up to Columnn.
Row5-Column1:   range. Range (range, that is, max-min). So on up to Columnn.
Row6-Column1:   sum. Sum of all non-missing values. So on up to Columnn.
Row7-Column1:   median. Median. So on up to Columnn.
Row8-Column1:   mean. Mean. So on up to Columnn.
Row9-Column1:   SE.mean. Standard error on the mean. So on up to Columnn.
Row10-Column1:  CI.mean.0.95. Confidence interval of the mean at 0.95  p-Value level. So on up to Columnn.
Row11-Column1:  var. Variance. So on up to Columnn.
Row12-Column1:  std.dev. Standard deviation. So on up to Columnn.
Row13-Column1:  coef.var. Variation coefficient. So on up to Columnn.

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
OUTPUT FILE: descri_calibration.csv. COMMA delimited.

DESCRIPTION: Various descriptive statistics ABOUT the output_calibration.csv data.frame

Following is a brief description of the variables: SAME as descri_interpolation.csv.

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
OUTPUT FILE: descri_mae.csv. COMMA delimited.

DESCRIPTION: Various descriptive statistics ABOUT the output_mae.csv data.frame

Following is a brief description of the variables: SAME as descri_interpolation.csv.
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

OUTPUT FILE: descri_rmse.csv. COMMA delimited.

DESCRIPTION: Various descriptive statistics ABOUT the output_rmse.csv data.frame

Following is a brief description of the variables: SAME as descri_interpolation.csv.







