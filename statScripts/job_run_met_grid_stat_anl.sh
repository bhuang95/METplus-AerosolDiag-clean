#!/bin/sh
#
# Usage: ./job_run_met_grid_stat_anl.sh
### This script submits multiple jobs of performing statistics averaged over different masks.
###     It compares the forecast and observations and produces statistics
###     (Fbar, Obar, bias, MSE, etc) for following profile and time-series plots.
### Please contact Bo Huang at bo.huang@noaa.gov, if further clarification is needed.

set -x 

proj_account="chem-var"
popts="1/1"

metrun=met_grid_stat_anl

### Define stat output directory
outdir=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NASALUTs-Hongli/aodLUTs_fv3Grid/METplus/METplus-diag//diagOutput/

### Define METplus package directory
export BASE=../METplus_pkg/

### Define directory or pre-processed regular lat-lon grid files. 
export INPUTBASE=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NASALUTs-Hongli/aodLUTs_fv3Grid/data/latlonData/

### Define stat scripts
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

# Define fcst and obs regular lat-lon directories/grid file names, model level, horizontal dimension to be verified. 
export MODELNAME="FV3GLOBAL"
export FCSTDIR=$INPUTBASE/
export FCSTINPUTTMP_aeros="fv3_aeros_{init?fmt=%Y%m%d%H}_pll.nc"
export FCSTLEV_aeros='"(0,0,*,*)","(0,1,*,*)","(0,2,*,*)","(0,3,*,*)","(0,4,*,*)","(0,5,*,*)","(0,6,*,*)","(0,7,*,*)","(0,8,*,*)"'
export FCSTLEV2_aeros='"0,0,*,*","0,1,*,*","0,2,*,*","0,3,*,*","0,4,*,*","0,5,*,*","0,6,*,*","0,7,*,*","0,8,*,*"'

export FCSTINPUTTMP_int="fv3_aeros_int_{init?fmt=%Y%m%d%H}_pll.nc"
export FCSTLEV_int='"(0,0,*,*)"'
export FCSTLEV2_int='"0,0,*,*"'

export OBSNAME="MERRA2"
export OBSDIR=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/METplus-diag/data/MERRA2/pll/
export OBSINPUTTMP_aeros="m2_aeros_{init?fmt=%Y%m%d%H}_pll.nc"
export OBSLEV_aeros='"(0,0,*,*)","(0,1,*,*)","(0,2,*,*)","(0,3,*,*)","(0,4,*,*)","(0,5,*,*)","(0,6,*,*)","(0,7,*,*)","(0,8,*,*)"'
export OBSLEV2_aeros='"0,0,*,*","0,1,*,*","0,2,*,*","0,3,*,*","0,4,*,*","0,5,*,*","0,6,*,*","0,7,*,*","0,8,*,*"'

export OBSINPUTTMP_int="m2_aeros_int_{init?fmt=%Y%m%d%H}_pll.nc"
export OBSLEV_int='"(0,0,*,*)"'
export OBSLEV2_int='"0,0,*,*"'

# set aerosol varibales to be evaluated
#CAMSiRA (EAC4)		MERRA2/GSDChem
#DUSTTOTAL		DUSTTOTAL
#SEASTOTAL		SEASTOTAL
#aermr01		SEASFINE
#aermr02		SEASMEDIUM
#aermr03		SEASCOARSE
#aermr04		DUSTFINE
#aermr05		DUSTMEDIUM
#aermr06		DUSTCOARSE
#aermr07		OCPHILIC
#aermr08		OCPHOBIC
#aermr09		BCPHILIC
#aermr10		BCPHOBIC
#aermr11		SO4
#aod550			AODANA/aod


### Define output directory
WRKDTOP=$outdir/wrk-${MODELNAME}-${OBSNAME}-${SDATE}-${EDATE}-${GRID_DEG}/${metrun}/

### Define corresponding aerosol variable names in the forecast and observation files (they are different sometimes). 
nvars=1
FCSTVARS=(CTOTAL)
OBSVARS=(CTOTAL)
FCSTVARS_int=(CTOTAL_INTEGRAL)
OBSVARS_int=(CTOTAL_INTEGRAL)

