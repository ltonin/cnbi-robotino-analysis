#!/usr/bin/env python
# -*- coding: utf-8 -*-


"""
@author: Luca Tonin, Felix Bauer
blob detection in track_robot(frame) inspired by 
https://www.pyimagesearch.com/2015/09/14/ball-tracking-with-opencv/

Call program with following options:
    --config <the yaml configuration file>
    -p show preview window with robot and marker

While tracking the robot, the program will make sure for each frame the newly 
determined robot position is not too far away (max_dist) from the previous one. 
Otherwise it will ignore the frame and print a warning. If no robot is found at 
all, a warning is printed as well and the frame is ignored.

If too many warnings are printed, use -p option to check what is going on and
adapt HSV range with rangeLower and rangeUpper.

Trajectories are saved in npy-file in the directory given with option -d, 
as array of arrays, where each subarray contains the x and y coordinates of 
one trial.

"""

import rosbag
import cv2
import argparse
import cv_bridge
import numpy as np
import matplotlib.pyplot as plt
import os
import yaml
import fnmatch
import pdb


n_tasks = 7
#maximum distance between two points before assuming an error (in cm)
max_dist = 200.

#TiD dict:
task0 = 26112
task0_end = 58880
evtResume = 25352
evtPause = 25353

################ Functions #######################

# Import configuration from yaml file
def import_configuration(filename):

    try:
        with open(filename, 'r') as file:
            cfg = yaml.load(file)
    except Exception as error:
        print("Cannot open the file:" + filename)
    return cfg


def distance(a, b):
    return np.sqrt((a[0]-b[0])**2 + (a[1]-b[1])**2)

def track_robot(frame, previous=None):
    # blur frame and convert it to the HSV
    # color space
    # blurred = cv2.GaussianBlur(frame, (11, 11), 0)
    hsv = cv2.cvtColor(frame, cv2.COLOR_BGR2HSV)
 
    # construct a mask for the color "green", then perform
    # a series of dilations and erosions to remove any small
    # blobs left in the mask
    mask = cv2.inRange(hsv, rangeLower, rangeUpper)
    mask = cv2.erode(mask, None, iterations=2)
    mask = cv2.dilate(mask, None, iterations=2)

    # find contours in the mask and initialize the current
    # (x, y) center of the ball
    cnts = cv2.findContours(mask.copy(), cv2.RETR_EXTERNAL,
        cv2.CHAIN_APPROX_SIMPLE)[-2]
    
    center = (10000, 10000)
 
    # only proceed if at least one contour was found
    if len(cnts) > 0:

        c = np.array([])
        dist_prev = 10000000
        for ct in cnts:
            dist_prev = distance(center, previous)
            (center1, radius) = cv2.minEnclosingCircle(ct)
            #check if new contour is closer to previous robot position and if not too small
            if distance(center1, previous) < dist_prev:# and radius > 2:
                center = center1
                c = ct
        if np.size(c) != 0:
            ((x, y), radius) = cv2.minEnclosingCircle(c)
            M = cv2.moments(c)
            center = (int(M["m10"] / M["m00"]), int(M["m01"] / M["m00"]))
            #print('(x,y): {},{}'.format(x,y))
            #print('center: {}'.format(center))
            # only proceed if the radius meets a minimum size
            if radius > 0:
                # draw the circle and centroid on the frame,
                cv2.circle(frame, (int(x), int(y)), int(radius),
                    (0, 255, 255), 2)
                cv2.circle(frame, center, 5, (0, 0, 255), -1)
        else:
            print("Nothing useful found")
    else:
        print("Nothing found at all")
    # show the frame to our screen
    if args['preview']:
        cv2.namedWindow("Frame", cv2.WINDOW_NORMAL)
        cv2.resizeWindow("Frame", 960,560)
        cv2.imshow("Frame", frame)
        key = cv2.waitKey(1) & 0xFF
        
    return center


def transform_image_to_world(coordinates, cam_inv, rot_inv, tvec):
    x = coordinates[0]
    y = coordinates[1]
    img_coords = np.array([ x, y, 1])

    #Determine scaling factor s from fact that Z=0 in rw
    s = (np.dot(rot_inv,tvec)[2] / np.dot(np.dot(rot_inv, cam_inv),img_coords)[2])

    #Determine real world coordinates
    rw_coords = np.dot(rot_inv, (s*np.dot(cam_inv,img_coords)-tvec[:,0]))
    return (rw_coords[0], rw_coords[1])





