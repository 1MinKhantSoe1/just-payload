#!/bin/bash

# Define the duration for the tool to run (3 hours)
DURATION="3h"

# Define the command you want to run (Replace 'your_tool_command' with the actual command)
TOOL_COMMAND="python3 Responder.py -I eth0 -wdv"

echo "Starting tool: ${TOOL_COMMAND}"
echo "It will run for a maximum of ${DURATION} and then be automatically terminated."
echo "--------------------------------------------------------"

# Use 'timeout' to run the command for the specified duration
timeout ${DURATION} ${TOOL_COMMAND}

# Check the exit status of the 'timeout' command
EXIT_STATUS=$?

if [ ${EXIT_STATUS} -eq 0 ]; then
    echo "--------------------------------------------------------"
    echo "Tool finished successfully before the timeout."
elif [ ${EXIT_STATUS} -eq 124 ]; then
    echo "--------------------------------------------------------"
    echo "Tool was automatically terminated after ${DURATION} (timeout reached)."
else
    echo "--------------------------------------------------------"
    echo "Tool terminated with an exit status of ${EXIT_STATUS}."
fi
