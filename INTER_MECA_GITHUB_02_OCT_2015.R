# Precipitation Interpolation Methods
# Instituto Tecnologico de Costa Rica (www.tec.ac.cr)
# Maikel Mendez-M (mamendez@itcr.ac.cr);(maikel.mendez@gmail.com)
# Luis Alexander Calvo-V (lcalvo@itcr.ac.cr);(lualcava.sa@gmail.com)
# This script is structured in R (www.r-project.org)
# General purpose: Generate temporal series of average precipitation for a waterbasin using
# deterministic and geostatistical interpolation methods.
# Input files: "calibration.dat", "validation.dat", "interpolation.dat", "matrix.dat", "blank.asc"
# Output files: "log.txt", "output_interpolation.csv","output_calibration.csv"
# "output_mae.csv", "output_rmse.csv"

# working directory is defined
setwd ("B:\\R_ITC\\OPTI_SCRIPTS\\INTER_MECA\\INTER_MECA_GITHUB_02_OCT_2015")

# source() and library() statements
require(automap)
require(gstat)
require(lattice)
require(maptools)
require(pastecs)
require(raster)
require(reshape2)
require(rgdal)
require(rgeos)
require(sp)

# Reading various spatial basin-attributes values and parameters
    attri <- read.delim ("attri.txt", header = TRUE, sep = "\t") # Atributes file
  spa.res <- as.numeric(attri[1, 2])  # Selected spatial resolution (m)
     xmin <- as.numeric(attri[2, 2])  # Minimun X extension
     xmax <- as.numeric(attri[3, 2])  # Maximum X extension
     ymin <- as.numeric(attri[4, 2])  # Minimun Y extension
     ymax <- as.numeric(attri[5, 2])  # Maximum Y extension
 goef.col <- as.numeric(attri[6, 2])  # Number of columns in the georeference
 geof.row <- as.numeric(attri[7, 2])  # Number of rows in the georeference
threshold <- as.numeric(attri[8, 2])  # Minimum precipitation-interpolation threshold (mm)

# Reading input files and creating data.frames
inter.all <- read.table("interpolation.dat", header = T, )  # Interpolation file, all stations are included
if (file.exists("calibration.dat") & file.exists("validation.dat")){  # Checks if there is not a subset of the all stations
  inter.cal <- read.table("calibration.dat", header = T, )  # Calibration file, only contains calibration stations
  inter.val <- read.table("validation.dat", header = T, )  # Validation file, only contains validation stations
} else {
  inter.cal <- read.table("interpolation.dat", header = T, )  # Calibration file, only contains calibration stations
  inter.val <- read.table("interpolation.dat", header = T, )  # Validation file, only contains validation stations
}

# Defining spatial data.frame structure
col.classes <- c("double", "double", "double", "double")
  col.names <- c("X", "Y", "Z", "DATE")
  frame.all <- read.table(text = "", colClasses = col.classes, col.names = col.names)  # Interpolation spatial data.frame
  frame.cal <- read.table(text = "", colClasses = col.classes, col.names = col.names)  # Calibration spatial data.frame
  frame.val <- read.table(text = "", colClasses = col.classes, col.names = col.names)  # Validation spatial data.frame

# Reading input data.frames and assigning counters
   n.obs.all <- nrow(inter.all)  # number of data rows for interpolation
n.points.all <- ncol(inter.all)  # number of columns for interpolation
   n.obs.cal <- nrow(inter.cal)  # number of data rows for calibration
n.points.cal <- ncol(inter.cal)  # number of columns for calibration
   n.obs.val <- nrow(inter.val)  # number of data rows for validation
n.points.val <- ncol(inter.val)  # number of columns for validation

# Completing values for interpolation spatial data.frame 
for (i in 1:(n.points.all - 1)) {
  frame.all [i, 1] <- inter.all[1, 1 + i]
  frame.all [i, 2] <- inter.all[2, 1 + i]
  frame.all [i, 3] <- inter.all[3, 1 + i]
  frame.all [i, 4] <- inter.all[4, 1 + i]
}

# Completing values for calibration spatial data.frame
for (i in 1:(n.points.cal - 1)) {
  frame.cal [i, 1] <- inter.cal[1, 1 + i]
  frame.cal [i, 2] <- inter.cal[2, 1 + i]
  frame.cal [i, 3] <- inter.cal[3, 1 + i]
  frame.cal [i, 4] <- inter.cal[4, 1 + i]
}

