# Set of common functions used across scripts

function is_slurm_controller() {
    test -e /usr/sbin/slurmctld
}

function is_login_node() {
    echo $HOSTNAME | grep -q 'login'
}

function is_compute_node() {
    ! is_slurm_controller && ! is_login_node
}
