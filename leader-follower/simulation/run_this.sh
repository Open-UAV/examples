#!/bin/bash
source /simulation/inputs/parameters/swarm.sh
source /opt/ros/kinetic/setup.bash
source ~/catkin_ws/devel/setup.bash

rm /simulation/outputs/*.csv
LOOP_EDGE=20

#Xvfb :1 -screen 0 1600x1200x16  &
#export DISPLAY=:1.0

echo "Setup..."
python /simulation/inputs/setup/testCreateUAVSwarm.py $num_uavs &> /dev/null &
sleep 15
python /simulation/inputs/setup/testArmAll.py $num_uavs &> /dev/null &
sleep 1
python /simulation/inputs/controllers/test_1_Loop.py $LOOP_EDGE 1 1 0 &> /dev/null &


for((i=1;i<$num_uavs;i+=1))
do
    one=1
    python /simulation/inputs/controllers/test_3_Follow.py $(( i + one)) $i  $(( i + one)) $i &> /dev/null &
    sleep 1
done

echo "Measures..."
python /simulation/inputs/measures/measureInterRobotDistance.py $num_uavs 1 &> /dev/null &

roslaunch rosbridge_server rosbridge_websocket.launch ssl:=false &> /dev/null &
rosrun web_video_server web_video_server _port:=80 _server_threads:=100 &> /dev/null &
tensorboard --logdir=/simulation/outputs/ --port=8008 &> /dev/null &
for((i=1;i<=$num_uavs;i+=1))
do
        /usr/bin/python -u /opt/ros/kinetic/bin/rostopic echo -p /mavros$i/local_position/odom > /simulation/outputs/uav$i.csv &
    done
    /usr/bin/python -u /opt/ros/kinetic/bin/rostopic echo -p /measure > /simulation/outputs/measure.csv &


    sleep $duration_seconds
    cat /simulation/outputs/measure.csv | awk -F',' '{sum+=$2; ++n} END { print sum/n }' > /simulation/outputs/average_measure.txt

