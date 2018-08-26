#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import fnmatch
import numpy as np
import argparse


################ Argument Parser #######################

ap = argparse.ArgumentParser()
ap.add_argument("-s", dest='subject', help="Subject Id", required=True)
ap.add_argument("-d", dest='directory', help="Target directory", default='./')
args = vars(ap.parse_args())

subject = args['subject']
directory = args['directory']

files = sorted(fnmatch.filter(os.listdir(directory), subject + '*.mobile.npy'))

for f in files:
    print f
    cdata = np.load(directory + f)

    v = []
    trIdx = []
    for i, x in enumerate(cdata):
        v.extend(x)
        cid = np.empty(len(x))
        cid.fill(i)
        trIdx.extend(cid)
   
    v = np.array(v)
    trIdx = np.array(trIdx, ndmin=2).T

    data = np.concatenate((v, trIdx), 1)

    # Save trajectory
    tfile, text = os.path.splitext(f)
    save_path = os.path.join(directory, tfile + ".csv")
    
    print("[out] - Saving trajectory in: " + directory + save_path)
    np.savetxt(save_path, data, "%.3f")



