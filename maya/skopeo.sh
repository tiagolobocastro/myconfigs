set -e

export registry="192.168.1.137:5000"
function mayastor() {
    skopeo copy docker-archive:/$(nix-build -A images.mayastor-dev --no-out-link) --dest-tls-verify=false docker://$registry/mayadata/mayastor:latest --insecure-policy
}
function mayastorCsi() {
    skopeo copy docker-archive:/$(nix-build -A images.mayastor-csi --no-out-link) --dest-tls-verify=false docker://$registry/mayadata/mayastor-csi:latest --insecure-policy
}
function mayastorAll() {
    mayastor
    mayastorCsi
}
function moac() {
    skopeo copy docker-archive:/$(nix-build -A images.moac --no-out-link) --dest-tls-verify=false docker://$registry/mayadata/moac:latest --insecure-policy
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
    csi)
        mayastorCsi
        ;;
    mayastorAll)
        mayastorAll
        ;;
    moac)
        moac 
        ;;
    kiiss)
        skopeo copy docker-archive:/$(nix-build -A images.services-kiiss-dev-image --no-out-link) --dest-tls-verify=false docker://$registry/kiiss:latest
        ;;
    all)
        all
        ;;
    *)
        echo $"Usage: $0 { mayastor | csi | mayastorCsi | mayastorAll | moac | all }"
        exit 1
esac