def analyze_infobag(infobag, wrd_start, tid_name, tic_name, odom_name, run=None):
    print("[track] - Analyzing rosbag")
    #iterate over messages
    in_trial = 0
    starttimes = []
    endtimes = []
    tasks = []
    probabilities = []
    odometry = []
    start_odom=(0,0)

    #Loop over all messages
    for topic, msg, t in infobag.read_messages():
        #Tid topic
        #trial begins
        if topic == tid_name and msg.event in range(task0+1, task0+n_tasks+1):
            time = int(t.to_sec()*1000)
            starttimes.append(time)
            in_trial = msg.event-task0
            tasks.append(msg.event-task0)
            #print(in_trial)
            #print(time)
            tic = []
            odom = []
            start_odom = current_odom
        #trial ends
        if topic == tid_name and msg.event in range(task0_end+1, task0_end+n_tasks+1):
            if not in_trial == msg.event-task0_end:
                print("[warning] - Something went wrong - Task of ending trial does not match task of active trial")
            probabilities.append(tic)
            odometry.append(odom)
            in_trial = 0
            time = int(t.to_sec()*1000)
            endtimes.append(time)
            #print(time)
               
        #Tic topic
        #Store integrated probabilities for active trial
        if topic == tic_name and not in_trial == 0:
            tic.append(msg.classifier.classes[0].value)

        #Odometry topic
        if topic == odom_name:
            current_odom = (msg.pose.pose.position.x,msg.pose.pose.position.y)
            #Store odometry for active trial
            if not in_trial == 0:
                odom.append( [msg.pose.pose.position.x-start_odom[0]+wrd_start[0],msg.pose.pose.position.y-start_odom[1]+wrd_start[1]] )

    return starttimes, endtimes, tasks, probabilities, odometry


def get_video_trajectories(vidbag, wrd_start, pnt_start, starttimes, endtimes, track_name):
    print("[track] - Getting video trajectories")
    i = 0
    trajectory = []
    trajectories = []
    world_old = wrd_start
    #img_start = args["start"]
    img_start = pnt_start
    img_old = img_start

    #loop over messages
    in_trial = False
    for topic, msg, t in vidbag.read_messages(topics=[track_name]):
        time = int(t.to_sec()*1000)
        #print(time) 
        if time in range(starttimes[i], endtimes[i]):
            in_trial = True
            img = bridge.compressed_imgmsg_to_cv2(msg)
            im_location = track_robot(img, img_old)
            if im_location == (10000,10000):
                print("[warning] - No object detected at t={}. Adding nan".format(time))
                #world_old = (float('nan'), float('nan'))
                world_coordinates = (float('nan'), float('nan'))
                trajectory.append(list(world_coordinates))
            else:
                #Check if im_location "jumps"    
                world_coordinates = transform_image_to_world(im_location,
                        camera_inv, rotation_inv, transf_vect )
                #print(im_location)
                #print(world_coordinates)
                if distance(world_coordinates,world_old) >= max_dist:
                    print("[warning] - Large distance between new and old location: {} vs {}- nan point (t: {})".format(world_coordinates,world_old, t))
                    world_coordinates = world_old
                    world_old = world_coordinates
                    img_old = im_location
                    trajectory.append(list((float('nan'), float('nan'))))
                else:
                    #world_old = world_coordinates
                    #img_old = im_location
                    world_old = world_coordinates
                    img_old = im_location
                    trajectory.append(list(world_old))
            #trajectory.append(list(world_old))
                       
        if (time > endtimes[i] and in_trial):
            in_trial = False
            i += 1
            trajectories.append(trajectory)
            trajectory = []
            cv2.destroyAllWindows()
            print("[track] - Trial {} finished".format(i))
            world_old = wrd_start
            img_old = img_start
            if i >= len(starttimes):
                return trajectories
    if i < len(starttimes):
        print("[warning] - Not all trials seem to be part of the video")
    return trajectories


############### Main routine ###########################

################ Argument Parser #######################

