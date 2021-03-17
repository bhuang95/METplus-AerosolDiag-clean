#!/bin/bash --login
##!/bin/sh --login

#SBATCH --account=chem-var
#SBATCH --qos=batch
##SBATCH --nodes=1 --ntasks-per-node=1 --cpus-per-task=1
#SBATCH -n 1
#SBATCH --time=00:29:00
#SBATCH --job-name=pythonJob
#SBATCH --output=pythonJob.out

### This scripts plots the vertical profiles and time-series of aerosol mixing ratio vertical profiles 
###      (plt_grid_stat_anl.py) and aerosol column intergral time-series (plt_grid_stat_anl_int.py).
###     Its input include stat files from two METplus met_grid_stat_anl runs (e.g., MODELNAME-OBSNAME 
###     and MODELNAME1-OBSNAME1). If the comparison involves the stat files from only a single or 
###     over multiple METplus runs, please add/remove corresponding MODELNAME-OBSNAME and related 
###     variables in this script and the above two python scripts. Please modify the legend variabels 
###     in the python scripts based on the plots. 
###   
### Please contact Bo.Huang at bo.huang@noaa.gov, if further clarification is needed.

export OMP_NUM_THREADS=1

set -x 

module use -a /contrib/anaconda/modulefiles
module load anaconda/latest

### Define the stat directories/files from the METplus met_grid_stat_anl run
EXPDIR="/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NASALUTs-Hongli/aodLUTs_fv3Grid/METplus/METplus-diag//diagOutput/"
MODELNAME="FV3GLOBAL"
MODELNAME1="FV3GLOBAL"
OBSNAME="MERRA2"
OBSNAME1="MERRA2"

### Define the start/end cycles and cycle increment is defined in the python script
CYCS="2016062100"
CYCE="2016062118"

### Define METplus stats resolution
GRID="1.0deg"
#GRID="2.5deg"
SUFFIX=${CYCS}-${CYCE}-${GRID}

### Define the variables to be verified for each fcst and obs. 
nvars=1
FCSTVARS=(CTOTAL)
FCSTVARS1=(CTOTAL)
OBSVARS=(CTOTAL)
OBSVARS1=(CTOTAL)

FCSTVARS_int=(CTOTAL_INTEGRAL)
FCSTVARS1_int=(CTOTAL_INTEGRAL)
OBSVARS_int=(CTOTAL_INTEGRAL)
OBSVARS1_int=(CTOTAL_INTEGRAL)

### Define masks for aera averaging. "FULL TROP CONUS EASIA NAFRME RUSC2S SAFRTROP SOCEAN CMAQ"
MSKLIST="CMAQ"

### Loop through for plot
for ((ivar=0;ivar<${nvars};ivar++))
do

### Aerosol mixing ratio vertical profile
    FCSTVAR=${FCSTVARS[ivar]}
    FCSTVAR1=${FCSTVARS1[ivar]}
    OBSVAR=${OBSVARS[ivar]}
    OBSVAR1=${OBSVARS1[ivar]}
    for MASK in ${MSKLIST}
    do
        python ./plt_grid_stat_anl.py ${EXPDIR} ${MODELNAME} ${MODELNAME1} ${OBSNAME} ${OBSNAME1} ${SUFFIX} ${FCSTVAR} ${FCSTVAR1} ${OBSVAR} ${OBSVAR1} ${MASK} ${CYCS} ${CYCE}
    done

    PLOTDIR=${MODELNAME1}-${MODELNAME}-${OBSNAME1}-${SUFFIX}/${FCSTVAR}-${OBSVAR1}
    mkdir -p ${PLOTDIR}
    mv *.png ${PLOTDIR}

### Aerosol column integral time-series
    FCSTVAR_int=${FCSTVARS_int[ivar]}
    FCSTVAR1_int=${FCSTVARS1_int[ivar]}
    OBSVAR_int=${OBSVARS_int[ivar]}
    OBSVAR1_int=${OBSVARS1_int[ivar]}
    for MASK in ${MSKLIST}
    do
	python ./plt_grid_stat_anl_int.py ${EXPDIR} ${MODELNAME} ${MODELNAME1} ${OBSNAME} ${OBSNAME1} ${SUFFIX} ${FCSTVAR_int} ${FCSTVAR1_int}  ${OBSVAR_int} ${OBSVAR1_int} ${MASK} ${CYCS} ${CYCE}
    done
    PLOTDIR=${MODELNAME1}-${MODELNAME}-${OBSNAME1}-${SUFFIX}/${FCSTVAR_int}-${OBSVAR1_int}
    mkdir -p ${PLOTDIR}
    mv *.png ${PLOTDIR}
    
done

### define AOD variable name and plot AOD time-series
sensors='modis_aqua modis_terra'
for sensor in ${sensors}
do
    FCSTVAR_aod="aod"
    FCSTVAR1_aod="aod"
    OBSVAR_aod="AODANA" 
    OBSVAR1_aod="AODANA"
    for MASK in ${MSKLIST}
    do
        python ./plt_grid_stat_anl_aod.py ${EXPDIR} ${MODELNAME} ${MODELNAME1} ${OBSNAME} ${OBSNAME1} ${SUFFIX} ${FCSTVAR_aod} ${FCSTVAR1_aod} ${OBSVAR_aod} ${OBSVAR1_aod} ${MASK} ${CYCS} ${CYCE} ${sensor}
    done
    PLOTDIR=${MODELNAME1}-${MODELNAME}-${OBSNAME1}-${SUFFIX}/${sensor}-${sensor}
    mkdir -p ${PLOTDIR}
    mv *.png ${PLOTDIR}
done

exit $?
