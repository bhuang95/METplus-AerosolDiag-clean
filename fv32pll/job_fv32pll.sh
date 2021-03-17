#!/bin/bash
#SBATCH -J fv32pll
#SBATCH -A wrf-chem
#SBATCH --open-mode=truncate
#SBATCH -o log.fv32pll.out
#SBATCH -e log.fv32pll.err
#SBATCH --nodes=1
#SBATCH -q debug
#SBATCH -t 00:19:00


. /etc/profile

#. /home/Bo.Huang/JEDI-2020/.environ.ksh

module purge
#module use -a /scratch1/NCEPDEV/jcsda/Ryan.Honeyager/jedi/modules/
#module load jedi-stack/intel-impi-18.0.5
export JEDI_OPT=/scratch1/NCEPDEV/jcsda/Ryan.Honeyager/jedi-stack/opt
module use /scratch1/NCEPDEV/jcsda/Ryan.Honeyager/jedi-stack/opt/modulefiles/core
module use /scratch1/NCEPDEV/jcsda/Ryan.Honeyager/jedi-stack/opt/modulefiles/apps
module load jedi/intel-20.2-impi-18

module load nco ncview ncl imagemagick/7.0.8-53

export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/scratch1/BMC/gsd-fv3-dev/MAPP_2018/pagowski/libs/fortran-datetime/lib"

### Define cycles to run this conversion software
start_date=2016062100
end_date=2016062118
cycle_frequency=6

### Define satellite sensor for AOD convesion. 
sensors='modis_terra modis_aqua'

### Define FV3 grid resolution
grid=C96

### Define executable path
maindir=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/pagowski
execdir=${maindir}/exec

### Define input FV3 grid file path
indir=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NASALUTs-Hongli/aodLUTs_fv3Grid/data

### Define output lat-lon grid file path
fv3dir=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NASALUTs-Hongli/aodLUTs_fv3Grid/data/latlonData
workdir=${fv3dir}/workdir_tmp
outdir=${fv3dir}

mkdir -p ${outdir}

ndate=/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate

if [[ ! -r $workdir ]]
then
    mkdir -p $workdir
fi

### Copy executables to $workdir
/bin/cp ${execdir}/fv32pll.x ${execdir}/fv3aod2ll.x ${execdir}/calc_col_integrals.x  $workdir

cd $workdir

### Loop through the dates for conversion 
ident=$start_date
while [[ $ident -le $end_date ]]
do

    identm6=`$ndate -${cycle_frequency} $ident`

    year=`echo "${ident}" | cut -c1-4`
    month=`echo "${ident}" | cut -c5-6`
    day=`echo "${ident}" | cut -c7-8`
    hour=`echo "${ident}" | cut -c9-10`

    yearm6=`echo "${identm6}" | cut -c1-4`
    monthm6=`echo "${identm6}" | cut -c5-6`
    daym6=`echo "${identm6}" | cut -c7-8`
    hourm6=`echo "${identm6}" | cut -c9-10`

    outfile="fv3_aeros_${year}${month}${day}${hour}_pll.nc"
    outfile_tmp=${outfile}.tmp

    outfile_int="fv3_aeros_int_${year}${month}${day}${hour}_pll.nc"


#fv3 files are analyses
echo ${identm6}
echo ${indir}/gdas.${yearm6}${monthm6}${daym6}/${hourm6}/RESTART/${year}${month}${day}.${hour}0000.fv_tracer.res.tile?.nc.ges


# Calculate mixing ratio on regular lat-lon grid
cat > fv32pll.nl <<EOF
&record_input
 date="${year}${month}${day}${hour}"
 input_grid_dir="${maindir}/fix_fv3/${grid}"
 fname_grid="grid_spec.tile?.nc"
 input_fv3_dir="${indir}/gdas.${yearm6}${monthm6}${daym6}/${hourm6}/RESTART/"
 fname_fv3_tracer="${year}${month}${day}.${hour}0000.fv_tracer.res.tile?.nc.ges"
 fname_fv3_core="${year}${month}${day}.${hour}0000.fv_core.res.tile?.nc.ges"
 fname_akbk="${year}${month}${day}.${hour}0000.fv_core.res.nc.ges"
