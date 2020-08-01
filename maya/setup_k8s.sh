#!/usr/bin/env bash
set -e

MAYASTOR=~/git/Mayastor
DEPLOY=$MAYASTOR/deploy
TERRA=$MAYASTOR/terraform
NODES=4
MAX_NBD=4
POOL_SIZE=2GiB
POOL_LOCATION=/data
REPO=192.168.1.137:5000
#REPO=mayadata
TAG="latest"
#TAG_MAYA=1e5dca3
#TAG_GRPC=08a71d45c9f2bf284f8b713dea116f0ab819fc4d
#TAG_MOAC=08a71d45c9f2bf284f8b713dea116f0ab819fc4d
SSH_KEY=`cat ~/.ssh/id_rsa.pub | tail -c +9`

# request sudo password
sudo ls >/dev/null

# enable LXD
sed -i 's/  source = \"\.\/mod\/libvirt\"/  #source = \"\.\/mod\/libvirt\"/g' $TERRA/main.tf
sed -i 's/  #source = \"\.\/mod\/lxd\"/  source = \"\.\/mod\/lxd\"/g' $TERRA/main.tf

# make sure the local registry is running
(ps aux | grep docker-compose | grep -v grep) || (
    echo "Starting local registry..."
    cd /docker-store && nohup docker-compose up </dev/null >/dev/null 2>&1 &
)

function waitForMayastorDS() {
    echo "Waiting for mayastor to come up..."
    tries=50
    while [[ $tries -gt 0 ]]; do
        ready=$(kubectl -n mayastor get daemonset mayastor -o jsonpath="{.status.numberReady}")
        required=$(kubectl -n mayastor get daemonset mayastor -o jsonpath="{.status.desiredNumberScheduled}")

        if [[ $ready -eq $required ]]; then
            return
        fi

        ((tries--))
        sleep 3
    done
    echo "Timed out waiting for mayastor daemonset..."
    kubectl get pods -A
    exit 1
}
function waitForMoacDeployment() {
    echo "Waiting for moac to come up..."
    tries=50
    while [[ $tries -gt 0 ]]; do
        ready=$(kubectl -n mayastor get deployment moac -o jsonpath="{.status.readyReplicas}")
        required=$(kubectl -n mayastor get deployment moac -o jsonpath="{.status.replicas}")

        if [[ $ready -eq $required ]]; then
            return
        fi

        ((tries--))
        sleep 3
    done
    echo "Timed out waiting for moac deployment..."
    kubectl get pods -A
    exit 1
}

function waitForMsn() {
    echo "Waiting for MSN..."

    tries=40
    while [[ $tries -gt 0 ]]; do
        up="yes"
        for i in $(seq 2 $NODES); do
            kubectl -n mayastor get msn ksnode-$i >/dev/null 2>/dev/null || up="no"
        done

        if [[ $up == "yes" ]]; then
            return
        fi

        ((tries--))
        sleep 5
    done
    echo "Timed out waiting for MSN..."
    exit 1
}

function waitForK8s() {
    echo "Waiting for K8S..."

    tries=20
    while [[ $tries -gt 0 ]]; do
        up="yes"
        kubectl get nodes 2>/dev/null || up="no"

        if [[ $up == "yes" ]]; then
            return
        fi

        ((tries--))
        sleep 1
    done
    echo "Timed out waiting for K8S..."
    exit 1
}


function tuneK8sNode() {
    # Get config to enable kubectl
    lxc exec ksnode-1 -- cat /etc/kubernetes/admin.conf > ~/.kube/config
    # This is where mayastor will run
    for i in $(seq 2 $NODES); do
        kubectl label node ksnode-$i openebs.io/engine=mayastor 2>/dev/null || true
    done
    
    # Create Pool for each node and mount it over loop
    for i in $(seq 2 $NODES); do
        loop=$(losetup -l -n | grep $POOL_LOCATION/data$i.img | cut -d' ' -f1)
        for j in $loop; do
            # remove before we detach
            lxc config device remove ksnode-$i ${loop:5:10} 2>/dev/null || true
            sudo losetup -d $j
        done
        rm $POOL_SIZE $POOL_LOCATION/data$i.img 2>/dev/null || true
        fallocate -l $POOL_SIZE $POOL_LOCATION/data$i.img
        sudo losetup -f $POOL_LOCATION/data$i.img
    done

    # Mount the pool into the node
    for i in $(seq 2 $NODES); do
        loop=$(losetup -l -n | grep $POOL_LOCATION/data$i.img | cut -d' ' -f1 | head -n 1)
        lxc config device add ksnode-$i ${loop:5:10} unix-block path=$loop
    done

    # Mount the NBD devices
    for i in $(seq 2 $NODES); do
        # Add 5, should be enough for now 
        for j in $(seq 0 $MAX_NBD); do
            lxc config device remove ksnode-$i nbd$j 2>/dev/null || true
            lxc config device add ksnode-$i nbd$j unix-block path=/dev/nbd$j
        done
    done
    
    # Mount the nvme-fabrics devices
    #for i in $(seq 2 $NODES); do
    #    lxc config device remove ksnode-$i nvme-fabrics 2>/dev/null || true
    #    lxc config device add ksnode-$i nvme-fabrics unix-block path=/dev/nvme-fabrics
    #done
}

