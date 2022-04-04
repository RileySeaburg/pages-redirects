#######
#!/bin/bash

set -e

CF_ORGANIZATION="gsa-18f-federalist"
CF_API="https://api.fr.cloud.gov"

if [ "$CIRCLE_BRANCH" == "main" ]; then
  CF_USERNAME=$CF_USER
  CF_PASSWORD=$CF_PASS
  CF_SPACE="redirects"
  CF_APP="pages-redirects"
  CF_MANIFEST="out/manifest-prod.yml"
else
  echo "Current branch has no associated deployment. Exiting."
  exit
fi

# install cf cli
curl -L -o cf-cli_amd64.deb 'https://cli.run.pivotal.io/stable?release=debian64&source=github'
sudo dpkg -i cf-cli_amd64.deb
rm cf-cli_amd64.deb

# install autopilot
cf install-plugin autopilot -f -r CF-Community

cf api $CF_API
cf login -u $CF_USERNAME -p $CF_PASSWORD -o $CF_ORGANIZATION -s $CF_SPACE


echo "Deploying to $CF_SPACE space."
cf zero-downtime-push $CF_APP -f $CF_MANIFEST

cf logout
