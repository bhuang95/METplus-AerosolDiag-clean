#!/bin/bash
#SBATCH -J NASALUTs
#SBATCH -A chem-var
#SBATCH -o log.NASALUTs.out
#SBATCH -e log.NASALUTs.out
#SBATCH --nodes=1
#SBATCH -n 36
#SBATCH -q batch
#SBATCH -t 00:19:00

. /etc/profile

module purge
export JEDI_OPT=/scratch1/NCEPDEV/jcsda/Ryan.Honeyager/jedi-stack/opt
module use /scratch1/NCEPDEV/jcsda/Ryan.Honeyager/jedi-stack/opt/modulefiles/core
module use /scratch1/NCEPDEV/jcsda/Ryan.Honeyager/jedi-stack/opt/modulefiles/apps
module load jedi/intel-20.2-impi-18

ulimit -s unlimited

echo "starttime"
echo `date`

#  Directories.
pwd=$(pwd)
TOPDIR=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NASALUTs-Hongli/aodLUTs_fv3Grid
JOBDIR=${TOPDIR}/job
DATADIR=${TOPDIR}/data
RUNDIR=${TOPDIR}/run
EXECX=${TOPDIR}/exec/gocart_aod_fv3_mpi_LUTs.x
NASALUTs=${TOPDIR}/nasaluts/geosaod.rc
NASAMIE=${TOPDIR}/nasaluts/Chem_MieRegistry.rc
NDATE=/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate
HOMEGFS=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/GSDChem_cycling/global-workflow

AODTYPE="MODIS"

DATE_STD=2016062100
DATE_END=2016062118
DATE_INC=6

if [ $AODTYPE = "VIIRS" ]; then
    sensorIDs="v.viirs-m_npp"
elif [ $AODTYPE = "MODIS" ]; then
    sensorIDs="v.modis_terra v.modis_aqua"
else
    echo "AODTYBE must be VIIRS or MODIS; exit this program now!"
    exit 1
fi

mkdir -p ${RUNDIR}

cd ${RUNDIR}
cp ${NASAMIE} ./
IDATE=${DATE_STD}
while [[ ${IDATE} -le ${DATE_END} ]]
do
    CDATE=${IDATE}
    cyy=$(echo $CDATE | cut -c1-4)
    cmm=$(echo $CDATE | cut -c5-6)
    cdd=$(echo $CDATE | cut -c7-8)
    chh=$(echo $CDATE | cut -c9-10)
    cprefix="${cyy}${cmm}${cdd}.${chh}0000"

    GDATE=$($NDATE -$DATE_INC $CDATE)
    gyy=$(echo $GDATE | cut -c1-4)
    gmm=$(echo $GDATE | cut -c5-6)
    gdd=$(echo $GDATE | cut -c7-8)
    ghh=$(echo $GDATE | cut -c9-10)

    for isensorID in ${sensorIDs}; do
        fdirin=${DATADIR}/gdas.${gyy}${gmm}${gdd}/${ghh}/RESTART/
        fakbk=${cprefix}.fv_core.res.nc.ges
	for itile in $(seq 1 6); do
            fcore=${cprefix}.fv_core.res.tile${itile}.nc.ges
            ftracer=${cprefix}.fv_tracer.res.tile${itile}.nc.ges
            fdirout=${fdirin}
            faod=${cprefix}.fv_aod_LUTs_${isensorID}.res.tile${itile}.nc.ges

cat << EOF > ${RUNDIR}/gocart_aod_fv3_mpi.nl      
&record_input
 input_dir = "${fdirin}"
 fname_akbk = "${fakbk}"
 fname_core = "${fcore}"
 fname_tracer = "${ftracer}"
 output_dir = "${fdirout}"
 fname_aod = "${faod}"
/
&record_model
 Model = "AodLUTs"
/
&record_conf_crtm
 AerosolOption = "aerosols_gocart_default"
 Absorbers = "H2O","O3"
 Sensor_ID = "${isensorID}"
 EndianType = "Big_Endian"
 CoefficientPath = ${HOMEGFS}/fix/jedi_crtm_fix_20200413/CRTM_fix/
 Channels = 4
/
&record_conf_luts
 AerosolOption = "aerosols_gocart_merra_2"
 Wavelengths = 550.
 RCFile = "${NASALUTs}"
/
EOF

    srun --export=all ${EXECX}
    ERR=$?
    if [ $ERR -ne 0 ]; then
        echo "gocart_aod_fv3_mpi_LUTs failed an exit!!!"
	exit $ERR
    else
	/bin/rm -rf ${DATA}/gocart_aod_fv3_mpi.nl
    fi
    done
done # end for isensorID
IDATE=`$NDATE +${DATE_INC} $IDATE`
done # date loop completed

exit $ERR
