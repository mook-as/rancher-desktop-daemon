#!/bin/bash

# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: SUSE LLC
# SPDX-FileCopyrightText: The Rancher Desktop Authors

set -o errexit -o nounset

API_GROUPS=$(find pkg/controllers -type d -mindepth 1 -maxdepth 1 -not -name base -exec basename {} \;)

# Generate deepcopy for each API group
for apigroup in $API_GROUPS; do
	go tool controller-gen object "paths=./pkg/apis/$apigroup/..."
done
