import sys,os
sys.path.append('/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/METplus-diag/METplus_pkg//pyscripts/lib')
#from subprocess import check_output as chkop
import subprocess as sbps
import numpy as np
import matplotlib
matplotlib.use('agg')
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from matplotlib.dates import (DAILY, DateFormatter,
                              rrulewrapper, RRuleLocator)
from ndate import ndate
from datetime import datetime
from datetime import timedelta

def readFcstObsStats(filename,nlevs):
    fbar=np.zeros((1,nlevs),dtype='float')
    obar=np.zeros((1,nlevs),dtype='float')
    f=open(filename,'r')
    nlev=-1
    for line in f.readlines():
        if (nlev==-1):
            nlev=nlev+1
            continue
        else:
            fbar[0,nlev]=float(line.split()[25])
            obar[0,nlev]=float(line.split()[26])
            nlev=nlev+1
    f.close()
    return fbar, obar

fsave=1

expdir=sys.argv[1]
modelname=sys.argv[2]
modelname1=sys.argv[3]
obsname=sys.argv[4]
obsname1=sys.argv[5]
suffix=sys.argv[6]
modelvar=sys.argv[7]
modelvar1=sys.argv[8]
obsvar=sys.argv[9]
obsvar1=sys.argv[10]
area=sys.argv[11]
sdatetmp=sys.argv[12]
edatetmp=sys.argv[13]
sensor=sys.argv[14]
sa_path="%s/wrk-%s-%s-%s/met_grid_stat_anl/%s-%s/met_tool_wrapper/stat_analysis/" %(expdir, modelname, obsname, suffix, sensor, sensor) 
sa_path1="%s/wrk-%s-%s-%s/met_grid_stat_anl/%s-%s/met_tool_wrapper/stat_analysis/" %(expdir, modelname1, obsname1, suffix, sensor, sensor) 

linetype="SL1L2"
plev=(100, 250, 400, 500, 600, 700, 850, 925, 1000)

sdate=int(sdatetmp)
edate=int(edatetmp)
inc_h=6

cdate=sdate
tmpfile="%s/%s/%s/%s_%s_%s.stat" %(sa_path,modelname,cdate,area,obsvar,linetype)
f=open(tmpfile,'r')
nlev=-1
for line in f.readlines():
    nlev=nlev+1
f.close()

dlist=[]
ntime=0
cdate=sdate
while (cdate<=edate):
    filename="%s/%s/%s/%s_%s_%s.stat" %(sa_path,modelname,cdate,area,obsvar,linetype)
    ntime=ntime+1
    dlist.append(str(cdate))
    cdate=ndate(cdate,inc_h)

p_matched=np.zeros((ntime,nlev),dtype='int')
fbar=np.zeros((ntime,nlev),dtype='float')
fbar1=np.zeros_like(fbar)
obar=np.zeros_like(fbar)
obar1=np.zeros_like(fbar)

ntime=0
cdate=sdate
while (cdate<=edate):
    filename="%s/%s/%s/%s_%s_%s.stat" %(sa_path,modelname,cdate,area,obsvar,linetype)
    fbar[ntime,:], obar[ntime,:]=readFcstObsStats(filename,nlev)

    filename1="%s/%s/%s/%s_%s_%s.stat" %(sa_path1,modelname1,cdate,area,obsvar1,linetype)
    fbar1[ntime,:], obar1[ntime,:]=readFcstObsStats(filename1,nlev)

    cdate=ndate(cdate,inc_h)
    ntime=ntime+1
print('get data')
#
# Plot data
#
edate1=ndate(edate,inc_h)
syy=int(str(sdate)[:4]); smm=int(str(sdate)[4:6])
sdd=int(str(sdate)[6:8]); shh=int(str(sdate)[8:10])
eyy=int(str(edate1)[:4]); emm=int(str(edate1)[4:6])
edd=int(str(edate1)[6:8]); ehh=int(str(edate1)[8:10])

date1 = datetime(syy,smm,sdd,shh)
date2 = datetime(eyy,emm,edd,ehh)
delta = timedelta(hours=inc_h)
dates = mdates.drange(date1, date2, delta)

rule = rrulewrapper(DAILY, byhour=0, interval=5)
loc = RRuleLocator(rule)
formatter = DateFormatter('%Y%h %n %d %Hz')

print('get dates')

leglist=["FV3GLOBAL", "MERRA2", "FV3GLOBAL", "MERRA2"]
print(leglist)

for nlv in np.arange(nlev):
    pltdata=np.zeros((ntime,4),dtype='float')
    pltdata[:,0]=fbar[:,nlv]
    pltdata[:,1]=obar[:,nlv]
    pltdata[:,2]=fbar1[:,nlv]
    pltdata[:,3]=obar1[:,nlv]

    print(pltdata)
    print('hbo')
    print(dates)
    fig=plt.figure(figsize=(12,6))
    ax=plt.subplot()
    ax.set_prop_cycle(color=['red','blue','orange','green'])
    ax.plot_date(dates,pltdata,'o-', lw=0.5)
    ax.xaxis.set_major_locator(loc)
    ax.xaxis.set_major_formatter(formatter)
    ax.xaxis.set_tick_params(labelsize=14)
    ax.legend(leglist,fontsize=16)
    ax.set_ylabel('AOD',fontsize=14)
    ax.grid()
    ax.set_title('%s %s AOD' %(sensor, area),loc='center',fontsize=18)

    if (fsave):
        fig.savefig('./TimeSeries_%s.%s_%s_%s_%s_%s.%s_%s.png' %(area,sensor,obsvar,obsname1,modelname,obsname,sdate,cdate), format='png')
