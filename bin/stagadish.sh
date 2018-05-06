
#!/bin/sh

# dependencies URL's
AWLESS_GITHUB="https://github.com/wallix/awless"
PSSH_GITHUB="https://github.com/robinbowes/pssh"

# display dependencies error
display_dep_error() {
  echo "stagadish requires '$1' module. Please install it from '$2'."
  exit;
}

# check dependencies
command -v awless > /dev/null 2>&1 || display_dep_error "awless" "$AWLESS_GITHUB"
command -v pssh > /dev/null 2>&1 || display_dep_error "pssh" "$PSSH_GITHUB"

# display help
display_help() {
  cat <<-EOF
  Usage: 
    stagadish [option] [option value]
  Options:
    --filter      Filter resources given key/values fields (case insensitive). Ex: --filter type=t2.micro
    --tag         Filter EC2 resources given tags (case sensitive!). Ex: --tag Env=Production
    --tag-key     Filter EC2 resources given a tag key only (case sensitive!). Ex: --tag-key Env
    --tag-value   Filter EC2 resources given a tag value only (case sensitive!). Ex: --tag-value Staging
    -command, -C  SSH command to excute. If the command has spaces, please put it inside double quotes. Ex: ls or "ls -lah"
  EX:
    stagadish --tag Env=Production -C "cd ~/logs; tail -n 10 foo-0-out.log"
EOF
}

# display missing params message
display_missing_params() {
  echo "Missing params. Please follow instractions: "; 
  display_help; 
  exit 1;
}

# main function
stagadish() {
  echo "Getting instances list for '$OPTION_NAME $OPTION_VALUE'";
  local TEMP_FILE_NAME=".temp-pssh-hosts-$(date +%s%3N)";
  awless list instances "$OPTION_NAME" "$OPTION_VALUE";
  read -p "Are you sure you want execute '$SSH_COMMAND' in the following instances [Y/n]? " IS_APPROVE;
  if [ $IS_APPROVE == 'n' ];
    then { echo "Action disapproved. See you next time!"; exit 1; }
  else {
    echo "Executing '$SSH_COMMAND' \n";
    awless list instances "$OPTION_NAME" "$OPTION_VALUE" --columns 'Public IP' --format tsv | grep -v "Public IP" > ${TEMP_FILE_NAME}; 
    pssh -O StrictHostKeyChecking=no -h ${TEMP_FILE_NAME} -i "$SSH_COMMAND"; 
    rm ${TEMP_FILE_NAME};
  }
  fi
  exit;
}

# handle arguments
while (( "$#" )); do

if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then 
  display_help;
  exit;
fi

if [[ "$1" == "--tag"* ]] || [[ "$1" == "--filter" ]]; then 
  OPTION_NAME=$1
  OPTION_VALUE=$2
fi

if [[ "$1" == "-command" ]] || [[ "$1" == "-C" ]]; then 
  SSH_COMMAND=$2
fi

shift
done

if [[ -z ${OPTION_NAME} ]] || [[ -z ${OPTION_VALUE} ]] || [[ -z ${SSH_COMMAND} ]]; then 
  display_missing_params
else 
  stagadish
fi
