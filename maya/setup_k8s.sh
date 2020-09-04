#!/usr/bin/env bash
set -e

MAYASTOR=~/git/Mayastor
DEPLOY=$MAYASTOR/deploy
TERRA=$MAYASTOR/terraform
NODES=4
MAX_NBD=4
POOL_SIZE=2G
POOL_LOCATION=/data
REPO=192.168.1.137:5000
#REPO=mayadata
TAG="latest"
#TAG="v0.0.3"
SSH_KEY=`cat ~/.ssh/id_rsa.pub | tail -c +9`
# lxd or libvirt
PROVIDER=lxd
export LIBVIRT_DEFAULT_URI=qemu:///system
LIBVIRT_IMAGE_DIR=$HOME/terraform_images
LIBVIRT_IMAGE_URL=https://cloud-images.ubuntu.com/releases/focal/release/ubuntu-20.04-server-cloudimg-amd64.img
LIBVIRT_IMAGE=`basename $LIBVIRT_IMAGE_URL`
LIBVIRT_IMAGE_PATH="$LIBVIRT_IMAGE_DIR"/$LIBVIRT_IMAGE

# request sudo password
sudo ls >/dev/null

# make sure the local registry is running
(ps aux | grep -v grep | grep -Eq "docker-compose|docker-registry") || (
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
            if ! kubectl get nodes | tail -n+2 | awk '{ print $2 }' | grep -vwq 'Ready'; then
                return
            fi
        fi

        ((tries--))
        sleep 1
    done
    echo "Timed out waiting for K8S..."
    exit 1
}

function tuneK8sNode() {
    if [ $PROVIDER == 'lxd' ]; then
        tuneK8sNodeLxd
    elif  [ $PROVIDER == 'libvirt' ]; then
        tuneK8sNodeLibVirt
    fi
    
    # This is where mayastor will run
    for i in $(seq 2 $NODES); do
        kubectl label node ksnode-$i openebs.io/engine=mayastor 2>/dev/null || true
    done
}
function tuneK8sNodeLibVirt() {
    # Get ansible config
    ( cd $TERRA && terraform output kluster ) >ansible-hosts
    # Get config to enable kubectl
    ansible -i ansible-hosts -a 'cat ~/.kube/config' master | tail -n+2 >~/.kube/config
    
    # Create Pool for each node and mount it using virsh
    sudo mkdir $POOL_LOCATION 2>/dev/null || true
    sudo chown $USER $POOL_LOCATION
    for i in $(seq 2 $NODES); do
        virsh detach-disk ksnode-$i vdb || true
        rm -f $POOL_LOCATION/data$i.img 2>/dev/null || true
        qemu-img create -f raw $POOL_LOCATION/data$i.img $POOL_SIZE
        virsh attach-disk ksnode-$i $POOL_LOCATION/data$i.img vdb --cache none --persistent
    done
}

function unTuneK8sNode() {
    if [ $PROVIDER == 'lxd' ]; then
        unTuneK8sNodeLxd
    elif  [ $PROVIDER == 'libvirt' ]; then
        unTuneK8sNodeLibVirt
    fi
}
function unTuneK8sNodeLibVirt() {
    for i in $(seq 2 $NODES); do
        virsh detach-disk ksnode-$i vdb || true
        rm -f $POOL_LOCATION/data$i.img 2>/dev/null || true
    done
}

function unTuneK8sNodeLxd() {
    for i in $(seq 2 $NODES); do
        loop=$(losetup -l -n | grep $POOL_LOCATION/data$i.img | cut -d' ' -f1)
        for j in $loop; do
            lxc config device remove ksnode-$i ${loop:5:10} 2>/dev/null || true
            sudo losetup -d $j
        done
        rm -f $POOL_LOCATION/data$i.img 2>/dev/null || true
    done
}

