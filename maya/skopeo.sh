set -e

export registry="192.168.1.137:5000"
function mayastor() {
    skopeo copy docker-archive:/$(nix-build -A images.mayastor-dev-image --no-out-link) --dest-tls-verify=false docker://$registry/mayastor:latest
}
function mayastorCsi() {
    skopeo copy docker-archive:/$(nix-build -A images.mayastor-csi-dev-image --no-out-link) --dest-tls-verify=false docker://$registry/mayastor-csi:latest
}
function mayastorAll() {
    mayastor
    mayastorCsi
}
function moac() {
    skopeo copy docker-archive:/$(nix-build -A images.moac-image --no-out-link) --dest-tls-verify=false docker://$registry/moac:latest
}
function all() {
    mayastorAll
    moac
}

# make sure the local registry is running
(ps aux | grep -v grep | grep -Eq "docker-compose|docker-registry") || (
    echo "Starting local registry..."
    cd /docker-store && nohup docker-compose up </dev/null >/dev/null 2>&1 &
)

case "$1" in
    mayastor)
        mayastor
        ;;
    mayastorCsi)
        mayastorCsi
        ;;
    mayastorAll)
        mayastorAll
        ;;
    moac)
        moac 
        ;;
    all)
        all
        ;;
    *)
        echo $"Usage: $0 { mayastor | mayastorCsi | mayastorAll | moac | all }"
        exit 1
esac

