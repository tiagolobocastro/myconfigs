set -e

registry="${1:-192.168.1.137:5000}"

#skopeo copy docker-archive:/$(nix-build -A images.mayastor-image-develop --no-out-link) --dest-tls-verify=false docker://$registry/mayastor:latest
#skopeo copy docker-archive:/$(nix-build -A images.mayastor-csi-develop --no-out-link) --dest-tls-verify=false docker://$registry/mayastor-csi:latest
skopeo copy docker-archive:/$(nix-build -A node-moacImage --no-out-link) --dest-tls-verify=false docker://$registry/moac:latest
