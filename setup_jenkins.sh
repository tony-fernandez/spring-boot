#!/bin/bash
# Setup Jenkins Project
if [ "$#" -ne 2 ]; then
    echo "Usage:"
    echo "  $0 REPO CLUSTER"
    echo "  Example: $0 wkha https://github.com/wkulhanek/ParksMap na39.openshift.opentlc.com"
    exit 1
fi

REPO=$1
CLUSTER=$2
echo "Setting up Jenkins in project jenkins from Git Repo ${REPO} for Cluster ${CLUSTER}"

# Code to set up the Jenkins project to execute the
# three pipelines.
# This will need to also build the custom Maven Slave Pod
# Image to be used in the pipelines.
# Finally the script needs to create three OpenShift Build
# Configurations in the Jenkins Project to build the
# three micro services. Expected name of the build configs:
# * mlbparks-pipeline
# * nationalparks-pipeline
# * parksmap-pipeline
# The build configurations need to have two environment variables to be passed to the Pipeline:
# * GUID: the GUID used in all the projects
# * CLUSTER: the base url of the cluster used (e.g. na39.openshift.opentlc.com)

# To be Implemented by Student


# Provision jenkins from template
# Ensure that we are creating the objects in the correct project
oc project jenkins

# Call template to provision nexus objects
oc new-app -f openshift/templates/jenkins.yaml \
	-p REPO=${REPO} -p CLUSTER=${CLUSTER} \
	-p MEM_REQUESTS=1Gi -p MEM_LIMITS=2Gi -p VOLUME_CAPACITY=4G \
	-p CPU_REQUESTS=1 -p CPU_LIMITS=2 -n jenkins

while : ; do
  echo "Checking if Jenkins is Ready..."
  oc get pod -n jenkins|grep -v deploy|grep -v build|grep "1/1"
  [[ "$?" == "1" ]] || break
  echo "...no. Sleeping 10 seconds."
  sleep 10
done

echo "************************"
echo "Jenkins setup complete"
echo "************************"

exit 0