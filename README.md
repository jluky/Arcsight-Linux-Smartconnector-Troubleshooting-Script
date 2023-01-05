# Arcsight-Linux-Smartconnector-Troubleshooting-Script

This script is designed to troubleshoot an ArcSight Linux connector. It performs the following checks:

It verifies that the connector process is running. If it is not running, it attempts to start it using the start script at /etc/init.d/arcsight.
It checks the connector log file for errors.
It checks the connector configuration file for syntax errors by running the agentConfig.sh script with the check option.
It checks the connector log file for received and forwarded events.
It checks the connector location disk usage and cpu usage.
