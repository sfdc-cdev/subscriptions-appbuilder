# Execute in Mac using: ./EXFiles/scripts/CreateOrg.sh
echo "*** Creating scratch Org..."
sfdx force:org:create -f config/project-scratch-def.json --setdefaultusername --setalias soAppBuilder --durationdays 30
echo "*** Opening scratch Org..."
sfdx force:org:open --path /lightning/setup/DeployStatus/home 
echo "*** Pushing metadata to scratch Org..."
sfdx force:source:push
echo "*** Assigning permission set to your user..."
sfdx force:user:permset:assign --permsetname Certification
echo "*** Creating required users..."
sfdx force:apex:execute -f @ELTOROIT/scripts/CreateUsers.apex
echo "*** Creating data"
sfdx ETCopyData:import -c @ELTOROIT/data --loglevel trace --json
echo "*** DONE"
