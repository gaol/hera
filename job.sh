#!/bin/bash
readonly BUILD_SCRIPT=${BUILD_SCRIPT:-'1'}
readonly ENV_FILE=$1
shift

# shellcheck source=library.sh
source "${HERA_HOME}"/library.sh

dumpBuildEnv() {
  local env_dump_file

  env_dump_file=${1}

  is_defined "${env_dump_file}" "No filename provided to store env."

  env | grep -e 'WORKSPACE' -e 'JAVA_HOME' -e 'MAVEN_' | sed -e 's;^;export ;;' > "${env_dump_file}"
  chmod +x "${env_dump_file}"
  if [ "${PIPESTATUS[0]}" -ne "0" ]; then
    echo "Env command failed"
    exit 1
  fi
}

is_defined "${BUILD_SCRIPT}" 'No build script provided' 2

readonly CONTAINER_NAME=$(container_name "${JOB_NAME}" "${BUILD_ID}")

dumpBuildEnv "${HERA_HOME}/build-env.sh"

# format in the env file is line delimited xx=yy
env_file_if_enabled() {
  if [ -n "${ENV_FILE}" ]; then
    env_lines=""
    while IFS= read -r line
    do
      env_lines+=" -e $line"
    done < <(grep -v '^ *#' < "${ENV_FILE}")
    echo "${env_lines}"
  fi
}

set +u
run_ssh "podman exec $(env_file_if_enabled) \
        -e LANG='en_US.utf8' \
        -e JOB_NAME="${JOB_NAME}" \
        -e PARENT_JOB_NAME="${PARENT_JOB_NAME}" \
        -e PARENT_JOB_BUILD_ID="${PARENT_JOB_BUILD_ID}" \
        -e WORKSPACE="${WORKSPACE}" \
        -e WORKDIR="${WORKDIR}" \
        -e JAVA_HOME="${JAVA_HOME}" \
        -e HARMONIA_SCRIPT="${HARMONIA_SCRIPT}" \
        -e TO_ADDRESS="${TO_ADDRESS}" \
        -e RULE_NAME="${RULE_NAME}" \
        -e REPORT_TITLE="${REPORT_TITLE}" \
        -e LOGGER_PROJECT_CODE="${LOGGER_PROJECT_CODE}" \
        -e DEBUG="${DEBUG}" \
        -e MAVEN_HOME="${MAVEN_HOME}" \
        -e MAVEN_OPTS='"${MAVEN_OPTS}"' \
        -e MAVEN_GOALS='"${MAVEN_GOALS}"' \
        -e BUILD_ID="${BUILD_ID}" \
        -e BUILD_COMMAND="${BUILD_COMMAND}" \
        -e COPY_ARTIFACTS="${COPY_ARTIFACTS}" \
        -e RERUN_FAILING_TESTS="${RERUN_FAILING_TESTS}" \
        -e MAVEN_SETTINGS_XML="${MAVEN_SETTINGS_XML}" \
        -e PULL_REQUEST_PROCESSOR_HOME="${PULL_REQUEST_PROCESSOR_HOME}" \
        -e VERSION="${VERSION}" \
        -e COMPONENT_UPGRADE_LOGGER="${COMPONENT_UPGRADE_LOGGER}" \
        -e NEXUS_URL=${NEXUS_URL} \
        -e NEXUS_REPO=${NEXUS_REPO} \
        -e NEXUS_CREDENTIALS=${NEXUS_CREDENTIALS} \
        -e GIT_REPOSITORY_URL="${GIT_REPOSITORY_URL}" \
        -e GIT_REPOSITORY_BRANCH="${GIT_REPOSITORY_BRANCH}" \
        -e TOOLS_DIR="${TOOLS_DIR}" \
        -e TOOLS_MOUNT="${TOOLS_MOUNT}" \
        -e BUILD_MOLECULE_SLAVE_SSHD_PORT="${BUILD_MOLECULE_SLAVE_SSHD_PORT}" \
        -e PROJECT_DOWNSTREAM_NAME="${PROJECT_DOWNSTREAM_NAME}" \
        -ti ${CONTAINER_NAME} '${BUILD_SCRIPT}' ${@}" | removeColorsControlCharactersFromOutput
exit "${PIPESTATUS[0]}"
