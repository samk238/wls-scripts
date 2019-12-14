##########################
# Sampath Kunapareddy    #
# sampath.a926@gmail.com #
##########################
#!/bin/bash
#set -x
HOST=$(echo `hostname` | tr [A-Z] [a-z])
echo -e "Working on $HOST:"
DOM_HMS=$(ls -ldrt /opt/oracle/admin/soa*_domain/*server/soa*_domain/servers/* | awk '{print $NF}')
for DOM_HM in $DOM_HMS; do
  if [[ -d $DOM_HM/logs ]]; then
    echo "Working on: $DOM_HM/logs"
    chmod -R 755 $DOM_HM/logs
    #sleep 1 
  fi
done
