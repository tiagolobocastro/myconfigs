set -e

registry="${1:-192.168.1.137:5000}"

# make sure the local registry is running
(ps aux | grep docker-compose | grep -v grep) || (
    echo "Starting local registry..."
    cd /docker-store && nohup docker-compose up </dev/null >/dev/null 2>&1 &
)

#skopeo copy docker-archive:/$(nix-build -A images.mayastor-image-develop --no-out-link) --dest-tls-verify=false docker://$registry/mayastor:latest
#skopeo copy docker-archive:/$(nix-build -A images.mayastor-csi-develop --no-out-link) --dest-tls-verify=false docker://$registry/mayastor-csi:latest
skopeo copy docker-archive:/$(nix-build -A node-moacImage --no-out-link) --dest-tls-verify=false docker://$registry/moac:latest
