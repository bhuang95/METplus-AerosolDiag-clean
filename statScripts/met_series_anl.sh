set -x
# Comparison between 2 models at pressure level as a time series.
# Requirements
# 1. If both models are in NetCDF, ensure they have the same vertical layers for comparison
#    and in same top-down or down-top order.
# 2. List all the pres layers in NetCDF files
# 3. List the name of variables that are desired to compare in the corresponding order.
#  
# main.conf: define input and output base.
# 
# Setup SDATE, EDATE, INCH, GRID_NAME, FCST_NAME, OBS_NAME, FCST_VAR, FCST_VARLEV, OBS_VAR, OBS_VARLEV, 
#       FCSTFILETMP, OBSFILETMP, OUTPUTFILE_NAME
# SDATE: start date of evaluation
# EDATE: end date of evaluation
# INC_H: increment of hours
# GRID_NAME: GXXX from https://www.nco.ncep.noaa.gov/pmb/docs/on388/tableb.html
#            G002 2.5 deg by 2.5 deg
#            G004 0.5 deg by 0.5 deg
# PLEV: All the pressure levels in NetCDF files
# FCST/OBSPATH: The path saved forecast and obs data files.
# FCST/OBSFILETMP: The name that can be searched under FCST/OBSPATH
# 
#


if [ -d /glade/scratch ]; then
   export machine=Cheyenne
elif [ -d /scratch1/NCEPDEV/da ]; then
   export machine=Hera
fi
source $BASE/ush/met_load.sh
rc=$?
if [ $rc -ne 0 ]; then
   exit $rc
fi


#
# User defined variables
#
#machine=Hera
#BASE=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/METplus-diag/METplus_pkg
#INPUTBASE=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/METplus-diag/data
#OUTPUTBASE=$BASE/output
#source $BASE/ush/met_load.sh

#SDATE=2016060100
#EDATE=2016060118
#INC_H=6

#GRID_NAME="G002"

PLEV="100 250 400 500 600 700 850 925 1000"

#FCSTPATH=$INPUTBASE/FV3/VIIRS/pll
#FCST_Head="fv3_aeros_"
#FCSTSUFF="_pll.nc"

#FCSTFILETMP="${FCST_Head}*${FCSTSUFF}"
#FCST_NAME="FV3"
#FCSTVARS="SEASFINE SEASMEDIUM SEASCOARSE DUSTFINE DUSTMEDIUM DUSTCOARSE OCPHILIC OCPHOBIC BCPHILIC BCPHOBIC SO4"
#FCSTVARS="aermr01 aermr02 aermr03 aermr04 aermr05 aermr06 aermr07 aermr08 aermr09 aermr10 aermr11"

#OBSPATH=$INPUTBASE/MERRA2/pll
#OBS_Head="m2_aeros_"
#OBSSUFF="_pll.nc"
#OBSFILETMP="${OBS_Head}*${OBSSUFF}"
#OBS_NAME="MERRA2"
#OBSVARS="SEASFINE SEASMEDIUM SEASCOARSE DUSTFINE DUSTMEDIUM DUSTCOARSE OCPHILIC OCPHOBIC BCPHILIC BCPHOBIC SO4"
#
# Default variables
#

FCSTFILETMP="${FCST_HEAD}*${FCST_SUFF}"
OBSFILETMP="${OBS_HEAD}*${OBS_SUFF}"
WRKD=${WRKD:-$BASE/wrk}
NDATE="python $BASE/bin/ndate.py"
CONFIG_DIR=$BASE/conf
INCONFIG=${CONFIG_DIR}/SeriesAnalysis.conf.IN
MAINCONF=$CONFIG_DIR/main.conf.IN
MASTER=$METPLUS_PATH/ush/master_metplus.py


cd $WRKD
mkdir -p $WRKD/fcst $WRKD/obs

FCSTDIR=$WRKD/fcst
OBSDIR=$WRKD/obs

CDATE=$SDATE
while [ $CDATE -le $EDATE ];
do
  ln -sf $FCSTPATH/${FCST_HEAD}${CDATE}${FCST_SUFF} ./fcst
  ln -sf $OBSPATH/${OBS_HEAD}${CDATE}${OBS_SUFF} ./obs
  CDATE=`$NDATE $CDATE $INC_H`
done

if [ ${SIGLEV} == "TRUE" ]; then
    FPLEVLIST=("sigLev")
    FNCLVIDXLIST=(0)

    OPLEVLIST=("sigLev")
    ONCLVIDXLIST=(0)
else
    FPLEVLIST=(100 250 400 500 600 700 850 925 1000)
    FNCLVIDXLIST=(0 1 2 3 4 5 6 7 8)

    OPLEVLIST=(100 250 400 500 600 700 850 925 1000)
    ONCLVIDXLIST=(0 1 2 3 4 5 6 7 8)
fi

nplv=${#FPLEVLIST[*]}

echo ${nplv}

np=0
while [[ $np -lt $nplv ]];
do
    PLEV=${FPLEVLIST[$np]}
    FCST_VARLEV="\"(0,${FNCLVIDXLIST[$np]},*,*)\""
    OBS_VARLEV="\"(0,${ONCLVIDXLIST[$np]},*,*)\""

    if [ ${FCST_VARDIM} == "3" ]; then
       FCST_VARLEV="\"(0,*,*)\""
    fi

    if [ ${OBS_VARDIM} == "3" ]; then
       OBS_VARLEV="\"(0,*,*)\""
    fi

    OUTPUTTMP="${FCST_VAR}_${PLEV}hPa.nc"

    echo $FCST_VAR $FCST_VARLEV
    echo $OBS_VAR $OBS_VARLEV
    echo $OUTPUTTMP

#if [ "YES" == "NO" ]; then
cat $MAINCONF | sed s:_MET_PATH_:${MET_PATH}:g \
              | sed s:_INPUTBASE_:${INPUTBASE}:g \
              | sed s:_OUTPUTBASE_:${OUTPUTBASE}:g \
              > ./main.conf 

cat $INCONFIG | sed s:_SDATE_:${SDATE}:g \
              | sed s:_EDATE_:${EDATE}:g \
              | sed s:_INC_H_:${INC_H}:g \
              | sed s:_BASE_:${BASE}:g \
              | sed s:_GRID_NAME_:${GRID_NAME}:g \
              | sed s:_FCST_NAME_:${FCST_NAME}:g \
              | sed s:_OBS_NAME_:${OBS_NAME}:g \
              | sed s:_FCST_VAR_:${FCST_VAR}:g \
              | sed s:_FCST_VARLEV_:${FCST_VARLEV}:g \
              | sed s:_OBS_VAR_:${OBS_VAR}:g \
              | sed s:_OBS_VARLEV_:${OBS_VARLEV}:g \
              | sed s:_FCSTDIR_:${FCSTDIR}:g \
              | sed s:_OBSDIR_:${OBSDIR}:g \
              | sed s:_FCSTFILETMP_:"${FCSTFILETMP}":g \
              | sed s:_OBSFILETMP_:"${OBSFILETMP}":g \
              | sed s:_OUTPUTTMP_:${OUTPUTTMP}:g \
              > ./SeriesAnalysis.${OBS_VAR}_${PLEV}hPa.conf
#fi

time $MASTER -c ./main.conf -c ./SeriesAnalysis.${OBS_VAR}_${PLEV}hPa.conf

let np=np+1
done

exit
