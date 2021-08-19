#!/bin/bash
set +u
readonly PARENT_JOB_VOLUME=${PARENT_JOB_VOLUME}
readonly BUILD_PODMAN_IMAGE=${BUILD_PODMAN_IMAGE:-'localhost/automatons'}
readonly JENKINS_HOME_DIR=${JENKINS_HOME_DIR:-'/home/jenkins/'}
readonly JENKINS_UID=${JENKINS_UID:-'1000'}
readonly JENKINS_GUID=${JENKINS_GUID:-"${JENKINS_UID}"}
readonly JOB_NAME=${JOB_NAME}
readonly BUILD_ID=${BUILD_ID}
readonly CONTAINER_SERVER_HOSTNAME=${CONTAINER_SERVER_HOSTNAME:-'olympus'}
readonly CONTAINER_SERVER_IP=${CONTAINER_SERVER_IP:-'10.88.0.1'}
set -u

add_parent_volume_if_provided() {
  if [ -n "${PARENT_JOB_VOLUME}" ]; then
    echo "-v '${PARENT_JOB_VOLUME}:/parent_job/:ro'"
  fi
}

# shellcheck source=./library.sh
source "${HERA_HOME}"/library.sh

is_defined "${WORKSPACE}" "No WORKSPACE provided." 1
is_dir "${WORKSPACE}" "Workspace provided is not a dir: ${WORKSPACE}" 2
is_defined "${JOB_NAME}" "No JOB_NAME provided." 3
is_defined "${BUILD_ID}" "No BUILD_ID provided." 4
is_defined "${CONTAINER_SERVER_HOSTNAME}" "No hostname provided for the container server"
is_defined "${CONTAINER_SERVER_IP}" 'No IP address provided for the container server'

# When running a job in parallel the workspace folder is not the same as JOB_NAME
readonly JOB_DIR=$(basename "${WORKSPACE}")
readonly CONTAINER_TO_RUN_NAME=${CONTAINER_TO_RUN_NAME:-$(container_name "${JOB_NAME}" "${BUILD_ID}")}
readonly CONTAINER_COMMAND=${CONTAINER_COMMAND:-"${WORKSPACE}/hera/wait.sh"}

# shellcheck disable=SC2016
run_ssh "podman run \
            --userns=keep-id -u ${JENKINS_UID}:${JENKINS_GUID} \
            --name "${CONTAINER_TO_RUN_NAME}" \
             --add-host=${CONTAINER_SERVER_HOSTNAME}:${CONTAINER_SERVER_IP}  \
            --rm $(add_parent_volume_if_provided) \
            --workdir ${WORKSPACE} \
            -v "${JENKINS_HOME_DIR}/workspace/${JOB_DIR}":${WORKSPACE}:rw \
            -v /opt/:/opt/:ro \
            -v "${JENKINS_HOME_DIR}/.ssh/":/var/jenkins_home/.ssh/:ro \
            -v "${JENKINS_HOME_DIR}/.gitconfig":/var/jenkins_home/.gitconfig:ro \
	        -d ${BUILD_PODMAN_IMAGE} '${CONTAINER_COMMAND}'"