function tuneK8sNodeLxd() {
    # Get config to enable kubectl
    lxc exec ksnode-1 -- cat /etc/kubernetes/admin.conf > ~/.kube/config
    
    # Create Pool for each node and mount it over loop
    sudo mkdir $POOL_LOCATION 2>/dev/null || true
    sudo chown $USER $POOL_LOCATION
    for i in $(seq 2 $NODES); do
        loop=$(losetup -l -n | grep $POOL_LOCATION/data$i.img | cut -d' ' -f1)
        for j in $loop; do
            # remove before we detach
            lxc config device remove ksnode-$i ${loop:5:10} 2>/dev/null || true
            sudo losetup -d $j
        done
        rm -f $POOL_LOCATION/data$i.img 2>/dev/null || true
        fallocate -l $POOL_SIZE $POOL_LOCATION/data$i.img
        sudo losetup -f $POOL_LOCATION/data$i.img
    done

    # Mount the pool into the node
    for i in $(seq 2 $NODES); do
        loop=$(losetup -l -n | grep $POOL_LOCATION/data$i.img | cut -d' ' -f1 | head -n 1)
        lxc config device add ksnode-$i ${loop:5:10} unix-block path=$loop || true
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
    for i in $(seq 2 $NODES); do
        lxc config device remove ksnode-$i nvme-fabrics 2>/dev/null || true
        lxc config device add ksnode-$i nvme-fabrics unix-char path=/dev/nvme-fabrics
    done
}

function restartK8S() {
    if [ $PROVIDER == 'lxd' ]; then
        for i in $(seq 2 $NODES); do
            lxc restart ksnode-$i
        done
    elif  [ $PROVIDER == 'libvirt' ]; then
        # todo
        echo "Restarting..."
    fi

    waitForK8s
}

