#1/bin/bash
YO_VERSION=2.0.0
JENKINS_SLAVE=cd/jenkins-slave-nodejs8-angular:latest

while [[ $# -gt 1 ]]
do
	key="$1"
	case $key in
		--registry)
		OCP_DOCKER_REGISTRY="$2"
		shift # past argument
		;;
		--user)
		OCP_DOCKER_REGISTRY_USER="$2"
		shift # past argument
		;;
		--token)
		OCP_DOCKER_REGISTRY_TOKEN="$2"
		shift # past argument
		;;
		*)
		# unknown option
		;;
	esac
shift # past argument or value
done
# change to directory of this script
cd $(dirname "$0")

sudo docker login \
  -u ${OCP_DOCKER_REGISTRY_USER} -p ${OCP_DOCKER_REGISTRY_TOKEN} ${OCP_DOCKER_REGISTRY}

sudo docker pull \
  ${OCP_DOCKER_REGISTRY}/${JENKINS_SLAVE}

sudo docker tag \
  ${OCP_DOCKER_REGISTRY}/${JENKINS_SLAVE} ${JENKINS_SLAVE}
  
sudo docker build -t yo:latest -t yo:$YO_VERSION --build-arg YO_VERSION=$YO_VERSION .
