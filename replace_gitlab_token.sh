#! /bin/sh

echo "Write gitlab access token to .terraformrc file..."

sed -i "s/<your.access.token>/${GITLAB_ACCESS_TOKEN}/g" /root/.terraformrc