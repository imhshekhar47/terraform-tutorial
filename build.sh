#!/bin/bash

ACTION=${1:-info}

get_aws_name() {
    aws_env_name=$(aws iam list-account-aliases | jq -r '.AccountAliases[0]')
    if [[ -z "${aws_env_name}" ]]; then
        exit 1
    fi 
    echo "AWS: ${aws_env_name}"
}

describe_aws_info() {
    echo "Environment name => $(get_aws_name)"
}

confirm_evironment() {
    aws_env_name=$(get_aws_name)
    if [[ -z "${aws_env_name}" ]]; then
        exit 1
    fi 
    read -p "You are manking changes in ${aws_env_name} ": confirm
    if [[ "${confirm}" != "yes" ]]; then
        echo "Terminating execuion"        
    fi

}

delete_terraform_state() {
    read -p "You are going to delete the terraform state. Type yes to confirm.": confirm
    if [[ "${confirm}" == "yes" ]]; then
        echo "Deleting terraform state files" 
        rm .terraform.lock.hcl terraform.tfstate       
    else
        echo "Your choice was '${confirm}' No action taken."
    fi
}


case "${ACTION}" in 
    info)
        describe_aws_info
        ;;
    run)
        confirm_evironment
        terraform init
        terraform plan
        ;;
    delete)
        delete_terraform_state
        ;;
    *)
        echo "Bad usage"
        exit 1
        ;;
esac

exit $?



