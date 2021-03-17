------ READ-ME file for the aerosol/AOD diagnostics using METplus software ------

This repository includes scripts for diagnostics of aerosol species and aerosol optical depth (AOD) using the Model Evaluation Tools plus (METplus) software developed by the Developmental Testbed Center. 

--- Contributed by Bo Huang and Mariusz Pagowski from CU/CIRES and NOAA/GSL and and Shih-Wei Wei and Sarah Lu from University at Albany. 

--- Contact information: bo.huang@noaa.gov

--- If you plan to utilize this package for your work, please acknowledge our contributions in your future presentations/publications. 

--- Notes: 

    -- Currently, this package is only ready for use on NOAA HERA HPC, because of the required libraries and executables.
    
    -- It is only tested for global model. This package is under development and will include more capabilities and improve general flexibility.

--- Repository description:   

    1. calcAOD-NASALUTs/
	(1.a) job_NODA_AOD_LUTs.sh: calculate AOD using NASA look-up tables (LUTs) and the FV3-grid NetCDF files from the UFS-GOCART model. 

    2. fv32pll/
	(2.a) job_fv32pll.sh: convert FV3-grid files to regular 2D lat-lon files and calculate column integral of aerosol species. 

    3. METplus_pkg/
	(3.a) masks/nc_mask contains NetCDF files to define regions over the global for following statistics. 

    4. statScripts/
	(4.a) job_run_met_grid_stat_anl.sh: submit multiple jobs to perform statistics (e.g., mean, bias, MSE) over different aerosol species, different masks and different model levels.
	(4.b) job_run_met_series_anl.sh: submit multiple jobs to perform time-averaged statistics (e.g., mean, bias, MSE). 

    (5) plotScripts/
	(5.a) plot-vertProfile-timeSeries/job_python.sh: use the statistics data from (4.a) to plot vertical profiles of aerosol mixing ratio and time series of column integral of aerosol species and AOD over different masks/regions.
	(5.b) plot-2DMapTimeMean/job_python.sh: use the statistics data from (4.b) to plot 2D lat-lon aerosol species/AOD mean/bias/mse. 
	(5.c) please modify the corresponding python scripts under the directories in (5.a) and (5.b) to have correct legends and scales in the plots.  
