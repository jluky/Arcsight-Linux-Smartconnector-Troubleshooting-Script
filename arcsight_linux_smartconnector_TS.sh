#!/bin/bash

# Check if the connector service is running
if ! systemctl is-active arcsight > /dev/null
then
    # Connector service is not running, try to start it
    if ! systemctl start arcsight > /dev/null
    then
        # There was an error starting the connector service
        echo "Error starting ArcSight connector service"
        exit 1
    fi
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

# Check connector log file for received and forwarded events
received_count=`grep -i "received" /opt/arcsight/current/logs/agent.log | wc -l`
forwarded_count=`grep -i "forwarded" /opt/arcsight/current/logs/agent.log | wc -l`
if [ $received_count -eq 0 ] || [ $forwarded_count -eq 0 ]
then
    # No received or forwarded events found in log file
    echo "No received or forwarded events found in connector log file"
    exit 1
fi

# Check connector CPU usage
cpu_usage=$(ps -o %cpu -p $(pgrep arcsight) | tail -n +2)
if [ "$cpu_usage" -gt 80 ]
then
    # Connector CPU usage is higher than 80%
    echo "Connector CPU usage is higher than 80%"
    exit 1
fi

# Check connector disk usage
disk_usage=$(df -h /opt/arcsight/current | tail -n +2 | awk '{print $5}' | tr -d '%')
if [ "$disk_usage" -gt 80 ]
then
    # Connector disk usage is higher than 80%
    echo "Connector disk usage is higher than 80%"
    exit 1
fi

# All checks passed
exit 0
