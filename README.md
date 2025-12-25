# lab
# create a folder for the docker container persistent storage, on Unraid it could be something like this: /mnt/user/appdata/taptap-mqtt/dockerbuild,  inside this folder we need these files:
Dockerfile #create this file an paste the contents from below,        
requirements.txt #from taptap-mqtt github repo
taptap #taptap binary from github       
taptap-mqtt.py #taptap-mqtt.py program from github

#contents of Dockerfile file so that we can build a docker image
-----

-----

#build the docker image:
cd /mnt/user/appdata/taptap-mqtt/dockerbuild
docker build -t taptap-mqtt .