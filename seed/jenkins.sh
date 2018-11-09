
JENKINS_URL="http://jenkins:8080"
JENKINS_PASS=$(cat /run/secrets/jenkins.pass)

echo "JENKINS is at ${JENKINS_URL}"

if [[ -z "$JENKINS_PASS" ]]; then
    echo "Warning: No Jenkins password, this will probably fail"
fi

JENKINS_AUTH_URL="http://${JENKINS_USER}:${JENKINS_PASS}@jenkins:8080"

# We wait until this works
POLL_URL="${JENKINS_AUTH_URL}/overallLoad/api/json"

echo "waiting for Jenkins"
while true
do
    if curl -s "$POLL_URL"; then break; fi
    sleep 1
done

# Then keep trying to add a job or update a job until one of them
# succeeds.

while true
do
    CRUMB=$(curl -s "${JENKINS_AUTH_URL}/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)")
    if curl --fail -H "$CRUMB" \
	    "${JENKINS_AUTH_URL}/createItem?name=cran-update" \
	    --header "Content-Type: application/xml" \
	    --data-binary @/seed/jenkins/cran-update.xml; then break;
    fi

    sleep 1

    if curl --fail -H "$CRUMB" \
	    "${JENKINS_AUTH_URL}/job/cran-update/config.xml" \
	    --header "Content-Type: application/xml" \
	    --data-binary @/seed/jenkins/cran-update.xml; then break;
    fi
    sleep 1
done
