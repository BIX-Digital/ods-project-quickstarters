#!/usr/bin/env bash

# This script sets up the resource objects for a certain component:
# * image streams
# * build configs: pipelines
# * build configs: images
# * services
# * routes

# Use -gt 1 to consume two arguments per pass in the loop (e.g. each
# argument has a corresponding value to go with it).
# Use -gt 0 to consume one or more arguments per pass in the loop (e.g.
# some arguments don't have a corresponding value to go with it such
# as in the --default example).
# note: if this is set to -gt 0 the /etc/hosts part is not recognized ( may be a bug )
while [[ $# -gt 1 ]]
do
key="$1"

case $key in
    -p|--project)
    PROJECT="$2"
    shift # past argument
    ;;
    -c|--component)
    COMPONENT="$2"
    shift # past argument
    ;;
    -b|--bitbucket)
    BITBUCKET_REPO="$2"
    shift # past argument
    ;;
    -ne|--nexus)
    NEXUS_HOST="$2"
    shift # past argument
    ;;
    *)
            # unknown option
    ;;
esac
shift # past argument or value
done

if [ -z ${PROJECT+x} ]; then
    echo "PROJECT is unset, but required";
    exit 1;
else echo "PROJECT=${PROJECT}"; fi
if [ -z ${COMPONENT+x} ]; then
    echo "COMPONENT is unset, but required";
    exit 1;
else echo "COMPONENT=${COMPONENT}"; fi
if [ -z ${NEXUS_HOST+x} ]; then
    echo "NEXUS_HOST is unset, but required";
    exit 1;
else echo "NEXUS_HOST=${NEXUS_HOST}"; fi

# iterate over different environments
for devenv in dev test ; do
    # create resources
    echo "${PROJECT} -- ${COMPONENT} -- ${BITBUCKET_REPO}"
    oc process cd//component-environment PROJECT=${PROJECT} COMPONENT=${COMPONENT} ENV=${devenv}  | oc create -n ${PROJECT}-${devenv} -f-

    oc process cd//component-route PROJECT=${PROJECT} COMPONENT=${COMPONENT} ENV=${devenv} | oc create -n ${PROJECT}-${devenv} -f-

    # create image build configs
    oc process cd//bc-docker PROJECT=${PROJECT} COMPONENT=${COMPONENT} ENV=${devenv} | oc create -n ${PROJECT}-${devenv} -f-

    # create build config docker strategy from statement
    oc patch bc ${COMPONENT} -p '{"spec":{"strategy":{"dockerStrategy":{"from":{"kind":"ImageStreamTag","name":"openresty-nginx:1.0","namespace":"shared-services"}},"type":"Docker"}}}' -n ${PROJECT}-${devenv}

    # set route host to gateway; right now not possible since --> host field is immutable
    # newroute=$(host=$(oc get --export route ${COMPONENT} -o yaml -n ${PROJECT}-${devenv} | grep 'host:' | cut -d ':' -f 2)| val=$(echo ${host: : -2}) | ret=$(echo ${val:2}) | echo "${ret/${COMPONENT}/gateway}")
    # oc patch route ${COMPONENT} -p "{\"spec\":{\"host\":\"${newroute}\"}}" -n ${PROJECT}-${devenv}

    # create component environment variables
    echo "--> setting environment variables for component ${COMPONENT} in env ${devenv}";
    oc set triggers dc/${COMPONENT} --from-config --remove -n ${PROJECT}-${devenv}
    oc set env dc/${COMPONENT} --env=SERVICE=change-to-your-target-component-name.${PROJECT}-${devenv}.svc.cluster.local -n ${PROJECT}-${devenv}
    oc set env dc/${COMPONENT} --env=SERVER_SIGNATURE=${COMPONENT} -n ${PROJECT}-${devenv}
    oc set env dc/${COMPONENT} --env=WAF_MODSECURITY=off -n ${PROJECT}-${devenv}
    oc set env dc/${COMPONENT} --env=SYSLOG_NG=off -n ${PROJECT}-${devenv}
    oc set env dc/${COMPONENT} --env=SYSLOG_NG_TO=127.0.0.1 -n ${PROJECT}-${devenv}
    oc set env dc/${COMPONENT} --env=SYSLOG_NG_TAGS=bix-${PROJECT}-${devenv} -n ${PROJECT}-${devenv}
    oc set triggers dc/${COMPONENT} --from-config -n ${PROJECT}-${devenv}

    # setting up resource limits: maximum of 4 CPU and 4GB memory, minimum of 0.5 CPU and 512MB memory
    oc set resources dc ${COMPONENT} --limits=cpu=4,memory=4Gi --requests=cpu=512m,memory=512Mi -n ${PROJECT}-${devenv}

done