/
&record_interp
!varlist_in is only for illustration since translation is hard-coded
!and will not aggregate correctly if all species not present
 varlist_in= "bc1","bc2","dust1","dust2","dust3","dust4","dust5","oc1","oc\
2","seas1","seas2","seas3","seas4","seas5","sulf"
!varlist_out is only for illustration since translation is hard-coded
!and will not aggregate correctly if all species not present
 varlist_out= "BCPHOBIC","BCPHILIC","DUSTFINE","DUSTMEDIUM","DUSTCOARSE","DUSTTOTAL","OCPHOBIC","OCPHILIC","SEASFINE","SEASMEDIUM","SEASCOARSE","SEASTOTAL","SO4"
 plist = 100.,250.,400.,500.,600.,700.,850.,925.,1000.
 dlon=0.5
 dlat=0.5
/
&record_output
 output_dir="${outdir}"
 fname_pll="${outfile_tmp}"
/
EOF

    echo ${outfile_tmp}

    ./fv32pll.x

    ncap2 -O -s "CPHOBIC=float(BCPHOBIC+OCPHOBIC);CPHILIC=float(BCPHILIC+OCPHILIC);CTOTAL=float(BCPHOBIC+OCPHOBIC+BCPHILIC+OCPHILIC)" ${outdir}/${outfile_tmp} ${outdir}/${outfile}
    ncatted -O -a long_name,CPHOBIC,o,c,"Hydrophobic Carbon Aerosol Total Mixing Ratio" ${outdir}/${outfile}
    ncatted -O -a long_name,CPHILIC,o,c,"Hydrophilic Carbon Aerosol Total Mixing Ratio" ${outdir}/${outfile}
    ncatted -O -a long_name,CTOTAL,o,c,"Carbon Aerosol Total Mixing Ratio" ${outdir}/${outfile}
    ncatted -O -a history,global,d,, ${outdir}/${outfile}
    /bin/rm -rf ${outdir}/${outfile_tmp}


# Calculate column integral on regular lat-lon grid
cat > calc_col_integrals.nl <<EOF
&record_input
 input_dir="${outdir}"
 fname_in="${outfile}"
 varlist= "BCPHOBIC","BCPHILIC","DUSTFINE","DUSTMEDIUM","DUSTCOARSE","DUSTTOTAL","OCPHOBIC","OCPHILIC","SEASFINE","SEASMEDIUM","SEASCOARSE","SEASTOTAL","SO4"
/
&record_output
 output_dir="${outdir}"
 fname_out="tmp.nc"
/
EOF

    ./calc_col_integrals.x

    ncap2 -O -s "CPHOBIC_INTEGRAL=float(BCPHOBIC_INTEGRAL+OCPHOBIC_INTEGRAL);CPHILIC_INTEGRAL=float(BCPHILIC_INTEGRAL+OCPHILIC_INTEGRAL);CTOTAL_INTEGRAL=float(BCPHOBIC_INTEGRAL+OCPHOBIC_INTEGRAL+BCPHILIC_INTEGRAL+OCPHILIC_INTEGRAL)" ${outdir}/tmp.nc ${outdir}/${outfile_int}
    rm -rf ${outdir}/tmp.nc


# Calculate AOD on regular lat-lon grid
for sensor in ${sensors}
do
outfile_aod="fv3_aods_${sensor}_${year}${month}${day}${hour}_ll.nc"
cat > fv3aod2ll.nl <<EOF
&record_input
 date="${year}${month}${day}${hour}"
 input_grid_dir="${maindir}/fix_fv3/${grid}"
 fname_grid="grid_spec.tile?.nc"
 input_fv3_dir="${indir}/gdas.${yearm6}${monthm6}${daym6}/${hourm6}/RESTART/"
 fname_fv3="${year}${month}${day}.${hour}0000.fv_aod_LUTs_v.${sensor}.res.tile?.nc.ges"
/
&record_interp
 dlon=0.5
 dlat=0.5
/
&record_output
 output_dir="${outdir}"
 fname_aod_ll="${outfile_aod}"
/
EOF

    echo $outfile_aod

    ./fv3aod2ll.x
done

    ident=`$ndate +${cycle_frequency} $ident`

done

exit
