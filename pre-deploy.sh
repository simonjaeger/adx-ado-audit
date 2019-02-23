#!/bin/bash
SRC_FOLDER=src
OUTPUT_FOLDER=publish
FILES=$(find $SRC_FOLDER | grep .csl)

# Create publish directory.
rm -rf $OUTPUT_FOLDER
mkdir $OUTPUT_FOLDER

VARIABLES=(
    # Agent variables.
    AGENT_BUILD_DIRECTORY
    AGENT_HOME_DIRECTORY
    AGENT_ID
    AGENT_JOB_NAME
    AGENT_JOB_STATUS
    AGEND_MACHINE_NAME
    AGENT_NAME
    AGENT_OS
    AGENT_OS_ARCHITECTURE 
    AGENT_TOOLS_DIRECTORY
    AGENT_WORK_FOLDER

    # Build variables.
    BUILD_ARTIFACT_STAGING_DIRECTORY
    BUILD_BUILD_ID
    BUILD_BUILD_NUMBER
    BUILD_BUILD_URI
    BUILD_BINARIES_DIRECTORY
    BUILD_DEFINITION_NAME
    BUILD_DEFINITION_VERSION
    BUILD_QUEUED_BY
    BUILD_QUEUED_BY_ID
    BUILD_REASON
    BUILD_REPOSITORY_CLEAN
    BUILD_REPOSITORY_LOCAL_PATH
    BUILD_REPOSITORY_NAME
    BUILD_REPOSITORY_PROVIDER
    BUILD_REPOSITORY_TFVC_WORKSPACE
    BUILD_REPOSITORY_URI
    BUILD_REQUESTED_FOR
    BUILD_REQUESTED_FOR_EMAIL
    BUILD_REQUESTED_FOR_ID
    BUILD_SOURCE_BRANCH
    BUILD_SOURCE_BRANCH_NAME
    BUILD_SOURCES_DIRECTORY
    BUILD_SOURCE_VERSION
    BUILD_SOURCE_VERSION_MESSAGE
    BUILD_STAGING_DIRECTORY
    BUILD_REPOSITORY_GIT_SUBMODULE_CHECKOUT
    BUILD_SOURCE_TFVC_SHELVESET
    BUILD_TRIGGERED_BY_BUILD_ID
    BUILD_TRIGGERED_BY_DEFINITION_ID
    BUILD_TRIGGERED_BY_DEFINITION_NAME
    BUILD_TRIGGERED_BY_BUILD_NUMBER
    BUILD_TRIGGERED_BY_PROJECT_ID
    COMMON_TEST_RESULTS_DIRECTORY
)

# Print variables.
for VARIABLE in "${VARIABLES[@]}"; do
    echo "$VARIABLE=${!VARIABLE}"
done

for FILE in $FILES
do
    # Create copy of file and folder(s).
    OUTPUT_FILE=$OUTPUT_FOLDER/${FILE#"$SRC_FOLDER/"}
    mkdir -p $(dirname $OUTPUT_FILE)
    echo "Processing $OUTPUT_FILE..."

    # Add values.
    VALS="make_datetime(\"$(date +'%Y-%m-%d %H:%M:%S')\")"
    VALS="$VALS, now()"
    VALS="$VALS, \"${FILE#"$SRC_FOLDER/"}\""
    VALS="$VALS, \"$(cksum $FILE | cut -d' ' -f1)\""

    for VARIABLE in "${VARIABLES[@]}"; do
        # Add value if available.
        VALUE=""
        if [[ ${!VARIABLE} != \$* ]];
        then
            VALUE=${!VARIABLE}
        fi
        VALS="$VALS, \"$VALUE\""
    done

    # Append to file.
    echo "// ***** Log ***** //" >> $OUTPUT_FILE
    echo ".set-or-append Deployments <| range Steps from 1 to 1 step 1 | project $VALS" >> $OUTPUT_FILE
    echo "" >> $OUTPUT_FILE
    echo "// ***** Function ***** //" >> $OUTPUT_FILE
    cat $FILE >> $OUTPUT_FILE
done