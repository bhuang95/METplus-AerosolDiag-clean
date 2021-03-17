import sys,os
sys.path.append('/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/METplus-diag/METplus_pkg//pyscripts/lib')
os.environ['PROJ_LIB'] = '/contrib/anaconda/anaconda3/latest/share/proj'
from mpl_toolkits.basemap import Basemap
from netCDF4 import Dataset as NetCDFFile
import numpy as np
import matplotlib
matplotlib.use('agg')
import matplotlib.pyplot as plt
import matplotlib.colors as mpcrs

fmname=str(sys.argv[1])
sensor=str(sys.argv[2])
fcstvar=str(sys.argv[3])
tmpfile1=sys.argv[4]
tmpfile2=sys.argv[5]

def setup_cmap(name,selidx):
    nclcmap='/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/METplus-diag/METplus_pkg/pyscripts/colormaps/'
    cmapname=name
    f=open(nclcmap+'/'+cmapname+'.rgb','r')
    a=[]
    for line in f.readlines():
        if ('ncolors' in line):
            clnum=int(line.split('=')[1])
        a.append(line)
    f.close()
    b=a[-clnum:]
    c=[]
    for i in selidx[:]:
        c.append(tuple(float(y)/255. for y in b[i].split()))

    d=mpcrs.LinearSegmentedColormap.from_list(name,c,selidx.size)
    return d


nc1 = NetCDFFile(tmpfile1)
lat = nc1.variables['lat'][:]
lon = nc1.variables['lon'][:]
fbar1 = nc1.variables['series_cnt_FBAR'][:]
obar1 = nc1.variables['series_cnt_OBAR'][:]
rmse1 = nc1.variables['series_cnt_MSE'][:]
bias1 = nc1.variables['series_cnt_ME'][:]
rmse1=np.sqrt(rmse1)

nc2 = NetCDFFile(tmpfile2)
fbar2 = nc2.variables['series_cnt_FBAR'][:]
obar2 = nc2.variables['series_cnt_OBAR'][:]
rmse2 = nc2.variables['series_cnt_MSE'][:]
bias2 = nc2.variables['series_cnt_ME'][:]
rmse2=np.sqrt(rmse2)

fbar=np.array([fbar1, fbar2])
obar=np.array([obar1, obar2])
bias=np.array([bias1, bias2])
rmse=np.array([rmse1, rmse2])

models=['FV3GLOBAL', 'FV3GLOBAL']
metrics=['Model', 'Bias', 'RMSE']

fig = plt.figure(figsize=[16,12])
nrows=3
ncols=2

pname='%s-%s-2D-timeMean.png' %(sensor, fcstvar)
for irow in range(nrows):
    metname=metrics[irow]
    if irow == 0:
        pdata1=fbar
        cbarname='WhiteBlueGreenYellowRed-v1'
        cbarmax=250
        cbarlab='MASS[\u03bcg/kg]'
        cbarextend='max'
        vmin=0.0
        vmax=0.6 # np.amax(pdata1)*0.4 
        n=40
    elif irow == 1:
        pdata1=bias
        cbarname='ViBlGrWhYeOrRe'
        cbarmax=100
        cbarlab='Mixing Ratio Bias [\u03bcg/kg]'
        cbarextend='both'
        vmax=0.6 # np.amax(np.absolute(pdata1)) *0.5
        vmin=-1.0*vmax
        n=40
    else:
        pdata1=rmse
        cbarname='WhiteYellowOrangeRed_v1'
        cbarmax=250
        cbarlab='Mixing Ratio RMSE [\u03bcg/kg]'
        cbarextend='max'
        vmin=0.0
        vmax=0.6  # np.amax(pdata1)*0.5
        n=40

    for icol in range(ncols):
        modelname=models[icol]
        iplot=irow*ncols+icol+1
        pdata=pdata1[icol,:,:]

        if irow == 0:
            tname='%s AOD %s %s' %(sensor, modelname, metname)
        else:
            tname='%s %s AOD %s agnst. MERRA2' %(modelname, sensor, metname)

        ax=fig.add_subplot(nrows, ncols, iplot)
        ax.set_title(tname)
        map=Basemap(projection='cyl',llcrnrlat=30,urcrnrlat=45,llcrnrlon=-120,urcrnrlon=-75,resolution='c')
        map.drawcoastlines(color='black', linewidth=0.2)
        parallels = np.arange(-30.,45,5.)
        meridians = np.arange(-120,-75,5.)
        map.drawparallels(parallels,labels=[True,False,False,False])
        map.drawmeridians(meridians,labels=[False,False,False,True])
        lons,lats = np.meshgrid(lon,lat)
        lons, pdata = map.shiftdata(lons, datain = pdata, lon_0=0)
        x,y = map(lons,lats)
        clridx=np.trunc(np.linspace(0, cbarmax, n+1))
        clridx=clridx.astype(int)
        if irow == 1:
            clridx[int(n/2-1)]=clridx[int(n/2)]
        cmap=setup_cmap(cbarname,clridx)
        levels = np.linspace(vmin, vmax, n+1)
        norm = mpcrs.BoundaryNorm(levels,len(levels))
        cs=map.contourf(x,y,pdata,levels,cmap=cmap,norm=norm,extend=cbarextend)
        cb=map.colorbar(cs,"right", size="2%", pad="2%")
        #cb.set_label(cbarlab)

        plt.savefig(pname)
