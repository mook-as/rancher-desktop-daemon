#!/bin/bash

# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: SUSE LLC
# SPDX-FileCopyrightText: The Rancher Desktop Authors

set -o errexit -o nounset

API_GROUPS=$(find pkg/controllers -type d -mindepth 1 -maxdepth 1 -not -name base -exec basename {} \;)

TMPDIR=$(mktemp -d)
trap 'rm -rf $TMPDIR' EXIT

for apigroup in $API_GROUPS; do
	# Generate all CRDs for this API group to temp directory
	go tool controller-gen crd "paths=./pkg/apis/${apigroup}/..." "output:crd:dir=${TMPDIR}"

	# Distribute CRDs to their respective controller directories
	for controller_dir in "pkg/controllers/${apigroup}"/*/; do
		if [ -f "$controller_dir/crd.yaml" ]; then
			controller=$(basename "$controller_dir")
			# Try plural form first (e.g., configmapreplicasets), then singular (e.g., notary)
			crd_file=$(ls "$TMPDIR"/*_"${controller}"s.yaml 2>/dev/null || ls "$TMPDIR"/*_"${controller}".yaml 2>/dev/null || echo "")
			if [ -n "$crd_file" ] && [ -f "$crd_file" ]; then
				mv "$crd_file" "$controller_dir/crd.yaml"
			fi
		fi
	done
done
