#!/usr/bin/env bash
# Cheatsheet: https://devhints.io/bash
# Unofficial Bash Strict Mode: http://redsymbol.net/articles/unofficial-bash-strict-mode/

clear
# Strict Mode >>>
set -euo pipefail
IFS=$'\n\t'
# <<< Strict Mode

# Global variables >>>
startAt="master"
createwith="master"
orgalias="soORG"
newOrg=false
hasFound=false
showResults=false
folderName="testPush"
SFDX_JSON_TO_STDOUT=true
testGit=false
# <<< Global variables

usage() {
    echo "usage: "
	echo "		testPush.sh -h"
    echo "		testPush.sh"
    echo "		testPush.sh -c commitName -s commitName -o orgAlias -n -d"
    echo "		testPush.sh --createwith commitName --startat commitName --orgalias orgAlias --neworg --debug"
}

debug() {
	echo "Create With    : ${createwith}"
	echo "Start At       : ${startAt}"
	echo "Org Alias      : ${orgalias}"
	echo "New Org        : ${newOrg}"
	echo "Has Found      : ${hasFound}"
	echo "Show Results   : ${showResults}"
	echo "Folder Name    : ${folderName}"
}

testBranches() {
	if [[ ${newOrg} != true ]]; then
		# If there is no need to create a scrath org for every commit, then create one now.
		echo "Creating scratch org only once..."
		testBranch true ${createwith}
		if [[ ${createwith} != ${startAt} ]]; then
			testBranch false ${startAt}
		fi
	fi

	while read currentBranch; do
		isStartAt=false
		if [[ ${currentBranch} == ${startAt} ]]; then
			hasFound=true
			isStartAt=true
		fi
		
		if [[ ${hasFound} == true ]]; then
			if [[ $newOrg == true ]]; then
				testBranch true ${currentBranch}
				# DEX602 has an error that we must create the scratch org from the base repo and then checkout the branch and push again.
				# if [[ ${currentBranch} != ${createwith} ]]; then
				# 	testBranch false ${currentBranch}
				# fi
			elif [[ $isStartAt == false ]]; then
				testBranch ${newOrg} ${currentBranch}
			fi
		fi
	done < testPush_branches.txt
	say -v Samantha "Testing the push of commits completed successfully..."
}

testBranch() {
	isFull=$1
	branch=$2
	check=

	logName="$(date '+%Y%m%d_%H%M%S')"
	# if [[ ${branch} != ${createwith} ]]; then
	# 	logName=""
	# fi

	echo ""
	echo "*** Testing branch: " ${branch}

	echo "--- Checking out commit..."
	cmd="git checkout -f ${branch}"
	check=("exec")
	mkdir -p "${folderName}/${logName}/${branch}"
	execute ${cmd} ${branch} ${check} "00_Checkout" ${logName}

	if [[ ${isFull} == true ]]; then
		echo "--- Creating scratch Org..."
		cmd="sfdx force:org:create -f config/project-scratch-def.json --setdefaultusername --setalias ${orgalias} -d 1 --json"
		check=("json" ".status" 0)
		execute ${cmd} ${branch} ${check} "01a_Create" ${logName}

		echo "--- Opening new scratch Org..."
		cmd="sfdx force:org:open --urlonly --json"
		check=("json" ".status" 0)
		execute ${cmd} ${branch} ${check} "02a_Open" ${logName}

		echo "--- Display scratch user info..."
		cmd="sfdx force:user:display --json"
		check=("json" ".status" 0)
		execute ${cmd} ${branch} ${check} "03a_UserInfo" ${logName}

		echo "--- Display scratch org info..."
		cmd="sfdx force:org:display --json"
		check=("json" ".status" 0)
		execute ${cmd} ${branch} ${check} "04a_OrgInfo" ${logName}

		echo "--- Pushing metadata to new scratch Org..."
		cmd="sfdx force:source:push --forceoverwrite --json"
		check=("json" ".status" 0)
		execute ${cmd} ${branch} ${check} "05a_Push" ${logName}

		echo "--- Assigning permission set to your user..."
		cmd="sfdx force:user:permset:assign --permsetname Certification --json"
		check=("json" ".status" 0)
		execute ${cmd} ${branch} ${check} "06a_Perm" ${logName}
		
		echo "--- Creating data using ETCopyData plugin..."
		cmd="sfdx ETCopyData:import --configfolder=./@ELTOROIT/data --orgsource=soNULL --orgdestination=${orgalias} --json"
		# check=("exec") 222
		check=("json" ".result._TOTAL_RECORDS.bad" 0)
		execute ${cmd} ${branch} ${check} "07a_Data" ${logName}

		echo "--- Running Apex Code..."
		cmd="sfdx force:apex:execute -f @ELTOROIT/scripts/apex/test.apex --json"
		check=("json" ".result.success" true)
		execute ${cmd} ${branch} ${check} "08a_ApexTest" ${logName}
	else
		echo "--- Pushing metadata to existing scratch Org..."
		cmd="sfdx force:source:push --forceoverwrite --json"
		check=("json" ".status" 0)
		execute ${cmd} ${branch} ${check} "01b_Push" ${logName}
	fi
}

