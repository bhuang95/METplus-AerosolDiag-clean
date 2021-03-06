set -x 
#
# Area masks: Generate through Gen_Vx_Masks advanced
# 
# STP1: Grid_Stat => STP2: Stat_Analysis => STP3: Visualization from filtered file.
#
# CAMSiRA (EAC4) :   aermr01,    aermr02,    aermr03,  aermr04,    aermr05,    aermr06,
# MERRA2/GSDChem :  SEASFINE, SEASMEDIUM, SEASCOARSE, DUSTFINE, DUSTMEDIUM, DUSTCOARSE,
#                    aermr07,  aermr08,  aermr09,  aermr10, aermr11
#                   OCPHILIC, OCPHOBIC, BCPHILIC, BCPHOBIC,     SO4
#
# SDATE: start date of evaluation
# EDATE: end date of evaluation
# INC_H: increment of hours
# GRID_NAME: GXXX from https://www.nco.ncep.noaa.gov/pmb/docs/on388/tableb.html
#            G002 2.5 deg by 2.5 deg
#            G004 0.5 deg by 0.5 deg
# MODEL/OBSNAME: name of model and observations (analysis)
# MSKLIST: Mask aera for statistics calculation
# LINETYPELIST: Available statistics from MET, only SL1L2 is available now.
# FCST/OBSDIR: the subfolder for forecast model and the obs (analysis) data.
# FCST/OBSINPUTTMP: naming format of forecast and obs files.
# 
if [ -d /glade/scratch ]; then
   export machine=Cheyenne
elif [ -d /scratch1/NCEPDEV/da ]; then
   export machine=Hera
fi
. $BASE/ush/met_load.sh
rc=$?
if [ $rc -ne 0 ]; then
   exit $rc
fi
#
# User defined variables
#
STP1="Y"
STP2="Y"
STP3="N"

#SDATE=2016060100
#EDATE=2016060118
#INC_H=6


#MODELNAME="CAMS"
#OBSNAME="MERRA2"
#MSKLIST="FULL TROP CONUS EASIA NAFRME RUSC2S SAFRTROP SOCEAN"
#FCSTVAR="DUSTTOTAL,SEASTOTAL,aermr09,aermr10,aermr07,aermr08,aermr11"  
#OBSVAR="DUSTTOTAL,SEASTOTAL,BCPHILIC,BCPHOBIC,OCPHILIC,OCPHOBIC,SO4"
#FCSTVAR="DUSTTOTAL"
#OBSVAR="DUSTTOTAL"
#FCSTLEV='"0,0,*,*","0,1,*,*","0,2,*,*","0,3,*,*","0,4,*,*","0,5,*,*","0,6,*,*","0,7,*,*","0,8,*,*"'
#OBSLEV='"0,0,*,*","0,1,*,*","0,2,*,*","0,3,*,*","0,4,*,*","0,5,*,*","0,6,*,*","0,7,*,*","0,8,*,*"'

#FCSTDIR=$INPUTBASE/CAMS/pll
#FCSTINPUTTMP="cams_aeros_{init?fmt=%Y%m%d%H}_sdtotals.nc"

#OBSDIR=$INPUTBASE/MERRA2/pll
#OBSINPUTTMP="m2_aeros_{init?fmt=%Y%m%d%H}_pll.nc"

#GRID_NAME="G002"
LINETYPELIST="SL1L2"


#
#
#
WRKD=${WRKD:-$BASE/wrk}
NDATE="python $BASE/bin/ndate.py"
CONFIG_DIR=$BASE/conf
MAINCONF=$CONFIG_DIR/main.conf.IN
MASKS_DIR=$BASE/masks/nc_mask
PY_DIR=$BASE/pyscripts
MASTER=$METPLUS_PATH/ush/master_metplus.py

cd $WRKD

echo $MAINCONF

cat $MAINCONF | sed s:_MET_PATH_:${MET_PATH}:g \
              | sed s:_INPUTBASE_:${INPUTBASE}:g \
              | sed s:_OUTPUTBASE_:${OUTPUTBASE}:g \
              > ./main.conf


#
# Grid_Stat
#
case $STP1 in
Y|y|yes)
echo "Step1: Grid_Stat for $MODELNAME vs. $OBSNAME from $SDATE to $EDATE"
for msk in $MSKLIST
do
  echo $msk
  if [[ $msk == "FULL" ]]; then
     continue
  else
     MSKFILE=${MASKS_DIR}/${msk}_MSK.nc
     if [ -z "${AREA_MASK}" ] ; then
        AREA_MASK="${MSKFILE}"
     else
        AREA_MASK="${AREA_MASK},${MSKFILE}"
     fi
  fi
done

INCONFIG=${CONFIG_DIR}/GridStat.conf.IN

