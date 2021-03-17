#!/bin/bash --login
##!/bin/sh --login

#SBATCH --account=chem-var
#SBATCH --qos=debug
#SBATCH --nodes=1 --ntasks-per-node=1 --cpus-per-task=1
#SBATCH --time=00:29:00
#SBATCH --job-name=timeSeries
#SBATCH --output=pythonJob.out

### This script plots the 2D lat-lon global stats of aerosol column integral (plt_2d_time_series.py).
##      Its input incldue stat files from two METplus met_series_anl runs (e.g., MODELNAME-OBSNAME, 
###      and MODELNAME1-OBSNAME1). This is necessary. It depends on where the fileds to be verified
###      are located. One METplus met_series_anl run is enough if it contains all the fields to be 
###      verified. The python ploting will produce six figures including
###                 top panel:     2D lat-lon global aerosol column integral 
###                 middle panel:  2D lat-lon global aerosol column integral bias of two verified fields
###                 bottom panel:  2D lat-lon global aerosol column integral bias of two verified fields
###      So please modiffy this script and the python plotting script according to your applications. 
###
### Please contact Bo Huang at bo.huang@noaa.gov, if further clarification is needed. 


export OMP_NUM_THREADS=1

set -x 

module use -a /contrib/anaconda/modulefiles
module load anaconda/latest

### Define the stat directories/files from the METplus met_series_anl run
EXPDIR="/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NASALUTs-Hongli/aodLUTs_fv3Grid/METplus/METplus-diag/diagOutput"
MODELNAME="FV3GLOBAL"
MODELNAME1="FV3GLOBAL"
OBSNAME="MERRA2"
OBSNAME1="MERRA2"


### Define the start/end cycles and cycle increment is defined in the python script
CYCS="2016062100"
CYCE="2016062118"

### Define METplus stats resolution
GRID="1.0deg"
SUFFIX=${CYCS}-${CYCE}-${GRID}

### Define the variables to be verified for each fcst and obs. 
nvars=1
FCSTVARS_int=(CTOTAL_INTEGRAL)
FCSTVARS1_int=(CTOTAL_INTEGRAL)
OBSVARS_int=(CTOTAL_INTEGRAL)
OBSVARS1_int=(CTOTAL_INTEGRAL)

### Loop through for plotting column integral of different aerosol species
for ((ivar=0;ivar<${nvars};ivar++))
do

    FCSTVAR_int=${FCSTVARS_int[ivar]}
    FCSTVAR1_int=${FCSTVARS_int[ivar]}
    OBSVAR_int=${OBSVARS_int[ivar]}
    OBSVAR1_int=${OBSVARS1_int[ivar]}

    tmpfile1=${EXPDIR}/wrk-${MODELNAME}-${OBSNAME}-${SUFFIX}/met_series_anl/${FCSTVAR}-${OBSVAR}/met_tool_wrapper/SeriesAnalysis/${FCSTVAR}_sigLevhPa.nc
    tmpfile2=${EXPDIR}/wrk-${MODELNAME1}-${OBSNAME1}-${SUFFIX}/met_series_anl/${FCSTVAR1}-${OBSVAR1}/met_tool_wrapper/SeriesAnalysis/${FCSTVAR1}_sigLevhPa.nc
    tmpfile1_int=${EXPDIR}/wrk-${MODELNAME}-${OBSNAME}-${SUFFIX}/met_series_anl/${FCSTVAR_int}-${OBSVAR_int}-INTEGRAL/met_tool_wrapper/SeriesAnalysis/${FCSTVAR_int}_sigLevhPa.nc
    tmpfile2_int=${EXPDIR}/wrk-${MODELNAME1}-${OBSNAME1}-${SUFFIX}/met_series_anl/${FCSTVAR1_int}-${OBSVAR1_int}-INTEGRAL/met_tool_wrapper/SeriesAnalysis/${FCSTVAR1_int}_sigLevhPa.nc
    python ./plt_2d_time_series.py ${MODELNAME} ${FCSTVAR_int} ${tmpfile1_int} ${tmpfile2_int} 

    PLOTDIR=${MODELNAME}-${MODELNAME1}-${OBSNAME}-${OBSNAME1}-${SUFFIX}/${FCSTVAR_int}-${OBSVAR_int}
    mkdir -p ${PLOTDIR}
    mv *.png ${PLOTDIR}
done

### Define AOD variable name and plot AOD 2Dmap
sensors='modis_aqua modis_terra'

FCSTVAR_aod="aod"
FCSTVAR1_aod="aod"
OBSVAR_aod="AODANA"
OBSVAR1_aod="AODANA"
for sensor in ${sensors}
do

    tmpfile1=${EXPDIR}/wrk-${MODELNAME}-${OBSNAME}-${SUFFIX}/met_series_anl/${sensor}-${sensor}/met_tool_wrapper/SeriesAnalysis/${FCSTVAR_aod}_sigLevhPa.nc
    tmpfile2=${EXPDIR}/wrk-${MODELNAME1}-${OBSNAME1}-${SUFFIX}/met_series_anl/${sensor}-${sensor}/met_tool_wrapper/SeriesAnalysis/${FCSTVAR1_aod}_sigLevhPa.nc
    python ./plt_2d_time_series_aod.py ${MODELNAME} ${sensor} ${FCSTVAR_aod} ${tmpfile1} ${tmpfile2}
    PLOTDIR=${MODELNAME}-${MODELNAME1}-${OBSNAME}-${OBSNAME1}-${SUFFIX}/${sensor}-${sensor}
    mkdir -p ${PLOTDIR}
    mv *.png ${PLOTDIR}
done

exit $?
