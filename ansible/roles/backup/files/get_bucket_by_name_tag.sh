#!/bin/bash

function get_arn() {
aws resourcegroupstaggingapi get-resources --tag-filters \
	Key=Project,Values=graduate_work \
	Key=Name,Values=$1 --region eu-central-1 |
	jq -e .ResourceTagMappingList[0].ResourceARN
}
arn=$(get_arn $1) || {
	echo "Resource with Name=$1 not found" 1>&2
	exit 1
}
echo "$arn" | tr -d '"' | cut -d : -f 6

