#!/bin/ksh

gen_vx_mask ./input/gdas.t00z.pgrb2.0p25.f000 ./input/gdas.t00z.pgrb2.0p25.f000 TROP_MSK.nc -type lat -thresh '>=-20&&<=20' -name TROP