# Completing values for validation spatial data.frame
for (i in 1:(n.points.val - 1)) {
  frame.val [i, 1] <- inter.val[1, 1 + i]
  frame.val [i, 2] <- inter.val[2, 1 + i]
  frame.val [i, 3] <- inter.val[3, 1 + i]
  frame.val [i, 4] <- inter.val[4, 1 + i]
}

# Coordinates are assigned and transformed into SpatialPointsDataFrame
coordinates(frame.all) <- c("X", "Y")
coordinates(frame.cal) <- c("X", "Y")
coordinates(frame.val) <- c("X", "Y")

# An empty data.frame is created with a selected resolution
# The extent of this SpatialGrid is valid only for waterbasin under analysis
georef <- expand.grid(X = seq(xmin, xmax, by = spa.res), Y = seq(ymin, ymax, by = spa.res), KEEP.OUT.ATTRS = F)

coordinates(georef) <- ~X + Y  # The empty data.frame is converted into SpatialPoints

# An empty SpatialGrid is created with a selected resolution
# The extent of this SpatialGrid is valid only for waterbasin under analysis
basin.grid <- SpatialGrid(GridTopology(c(X = xmin, Y = ymin), c(spa.res, spa.res), c(goef.col, geof.row)))
basin.grid <- SpatialPoints(basin.grid)  # The empty SpatialGrid is converted into SpatialPoints
gridded(basin.grid) <- T  # The empty SpatialGrid is converted into SpatialPixels

       blank <- paste("blank.asc", sep = "/")  # The *.ASC map is imported from GIS to be used as a black or mask
  blank.grid <- read.asciigrid(blank, as.image = FALSE)  # The map is transformed into SpatialGridDataFrame
blank.raster <- raster(blank.grid)  # The map is transformed into RasterLayer
image(blank.raster, main = "*.ASC Blanking Map", col = topo.colors(64)) # The map is printed as verification
                                                                        
# data.frames that will contain the output of the interpolation process are defined
          mae.dataframe <- NULL  # MAE (Mean Absolute Error)
         rmse.dataframe <- NULL  # RMSE (Root Mean Square Error)
  calibration.dataframe <- NULL
interpolation.dataframe	<- NULL

# The start time of the process is saved
start.time <- Sys.time()

# Main counter is defined
counter.main <- (n.obs.all - 3)