function restartK8S() {
    for i in $(seq 2 $NODES); do
        lxc restart ksnode-$i
    done

    waitForK8s
}

function installMayastorYaml() {
    # Patch the mayastor, mayastor-grpc and moac images?
    sed -i 's/mayadata\/mayastor:v0.2.0/$REPO\/mayastor:$TAG/g' $DEPLOY/*.yaml
    sed -i 's/mayadata\/mayastor-grpc:v0.2.0/$REPO\/mayastor-grpc:$TAG/g' $DEPLOY/*.yaml
    sed -i 's/mayadata\/mayastor-csi:v0.2.0/$REPO\/mayastor-csi:$TAG/g' $DEPLOY/*.yaml
    sed -i 's/mayadata\/moac:v0.2.0/$REPO\/moac:$TAG/g' $DEPLOY/*.yaml

    # Ok now we're ready to apply some yaml!
    set +e
    # Namespace, moac and mayastor
    kubectl create -f $DEPLOY/namespace.yaml 
    kubectl create -f $DEPLOY/nats-deployment.yaml
    kubectl create -f $DEPLOY/mayastorpoolcrd.yaml
    REPO=$REPO TAG=$TAG envsubst '$REPO $TAG' < $DEPLOY/mayastor-daemonset.yaml | kubectl create -f -
    REPO=$REPO TAG=$TAG envsubst '$REPO $TAG' < $DEPLOY/moac-deployment.yaml | kubectl create -f -
    set -e

    # Wait for them to come up
    waitForMayastorDS
    waitForMoacDeployment
    kubectl -n mayastor get pods
}
function removeMayastorYaml() {
    # Patch the mayastor, mayastor-grpc and moac images?
    sed -i 's/mayadata\/mayastor:latest/$REPO\/mayastor:$TAG/g' $DEPLOY/*.yaml
    sed -i 's/mayadata\/mayastor-grpc:latest/$REPO\/mayastor-grpc:$TAG/g' $DEPLOY/*.yaml
    sed -i 's/mayadata\/mayastor-csi:latest/$REPO\/mayastor-csi:$TAG/g' $DEPLOY/*.yaml
    sed -i 's/mayadata\/moac:latest/$REPO\/moac:$TAG/g' $DEPLOY/*.yaml
    
    set +e
    REPO=$REPO TAG=$TAG envsubst '$REPO $TAG' < $DEPLOY/moac-deployment.yaml | kubectl delete -f - 2>/dev/null
    REPO=$REPO TAG=$TAG envsubst '$REPO $TAG' < $DEPLOY/mayastor-daemonset.yaml | kubectl delete -f - 2>/dev/null
    kubectl delete -f $DEPLOY/nats-deployment.yaml 2>/dev/null
    kubectl delete -f $DEPLOY/mayastorpoolcrd.yaml 2>/dev/null
    kubectl delete -f $DEPLOY/namespace.yaml 2>/dev/null
    set -e

    # Wait for objects to go away...
    kubectl -n mayastor get pods
}

function add_storage() {
    # Wait for the MSN to be ready
    waitForMsn
# Now the pools!
cat << 'EOF' > /tmp/storage_pool.yaml
apiVersion: "openebs.io/v1alpha1"
kind: MayastorPool
metadata:
  name: pool-on-node-$NODE
  namespace: mayastor
spec:
  node: ksnode-$NODE
  disks: ["$POOL"]
EOF
    # delete old ones
    kubectl -n mayastor delete msp --all 2>/dev/null || true

    for i in $(seq 2 $NODES); do
        loop=$(losetup -l -n | grep $POOL_LOCATION/data$i.img | cut -d' ' -f1)
        NODE=$i POOL=$loop envsubst '$NODE $POOL' < /tmp/storage_pool.yaml | kubectl create -f -
    done

    #sleep 1
    #for i in $(seq 2 $NODES); do kubectl -n mayastor describe msp pool-on-node-$i; done
}
function remove_storage() {
cat << 'EOF' > /tmp/storage_pool.yaml
apiVersion: "openebs.io/v1alpha1"
kind: MayastorPool
metadata:
  name: pool-on-node-$NODE
  namespace: mayastor
spec:
  node: ksnode-$NODE
  disks: ["$POOL"]
EOF

    for i in $(seq 2 $NODES); do
        loop=$(losetup -l -n | grep $POOL_LOCATION/data$i.img | cut -d' ' -f1)
        NODE=$i POOL=$loop envsubst '$NODE $POOL' < /tmp/storage_pool.yaml | kubectl delete -f - || true
    done

    sleep 10
}

function create_pvc() {
    # Let's create a PVC
    kubectl create -f $DEPLOY/storage-class.yaml
    kubectl create -f $DEPLOY/pvc.yaml # ms-volume-claim
    #kubectl create -f $DEPLOY/fio.yaml

    kubectl get pvc
    kubectl get pods
}
function delete_pvc() {
    kubectl delete -f $DEPLOY/fio.yaml --force || true
    kubectl delete -f $DEPLOY/pvc.yaml || true
    kubectl delete -f $DEPLOY/storage-class.yaml || true
}

function terraform_prepare() {
    sed -i "s/#default     = \"\/home\/user/default     = \"\/home\/$USER/g" "$TERRA/variables.tf"
    sed -i "s/#default     = \"user\"/default     = \"$USER\"/g" "$TERRA/variables.tf"
    sed -i "s/#default     = \"ssh-rsa/default     = \"ssh-rsa/g" "$TERRA/variables.tf"
    sed -i "s~\.\.\.~$SSH_KEY~g" "$TERRA/variables.tf"
}
function terraform_create() {
    pushd $TERRA
    # Prepare hugepages and conn hashsize
    echo 2048 | sudo tee /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages >/dev/null
    echo "393216" | sudo tee /sys/module/nf_conntrack/parameters/hashsize >/dev/null
    # extra space is to stop it from doing it again everytime
    sed -i "s/\"storage-driver\": \"overlay2\"/\"storage-driver\":  \"overlay2\",\n  \"insecure-registries\" : [\"192\.168\.1\.137:5000\"]/g" "$TERRA/mod/k8s/repo.sh"

    terraform apply -var="num_nodes=$NODES" -auto-approve
    popd
}
function terraform_destroy() {
    pushd $TERRA
    terraform destroy -auto-approve
    localRegistry=$(ps a | grep docker-compose | grep -v grep | cut -d' ' -f1)
    [ "$localRegistry" != "" ] && kill $localRegistry
    popd
}

function install_mayastor() {
    installMayastorYaml
    add_storage
    create_pvc
}
function remove_mayastor() {
    delete_pvc
    remove_storage    
    removeMayastorYaml
}

case "$1" in
    destroy)
        terraform_prepare
        terraform_destroy
        ;;
    create)
        terraform_prepare
        terraform_destroy
        terraform_create
        tuneK8sNode
        install_mayastor
        ;;
    create_only)
        terraform_prepare
        terraform_destroy
        terraform_create
        tuneK8sNode
        installMayastorYaml
        ;;
    install)
        install_mayastor
        ;;
    install_only)
        installMayastorYaml
        ;;
    remove)
        remove_mayastor
        ;;
    reinstall_only)
        remove_mayastor
        installMayastorYaml
        ;;
    reinstall)
        remove_mayastor
        install_mayastor
        ;;
    tune)
        tuneK8sNode
        restartK8S
        ;;
    pvc_remove)
        delete_pvc
        ;;
    test)
        delete_pvc
        create_pvc
        ;;
    add_storage)
        add_storage
        ;;
    restart)
        restartK8S
        ;;
    *)
        echo $"Usage: $0 {create|destroy|install|remove|reinstall|restart|test}"
        exit 1
esac

echo "Done"

