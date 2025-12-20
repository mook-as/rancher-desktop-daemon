load '../../helpers/load'

# Mock controller tests - using the mock controller, verify that the container
# and image controllers work as expected.

local_setup_file() {
    setup_rdd_control_plane "containers"
    echo "${PATH_LOGS}/mock-controller.log" >&3
    "mock-controller${EXE}" &>"${PATH_LOGS}/mock-controller.log" &
    echo "$!" >"${BATS_FILE_TMPDIR}/controller_pid"
}

local_teardown_file() {
    if [[ -f "${BATS_FILE_TMPDIR}/controller_pid" ]]; then
        read -r controller_pid <"${BATS_FILE_TMPDIR}/controller_pid"
        kill "${controller_pid}" 2>/dev/null || true
        wait "${controller_pid}" 2>/dev/null || true
    fi
}

@test "containers are created" {
    run -0 cat ../pkg/controllers/mock/testdata/containers.json
    run -0 jq_output '.[].Id'
    mapfile -t containers <<<"${output}"

    try --max 30 --delay 1 -- rdd ctl get namespace rdd-mocks -o name

    for container in "${containers[@]}"; do
        try --max 30 --delay 1 -- rdd ctl get container "${container}" -o name
        assert_line "container.containers.rancherdesktop.io/${container}"
    done
}

@test "images are created" {
    run -0 cat ../pkg/controllers/mock/testdata/images.json
    run -0 jq_output '.[].RepoTags.[]'
    mapfile -t images <<<"${output}"

    try --max 30 --delay 1 -- rdd ctl get namespace rdd-mocks -o name

    for image in "${images[@]}"; do
        try --max 30 --delay 1 -- rdd ctl get image --field-selector "status.repoTag=${image}" --output jsonpath='{.items[*].status.repoTag}'
        assert_line "${image}"
    done
}
