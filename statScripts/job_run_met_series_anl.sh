#!/bin/sh
#
# Usage: ./job_run_met_series_anl.sh
# BASE: The path
# INPUTBASE: the path saved dataset files.
### This script submits multiple jobs of performing 2D lat-lon map statistics 
###     averaged over all cycling period at different model levels. 
###     It compares the forecast and observations and produces statistics 
###     (Fbar, Obar, bias, MSE, etc) for subsequent 2D lat-lon map plots.
### Please contact Bo Huang at bo.huang@noaa.gov, if further clarification is needed.

set -x 

proj_account="chem-var"
popts="1/1"

metrun=met_series_anl

### Define METplus package directory
export BASE=../METplus_pkg/

### Define stat output directory
outdir=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NASALUTs-Hongli/aodLUTs_fv3Grid/METplus/METplus-diag/diagOutput


### Define directory or pre-processed regular lat-lon grid files. 
export INPUTBASE=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NASALUTs-Hongli/aodLUTs_fv3Grid/data/latlonData/

### Define stat script
curdir=`pwd`
export RUNSCRIPT=${curdir}/${metrun}.sh

### Define start/end cycles and cycle increment.
export SDATE=2016062100
export EDATE=2016062118
export INC_H=6

#define model resolution for stat
export GRID_NAME="G003"
GRID_DEG="1.0deg"
#export GRID_NAME="G002"
#GRID_DEG="2.5deg"

# Define fcst and obs regular lat-lon directories/grid files/dimensions 
export FCST_NAME="FV3GLOBAL"
export FCSTPATH=$INPUTBASE
export FCST_HEAD_int="fv3_aeros_int_"
export FCST_SUFF_int="_pll.nc"
export FCST_VARDIM_int="4"

export OBS_NAME="MERRA2"
export OBSPATH=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/METplus-diag/data/MERRA2/pll/
export OBS_HEAD_int="m2_aeros_int_"
export OBS_SUFF_int="_pll.nc"
export OBS_VARDIM_int="4"

### Define output directory
WRKDTOP=$outdir/wrk-${FCST_NAME}-${OBS_NAME}-${SDATE}-${EDATE}-${GRID_DEG}/${metrun}/

### Define corresponding variable names in the forecast and observation files (they are different sometimes).
if [ -d /glade/scratch ]; then
   export machine=Cheyenne
   export subcmd=$BASE/ush/sub_ncar
elif [ -d /scratch1/NCEPDEV/da ]; then
   export machine=Hera
   export subcmd=$BASE/ush/sub_hera
fi


### Define corresponding variable names in the forecast and observation files (they are different sometimes).
nvars=1
FCSTVARS_int=(CTOTAL_INTEGRAL)
OBSVARS_int=(CTOTAL_INTEGRAL)

#Process aerosol species
nvars=0
for ((ivar=0;ivar<${nvars};ivar++))
do

    export FCST_VAR=${FCSTVARS_int[ivar]}
    export FCST_VARDIM=${FCST_VARDIM_int}
    export FCST_HEAD=${FCST_HEAD_int}
    export FCST_SUFF=${FCST_SUFF_int}
    export OBS_VAR=${OBSVARS_int[ivar]}
    export OBS_VARDIM=${OBS_VARDIM_int}
    export OBS_HEAD=${OBS_HEAD_int}
    export OBS_SUFF=${OBS_SUFF_int}
    export WRKD=${WRKDTOP}/${FCST_VAR}-${OBS_VAR}-INTEGRAL
    export DATA=$WRKD/tmp
    export OUTPUTBASE=${WRKD}
    export SIGLEV="TRUE"

### Submit a job for aerosol species 2D lat-lon map column integral statistics
    cd $WRKD
    /bin/sh $subcmd -a $proj_account -p $popts -j $metrun-${FCST_NAME}.${FCST_VAR}-${OBS_NAME}.${OBS_VAR} -o ${WRKD}/$metrun-${FCST_NAME}.${FCST_VAR}-${OBS_NAME}.${OBS_VAR}.out -q batch -t 00:09:00 -r /1 ${RUNSCRIPT}
    sleep 1
done

# Process AOD
sensors='modis_aqua modis_terra'
for sensor in ${sensors}
do

    export FCST_VAR=aod
    export FCST_VARDIM="4"
    export FCST_HEAD="fv3_aods_${sensor}_"
    export FCST_SUFF="_ll.nc"

    export OBS_VAR=AODANA
    export OBS_VARDIM="3"
    export OBS_HEAD="m2_aods_"
    export OBS_SUFF="_ll.nc"

export WRKD=${WRKDTOP}/${sensor}-${sensor}
export DATA=$WRKD/tmp
export OUTPUTBASE=${WRKD}
export SIGLEV="TRUE"

cd $WRKD
#rm -rf $WRKD/*
/bin/sh $subcmd -a $proj_account -p $popts -j $metrun-${FCST_NAME}.${FCST_VAR}-${OBS_NAME}.${OBS_VAR} -o ${WRKD}/$metrun-${FCST_NAME}.${FCST_VAR}-${OBS_NAME}.${OBS_VAR}.out -q batch -t 00:09:00 -r /1 ${RUNSCRIPT}
done

exit
