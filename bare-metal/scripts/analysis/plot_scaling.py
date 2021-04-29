# ===================================================================
# The contents of this file are dedicated to the public domain.  To
# the extent that dedication to the public domain is not available,
# everyone is granted a worldwide, perpetual, royalty-free,
# non-exclusive license to exercise all rights associated with the
# contents of this file for any purpose whatsoever.
# No rights are reserved.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# ===================================================================

'''
Created on Wed Sep 25 08:02:46 2020

HPC Scaling Utilities
Contains:
    get_scalings
    plt_scalings

@author James Harle
$Last commit on:$
'''

import matplotlib.pyplot as plt
import matplotlib.collections
import numpy as np
import seaborn as sns
import pandas as pd
import re        
sns.set()


def get_scalings(file_list, rdt, ln_log=False):
    """ 
    Read mask information from file or open GUI.

    This method reads the mask information from the netcdf file or opens a gui
    to create a mask depending on the mask_gui input. The default mask data 
    uses the bathymetry and applies a 1pt halo.

    Args:
        Setup    (list): settings for bdy
        mask_gui (bool): whether use of the GUI is required

    Returns:
        numpy.array     : a mask array of the regional domain
        
    Example:
        
            ln_log=False
    
    file_list = ['timing.output.001', \
                 'timing.output.002', \
                 'timing.output.003', \
                 'timing.output.004', \
                 'timing.output.005']
    """
        
    # TODO: add option a wildcard rather than having to list all files
        
    fn  = len(file_list)
    rdt = float(rdt)
    
    # Set up input arrays
        
    time = np.zeros((fn,))
    proc = np.zeros((fn,))
    tstp = np.zeros((fn,))
        
    # Scrape the data from the input file list
    
    for f in range(fn):
        
        with open(file_list[f]) as file:
            for line in file:
                
                if re.search(r'MPI rank ', line):
                    proc[f] = float(line.split()[-1])
                    
                if re.search(r'Average ', line):
                #if re.search(r'tra_adv ', line):
                    time[f] = float(line.split()[4])
                    
                if re.search(r'timing step ', line):
                    tstp[f] = int(line.split()[2])
   
    if np.sum(np.abs(np.diff(tstp))) != 0:
        print('E R R O R')
    print(time)
    time = time/3600.
            
    # How many unique processor counts?
                    
    uniq_proc, counts = np.unique(proc, return_counts=True)
    nproc = len(uniq_proc)
    print(proc)
    
    # Set up arrays
                    
    proc_arr = np.zeros((nproc+fn,))
    time_arr = np.zeros((nproc+fn,))
    
    # Populate
    
    proc_arr[:nproc] = uniq_proc
    time_arr[:nproc] = np.mean(time[proc==uniq_proc[0]])
    
    # Scale ideal based on lowest processor run
    
    time_arr[:nproc] = time_arr[0]/(proc_arr[:nproc]/proc_arr[0])
    
    proc_arr[nproc:] = proc
    time_arr[nproc:] = time
    
    # Create PD DataFrame
    
    sf = ( 365. * 86400. ) / ( tstp[0] * rdt ) 
    
    if ln_log:
        data = np.vstack((np.log(time_arr*sf),time_arr[0]/time_arr,proc_arr))
    else:
        data = np.vstack((time_arr*sf,time_arr[0]/time_arr,proc_arr))
    
    scaling = pd.DataFrame(data=data.T, index=np.arange(len(time_arr)), 
                           columns=['hrs/yr', 'speed-up', 'cores'])
    
    # Add Label to data
    
    labl_arr = list(['ideal']*nproc) + list(['real']*fn)
    scaling.loc[:,'measure'] = labl_arr

    return scaling

def plt_scalings(scaling, title_cfg):
    """ 
    Read mask information from file or open GUI.

    This method reads the mask information from the netcdf file or opens a gui
    to create a mask depending on the mask_gui input. The default mask data 
    uses the bathymetry and applies a 1pt halo.

    Args:
        Setup    (list): settings for bdy
        mask_gui (bool): whether use of the GUI is required

    Returns:
        numpy.array     : a mask array of the regional domain
        
    Example:
        
            ln_log=False
    
    file_list = ['timing.output.001', \
                 'timing.output.002', \
                 'timing.output.003', \
                 'timing.output.004', \
                 'timing.output.005']
    """
    
    # Create figure
    
    fig = plt.figure(figsize=(10,6))
    
    # Plot speed-up and idea
    
    ax = sns.lineplot(x="cores", y="speed-up", hue="measure", style="measure", 
                      data=scaling, ci=95)
    #ax.axes.set_xlim(scaling['cores'].min(),scaling['cores'].max())
    #ax.axes.set_ylim(1,scaling['speed-up'].max())
    ax.tick_params(axis='y', color=(0.7,0.2,0.2,0.5), 
                   labelcolor=(0.7,0.2,0.2,0.5))
    ax.set_ylim((0,15))
    ax_y = ax.get_yaxis()
    ax_y.label.set_color((0.7,0.2,0.2,0.5))
    
    plt.legend(bbox_to_anchor=(1.1, 1),borderaxespad=0)
    
    # Plot up how long it takes to run a model year
    
    ax2 = plt.twinx()
    sns.lineplot(x="cores", y="hrs/yr", 
                 data=scaling[scaling["measure"]=='real'], ax=ax2, ci=95) 
    ax2.grid(None)
    
    # Tidy up
    
    for h in range(2):        
        han = ax2.get_children()[h]
        if isinstance(han, matplotlib.lines.Line2D):
            han.set_color('g')
            han.set_alpha(0.5)
        elif isinstance(han, matplotlib.collections.PolyCollection):
            han.set_facecolor((0.2,0.7,0.2))
            han.set_edgecolor((0.2,0.7,0.2))
            han.set_alpha(0.1)
    
    ax_y = ax2.get_yaxis()
    ax_y.label.set_color((0.2,0.7,0.2,0.5))
    
    ax2.tick_params(axis='y', color=(0.2,0.7,0.2,0.5), 
                    labelcolor=(0.2,0.7,0.2,0.5))
    #ax2.set_yscale('log')
    ax2.set_ylim((0,13))
    min_cores=scaling.at[0,'cores']
    if min_cores==1:
        nam_cores="core"
    else:
        nam_cores="cores"
        
    # Set title
        
    ax.set_title('HPC Strong Scaling '+title_cfg+' (Base: '+str(min_cores)+' '
                  +nam_cores+'; medium IO)',fontweight='bold')
    plt.tight_layout()
    fig.show()