#parse name of videobagfile, bagfile, subject, run
ap = argparse.ArgumentParser()
ap.add_argument("--config", help="Configuration filename", required=True)
ap.add_argument("-p", "--preview",
    help="Show preview of video and tracked position", action='store_true')
args = vars(ap.parse_args())

############### Importing configuration ################
cfgfile    = args['config']

config = import_configuration(cfgfile) 

subject    = config['subject']
date       = config['date']
rangeLower = tuple(config['ranges']['lower'])
rangeUpper = tuple(config['ranges']['upper'])
track_dir  = config['folderpath']['tracking']
robot_dir  = config['folderpath']['robot']
calib_dir  = config['folderpath']['calibration']
calib_file = calib_dir + subject + "_" + str(date) + "_" + "calibration.npy"

topic_track = config['rostopics']['video']
topic_tid   = config['rostopics']['tid']
topic_tic   = config['rostopics']['tic']
topic_odom  = config['rostopics']['odom']


print("[config] - Subject: " + subject)
print("[config] - Date: " + str(date))
print("[config] - Lower Range: " + ", ".join(str(x) for x in rangeLower))
print("[config] - Upper Range: " + ", ".join(str(x) for x in rangeUpper))
print("[config] - Video tracking directory: " + track_dir)
print("[config] - Bag robot directory: " + robot_dir)
print("[config] - Calibration directory: " + calib_dir)
print("[config] - Calibration file: " + calib_file)
print("[config] - Topic video: " + topic_track)
print("[config] - Topic tid: " + topic_tid)
print("[config] - Topic tic: " + topic_tic)
print("[config] - Topic odometry: " + topic_odom)


# Load coordinate transformation data
transform    = np.load(calib_file)
camera_inv   = transform[0]
rotation_inv = transform[1]
transf_vect  = transform[2]
pnt_start    = transform[3]
wrd_start    = transform[4]

# Get robot bag files
robot_list = sorted(fnmatch.filter(os.listdir(robot_dir), subject + '*.mobile.bag'))

print("[config] + Using the following rosbags for robot:")
for i, file in enumerate(robot_list):
    print("         |- {}".format(robot_dir + file))

# Get video bag files
track_list = sorted(fnmatch.filter(os.listdir(track_dir), subject + '*.mobile.bag'))

print("[config] + Using the following rosbags for video tracking:")
for i, file in enumerate(track_list):
    print("         |- {}".format(track_dir + file))

# Initialize CV bridge
bridge = cv_bridge.CvBridge()


for run, (bfile, vfile) in enumerate(zip(robot_list, track_list)):
    
    print("[tracking] - Starting run {}: {}".format(run+1, vfile))
    
    ## load bagfiles
    infobag_path  = os.path.join(robot_dir, bfile)
    videobag_path = os.path.join(track_dir, vfile)
    infobag = rosbag.Bag(infobag_path)
    vidbag  = rosbag.Bag(videobag_path)

    starttimes, endtimes, tasks, probabilities, odometry = analyze_infobag(infobag, wrd_start, topic_tid, topic_tic, topic_odom, run=run)

    video_trajectories = get_video_trajectories(vidbag, wrd_start, pnt_start, starttimes, endtimes, topic_track)

    v = []
    trIdx = []
    tskIdx = []
    for i, x in enumerate(video_trajectories):
        v.extend(x)
        cid=np.empty(len(x))
        cid.fill(i)
        trIdx.extend(cid)
        ctsk = np.empty(len(x))
        ctsk.fill(tasks[i])
        tskIdx.extend(ctsk)

    #v = np.array([np.array(x) for x in video_trajectories])
    
    v = np.array(v)
    trIdx = np.array(trIdx, ndmin=2).T
    tskIdx = np.array(tskIdx, ndmin=2).T

    data = np.concatenate((v, trIdx, tskIdx), 1)

    #pdb.set_trace()
    # Save trajectory
    save_dir = track_dir + "trajectories"
    if not os.path.exists(save_dir):
        print("[out] - Creating new folder: " + save_dir)
        os.makedirs(save_dir)

    tfile, text = os.path.splitext(vfile)
    #save_path = os.path.join(save_dir, tfile + ".npy")
    save_path = os.path.join(save_dir, tfile + ".csv")
    
    print("[out] - Saving trajectory in: " + save_path)
    #np.save(save_path, v)
    np.savetxt(save_path, data, "%.3f")