### Define the mask for area averaging (FULL NNPAC TROP CONUS EASIA NAFRME RUSC2S SAFRTROP SOCEAN CMAQ)
export MSKLIST="CMAQ"

if [ -d /glade/scratch ]; then
   export machine=Cheyenne
   export subcmd=$BASE/ush/sub_ncar
elif [ -d /scratch1/NCEPDEV/da ]; then
   export machine=Hera
   export subcmd=$BASE/ush/sub_hera
fi

#Process aerosol species
for ((ivar=0;ivar<${nvars};ivar++))
do
    export FCSTVAR=${FCSTVARS[ivar]}
    export FCSTINPUTTMP=${FCSTINPUTTMP_aeros}
    export FCSTLEV=${FCSTLEV_aeros}
    export FCSTLEV2=${FCSTLEV2_aeros}
    export OBSVAR=${OBSVARS[ivar]}
    export OBSINPUTTMP=${OBSINPUTTMP_aeros}
    export OBSLEV=${OBSLEV_aeros}
    export OBSLEV2=${OBSLEV2_aeros}
    export WRKD=${WRKDTOP}/${FCSTVAR}-${OBSVAR}
    export DATA=$WRKD/tmp
    export OUTPUTBASE=${WRKD}

    cd $WRKD
### Submit a job for aerosol species  mixing ratio statistics
    /bin/sh $subcmd -a $proj_account -p $popts -j $metrun-${MODELNAME}.${FCSTVAR}-${OBSNAME}.${OBSVAR} -o ${WRKD}/$metrun-${MODELNAME}.${FCSTVAR}-${OBSNAME}.${OBSVAR}.out -q batch -t 00:09:00 -r /1 ${RUNSCRIPT}

### Submit a job for aerosol species column integral statistics
    export FCSTVAR=${FCSTVARS_int[ivar]}
    export FCSTINPUTTMP=${FCSTINPUTTMP_int}
    export FCSTLEV=${FCSTLEV_int}
    export FCSTLEV2=${FCSTLEV2_int}
    export OBSVAR=${OBSVARS_int[ivar]}
    export OBSINPUTTMP=${OBSINPUTTMP_int}
    export OBSLEV=${OBSLEV_int}
    export OBSLEV2=${OBSLEV2_int}
    export WRKD=${WRKDTOP}/${FCSTVAR}-${OBSVAR}-INTEGRAL
    export DATA=$WRKD/tmp
    export OUTPUTBASE=${WRKD}

    cd $WRKD
    #rm -rf $WRKD/*
    /bin/sh $subcmd -a $proj_account -p $popts -j $metrun-${MODELNAME}.${FCSTVAR}-${OBSNAME}.${OBSVAR} -o ${WRKD}/$metrun-${MODELNAME}.${FCSTVAR}-${OBSNAME}.${OBSVAR}.out -q batch -t 00:09:00 -r /1 ${RUNSCRIPT}
    sleep 1
done


# Process AOD 
sensors='modis_aqua modis_terra'
for sensor in $sensors
do

    export FCSTVAR=aod
    export FCSTINPUTTMP="fv3_aods_${sensor}_{init?fmt=%Y%m%d%H}_ll.nc"
    export FCSTLEV='"(0,0,*,*)"'
    export FCSTLEV2='"0,0,*,*"'

    export OBSVAR=AODANA
    export OBSINPUTTMP="m2_aods_{init?fmt=%Y%m%d%H}_ll.nc"
    export OBSLEV='"(0,*,*)"'
    export OBSLEV2='"0,*,*"'

    export WRKD=${WRKDTOP}/${sensor}-${sensor}
    export DATA=$WRKD/tmp
    export OUTPUTBASE=${WRKD}

    cd $WRKD
    /bin/sh $subcmd -a $proj_account -p $popts -j $metrun-${MODELNAME}.${FCSTVAR}-${OBSNAME}.${OBSVAR} -o ${WRKD}/$metrun-${MODELNAME}.${FCSTVAR}-${OBSNAME}.${OBSVAR}.out -q batch -t 00:09:00 -r /1 ${RUNSCRIPT}
done


exit