cat $INCONFIG | sed s:_SDATE_:${SDATE}:g \
              | sed s:_EDATE_:${EDATE}:g \
              | sed s:_INC_H_:${INC_H}:g \
              | sed s:_BASE_:${BASE}:g \
              | sed s:_GRID_NAME_:${GRID_NAME}:g \
              | sed s:_MODELNAME_:${MODELNAME}:g \
              | sed s:_OBSNAME_:${OBSNAME}:g \
              | sed s:_FCSTVAR_:${FCSTVAR}:g \
              | sed s:_FCSTLEV_:${FCSTLEV}:g \
              | sed s:_OBSVAR_:${OBSVAR}:g \
              | sed s:_OBSLEV_:${OBSLEV}:g \
              | sed s:_FCSTDIR_:${FCSTDIR}:g \
              | sed s:_OBSDIR_:${OBSDIR}:g \
              | sed s:_FCSTINPUTTMP_:"${FCSTINPUTTMP}":g \
              | sed s:_OBSINPUTTMP_:"${OBSINPUTTMP}":g \
              | sed s:_AREA_MASK_:${AREA_MASK}:g \
              > ./GridStat.conf

$MASTER -c ./main.conf -c ./GridStat.conf
;;
*)
 echo "Skip Step1: Grid_Stat"
;;
esac


#
# Stat_Analysis
#
case $STP2 in
Y|y|yes)
echo "Step2: Stat_Analysis for $MODELNAME vs. $OBSNAME from $SDATE to $EDATE"

# determine valid time list for stat_analysis
tmpedate=`$NDATE $SDATE 24`
CDATE=$SDATE
while [ $CDATE -lt $tmpedate ];
do
  HH=`echo $CDATE | cut -c9-10`
  if [ -z "$VALIDHLIST" ]; then
     VALIDHLIST="$HH"
  else
     VALIDHLIST="$VALIDHLIST, $HH"
  fi
  CDATE=`$NDATE $CDATE $INC_H`
done

for msk in $MSKLIST
do
  if [ -z "$AREAMASKNAME" ]; then
     AREAMASKNAME="${msk}"
  else
     AREAMASKNAME="$AREAMASKNAME,${msk}"
  fi
done

INCONFIG=${CONFIG_DIR}/StatAnalysis.conf.IN
cat $INCONFIG | sed s:_SDATE_:${SDATE}:g \
              | sed s:_EDATE_:${EDATE}:g \
              | sed s:_GRID_NAME_:${GRID_NAME}:g \
              | sed s:_MODELNAME_:${MODELNAME}:g \
              | sed s:_OBSNAME_:${OBSNAME}:g \
              | sed s:_VALIDHLIST_:"${VALIDHLIST}":g \
              | sed s:_FCSTVAR_:${FCSTVAR}:g \
              | sed s:_FCSTLEV_:${FCSTLEV2}:g \
              | sed s:_OBSVAR_:${OBSVAR}:g \
              | sed s:_OBSLEV_:${OBSLEV2}:g \
              | sed s:_AREAMASKNAME_:"${AREAMASKNAME}":g \
              | sed s:_LINETYPELIST_:${LINETYPELIST}:g \
              > ./StatAnalysis.conf

$MASTER -c ./main.conf -c ./StatAnalysis.conf
;;
*)
  echo "Skip Step2: Stat_Analysis"
;;
esac
#
# Plot vertical profile and time series
#
case $STP3 in
Y|y|yes)
OUTPUT_BASE=`grep OUTPUT_BASE ./main.conf | awk '{print $3}'`
echo $OUTPUT_BASE
TMPSAPATH=`grep "STAT_ANALYSIS_OUTPUT_DIR =" $CONFIG_DIR/StatAnalysis.conf.IN | awk '{print $3}' | sed -e 's/{OUTPUT_BASE}/${OUTPUT_BASE}/g'`
SAPATH=`eval echo $TMPSAPATH`
echo $SAPATH

if [ ! -s $OUTPUT_BASE/stat_images ]; then
   mkdir $OUTPUT_BASE/stat_images
fi

for LINETYPE in $LINETYPELIST
do
for AREAMSK in $MSKLIST
do

INPYSCRIPT=${PY_DIR}/plt_grid_stat_anl.py.IN
cat $INPYSCRIPT | sed s:_BASE_:${BASE}:g \
                | sed s:_SDATE_:${SDATE}:g \
                | sed s:_EDATE_:${EDATE}:g \
                | sed s:_INC_H_:${INC_H}:g \
                | sed s:_SAPATH_:${SAPATH}:g \
                | sed s:_MODELNAME_:${MODELNAME}:g \
                | sed s:_OBSNAME_:${OBSNAME}:g \
                | sed s:_AREAMSK_:${AREAMSK}:g \
                | sed s:_OBSVAR_:${OBSVAR}:g \
                | sed s:_LINETYPE_:${LINETYPE}:g \
                > ./plt_grid_stat_anl.py

if [ -s ./plt_grid_stat_anl.py ]; then
   python ./plt_grid_stat_anl.py > ./plt_grid_stat_anl.out 2>&1
   if [[ $? == 0 ]] ; then
      mv ./*.png $OUTPUT_BASE/stat_images
   fi
fi
done
done
;;
*)
  echo "Skip Step3: Generate Plots of "
;;
esac
