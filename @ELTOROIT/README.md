# Instructions

Find the original instructions here: https://github.com/sfdc-cdev/etgitter/blob/master/ETCDEV_Setup_Instructions.docx

# "Personalized Instructions"

Scripts must be run from the "AppBuilder" folder

1. Open VS Code and the ETGitter project (/Users/aperez/DO NOT BACKUP/GitProjects/Current/ETGitterRoot/etgitter/)
2. Change directory to "AppBuilder"
3. Execute these instructions
   - "/Users/aperez/DO NOT BACKUP/GitProjects/Current/ETGitterRoot/etgitter/bin/run" ETCDEV:Git2Folder --loglevel trace
   - "/Users/aperez/DO NOT BACKUP/GitProjects/Current/ETGitterRoot/etgitter/bin/run" ETCDEV:Folder2Git --loglevel trace

# If you want to debug

1. Execute these instructions
   - NODE_OPTIONS=--inspect-brk "/Users/aperez/DO NOT BACKUP/GitProjects/Current/ETGitterRoot/etgitter/bin/run" ETCDEV:Git2Folder --loglevel trace
   - NODE_OPTIONS=--inspect-brk "/Users/aperez/DO NOT BACKUP/GitProjects/Current/ETGitterRoot/etgitter/bin/run" ETCDEV:Folder2Git --loglevel trace
2. Open the debugger in VS Code and run "Attach to remote"

# Testing the created repo

1. Change directory to "AppBuilder"
2. Generate [testPush_branches] which contains a list of branches
   - "/Users/aperez/DO NOT BACKUP/GitProjects/Current/ETGitterRoot/etgitter/bin/run" ETCDEV:TestPush -g after --loglevel trace
3. Copy file from "AppBuilder/output/testPush_branches.txt" to "AppBuilder/03-newRepo/testPush_branches.txt"
4. Copy file from "AppBuilder/testPush.sh" to "AppBuilder/03-newRepo/testPush.sh"
5. Change directory to "03-newRepo"
6. Execute script
   - ./testPush.sh --createwith "Start" --startat "Start" --orgalias soAppBuilderTest --neworg --debug
   - ./testPush.sh --createwith "EX02" --startat "EX02" --orgalias soAppBuilderTest --neworg --debug

# GitHub

1. Repo:
   - https://github.com/sfdc-cdev/subscriptions-appbuilder.git
   - git remote add origin https://github.com/sfdc-cdev/subscriptions-appbuilder.git
2. Push all branches
   - git push --all origin --force
