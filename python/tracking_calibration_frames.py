#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
@author: Luca Tonin, Felix Bauer

Export each frame from the video in a ROS bag file as a jpg-file.
Call program with following arguments:
        --config <the yaml configuration file>
You need to have OpenCV  and the cv_bridge package installed.
"""

import rosbag
import cv2
import argparse
import cv_bridge
import numpy as np
import matplotlib.pyplot as plt
import os
import yaml
from progressbar import ProgressBar, Percentage, Bar
import pdb


################ Functions #######################

# Import configuration from yaml file
def import_configuration(filename):

    try:
        with open(filename, 'r') as file:
            cfg = yaml.load(file)
    except Exception as error:
        print("Cannot open the file:" + filename)
    return cfg

#parse name of videobagfile, bagfile, subject, run
ap = argparse.ArgumentParser()
ap.add_argument("--config", help="Configuration filename", required=True)

args = vars(ap.parse_args())

############### Importing configuration ################
cfgfile    = args['config']

config = import_configuration(cfgfile) 

subject    = config['subject']
date       = config['date']
track_dir  = config['folderpath']['tracking']
calib_dir  = config['folderpath']['calibration']
calib_file = config['calibration']['file']
topic_track = config['rostopics']['video']

print("[config] - Subject: " + subject)
print("[config] - Date: " + str(date))
print("[config] - Calibration directory: " + calib_dir)
print("[config] - Calibration bag video file: " + calib_file)
print("[config] - Topic video: " + topic_track)


#Create target directory if it doesn't exist 
if not os.path.exists(calib_dir):
    os.makedirs(calib_dir)

#Import the bag file
vidbag = rosbag.Bag(calib_file)
#CvBridge for conversion from message to image
bridge = cv_bridge.CvBridge()

print("[proc] - Exporting frames from {} \n to {}...".format(calib_file, calib_dir))

i = 0
#loop over all messages in the topic with the video
in_trial = False
vmessages = vidbag.read_messages(topics=[topic_track])
pbar=ProgressBar(widgets=[Percentage(), Bar()], maxval=vidbag.get_message_count()).start()
for topic, msg, t in vmessages:
    #Convert message to image (each message corresponds to one frame)
    img = bridge.compressed_imgmsg_to_cv2(msg)
    #Path of the image to be saved
    img_path = os.path.join(calib_dir, "Frame{}.jpg".format(str(i).zfill(4)))
    #Save image
    cv2.imwrite(img_path, img)
    #print("Storing Frame{}.jpg".format(str(i).zfill(4)))
    i += 1
    pbar.update(i)

pbar.finish()


print("[proc] - Successfully exported {} frames".format(i))
