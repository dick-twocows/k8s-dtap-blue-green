#!/usr/bin/env bash


declare -x DTAP_ENVIRONMENT
read -r -p 'Enter DTAP environment, e.g. dev|test|stage|prod: ' DTAP_ENVIRONMENT

printf 'Creating %s-blue-green.tfvars...\n' "${DTAP_ENVIRONMENT}"
envsubst <'./dtap/blue-green.tfvars.envsubst' >./"${DTAP_ENVIRONMENT}-blue-green.tfvars"

declare -x BLUE_GREEN

BLUE_GREEN='blue'
printf 'Creating %s-%s.tf...\n' "${DTAP_ENVIRONMENT}" "${BLUE_GREEN}"
envsubst <'./dtap/blue-green.tf.envsubst' >./"${DTAP_ENVIRONMENT}-${BLUE_GREEN}.tf"

BLUE_GREEN='green'
printf 'Creating %s-%s.tf...\n' "${DTAP_ENVIRONMENT}" "${BLUE_GREEN}"
envsubst <'./dtap/blue-green.tf.envsubst' >./"${DTAP_ENVIRONMENT}-${BLUE_GREEN}.tf"

declare -x BLUE_GREEN_ACTIVE
BLUE_GREEN_ACTIVE='blue'
printf 'Creating %s.tf, %s is active...\n' "${DTAP_ENVIRONMENT}" "${BLUE_GREEN_ACTIVE}"
envsubst <'./dtap/environment.tf.envsubst' >./"${DTAP_ENVIRONMENT}.tf"

printf 'ok\n'
