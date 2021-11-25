# Clean logs...
clear
mkdir -p "ETLOGS"
rm -rf "ETLOGS"
mkdir -p "ETLOGS"

jq "{template: .template}" ./config/project-scratch-def.json 
echo "*** sfdx force:org:create"
date
sfdx force:org:create --definitionfile="config/project-scratch-def.json" --durationdays=30 --setalias="${soALIAS}" --targetdevhubusername="${dhALIAS}" --json --wait=60

echo "*** sfdx force:org:open"
date
sfdx force:org:open --targetusername="${soALIAS}" --path /lightning/setup/DeployStatus/home --json
# node --inspect ../fetch/pinger.js $soALIAS

echo "*** sfdx force:source:push"
date
sfdx force:source:push --targetusername="${soALIAS}" --json

echo "*** sfdx force:apex:execute"
date
sfdx force:apex:execute --apexcodefile="./@ELTOROIT/scripts/apex/test.apex" --targetusername="${soALIAS}" --json

echo "*** sfdx force:user:permset:assign"
date
sfdx force:user:permset:assign --permsetname Certification --targetusername="${soALIAS}" --json

# echo "*** sfdx force:source:deploy Admin profile"
# date
# sfdx force:source:deploy --sourcepath="force-apps/doNotDeploy/main/default/profiles/Admin.profile-meta.xml" --targetusername="${soALIAS}" --json

echo "*** sfdx ETCopyData:import"
date
sfdx ETCopyData:import --configfolder="./@ELTOROIT/data" --orgsource="soNULL" --orgdestination="${soALIAS}" --loglevel warn --json

# echo "*** sfdx force:apex:test:run"
# date
# sfdx force:apex:test:run --codecoverage --verbose --resultformat=json --wait=60 --targetusername="${soALIAS}" --json

echo "*** sfdx force:user:password:generate"
date
sfdx force:user:password:generate --targetdevhubusername="${dhALIAS}" --targetusername="${soALIAS}" --json

echo "*** sfdx force:user:display"
date
sfdx force:user:display  --targetusername="${soALIAS}" --targetdevhubusername="${dhALIAS}" --json

echo "*** Done"
date