# Main loop is initialized
for (i in 1:counter.main) {
  
  # Completing values for interpolation spatial data.frame within the main loop
  for (a in 1:(n.points.all - 1)) {
    frame.all [a, 2] <- inter.all[i + 3, a + 1]
  }
  
  # Completing values for calibration spatial data.frame within the main loop
  for (c in 1:(n.points.cal - 1)) {
    frame.cal [c, 2] <- inter.cal[i + 3, c + 1]
  }
  
  # Completing values for validation spatial data.frame within the main loop
  for (v in 1:(n.points.val - 1)) {
    frame.val [v, 2] <- inter.val[i + 3, v + 1]
  }
 
  # Interpolation counters are defined
  counter.all <- paste(names(frame.all[2]), "~1", sep = "")
  counter.cal <- paste(names(frame.cal[2]), "~1", sep = "")
  
  # The mean of the vertical data.frame for interpolation should be above the defined threshold
  if ((mean(frame.all$DATE)) > threshold) {
    
  # Total Interpolation Methods
         idw2.all <- idw(as.formula(counter.all),
                         loc = frame.all, newdata = basin.grid, idp = 2)  # Inverse Distance Weighting Exp 2
         idw3.all <- idw(as.formula(counter.all),
                         loc = frame.all, newdata = basin.grid, idp = 3)  # Inverse Distance Weighting Exp 3
         idw4.all <- idw(as.formula(counter.all),
                         loc = frame.all, newdata = basin.grid, idp = 4)  # Inverse Distance Weighting Exp 4
         idw5.all <- idw(as.formula(counter.all),
                         loc = frame.all, newdata = basin.grid, idp = 5)  # Inverse Distance Weighting Exp 5
           ok.all <- krige(as.formula(counter.all),
                           loc = frame.all, newdata = basin.grid, model = NULL)  # Ordinary Kriging with Regional Trend Only
          ts2.all <- krige((frame.all[[2]]) ~ (I(X ^ 2) + I(Y ^ 2) + (abs(X * Y)) + X + Y),
                            frame.all, newdata = basin.grid, model = NULL)  # Trend Surface 2nd degree
      ts2para.all <- krige((frame.all[[2]]) ~ (I(X ^ 2) + I(Y ^ 2) + X + Y),
                            frame.all, newdata = basin.grid, model = NULL)  # Trend Surface 2nd degree Parabolic
    ts2linear.all <- krige((frame.all[[2]]) ~ ((abs(X * Y)) + X + Y),
                            frame.all, newdata = basin.grid, model = NULL)  # Trend Surface 2nd degree Linear
    
    # SpatialPixelsDataFrames are converted into RasterLayers
         idw2.all.raster <- raster(idw2.all)
         idw3.all.raster <- raster(idw3.all)
         idw4.all.raster <- raster(idw4.all)
         idw5.all.raster <- raster(idw5.all)
           ok.all.raster <- raster(ok.all)
          ts2.all.raster <- raster(ts2.all)
      ts2para.all.raster <- raster(ts2para.all)
    ts2linear.all.raster <- raster(ts2linear.all)
    
    # The resampling is defined based on idw2.cal.raster
    resampling <- resample(blank.raster, idw2.all.raster, resample = 'bilinear')
    
    # RasterLayers are created after cutting
         mask.idw2.all <- mask(idw2.all.raster, resampling)
         mask.idw3.all <- mask(idw3.all.raster, resampling)
         mask.idw4.all <- mask(idw4.all.raster, resampling)
         mask.idw5.all <- mask(idw5.all.raster, resampling)
           mask.ok.all <- mask(ok.all.raster, resampling)
          mask.ts2.all <- mask(ts2.all.raster, resampling)
      mask.ts2para.all <- mask(ts2para.all.raster, resampling)
    mask.ts2linear.all <- mask(ts2linear.all.raster, resampling)
    
    # The mean is extracted from the RasterLayers
         mean.idw2.all <- cellStats(mask.idw2.all, mean)
         mean.idw3.all <- cellStats(mask.idw3.all, mean)
         mean.idw4.all <- cellStats(mask.idw4.all, mean)
         mean.idw5.all <- cellStats(mask.idw5.all, mean)
           mean.ok.all <- cellStats(mask.ok.all, mean)
          mean.ts2.all <- cellStats(mask.ts2.all, mean)
      mean.ts2para.all <- cellStats(mask.ts2para.all, mean)
    mean.ts2linear.all <- cellStats(mask.ts2linear.all, mean)
    
    # The mean is rounded to three significant digits
         rounded.idw2.all <- round(mean.idw2.all, 3)
         rounded.idw3.all <- round(mean.idw3.all, 3)
         rounded.idw4.all <- round(mean.idw4.all, 3)
         rounded.idw5.all <- round(mean.idw5.all, 3)
           rounded.ok.all <- round(mean.ok.all, 3)
          rounded.ts2.all <- round(mean.ts2.all, 3)
      rounded.ts2para.all <- round(mean.ts2para.all, 3)
    rounded.ts2linear.all <- round(mean.ts2linear.all, 3)
    
    # All negative values are converted into 0
    if (rounded.idw2.all < 0)
        rounded.idw2.all <- 0
    if (rounded.idw3.all < 0)
        rounded.idw3.all <- 0
    if (rounded.idw4.all < 0)
        rounded.idw4.all <- 0
    if (rounded.idw5.all < 0)
        rounded.idw5.all <- 0
    if (rounded.ok.all < 0)
        rounded.ok.all <- 0
    if (rounded.ts2.all < 0)
        rounded.ts2.all <- 0
    if (rounded.ts2para.all < 0)
        rounded.ts2para.all <- 0
    if (rounded.ts2linear.all < 0)
        rounded.ts2linear.all <- 0
    
    # Interpolation Methods for calibration
         idw2.cal <- idw(as.formula(counter.cal), 
                         loc = frame.cal, newdata = basin.grid, idp = 2)  # Inverse Distance Weighting Exp 2
         idw3.cal <- idw(as.formula(counter.cal), 
                         loc = frame.cal, newdata = basin.grid, idp = 3)  # Inverse Distance Weighting Exp 3
         idw4.cal <- idw(as.formula(counter.cal), 
                         loc = frame.cal, newdata = basin.grid, idp = 4)  # Inverse Distance Weighting Exp 4
         idw5.cal <- idw(as.formula(counter.cal), 
                         loc = frame.cal, newdata = basin.grid, idp = 5)  # Inverse Distance Weighting Exp 5
           ok.cal <- krige(as.formula(counter.cal), 
                           loc = frame.cal, newdata = basin.grid, model = NULL)  # Ordinary Kriging with Regional Trend Only
          ts2.cal <- krige((frame.cal[[2]]) ~ (I(X ^ 2) + I(Y ^ 2) + (abs(X * Y)) + X + Y), 
                            frame.cal, newdata = basin.grid, model = NULL)  # Trend Surface 2nd degree
      ts2para.cal <- krige((frame.cal[[2]]) ~ (I(X ^ 2) + I(Y ^ 2) + X + Y), 
                           frame.cal, newdata = basin.grid, model = NULL)  # Trend Surface 2nd degree Parabolic
    ts2linear.cal <- krige((frame.cal[[2]]) ~ ((abs(X * Y)) + X + Y), 
                           frame.cal, newdata = basin.grid, model = NULL)  # Trend Surface 2nd degree Linear
    
    # SpatialPixelsDataFrames are converted into RasterLayer
         idw2.cal.raster <- raster(idw2.cal)
         idw3.cal.raster <- raster(idw3.cal)
         idw4.cal.raster <- raster(idw4.cal)
         idw5.cal.raster <- raster(idw5.cal)
           ok.cal.raster <- raster(ok.cal)
          ts2.cal.raster <- raster(ts2.cal)
      ts2para.cal.raster <- raster(ts2para.cal)
    ts2linear.cal.raster <- raster(ts2linear.cal)
    
    # RasterLayers are created after cutting
         mask.idw2.cal <- mask(idw2.cal.raster, resampling)
         mask.idw3.cal <- mask(idw3.cal.raster, resampling)
         mask.idw4.cal <- mask(idw4.cal.raster, resampling)
         mask.idw5.cal <- mask(idw5.cal.raster, resampling)
           mask.ok.cal <- mask(ok.cal.raster, resampling)
          mask.ts2.cal <- mask(ts2.cal.raster, resampling)
      mask.ts2para.cal <- mask(ts2para.cal.raster, resampling)
    mask.ts2linear.cal <- mask(ts2linear.cal.raster, resampling)
    
    # The mean is extracted from the RasterLayers
         mean.idw2.cal <- cellStats(mask.idw2.cal, mean)
         mean.idw3.cal <- cellStats(mask.idw3.cal, mean)
         mean.idw4.cal <- cellStats(mask.idw4.cal, mean)
         mean.idw5.cal <- cellStats(mask.idw5.cal, mean)
           mean.ok.cal <- cellStats(mask.ok.cal, mean)
          mean.ts2.cal <- cellStats(mask.ts2.cal, mean)
      mean.ts2para.cal <- cellStats(mask.ts2para.cal, mean)
    mean.ts2linear.cal <- cellStats(mask.ts2linear.cal, mean)
    
    # The mean is rounded to three significant digits
         rounded.idw2.cal <- round(mean.idw2.cal, 3)
         rounded.idw3.cal <- round(mean.idw3.cal, 3)
         rounded.idw4.cal <- round(mean.idw4.cal, 3)
         rounded.idw5.cal <- round(mean.idw5.cal, 3)
           rounded.ok.cal <- round(mean.ok.cal, 3)
          rounded.ts2.cal <- round(mean.ts2.cal, 3)
      rounded.ts2para.cal <- round(mean.ts2para.cal, 3)
    rounded.ts2linear.cal <- round(mean.ts2linear.cal, 3)
    
    # All negative values are converted into 0
    if (rounded.idw2.cal < 0)
        rounded.idw2.cal <- 0
    if (rounded.idw3.cal < 0)
        rounded.idw3.cal <- 0
    if (rounded.idw4.cal < 0)
        rounded.idw4.cal <- 0
    if (rounded.idw5.cal < 0)
        rounded.idw5.cal <- 0
    if (rounded.ok.cal < 0)
        rounded.ok.cal <- 0
    if (rounded.ts2.cal < 0)
        rounded.ts2.cal <- 0
    if (rounded.ts2para.cal < 0)
        rounded.ts2para.cal <- 0
    if (rounded.ts2linear.cal < 0)
        rounded.ts2linear.cal <- 0
    
    # Point cross validation
    raster.georef <- raster(basin.grid)  # The grid is converted into RasterLayer
       ext.raster <- frame.val[2]  # Date and hour are extracted
     point.raster <- rasterize(ext.raster, raster.georef)  # Point values are rasterized
    
    # The layers are disaggregated from the point.raster
    upper.layer <- unstack(point.raster)
    lower.layer <- upper.layer[[2]]
    
    # The Mean Absolute Error is calculated
         mae.idw2 <- abs(lower.layer - (idw2.cal.raster))
         mae.idw3 <- abs(lower.layer - (idw3.cal.raster))
         mae.idw4 <- abs(lower.layer - (idw4.cal.raster))
         mae.idw5 <- abs(lower.layer - (idw5.cal.raster))
           mae.ok <- abs(lower.layer - (ok.cal.raster))
          mae.ts2 <- abs(lower.layer - (ts2.cal.raster))
      mae.ts2para <- abs(lower.layer - (ts2para.cal.raster))
    mae.ts2linear <- abs(lower.layer - (ts2linear.cal.raster))
    
    # The mean value of deviations is determined
         mean.mae.idw2 <- cellStats(mae.idw2, (mean))
         mean.mae.idw3 <- cellStats(mae.idw3, (mean))
         mean.mae.idw4 <- cellStats(mae.idw4, (mean))
         mean.mae.idw5 <- cellStats(mae.idw5, (mean))
           mean.mae.ok <- cellStats(mae.ok, (mean))
          mean.mae.ts2 <- cellStats(mae.ts2, (mean))
      mean.mae.ts2para <- cellStats(mae.ts2para, (mean))
    mean.mae.ts2linear <- cellStats(mae.ts2linear, (mean))
    
    # The mean is rounded to three significant digits
         rounded.mae.idw2 <- round(mean.mae.idw2, 3)
         rounded.mae.idw3 <- round(mean.mae.idw3, 3)
         rounded.mae.idw4 <- round(mean.mae.idw4, 3)
         rounded.mae.idw5 <- round(mean.mae.idw5, 3)
           rounded.mae.ok <- round(mean.mae.ok, 3)
          rounded.mae.ts2 <- round(mean.mae.ts2, 3)
      rounded.mae.ts2para <- round(mean.mae.ts2para, 3)
    rounded.mae.ts2linear <- round(mean.mae.ts2linear, 3)
    
    # The Root Mean Square Error is calculated
         rmse.idw2 <- (lower.layer - (idw2.cal.raster)) ^ 2
         rmse.idw3 <- (lower.layer - (idw3.cal.raster)) ^ 2
         rmse.idw4 <- (lower.layer - (idw4.cal.raster)) ^ 2
         rmse.idw5 <- (lower.layer - (idw5.cal.raster)) ^ 2
           rmse.ok <- (lower.layer - (ok.cal.raster)) ^ 2
          rmse.ts2 <- (lower.layer - (ts2.cal.raster)) ^ 2
      rmse.ts2para <- (lower.layer - (ts2para.cal.raster)) ^ 2
    rmse.ts2linear <- (lower.layer - (ts2linear.cal.raster)) ^ 2
    
    # The mean value of deviations is determined
         mean.rmse.idw2 <- (cellStats(rmse.idw2, (mean))) ^ 0.5
         mean.rmse.idw3 <- (cellStats(rmse.idw3, (mean))) ^ 0.5
         mean.rmse.idw4 <- (cellStats(rmse.idw4, (mean))) ^ 0.5
         mean.rmse.idw5 <- (cellStats(rmse.idw5, (mean))) ^ 0.5
           mean.rmse.ok <- (cellStats(rmse.ok, (mean))) ^ 0.5
          mean.rmse.ts2 <- (cellStats(rmse.ts2, (mean))) ^ 0.5
      mean.rmse.ts2para <- (cellStats(rmse.ts2para, (mean))) ^ 0.5
    mean.rmse.ts2linear <- (cellStats(rmse.ts2linear, (mean))) ^ 0.5
    
    # The mean is rounded to three significant digits
         rounded.rmse.idw2 <- round(mean.rmse.idw2, 3)
         rounded.rmse.idw3 <- round(mean.rmse.idw3, 3)
         rounded.rmse.idw4 <- round(mean.rmse.idw4, 3)
         rounded.rmse.idw5 <- round(mean.rmse.idw5, 3)
           rounded.rmse.ok <- round(mean.rmse.ok, 3)
          rounded.rmse.ts2 <- round(mean.rmse.ts2, 3)
      rounded.rmse.ts2para <- round(mean.rmse.ts2para, 3)
    rounded.rmse.ts2linear <- round(mean.rmse.ts2linear, 3)
  }
  else {
         rounded.idw2.all <- 0
         rounded.idw3.all <- 0
         rounded.idw4.all <- 0
         rounded.idw5.all <- 0
           rounded.ok.all <- 0
          rounded.ts2.all <- 0
      rounded.ts2para.all <- 0
    rounded.ts2linear.all <- 0
    
         rounded.idw2.cal <- 0
         rounded.idw3.cal <- 0
         rounded.idw4.cal <- 0
         rounded.idw5.cal <- 0
           rounded.ok.cal <- 0
          rounded.ts2.cal <- 0
      rounded.ts2para.cal <- 0
    rounded.ts2linear.cal <- 0
    
         rounded.mae.idw2 <- 0
         rounded.mae.idw3 <- 0
         rounded.mae.idw4 <- 0
         rounded.mae.idw5 <- 0
           rounded.mae.ok <- 0
          rounded.mae.ts2 <- 0
      rounded.mae.ts2para <- 0
    rounded.mae.ts2linear <- 0
    
         rounded.rmse.idw2 <- 0
         rounded.rmse.idw3 <- 0
         rounded.rmse.idw4 <- 0
         rounded.rmse.idw5 <- 0
           rounded.rmse.ok <- 0
          rounded.rmse.ts2 <- 0
      rounded.rmse.ts2para <- 0
    rounded.rmse.ts2linear <- 0
  }
  
  date.charac <- as.character (inter.all [i + 3, 1]) # Date is saved as character
  
  # Interpolation output data.frame is completed and saved
  interpolation.dataframe <- rbind(interpolation.dataframe, data.frame(date.charac, rounded.idw2.all, rounded.idw3.all,
                                                                       rounded.idw4.all, rounded.idw5.all, rounded.ok.all,
                                                                       rounded.ts2.all, rounded.ts2para.all,
                                                                       rounded.ts2linear.all))
  write.csv(interpolation.dataframe, file = "output_interpolation.csv")
  
  # Calibration output data.frame is completed and saved
  calibration.dataframe = rbind(calibration.dataframe, data.frame(date.charac, rounded.idw2.cal, rounded.idw3.cal,
                                                                  rounded.idw4.cal, rounded.idw5.cal, rounded.ok.cal,
                                                                  rounded.ts2.cal, rounded.ts2para.cal, 
                                                                  rounded.ts2linear.cal))
  write.csv(calibration.dataframe, file = "output_calibration.csv")
  
  # MAE output data.frame is completed and saved
  mae.dataframe <- rbind(mae.dataframe, data.frame(date.charac, rounded.mae.idw2, rounded.mae.idw3, rounded.mae.idw4,
                                                   rounded.mae.idw5, rounded.mae.ok, rounded.mae.ts2, rounded.mae.ts2para,
                                                   rounded.mae.ts2linear))
  write.csv(mae.dataframe, file = "output_mae.csv")
  
  # RSME output data.frame is completed and saved
  rmse.dataframe <- rbind(rmse.dataframe, data.frame(date.charac, rounded.rmse.idw2, rounded.rmse.idw3, 
                                                     rounded.rmse.idw4, rounded.rmse.idw5, rounded.rmse.ok,
                                                     rounded.rmse.ts2, rounded.rmse.ts2para, rounded.rmse.ts2linear))
  write.csv(rmse.dataframe, file = "output_rmse.csv")

}

# A descriptive statistics data.frame for interpolation is created and saved
interpolation.descri <- round(stat.desc(interpolation.dataframe [, 2 : 9]), 3)
write.csv(interpolation.descri, file = "descri_interpolation.csv")

# A descriptive statistics data.frame for calibration is created and saved
calibration.descri <- round(stat.desc(calibration.dataframe [, 2 : 9]), 3)
write.csv(calibration.descri, file = "descri_calibration.csv")

# A descriptive statistics data.frame for MAE is created and saved
mae.descri <- round(stat.desc(mae.dataframe [, 2 : 9]), 3)
write.csv(mae.descri, file = "descri_mae.csv")

# A descriptive statistics data.frame for RMSE is created and saved
rmse.descri <- round(stat.desc(rmse.dataframe [, 2 : 9]), 3)
write.csv(rmse.descri, file = "descri_rmse.csv")

# End time is saved
  end.time <- Sys.time()
time.taken <- end.time - start.time
print(time.taken)