execute() {
	cmd=$1 
	branch=$2
	check=$3
	action=$4
	# logName=""
	# if [ ! -z "$5" ]; then
	set +u
	logName=$5
	set -u
	# fi

	exitCode=0

	if [[ ${showResults} == true ]]; then
		echo "folderName     : ${folderName}"
		echo "logName        : ${logName}"
	fi
	echo "branch         : ${branch}"
	echo "action         : ${action}"
	outputFile="./${folderName}/${logName}/${branch}"
	mkdir -p ${outputFile}
	outputFile="${outputFile}/${action}.json"
	# DEBUG-START: Testing bash, makes it run faster
	if [[ ${testGit} == true ]]; then
		tmpCmd=$(IFS=" " ; set -- $cmd ; echo $1)
		if [[ ${tmpCmd} == "sfdx" ]]; then
			cmd="echo \"$cmd\""
			check=("exec")
		fi
	fi
	# DEBUG-END: Testing bash, makes it run faster
	cmd="${cmd} &> ${outputFile}"
	echo ${cmd}
	set +e
	eval ${cmd}
	exitCode=$?
	set -e
	echo "Command executed: ${exitCode}"
	if [[ ${showResults} == true ]]; then
		# When debug flag was set in the commandInvocation
		cat ${outputFile}
	fi
	if [[ ${check[0]} == "json" ]]; then
		res=`jq ${check[1]} ${outputFile}`
		if [[ ${res} != ${check[2]} ]]; then
			say -v Samantha "An error has occurred in the json file. I have stopped testing the push of commits..."
			cat ${outputFile}
			exit 1
		fi
	else
		if [ ${exitCode} != 0 ]; then
			say -v Samantha "An error has occurred while executing the command. I have stopped testing the push of commits..."
			cat ${outputFile}
			exit 1
		fi
	fi
	# DEBUG-START: Testing bash, makes it run faster
	if [[ ${testGit} != true ]]; then
		# Sleep... I have seen that not sleeping causes some fields to not be found. It appears the push has not taken effect. 
		# "So, I said to my people.... Slow the testing down!" https://www.youtube.com/watch?v=NEugeUuKKmQ&t=28
		# sleep 1
		sleep 5
		date
	fi
	# DEBUG-END: Testing bash, makes it run faster
}

### MAIN

### Read Arguments
	set +u
	while [ "$1" != "" ]; do
		case $1 in
			-c | --createwith )
				shift
				createwith=$1
				;;
			-s | --startat )
				shift
				startAt=$1
				;;
			-o | --orgalias )
				shift
				orgalias=$1
				;;
			-n | --neworg )
				newOrg=true
				;;
			-g | --testgit )
				testGit=true
				;;
			-d | --debug )
				showResults=true
				;;
			-h | --help )
				usage
				exit
				;;
			* )
				usage
				exit 1
		esac
		shift
	done
	set -u
	debug

# Execute
	# Backup this script
	cp ./testPush.sh ..
	cp ./testPush_branches.txt ..
	folderName="testPush/$(date '+%Y%m%d_%H%M%S')";
	mkdir -p ${folderName}
	testBranches
	