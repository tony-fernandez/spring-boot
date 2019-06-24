#!groovy
// Jenkinsfile for MLBParks
node('jenkins-slave-appdev') {
	echo "GUID: ${GUID}"
    echo "CLUSTER: ${CLUSTER}"

    def mvnCmd = "mvn -s nexus_settings.xml"
    echo "mvnCmd: ${mvnCmd}"

    // Your Pipeline Code goes here. Make sure to use the ${GUID} and ${CLUSTER} parameters where appropriate
    // You need to build the application in directory `MLBParks`.
    // Also copy "../nexus_settings.xml" to your build directory
    // and replace 'GUID' in the file with your ${GUID} to point to >your< Nexus instance
     // Checkout Source Code
    stage('Checkout Source') {
      git url: 'https://github.com/tony-fernandez/advdev_homework.git'
    }
 
	// The following variables need to be defined at the top level
	// and not inside the scope of a stage - otherwise they would not be accessible from other stages.
	// Extract version and other properties from the pom.xml
	def groupId    = getGroupIdFromPom("pom.xml")
	def artifactId = getArtifactIdFromPom("pom.xml")
	def version    = getVersionFromPom("pom.xml")
	
	// Set the tag for the development image: version + build number
	def devTag  = "${version}-${BUILD_NUMBER}"
	echo "devTag: ${devTag}"
	// Set the tag for the production image: version
	def prodTag = "${version}"
	echo "prodTag: ${prodTag}"
	
	// Using Maven build the war file
	// Do not run tests in this step
	stage('Build war') {
		echo "Building version ${devTag}"
	    sh "${mvnCmd} clean package -DskipTests"
	}
	
	// Using Maven run the unit tests
	stage('Unit Tests') {
		echo "Running Unit Tests"     
	    sh "${mvnCmd} test"
	}
		
	// Publish the built war file to Nexus
	stage('Publish to Nexus') {
		echo "Publish to Nexus"
		sh "${mvnCmd} deploy -DskipTests=true -DaltDeploymentRepository=nexus::default::http://nexus3.nexus.svc.cluster.local:8081/repository/releases"
	}
	
	// Build the OpenShift Image in OpenShift and tag it.
	stage('Build and Tag OpenShift Image') {
		echo "Building OpenShift container image spring-boot:${devTag}"
	   	//sh "oc start-build mlbparks --follow --from-file=./target/spring-boot.war -n spring-boot"
		sh "oc start-build spring-boot --follow=true --from-file=http://nexus3-nexus.apps.${CLUSTER}/repository/releases/com/openshift/evg/roadshow/spring-boot/${version}/spring-boot-${version}.war -n spring-boot"
  
	
	  	// OR use the file you just published into Nexus:
	   	//http_status=$(curl -I http://$(oc get route nexus3 --template='{{ .spec.host }}' -n ${NEXUS})/repository/maven-public/ -o /dev/null -w '%{http_code}\n' -s)
    		
    	//http://$(oc get route nexus3 --template='{{ .spec.host }}' -n ${NEXUS})/repository/releases/org/jboss/quickstarts/eap/mlbparks/${version}/mlbparks-${version}.war
    		
    	//def host = sh "oc get route nexus3 --template='{{ .spec.host }}' -n ${GUID}-nexus"
	  	//echo "Nexus host:${host}"
	  		
	  	//def fileUrl = "http://${host}/repository/releases/org/jboss/quickstarts/eap/mlbparks/${version}/mlbparks-${version}.war"	    	
    	//echo "File URL:${fileUrl}"
    		
    	//sh "oc start-build mlbparks -n ${GUID}-parks-dev --follow --from-file=${fileUrl}"
	
	    // Tag the image using the devTag
     	openshiftVerifyBuild bldCfg: 'spring-boot', checkForTriggeredDeployments: 'false', namespace: 'spring-boot', verbose: 'false'
	    openshiftTag alias: 'false', destStream: 'spring-boot', destTag: devTag, destinationNamespace: 'spring-boot', namespace: 'spring-boot', srcStream: 'spring-boot', srcTag: 'latest', verbose: 'false'
	}
	
	    // Deploy the built image to the Development Environment.
	    stage('Deploy to Dev') {
	    	echo "Deploying container image to Development Project"
	    	sh "oc set image dc/mlbparks mlbparks=docker-registry.default.svc:5000/${GUID}-parks-dev/mlbparks:${devTag} -n ${GUID}-parks-dev"	
	     	openshiftDeploy depCfg: 'mlbparks', namespace: '${GUID}-parks-dev', verbose: 'true', waitTime: '20', waitUnit: 'min'
	    	openshiftVerifyDeployment depCfg: 'mlbparks', namespace: '${GUID}-parks-dev', replicaCount: '1', verbose: 'true', verifyReplicaCount: 'false', waitTime: '', waitUnit: 'sec'
	    	openshiftVerifyService namespace: '${GUID}-parks-dev', svcName: 'mlbparks', verbose: 'false'
	    }
	
	    // Run Integration Tests in the Development Environment.
	    stage('Integration Tests') {
	    	sleep 20
	      	echo "Running Integration Tests"
	
	      	echo "Health check MLBParks"
	        sh "curl -i  http://mlbparks-${GUID}-parks-dev.apps.${CLUSTER}/ws/healthz/"
	
	      	echo "ls ws info"
	        sh "curl -i -H 'Content-Length: 0' -X GET http://mlbparks-${GUID}-parks-dev.apps.${CLUSTER}/ws/info/"
	    }
	
	    // Copy Image to Nexus Docker Registry
	    stage('Copy Image to Nexus Docker Registry') {
	    	echo "Copy image to Nexus Docker Registry"
	
	    	sh "skopeo copy --src-tls-verify=false --dest-tls-verify=false --src-creds openshift:\$(oc whoami -t) --dest-creds admin:admin123 docker://docker-registry.default.svc.cluster.local:5000/${GUID}-parks-dev/mlbparks:${devTag} docker://nexus-registry.${GUID}-nexus.svc.cluster.local:5000/mlbparks:${devTag}"
	
	    	// Tag the built image with the production tag
	    	openshiftTag alias: 'false', destStream: 'spring-boot', destTag: prodTag, destinationNamespace: 'spring-boot', namespace: 'spring-boot', srcStream: 'spring-boot', srcTag: devTag, verbose: 'false'
	    }
	
	    // Blue/Green Deployment into Production
	    // -------------------------------------
	    // Do not activate the new version yet.
	    def destApp   = "spring-boot-green"
	    def activeApp = ""
	
	    stage('Blue/Green Production Deployment') {
	    	activeApp = sh(returnStdout: true, script: "oc get route spring-boot -n spring-boot-prod -o jsonpath='{ .spec.to.name }'").trim()
	      	
	      	if (activeApp == "spring-boot-green") {
	        	destApp = "spring-boot-blue"
	      	}
	      	
	      	echo "Active Application:      " + activeApp
	      	echo "Destination Application: " + destApp
	
	      	// Update the Image on the Production Deployment Config
	      	sh "oc set image dc/${destApp} ${destApp}=docker-registry.default.svc:5000/spring-boot/spring-boot:${prodTag} -n spring-boot-prod"
	
	        // Deploy the inactive application.
	      	openshiftDeploy depCfg: destApp, namespace: 'spring-boot-prod', verbose: 'false', waitTime: '', waitUnit: 'sec'
	      	openshiftVerifyDeployment depCfg: destApp, namespace: 'spring-boot-prod', replicaCount: '1', verbose: 'false', verifyReplicaCount: 'true', waitTime: '', waitUnit: 'sec'
	      	openshiftVerifyService namespace: 'spring-boot-prod', svcName: destApp, verbose: 'false'
	    }
	
	    stage('Switch over to new Version') {
	    	//input "Switch Production?"
	      	echo "Switching Production application to ${destApp}."
	      	sh 'oc patch route spring-boot -n spring-boot-prod -p \'{"spec":{"to":{"name":"' + destApp + '"}}}\''
	    }   
}

// Convenience Functions to read variables from the pom.xml
// Do not change anything below this line.
def getVersionFromPom(pom) {
  def matcher = readFile(pom) =~ '<version>(.+)</version>'
  matcher ? matcher[0][1] : null
}
def getGroupIdFromPom(pom) {
  def matcher = readFile(pom) =~ '<groupId>(.+)</groupId>'
  matcher ? matcher[0][1] : null
}
def getArtifactIdFromPom(pom) {
  def matcher = readFile(pom) =~ '<artifactId>(.+)</artifactId>'
  matcher ? matcher[0][1] : null
}