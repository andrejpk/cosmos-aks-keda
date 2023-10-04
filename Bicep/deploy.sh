#!/bin/bash

source .env

az deployment sub create \
	--name $deploymentName \
	--location $location \
	--template-file main.bicep \
	--parameters @param.json \
	-o json