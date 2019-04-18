#!/bin/bash
if [ $# -lt 2 ]; then 
  echo ""
  echo "Usage: terraform.sh <environment> <command> [args]"
  echo "    Convenience wrapper for terraform commands"
  echo ""
  echo "Environment:"
  echo "    The environment in which to run terraform commands. The folder src/environments/<environment> must exist."
  echo ""
  echo "Commands:"
  echo "    run: Create the docker container and initialize terraform."
  echo "    stop: Stop and remove the docker container."
  echo "    uplan: Update modules and plan to apply changes to infrastructure."
  echo "    *: Any unrecognized command will be passed directly to Terraform."
  echo ""
  echo "Args:"
  echo "    *: Args will be passed directly to Terraform."
  echo ""
  echo "Examples:"
  echo "    ./terraform.sh sandbox run"
  echo "    ./terraform.sh sandbox uplan"
  echo "    ./terraform.sh sandbox apply"
  exit 0
fi

cd "$(dirname "${BASH_SOURCE}")"

projectDir=$(pwd)
workingDir="/src/environments/$1"

if [ ! -d "$projectDir/$workingDir" ]; then
  echo "Unknown environment $1. Cannot find directory ${workingDir}"
  exit 1
fi

# Build Terraform arguments
args="${@:3}"

containerName="terraform-demoproject-$1"

case "$2" in
  "start")
    # Fall through
    ;;
  "run")
    if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
      echo "Access key environment variables are not set. Please set AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, and AWS_SESSION_TOKEN (if needed)."
      exit 1
    fi

    # Build docker image
    dockerImage="terraform:extended"
    docker build -t $dockerImage - < Dockerfile

    # Run docker container
    projectAbsolutePath=$(pwd | sed 's/^\/\([a-z]\)\//\1:\//')
    docker run --name $containerName \
      -idt -w "/$workingDir" \
      --volume $projectAbsolutePath/src:/src \
      --env TF_VAR_current_sha=$(git rev-parse HEAD) \
      --env AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
      --env AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
      --env AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN \
      $dockerImage
    docker exec $containerName terraform init
    ;;
  "stop")
    docker stop $containerName
    docker rm $containerName
    rm -r -f ./src/environments/$1/.terraform
    ;;
  "uplan")
    docker exec -t -i $containerName terraform get -update
    docker exec -t -i $containerName terraform plan $args
    ;;
  "cli")
    docker exec -t -i $containerName sh
    ;;
  *)
    docker exec -t -i $containerName terraform $2 $args
    ;;
esac