function patchYamlImages() {
    # Patch our k8s container images
    for image in mayastor mayastor-csi moac; do
        sed -i "s/image: .*\/$image:.*$/image: \$REPO\/$image:\$TAG/g" $DEPLOY/*.yaml
    done
}
function installMayastorYaml() {
    patchYamlImages

    # Ok now we're ready to apply some yaml!
    set +e
    # Namespace, moac and mayastor
    kubectl create -f $DEPLOY/namespace.yaml 
    kubectl create -f $DEPLOY/nats-deployment.yaml
    REPO=$REPO TAG=$TAG envsubst '$REPO $TAG' < $DEPLOY/csi-daemonset.yaml | kubectl create -f -
    kubectl create -f $DEPLOY/mayastorpoolcrd.yaml
    kubectl create -f $DEPLOY/moac-rbac.yaml
    REPO=$REPO TAG=$TAG envsubst '$REPO $TAG' < $DEPLOY/moac-deployment.yaml | kubectl create -f -
    REPO=$REPO TAG=$TAG envsubst '$REPO $TAG' < $DEPLOY/mayastor-daemonset.yaml | kubectl create -f -
    set -e

    # Wait for them to come up
    waitForMayastorDS
    waitForMoacDeployment
    kubectl -n mayastor get pods
}
function removeMayastorYaml() {
    patchYamlImages

    set +e
    REPO=$REPO TAG=$TAG envsubst '$REPO $TAG' < $DEPLOY/csi-daemonset.yaml | kubectl delete - 2>/dev/null
    REPO=$REPO TAG=$TAG envsubst '$REPO $TAG' < $DEPLOY/mayastor-daemonset.yaml | kubectl delete - 2>/dev/null
    kubectl delete -f $DEPLOY/mayastorpoolcrd.yaml 2>/dev/null
    REPO=$REPO TAG=$TAG envsubst '$REPO $TAG' < $DEPLOY/moac-deployment.yaml | kubectl delete - 2>/dev/null
    kubectl delete -f $DEPLOY/nats-deployment.yaml 2>/dev/null
    kubectl delete -f $DEPLOY/moac-rbac.yaml
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

    if [ $PROVIDER == 'lxd' ]; then
        for i in $(seq 2 $NODES); do
            loop=$(losetup -l -n | grep $POOL_LOCATION/data$i.img | cut -d' ' -f1)
            NODE=$i POOL=$loop envsubst '$NODE $POOL' < /tmp/storage_pool.yaml | kubectl create -f -
        done
    elif  [ $PROVIDER == 'libvirt' ]; then
        for i in $(seq 2 $NODES); do
            pool='/dev/vda'
            NODE=$i POOL=$pool envsubst '$NODE $POOL' < /tmp/storage_pool.yaml | kubectl create -f -
        done
    fi

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

    if [ $PROVIDER == 'lxd' ]; then
        for i in $(seq 2 $NODES); do
            loop=$(losetup -l -n | grep $POOL_LOCATION/data$i.img | cut -d' ' -f1)
            NODE=$i POOL=$loop envsubst '$NODE $POOL' < /tmp/storage_pool.yaml | kubectl delete -f - || true
        done
    elif  [ $PROVIDER == 'libvirt' ]; then
        for i in $(seq 2 $NODES); do
            pool='/dev/vda'
            NODE=$i POOL=$pool envsubst '$NODE $POOL' < /tmp/storage_pool.yaml | kubectl delete -f - || true
        done
    fi

    kubectl -n mayastor delete msp --all

    sleep 10
}

function create_pvc() {
grep -q nbd $DEPLOY/storage-class.yaml || cat << 'EOF' >> $DEPLOY/storage-class.yaml
---
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: mayastor-nbd
parameters:
  repl: '2'
  protocol: 'nbd'
provisioner: io.openebs.csi-mayastor
EOF
    # Let's create a PVC
    kubectl create -f $DEPLOY/storage-class.yaml || true
    kubectl create -f $DEPLOY/pvc.yaml # ms-volume-claim
    kubectl create -f $DEPLOY/fio.yaml

    kubectl get pvc
    kubectl get pods
}
function delete_pvc() {
    kubectl delete -f $DEPLOY/fio.yaml || true
    kubectl delete -f $DEPLOY/pvc.yaml || true
    kubectl delete -f $DEPLOY/storage-class.yaml || true
}

function terraform_prepare() {
    sed -i "s/#default     = \"\/home\/user/default     = \"\/home\/$USER/g" "$TERRA/variables.tf"
    sed -i "s/#default     = \"user\"/default     = \"$USER\"/g" "$TERRA/variables.tf"
    sed -i "s/#default     = \"ssh-rsa/default     = \"ssh-rsa/g" "$TERRA/variables.tf"
    sed -i "s~\.\.\.~$SSH_KEY~g" "$TERRA/variables.tf"

    if [ $PROVIDER == 'lxd' ]; then
        sed -i 's/  source = \"\.\/mod\/libvirt\"/  #source = \"\.\/mod\/libvirt\"/g' $TERRA/main.tf
        sed -i 's/  #source = \"\.\/mod\/lxd\"/  source = \"\.\/mod\/lxd\"/g' $TERRA/main.tf
        sed -i "s/storageClassName: mayastor$/storageClassName: mayastor-nbd/g" "$DEPLOY/pvc.yaml"
        echo "Using LXD provider"
    elif  [ $PROVIDER == 'libvirt' ]; then
        sed -i 's/  source = \"\.\/mod\/lxd\"/  #source = \"\.\/mod\/lxd\"/g' $TERRA/main.tf
        sed -i 's/  #source = \"\.\/mod\/libvirt\"/  source = \"\.\/mod\/libvirt\"/g' $TERRA/main.tf
        sudo mkdir -p $LIBVIRT_IMAGE_DIR
        sudo chown $USER $LIBVIRT_IMAGE_DIR
        if [ ! -f $LIBVIRT_IMAGE_PATH ]; then
            ( cd $LIBVIRT_IMAGE_DIR && wget $LIBVIRT_IMAGE_URL )
        fi
        sed -i "s/storageClassName: mayastor$/storageClassName: mayastor-iscsi/g" "$DEPLOY/pvc.yaml"
        sed -i "s/default     = \"\/ubuntu.*$/default     = \"${LIBVIRT_IMAGE_PATH//\//\\/}\"/g" "$TERRA/variables.tf"
        echo "Using libvirt provider"
    fi
}

function terraform_create() {
    pushd $TERRA
    # Prepare hugepages and conn hashsize
    if [ $PROVIDER == 'lxd' ]; then
        echo 2048 | sudo tee /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages >/dev/null
        echo "393216" | sudo tee /sys/module/nf_conntrack/parameters/hashsize >/dev/null
    fi
    # extra space is to stop it from doing it again everytime
    sed -i "s/\"storage-driver\": \"overlay2\"/\"storage-driver\":  \"overlay2\",\n  \"insecure-registries\" : [\"192\.168\.1\.137:5000\"]/g" "$TERRA/mod/k8s/repo.sh"

    terraform init
    terraform apply -var="num_nodes=$NODES" -var="modprobe_nvme=$LIBVIRT_IMAGE" -var="qcow2_image=$LIBVIRT_IMAGE_PATH" -auto-approve
    popd
}
function terraform_destroy() {
    if  [ $PROVIDER == 'libvirt' ]; then
        for i in $(seq 2 $NODES); do
            virsh detach-disk ksnode-$i vdb 2>/dev/null 1>/dev/null || true
        done
    fi
    pushd $TERRA
    terraform init
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
    prepare)
        terraform_prepare
        ;;
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
    untune)
        unTuneK8sNode
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
        echo $"Usage: $0 {create|create_only|destroy|install|remove|reinstall|restart|test|tune|untune|add_storage|pvc_remove|install_only|reinstall_only}"
        exit 1
esac

echo "Done"

