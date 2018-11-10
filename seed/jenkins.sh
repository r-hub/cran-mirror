
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

# We go over all jobs. For each job, we  keep trying to add or update it,
# until one of them succeeds.

for jobfile in $(cd /seed/jenkins/; ls *.xml);
do
    job=${jobfile%.xml}
    echo "Adding job ${job}"

    while true
    do
	CRUMB=$(curl -s "${JENKINS_AUTH_URL}/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)")
	if curl --fail -H "$CRUMB" \
		"${JENKINS_AUTH_URL}/createItem?name=${job}" \
		--header "Content-Type: application/xml" \
		--data-binary "@/seed/jenkins/${job}.xml"; then break;
	fi

	sleep 1

	if curl --fail -H "$CRUMB" \
		"${JENKINS_AUTH_URL}/job/${job}/config.xml" \
		--header "Content-Type: application/xml" \
		--data-binary "@/seed/jenkins/${job}.xml"; then break;
	fi
	sleep 1
    done
done
