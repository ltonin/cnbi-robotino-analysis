#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
@author: Luca Tonin, Felix Bauer
blob detection in track_robot(frame) inspired by 
https://www.pyimagesearch.com/2015/09/14/ball-tracking-with-opencv/

For given frame image it calculates the homography map to convert from the image
to real world coordinates, based on frames with robot on calibration points Test
accuracy of conversion with some test points

YAML configuration file must be provided with the followinf fields:
    - subject
    - date
    - ranges (lower and upper for HSV thresholding)
    - coordinates points 
    - indexes for training and testing points
    - index for the frame where the robot is in the starting point
    - camera matrix and distortion

See the provided yaml configuration template file for more details

Call program as follows:
    -d       <directory where the frames are stored>

    --config <optional: the yaml configuration file, by default it looks for
              config_calibration.yaml in the same directory where the frames are
              stored>

    -c       <optional: the camera type, by default kinect2>

For transformation the matrices from the equation in
https://docs.opencv.org/2.4/modules/calib3d/doc/camera_calibration_and_3d_reconstruction.html?highlight=stereosgbm
are determined using solvepnp. The equation is inverted and s is found by setting Z=0.
"""

import cv2
import sys
import glob
import fnmatch
import argparse
import numpy as np 
from time import sleep
import os
import yaml

################ Functions #######################

# Import configuration from yaml file
def import_configuration(filename):

    try:
        with open(filename, 'r') as file:
            cfg = yaml.load(file)
    except Exception as error:
        print("Cannot open the file:" + filename)
    return cfg

# Tracking the marker in a given frame
def track_robot(frame, lrange, urange):

    # Convert frame to HSV color space
    hsv = cv2.cvtColor(frame, cv2.COLOR_BGR2HSV)
 
    # Mask for defined color range, some dilations and erosions
    # to remove any small blobs left in the mask
    mask = cv2.inRange(hsv, lrange, urange)
    mask = cv2.erode(mask, None, iterations=2)
    mask = cv2.dilate(mask, None, iterations=2)

    # Find contours in the mask and initialize the current (x, y) center of the ball
    cnts = cv2.findContours(mask.copy(), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)[-2]
    center = None
 
    # Only proceed if at least one contour was found
    if len(cnts) > 0:

        # Find the largest contour in the mask, then use
        # it to compute the minimum enclosing circle and
        # centroid
        c = max(cnts, key=cv2.contourArea)
        ((x, y), radius) = cv2.minEnclosingCircle(c)
        M = cv2.moments(c)
        center = (int(M["m10"] / M["m00"]), int(M["m01"] / M["m00"]))
        
        # Only proceed if the radius meets a minimum size
        if radius > 0:
            # draw the circle and centroid on the frame,
            cv2.circle(frame, (int(x), int(y)), int(radius),
                (0, 255, 255), 2)
            cv2.circle(frame, center, 5, (0, 0, 255), -1)

        # Show the frame to our screen
        cv2.namedWindow("Frame", cv2.WINDOW_NORMAL)
        cv2.resizeWindow("Frame", 960,560)
        cv2.imshow("Frame", frame)
        key = cv2.waitKey(500) & 0xFF
        return center

    else:
        # This way it is obvious that something went wrong
        raise ValueError('[error] - Robot cannot be found')
        #return (10000, 10000)

def length(a):
    """Euclidian length of a 2-vector"""
    return np.sqrt(a[0]**2 + a[1]**2)

############### Main routine ###########################

################ Argument Parser #######################
ap = argparse.ArgumentParser()
ap.add_argument("--config", default='config_calibration.yaml', 
                help="Configuration filename (default: DIRECTORY/config_calibration.yaml)")
ap.add_argument("-d", dest='directory',
                help="Directory where images for calibration are stored", 
                required=True)
ap.add_argument("-c", default='kinect2', dest='cam_type',
                help="Type of the camera (e.g., kinect1 or kinect2). The matrix\
                and the distortion coefficient should be present in the yaml \
                configuration file (default: kinect2)")
args = vars(ap.parse_args())

############### Importing configuration ################
cfgfile    = args['config']
directory  = args['directory']
cam_type   = args['cam_type']

config = import_configuration(directory + cfgfile) 

subject    = config['subject']
date       = config['date']
rangeLower = tuple(config['ranges']['lower'])
rangeUpper = tuple(config['ranges']['upper'])

print("[config] - Subject: " + subject)
print("[config] - Date: " + str(date))
print("[config] - Camera: " + cam_type)
print("[config] - Lower Range: " + ", ".join(str(x) for x in rangeLower))
print("[config] - Upper Range: " + ", ".join(str(x) for x in rangeUpper))
print("[config] - Directory: " + directory)

################### Main Routine ##########################

# Camera calibration
cam_matrix = np.array(config['calibration']['camera'][cam_type]['matrix'])
cam_distortion = np.array(config['calibration']['camera'][cam_type]['distortion'])

# Coordinates of calibration points and test points
wrd_points = np.float32(config['calibration']['coordinates']['points'])
idx_training = config['calibration']['coordinates']['training']
idx_testing  = config['calibration']['coordinates']['testing']
idx_starting_point = config['calibration']['coordinates']['starting']
npoints = len(wrd_points)

# Add robot radius in y direction as not center of robot was placed on points but rear point
correction = 19     # [cm]
for i in range(np.shape(wrd_points)[0]):
    wrd_points[i] += [0,correction,0]


# Look for files in given directory
images  = sorted(fnmatch.filter(os.listdir(directory), '*jpg'))
nimages = len(images)

# Check for the number of images == number of points
if npoints != nimages:
    print >> sys.stderr, "[error] - Different amount of images and coordinates"
    sys.exit()

#Load images and search for robot
img_points = []
for i, file in enumerate(images):
   
    # Re-create the filepath
    path = os.path.join(directory, file)
    
    # Reading current image
    print("[track] + Loading {}".format(path))
    img = cv2.imread(path)

    # Find image coordinates of robot
    try:
        coords = track_robot(img, rangeLower, rangeUpper)
        img_points.append(coords)
        print("        |- Robot coordinates: {}".format(coords))
    except ValueError as err:
        print("[warning] - object not found in image {}".format(i))
        sys.exit()

# Array with image coordinates
img_points = np.float32(img_points)

# Create train and test image points array
img_points_testing  = []
img_points_training = []
for i in idx_testing:
    img_points_testing.append(img_points[i])
   
for i in idx_training:
    img_points_training.append(img_points[i])

img_points_training = np.float32(img_points_training)
img_points_testing  = np.float32(img_points_testing)

# Create train and test world points array
wrd_points_testing  = []
wrd_points_training = []
for i in idx_testing:
    wrd_points_testing.append(wrd_points[i])
   
for i in idx_training:
    wrd_points_training.append(wrd_points[i])

wrd_points_training = np.float32(wrd_points_training)
wrd_points_testing  = np.float32(wrd_points_testing)


# Homography for conversion between image and real world coordinates

# Get rotation and translation vector, convert rvec to matrix
some_bool, rvec, tvec = cv2.solvePnP(wrd_points_training, img_points_training, 
                                     cam_matrix, np.zeros(4))
m_rot = cv2.Rodrigues(rvec)[0]

# Inverse rotation matrix
rot_inv = np.linalg.inv(m_rot)

# Inverse camera matrix
cam_inv = np.linalg.inv(cam_matrix)

print("[check] + Checking test points:")
dist = []
for i in reversed(range(len(img_points_testing))):
    img = np.array( img_points_testing[i])
    img = np.hstack((img, 1.))
        
    # Determine scaling factor s from fact that Z=0 in rw
    s = (np.dot(rot_inv,tvec)[2] / np.dot(np.dot(rot_inv, cam_inv),img)[2])

    # Determine real world coordinates
    wrd_points_computed = np.dot(rot_inv, (s*np.dot(cam_inv,img)-tvec[:,0])) 

    cpnt = [wrd_points_testing[i][0], wrd_points_testing[i][1]]
    ccmp = wrd_points_computed

    cdiff = [cpnt[0] - ccmp[0], cpnt[1] - ccmp[1]]

    print("        |- Reference point: ({:3f},{:3f})".format(cpnt[0], cpnt[1]))
    print("        |- Computed point:  ({:3f},{:3f})".format(ccmp[0], ccmp[1]))
    print("        |- Difference: ({:3f},{:3f})".format(cdiff[0], cdiff[1]))

    dist.append(length((cdiff[0], cdiff[1])))

print("[check] - Max. error: {:3f} cm for test point {}".format(np.amax(dist), np.argmax(dist)))
print("[check] - Mean error: {:3f} cm".format(np.mean(dist)))
print("[check] - Starting point: ({}, {})".format(img_points[idx_starting_point][0], img_points[idx_starting_point][1]))

# Save transformation info in npy file
transform = np.empty(5, dtype=object)
transform[0] = cam_inv
transform[1] = rot_inv
transform[2] = tvec
transform[3] = img_points[idx_starting_point]
transform[4] = wrd_points[idx_starting_point]

print('[out] - Saving calibration file in: ' + directory + "{}_{}_calibration.npy".format(subject, date))
savepath = os.path.join(directory, "{}_{}_calibration.npy".format(subject, date))
np.save(savepath, transform)

# Close any open windows
cv2.destroyAllWindows()
