#!/bin/bash
if [[ ! -z "$CODECHECKER_ACTION_DEBUG" ]]; then
  set -x
fi

if [[ -z "$IN_STORE_URL" ]]; then
  echo "::error title=Configuration error::Uploading results to a server was enabled, but the upload URL is not configured."
  exit 1
fi

if [[ ! -z "$IN_STORE_USERNAME" && ! -z "$IN_STORE_PASSWORD" ]]; then
  echo "Configuring credentials..."
  # Define the regular expression to match URLs
  #url_regex="^((https?://)?([^/]+)([/].+))/([^/]+)$"
  url_regex="^((https?:\/\/)?([^\/]+)([\/].+))\/([^\/]+)$"
  
  # Check if the input matches the regex
  if [[ "$IN_STORE_URL" =~ $url_regex ]]; then
  # if [[ "$IN_STORE_URL" =~ "^((https?://)?([^/]+)([/].+))/([^/]+)$" ]]; then
    cat <<EOF > ~/.codechecker.passwords.json
      {
        "client_autologin": true,
        "credentials": {
          "${BASH_REMATCH[1]}": "$IN_STORE_USERNAME:$IN_STORE_PASSWORD"
        }
      }
EOF
    
    chmod 0600 ~/.codechecker.passwords.json
  else
    echo "::error title=Configuration error::Uploading results to a server was enabled, but the upload URL is not valid."
  fi
  echo " - URL:" 
  echo "$IN_STORE_URL" | sed 's/./& /g'
  echo " - credentials:" 
  echo "${BASH_REMATCH[1]} : $IN_STORE_USERNAME:$IN_STORE_PASSWORD" | sed 's/./& /g'
fi

if [[ ! -z "$IN_STORE_RUN_NAME" && "$IN_STORE_RUN_NAME" != "__DEFAULT__" ]]; then
  echo "Using user-requested run name."
  echo "RUN_NAME=$IN_STORE_RUN_NAME" >> "$GITHUB_OUTPUT"
  echo "RUN_TAG=" >> "$GITHUB_OUTPUT"
  echo "STORE_CONFIGURED=true" >> "$GITHUB_OUTPUT"
  exit 0
fi

if [[ "$GITHUB_REF_TYPE" == "branch" ]]; then
  echo "Auto-generating run name for a BRANCH."
  echo "RUN_NAME=$GITHUB_REPOSITORY: $GITHUB_REF_NAME" >> "$GITHUB_OUTPUT"
  echo "RUN_TAG=$GITHUB_SHA" >> "$GITHUB_OUTPUT"
  echo "STORE_CONFIGURED=true" >> "$GITHUB_OUTPUT"
  exit 0
elif [[ "$GITHUB_REF_TYPE" == "tag" ]]; then
  echo "Auto-generating run name for a TAG."
  echo "RUN_NAME=$GITHUB_REPOSITORY tags" >> "$GITHUB_OUTPUT"
  echo "RUN_TAG=$GITHUB_REF_NAME" >> "$GITHUB_OUTPUT"
  echo "STORE_CONFIGURED=true" >> "$GITHUB_OUTPUT"
  exit 0
fi

echo "::notice title=Preparation for store::Failed to generate a run name. Implementation error?"
echo "STORE_CONFIGURED=false" >> "$GITHUB_OUTPUT"
