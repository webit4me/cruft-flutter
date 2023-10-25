#!/usr/bin/env bash

### WARNING! This is a generated file and should ONLY be edited in https://github.com/hmrc/telemetry-docker-resources

# A helper tool to assist us maintaining docker functions
# Intention here is to keep this files and all its functions reusable for all Telemetry repositories

set -o errexit
set -o nounset

#####################################################################
## Beginning of the configurations ##################################

BASE_LOCATION="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE_NAME="{{ cookiecutter.docker_image_name_formatted }}"

## End of the configurations ########################################
#####################################################################

debug_env(){
  echo BASE_LOCATION="${BASE_LOCATION}"
  echo IMAGE_NAME="${IMAGE_NAME}"
}

# Creates a release tag in the repository
cut_release() {
  print_begins
  poetry run cut-release
  print_completed
}

# Build the Docker image
package() {
  print_begins
  export_version

  echo Export poetry packages
  rm -fv requirements.txt requirements-tests.txt
  poetry export --without-hashes --format requirements.txt --output "requirements.txt"
  poetry export --without-hashes --format requirements.txt --with dev --output "requirements-tests.txt"

  echo Building the images

{%- if cookiecutter.docker_include_default_build|lower == "true" %}
  {%- if cookiecutter.docker_build_options_default is defined and cookiecutter.docker_build_options_default|length %}
  docker build --tag "{{cookiecutter.aws_account_id}}.dkr.ecr.{{cookiecutter.aws_region}}.amazonaws.com/{{cookiecutter.docker_image_name_formatted}}:${VERSION}" {{cookiecutter.docker_build_options_default|safe}} .
  {%- else %}
  docker build --tag "{{cookiecutter.aws_account_id}}.dkr.ecr.{{cookiecutter.aws_region}}.amazonaws.com/{{cookiecutter.docker_image_name_formatted}}:${VERSION}" .
  {%- endif %}
{%- endif %}
{%- for key, value in cookiecutter.docker_build_options_additional|dictsort %}
  docker build --tag "{{cookiecutter.aws_account_id}}.dkr.ecr.{{cookiecutter.aws_region}}.amazonaws.com/{{cookiecutter.docker_image_name_formatted}}:${VERSION}{{key|safe}}" {{value|safe}} .
{%- endfor %}
  print_completed
}

# Bump the function's version when appropriate
prepare_release() {
  print_begins
  poetry run prepare-release
  export_version
  print_completed
}

publish_to_ecr() {
  print_begins
  export_version

  echo Authenticating with ECR
  aws ecr get-login-password --region "{{cookiecutter.aws_region}}" | docker login --username AWS --password-stdin "{{cookiecutter.aws_account_id}}.dkr.ecr.{{cookiecutter.aws_region}}.amazonaws.com"

  echo Pushing the images

{%- if cookiecutter.docker_include_default_build|lower == "true" %}
  docker push "{{cookiecutter.aws_account_id}}.dkr.ecr.{{cookiecutter.aws_region}}.amazonaws.com/{{cookiecutter.docker_image_name_formatted}}:${VERSION}"
{%- endif %}
{%- for key, value in cookiecutter.docker_build_options_additional|dictsort %}
  docker push "{{cookiecutter.aws_account_id}}.dkr.ecr.{{cookiecutter.aws_region}}.amazonaws.com/{{cookiecutter.docker_image_name_formatted}}:${VERSION}{{key|safe}}"
{%- endfor %}
  print_completed
}

#####################################################################
## Beginning of the helper methods ##################################

export_version() {

  if [ ! -f ".version" ]; then
    echo ".version file not found! Have you run prepare_release command?"
    exit 1
  fi

  VERSION=$(cat .version)
  export VERSION=${VERSION}
}

help() {
  echo "$0 Provides set of commands to assist you with day-to-day tasks when working in this project"
  echo
  echo "Available commands:"
  echo -e " - prepare_release\t\t Bump the function's version when appropriate"
  echo -e " - cut_release\t\t Creates a release tag in the repository"
  echo -e " - package\t\t\t Build the Docker image"
  echo -e " - publish_to_ecr\t Upload Docker image to internal-base ECR"
  echo
}

print_begins() {
  echo -e "\n-------------------------------------------------"
  echo -e ">>> ${FUNCNAME[1]} Begins\n"
}

print_completed() {
  echo -e "\n### ${FUNCNAME[1]} Completed!"
  echo -e "-------------------------------------------------"
}

print_configs() {
  echo -e "BASE_LOCATION:\t\t\t${BASE_LOCATION}"
  echo -e "IMAGE_NAME:\t\t${IMAGE_NAME}"
}

## End of the helper methods ########################################
#####################################################################

#####################################################################
## Beginning of the Entry point #####################################
main() {
  # Validate command arguments
  [ "$#" -ne 1 ] && help && exit 1
  function="$1"
  functions="help cut_release debug_env package prepare_release print_configs publish_to_ecr"
  [[ $functions =~ (^|[[:space:]])"$function"($|[[:space:]]) ]] || (echo -e "\n\"$function\" is not a valid command. Try \"$0 help\" for more details" && exit 2)

  $function
}

main "$@"
## End of the Entry point ###########################################
#####################################################################
