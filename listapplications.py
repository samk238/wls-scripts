##########################
# Sampath Kunapareddy    #
# sampath.a926@gmail.com #
##########################
import sys
connect()

print "---------------------------------------"
print "Print deployed applications"
print "---------------------------------------"

deployed_application_names = [];
app_deployments = cmo.getAppDeployments()
for app_deployment in app_deployments:
    deployed_application_names.append(app_deployment.getName())
print deployed_application_names