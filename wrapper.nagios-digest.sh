#!/bin/bash
################################################################################
#
#	Program:	wrapper.nagios-digest.sh
#
#	Author:		Tim Schaefer tim@asystemarchitect.com
#
#	Description:	Produces a collective report about alerts, sent to you 
#                       in email, calling the nagios-digest.pl program  
#			with several arguments to produce an email-based report 
#			showing any level of alerts, either OK, WARNING,
#			CRITICAL, and UNKNOWN.
#
#			It is recommended for large Nagios installations to 
#			avoid level '0', which are services that are "OK".  
#
#			The intent of the report is to send you a consolidated 
#			report across all hosts and services on a given Nagios
#			instance, typically for WARNING and CRITICAL alerts,
#			as a reminder of what is happening on the system, 
#			eliminating the need to have to use the Nagios web-based 
#			UI just to see the status of services.
#
#	Usage:		Before running this program please set the environment
#			variables to point to the right locations and recipients
#			to send the report to.
#
#
################################################################################

# Where this program and nagios-status-digest.pl live
export BIN=/root/nagios-digest

# Where your status.dat lives
export STATUS_DAT=/var/log/nagios/status.dat

# Add a list of recipients with spaces in between
# export RECIPIENTS="user1@domain.com user2@domain.com user3@domain.com"

export RECIPIENTS=""

for RECIPIENT in $RECIPIENTS
do
	for level in 2 1 
	do
		${BIN}/nagios-status-digest.pl stats=$STATUS_DAT recipient=$RECIPIENT  level=$level only=Y
	done

done
