#! /bin/sh

echo "Start getting consul access_token:"

KC_BASE_URL="http://keycloak.service.${OS_USER_DOMAIN_NAME}.gec"
KC_REALM=$OS_USER_DOMAIN_NAME
KC_CLIENT_ID=terraform

CONSUL_HOSTNAME="consul-ui.service.${OS_USER_DOMAIN_NAME}.gec"
CONSUL_BASE_URL="http://${CONSUL_HOSTNAME}"
CONSUL_PORT=80
CONSUL_AUTH_METHOD="keycloak"

echo "...Lookup Keycloak access token at ${KC_BASE_URL} in realm ${KC_REALM} with client id ${KC_CLIENT_ID}"
KC_ACCESS_TOKEN=$(curl -X POST -s --location "${KC_BASE_URL}/auth/realms/${KC_REALM}/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=password&username=${OS_USERNAME}&password=${OS_PASSWORD}&client_id=${KC_CLIENT_ID}" | \
    jq -r .access_token)


echo "...lookup consul token at ${CONSUL_BASE_URL} with auth method ${CONSUL_AUTH_METHOD}"
CONSUL_HTTP_TOKEN=$(curl -X POST -s --location "${CONSUL_BASE_URL}/v1/acl/login" \
    -H "Content-Type: application/json" \
    -d '{
          "AuthMethod": "'${CONSUL_AUTH_METHOD}'",
          "BearerToken": "'${KC_ACCESS_TOKEN}'"
        }' | \
    jq -r .SecretID)

echo "export CONSUL_HTTP_TOKEN=${CONSUL_HTTP_TOKEN}" >> /root/.bashrc
echo "export CONSUL_HTTP_ADDR=${CONSUL_HOSTNAME}:${CONSUL_PORT}" >> /root/.bashrc

echo "done."
