#!/bin/bash

# Check if the connector is running
if ! ps aux | grep '[a]rcsight' > /dev/null
then
    # Connector is not running, try to start it
    if [ -f /etc/init.d/arcsight ]
    then
        # Start script exists, try to start connector
        if ! /etc/init.d/arcsight start > /dev/null
        then
            # There was an error starting the connector
            echo "Error starting ArcSight connector"
            exit 1
        fi
    else
        # Start script does not exist
        echo "ArcSight start script not found"
        exit 1
    fi
fi

# Check if the connector process is running
if ! ps aux | grep '[a]rcsight' > /dev/null
then
    # Connector process is not running, even though start script ran successfully
    echo "Error: ArcSight connector process not found"
    exit 1
fi

# Check the connector log file for errors
if grep -i error /opt/arcsight/current/logs/agent.log > /dev/null
then
    # There are errors in the log file
    echo "Errors found in connector log file"
    exit 1
fi

# Check connector configuration file for syntax errors
if [ -f /opt/arcsight/current/user/agent/agent.properties ]
then
    # Configuration file exists, check for syntax errors
    if /opt/arcsight/current/bin/agentConfig.sh check /opt/arcsight/current/user/agent/agent.properties 2>&1 | grep -i "error" > /dev/null
    then
        # Syntax errors found in configuration file
        echo "Syntax errors found in connector configuration file"
        exit 1
    fi
else
    # Configuration file does not exist
    echo "ArcSight connector configuration file not found"
    exit 1
fi

# Check connector log file for parsing issues
if grep -i "parsing" /opt/arcsight/current/logs/agent.log > /dev/null
then
    # Parsing errors found in log file
    echo "Parsing errors found in connector log file"
    exit 1
fi

# Check connector log file for received and forwarded events
received_count=`grep -i "received" /opt/arcsight/current/logs/agent.log | wc -l`
forwarded_count=`grep -i "forwarded" /opt/arcsight/current/logs/agent.log | wc -l`
if [ $received_count -eq 0 ] || [ $forwarded_count -eq 0 ]
then
    # No received or forwarded events found in log file
    echo "No received or forwarded events found in connector log file"
    exit 1
fi

# Check connector location disk usage
location_disk_usage=$(df -h /opt/arcsight/current/user/agent/location | awk 'FNR == 2 {print $5}')
if [ ${location_disk_usage%?} -ge 95 ]
then
    # Connector location disk usage is 95% or higher
    echo "Connector location disk is up to 95%"
