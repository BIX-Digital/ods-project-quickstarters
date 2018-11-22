#!/bin/bash
set -e

usage() {
    echo "usage: sh $0 -p <project id> -o <openshift host> -b <bitbucket host> -c <http basic auth credentials \
for bitbucket host> -t <target env to clone to> -s <source env to clone from>";
}

while [[ "$#" > 0 ]]; do case $1 in
  -o=*|--openshift-host=*) OPENSHIFT_HOST="${1#*=}";;
  -o|--openshift-host) OPENSHIFT_HOST="$2"; shift;;

  -b=*|--bitbucket-host=*) BITBUCKET_HOST="${1#*=}";;
  -b|--bitbucket-host) BITBUCKET_HOST="$2"; shift;;

  -c=*|--credentials=*) CREDENTIALS="${1#*=}";;
  -c|--credentials) CREDENTIALS="$2"; shift;;

  -p=*|--project-id=*) PROJECT_ID="${1#*=}";;
  -p|--project-id) PROJECT_ID="$2"; shift;;

  -s=*|--source-env=*) SOURCE_ENV="${1#*=}";;
  -s|--source-env) SOURCE_ENV="$2"; shift;;

  -t=*|--target-env=*) TARGET_ENV="${1#*=}";;
  -t|--target-env) TARGET_ENV="$2"; shift;;

  -d|--debug) DEBUG="true"; shift;;

  *) echo "Unknown parameter passed: $1"; usage; exit 1;;
esac; shift; done

if [[ -z "$PROJECT_ID" ]]; then
    echo "[ERROR]: No project id set - required value"
    usage
    exit 1
fi
if [[ -z "$BITBUCKET_HOST" ]]; then
    echo "[ERROR]: No BitBucket host set - required value"
    usage
    exit 1
fi
if [[ -z "$CREDENTIALS" ]]; then
    echo "[ERROR]: No BitBucket credentials set - required value"
    usage
    exit 1
fi
if [[ -z "$TARGET_ENV" ]]; then
    echo "[ERROR]: No target environment set - required value"
    usage
    exit 1
fi
if [[ -z "$SOURCE_ENV" ]]; then
    echo "[ERROR]: No source environment set - required value"
    usage
    exit 1
fi
if [[ -z "$OPENSHIFT_HOST" ]]; then
    echo "[ERROR]: No OpenShift host set - required value"
    usage
    exit 1
fi

echo "Provided params: \
- PROJECT_ID: $PROJECT_ID \
- OPENSHIFT_HOST: $OPENSHIFT_HOST \
- BITBUCKET_HOST: $BITBUCKET_HOST \
- CREDENTIALS: **** \
- SOURCE_ENV: $SOURCE_ENV \
- TARGET_ENV: $TARGET_ENV"

SOURCE_PROJECT="$PROJECT_ID-$SOURCE_ENV"
TARGET_PROJECT="$PROJECT_ID-$TARGET_ENV"

echo "[INFO]: creating workplace: mkdir -p oc_migration_scripts/migration_config"
mkdir -p oc_migration_scripts/migration_config
cd oc_migration_scripts
echo $(pwd)
export_url="https://$BITBUCKET_HOST/projects/opendevstack/repos/ods-project-quickstarters/raw/ocp-templates/scripts/export_ocp_project_metadata.sh?at=refs%2Fheads%2Fproduction"
curl --fail -s --user $CREDENTIALS -G $export_url -d raw -o export.sh
import_url="https://$BITBUCKET_HOST/projects/opendevstack/repos/ods-project-quickstarters/raw/ocp-templates/scripts/import_ocp_project_metadata.sh?at=refs%2Fheads%2Fproduction"
curl --fail -s --user $CREDENTIALS -G $import_url -d raw -o import.sh

cd migration_config
echo $(pwd)
source_url="https://$BITBUCKET_HOST/projects/opendevstack/repos/ods-configuration/raw/ods-project-quickstarters/ocp-templates/scripts/ocp_project_config_source"
curl --fail -s --user $CREDENTIALS -G $source_url -d raw -o ocp_project_config_source
target_url="https://$BITBUCKET_HOST/projects/opendevstack/repos/ods-configuration/raw/ods-project-quickstarters/ocp-templates/scripts/ocp_project_config_target"
curl --fail -s --user $CREDENTIALS -G $target_url -d raw -o ocp_project_config_target

cd ..
echo $(pwd)

git_url="https://$CREDENTIALS@$BITBUCKET_HOST/scm/$PROJECT_ID/$PROJECT_ID-occonfig-artifacts.git"

if [[ -z "$DEBUG" ]]; then
  verbose=""
else
  verbose="-v true"
fi
echo "[INFO]: export resources from $SOURCE_ENV"
sh export.sh -p $PROJECT_ID -h $OPENSHIFT_HOST -e $SOURCE_ENV -g $git_url -cpj $verbose
echo "[INFO]: import resources into $TARGET_ENV"
sh import.sh -h $OPENSHIFT_HOST -p $PROJECT_ID -e $SOURCE_ENV -g $git_url -n $TARGET_PROJECT $verbose --apply true

echo "[INFO]: cleanup workplace"
cd ..
rm -rf oc_migration_scripts

echo "[INFO]: import image tags from $SOURCE_ENV"
oc get is --no-headers -n $SOURCE_PROJECT | awk '{print $2}' | while read DOCKER_REPO; do
  echo "[INFO]: importing latest image from ${DOCKER_REPO}"
  image="${DOCKER_REPO}:latest"
  oc tag ${SOURCE_PROJECT}/${image} ${image} -n $TARGET_PROJECT || true
done