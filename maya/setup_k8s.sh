#!/usr/bin/env bash
set -e

MAYASTOR=~/git/bolt/mayastor
DEPLOY_ORG=$MAYASTOR/deploy
DEPLOY=/tmp/terraform/deploy
TERRA=/tmp/terraform
TERRA_ORG=$MAYASTOR/terraform
MCP=~/git/bolt/mobs/
#MCP=
NODES=3 # includes the master
MAX_NBD=4
POOL_SIZE=16G
POOL_LOCATION=/data
NR_HUGEPAGES=1024
MEMORY=6144
VCPU=4
REPO=192.168.1.137:5000/mayadata
#REPO=ci-registry.mayastor-ci.mayadata.io/mayadata
TAG="latest"
#TAG="v0.0.3"
SSH_KEY=`cat ~/.ssh/id_rsa.pub | tail -c +9`
# lxd or libvirt
PROVIDER=libvirt
PROTOCOL=nvmf
OS_DISK_SIZE=10737418240 # 10GB
export LIBVIRT_DEFAULT_URI=qemu:///system
LIBVIRT_IMAGE_DIR=$HOME/terraform_images
LIBVIRT_IMAGE_URL=https://cloud-images.ubuntu.com/releases/focal/release/ubuntu-20.04-server-cloudimg-amd64.img
LIBVIRT_IMAGE=`basename $LIBVIRT_IMAGE_URL`
LIBVIRT_IMAGE_PATH="$LIBVIRT_IMAGE_DIR"/$LIBVIRT_IMAGE

# request sudo password
sudo ls >/dev/null

# :(
sudo mkdir /images 2>/dev/null || true; sudo chown $USER /images

# make sure the local registry is running
(ps aux | grep -v grep | grep -Eq "docker-compose|docker-registry") || (
    echo "Starting local registry..."
    cd /docker-store && nohup docker-compose up </dev/null >/dev/null 2>&1 &
)

function waitForMsp() {
    echo "Waiting for the pools to become online..."
    tries=80
    while [[ $tries -gt 0 ]]; do
        not_online="no"
        for state in $(kubectl -n mayastor get msp -o json | jq ".items[].status.state" | sed 's/"//g'); do
            if [[ $state != "online" ]]; then
                not_online="yes"
            fi
        done
        if [[ $not_online = "no" ]]; then
            echo "all nodes good!"
            kubectl -n mayastor get msp
            return
        fi

        ((tries--))
        sleep 1
    done
    echo "Timed out waiting for mayastor pools..."
    kubectl get pods -A
    kubectl -n mayastor get msp
    exit 1
}

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
function waitForMcpDeployment() {
    for deployment in csi-controller msp-operator rest; do
        echo "Waiting for $deployment to come up..."
        tries=50
        while [[ $tries -gt 0 ]]; do
            ready=$(kubectl -n mayastor get deployment $deployment -o jsonpath="{.status.readyReplicas}")
            required=$(kubectl -n mayastor get deployment $deployment -o jsonpath="{.status.replicas}")

            if [[ $ready -eq $required ]]; then
                break
            fi

            ((tries--))
            sleep 3
        done
        if [[ $ready -eq $required ]]; then
            echo "Timed out waiting for $deployment..."
            kubectl get pods -A
            exit 1
        fi
    done
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
    mkdir ~/.kube 2>/dev/null || true

    if [ $PROVIDER == 'lxd' ]; then
        tuneK8sNodeLxd
    elif  [ $PROVIDER == 'libvirt' ]; then
        tuneK8sNodeLibVirt
    fi
    
    # This is where mayastor will run
    for i in $(seq 2 $NODES); do
        kubectl label node ksnode-$i openebs.io/engine=mayastor 2>/dev/null || true
        kubectl label node ksnode-$i datacore.com/engine=io-engine 2>/dev/null || true
    done
}
function tuneK8sNodeLibVirt() {
    # Get ansible config
    ( cd $TERRA && terraform output kluster >ansible-hosts ) 
    # Get config to enable kubectl
    ansible -i $TERRA/ansible-hosts -a 'cat ~/.kube/config' master | tail -n+2 >~/.kube/config
    
    # Create Pool for each node and mount it using virsh
    sudo mkdir $POOL_LOCATION 2>/dev/null || true
    sudo chown $USER $POOL_LOCATION
    for i in $(seq 2 $NODES); do
        virsh detach-disk ksnode-$i vdb --live --config 2>/dev/null || true
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
        virsh detach-disk ksnode-$i vdb --live --config || true
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
        #lxc config device remove ksnode-$i nvme1 2>/dev/null || true
        #lxc config device add ksnode-$i nvme1 unix-block path=/dev/nvme1 major=259 minor=0
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
    for image in mayastor mayastor-csi; do
        sed -i "s/image: .*\/$image:.*$/image: \$REPO\/$image:\$TAG/g" $DEPLOY/*.yaml
    done
    if [[ ! $MCP = "" ]]; then
        for image in mcp-csi-controller mcp-rest mcp-core mcp-jsongrpc mcp-msp-operator; do
            sed -i "s/image: .*\/$image:.*$/image: \$REPO\/$image:\$TAG/g" $MCP/*.yaml
        done
    fi
    # Reduce memory and cpu
    sed -i "/-m0x3/d" $DEPLOY/mayastor-daemonset.yaml
    sed -i "s/cpu: \".\"/cpu: \"1\"/g" $DEPLOY/mayastor-daemonset.yaml
    # Add poll delay
    sed -i "s/IMPORT_NEXUSES/MAYASTOR_DELAY/g" $DEPLOY/mayastor-daemonset.yaml
}

function installMayastorCpYaml() {
    patchYamlImages
    set +e
    kubectl create -f $MCP/mayastorpoolcrd.yaml
    kubectl create -f $MCP/crd.yaml
    kubectl create -f $MCP/jaeger-operator
    REPO=$REPO TAG=$TAG envsubst '$REPO $TAG' < $MCP/rest-deployment.yaml | kubectl create -f -
    REPO=$REPO TAG=$TAG envsubst '$REPO $TAG' < $MCP/core-agents-deployment.yaml | kubectl create -f -
    REPO=$REPO TAG=$TAG envsubst '$REPO $TAG' < $MCP/csi-deployment.yaml | kubectl create -f -
    REPO=$REPO TAG=$TAG envsubst '$REPO $TAG' < $MCP/msp-deployment.yaml | kubectl create -f -
    REPO=$REPO TAG=$TAG envsubst '$REPO $TAG' < $MCP/msp-deployment.yaml | kubectl create -f -
    kubectl create -f $MCP/operator-rbac.yaml
    kubectl create -f $MCP/rest-service.yaml
    set -e
}
function installMayastorYaml() {
    patchYamlImages

    # Ok now we're ready to apply some yaml!
    set +e
    kubectl create namespace mayastor
    kubectl create -f $DEPLOY/nats-deployment.yaml
    REPO=$REPO TAG=$TAG envsubst '$REPO $TAG' < $DEPLOY/csi-daemonset.yaml | kubectl create -f -
    kubectl create -f $DEPLOY/etcd/storage
    kubectl create -f $DEPLOY/etcd
    REPO=$REPO TAG=$TAG envsubst '$REPO $TAG' < $DEPLOY/mayastor-daemonset.yaml | kubectl create -f -
    set -e
    
    # Wait for them to come up
    waitForMayastorDS
    
    if [ -n "$MCP" ]; then
        installMayastorCpYaml
        add_storage
        waitForMcpDeployment
    fi

    kubectl -n mayastor get pods
}
function removeMayastorCpYaml() {
    patchYamlImages
    set +e
    REPO=$REPO TAG=$TAG envsubst '$REPO $TAG' < $MCP/rest-deployment.yaml | kubectl delete -f - 2>/dev/null
    REPO=$REPO TAG=$TAG envsubst '$REPO $TAG' < $MCP/core-agents-deployment.yaml | kubectl delete -f - 2>/dev/null
    REPO=$REPO TAG=$TAG envsubst '$REPO $TAG' < $MCP/csi-deployment.yaml | kubectl create -f - 2>/dev/null
    REPO=$REPO TAG=$TAG envsubst '$REPO $TAG' < $MCP/msp-deployment.yaml | kubectl create -f - 2>/dev/null
    kubectl delete -f $MCP/operator-rbac.yaml 2>/dev/null
    kubectl delete -f $MCP/rest-service.yaml 2>/dev/null
    kubectl delete -f $MCP/mayastorpoolcrd.yaml 2>/dev/null
    kubectl delete -f $MCP/jaeger-operator 2>/dev/null || true
    set -e
}
function removeMayastorYaml() {
    patchYamlImages

    set +e
    REPO=$REPO TAG=$TAG envsubst '$REPO $TAG' < $DEPLOY/csi-daemonset.yaml | kubectl delete -f - 2>/dev/null
    REPO=$REPO TAG=$TAG envsubst '$REPO $TAG' < $DEPLOY/mayastor-daemonset.yaml | kubectl delete -f - 2>/dev/null
    kubectl delete -f $DEPLOY/nats-deployment.yaml 2>/dev/null
    kubectl delete -f $DEPLOY/etcd
    kubectl -n mayastor delete pvc --all
    kubectl delete -f $DEPLOY/etcd/storage
    removeMayastorCpYaml
    
    kubectl delete namespace mayastor
    set -e

    # Wait for objects to go away...
    kubectl -n mayastor get pods
}

function remove_storage() {
    kubectl -n mayastor delete msp --all 2>/dev/null || true
    kubectl -n bolt delete dsp --all 2>/dev/null || true
}

function add_storage() {
    # Wait for the MSN to be ready
    # waitForMsn
# Now the pools!
cat << 'EOF' > /tmp/storage_pool.yaml
apiVersion: "openebs.io/v1alpha1"
#apiVersion: "datacore.com/v1alpha1"
#kind: MayastorPool
kind: DiskPool
metadata:
  name: pool-on-node-$NODE
  namespace: bolt
  # namespace: mayastor
spec:
  node: ksnode-$NODE
  disks: ["$POOL"]
EOF
    # delete old ones
    kubectl -n mayastor delete msp --all 2>/dev/null || true
    kubectl -n bolt delete dsp --all 2>/dev/null || true

    if [ $PROVIDER == 'lxd' ]; then
        for i in $(seq 2 $NODES); do
            loop=$(losetup -l -n | grep $POOL_LOCATION/data$i.img | cut -d' ' -f1)
            NODE=$i POOL=$loop envsubst '$NODE $POOL' < /tmp/storage_pool.yaml | kubectl apply -f -
            #NODE=$i POOL=$loop envsubst '$NODE $POOL' < /tmp/storage_pool.yaml | kubectl create -f -
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
kind: DiskPool
metadata:
  name: pool-on-node-$NODE
  namespace: bolt
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

    kubectl -n mayastor delete msp --all || true

    #sleep 10
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
    #kubectl create -f $DEPLOY/fio.yaml

    kubectl get pvc
    kubectl get pods
}
function delete_pvc() {
    kubectl delete -f $DEPLOY/fio.yaml || true
    kubectl delete -f $DEPLOY/pvc.yaml || true
    kubectl delete -f $DEPLOY/storage-class.yaml || true
}
function terraform_setup_force() {
    mkdir -p $DEPLOY
    cp -r $TERRA_ORG/* $TERRA
    cp -rp $DEPLOY_ORG/* $DEPLOY
    rm $DEPLOY/mayastorpool.yaml 2>/dev/null || true
}
function terraform_setup() {
    if [ ! -d $DEPLOY ]; then
        terraform_setup_force
    else
        cp -r $TERRA_ORG/* $TERRA
    fi
}
function terraform_prepare() {
    terraform_setup
    sed -i "s/#default     = \"\/home\/user/default     = \"\/home\/$USER/g" "$TERRA/variables.tf"
    sed -i "s/#default     = \"user\"/default     = \"$USER\"/g" "$TERRA/variables.tf"
    sed -i "s/#default     = \"ssh-rsa/default     = \"ssh-rsa/g" "$TERRA/variables.tf"
    sed -i "/description = \"The size of the root disk in bytes\"$/{N;s/description = \"The size of the root disk in bytes\"\n  default     = 6442450944/description = \"The size of the root disk in bytes\"\n  default     = $OS_DISK_SIZE/}" "$TERRA/variables.tf"

    #sed -i "s/dmacvicar/nixpkgs/" "$TERRA/mod/libvirt/main.tf"
    sed -i "s/cpu = {/cpu {/" "$TERRA/mod/libvirt/main.tf"
    sed -i "s/version = \"0\.6\.2\"/#version = \"0\.6\.3\"/" "$TERRA/mod/libvirt/main.tf"

    sed -i "s/gilanetes/castrol/" "$TERRA/mod/k8s/kubeadm_config.yaml"

    sed -i "s~\.\.\.~$SSH_KEY~g" "$TERRA/variables.tf"

    if [ $PROVIDER == 'lxd' ]; then
        sed -i 's/  source = \"\.\/mod\/libvirt\"/  #source = \"\.\/mod\/libvirt\"/g' $TERRA/main.tf
        sed -i 's/  #source = \"\.\/mod\/lxd\"/  source = \"\.\/mod\/lxd\"/g' $TERRA/main.tf
        sed -i "s/storageClassName: mayastor$/storageClassName: mayastor-nbd/g" "$DEPLOY/pvc.yaml"
        echo "Using LXD provider"
    elif  [ $PROVIDER == 'libvirt' ]; then
        sed -i 's/  source = \"\.\/mod\/lxd\"/  #source = \"\.\/mod\/lxd\"/g' $TERRA/main.tf
        sed -i 's/  #source = \"\.\/mod\/libvirt\"/  source = \"\.\/mod\/libvirt\"/g' $TERRA/main.tf
        sed -i "s/storageClassName: mayastor.*$/storageClassName: mayastor-$PROTOCOL-2/g" "$DEPLOY/pvc.yaml"
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
    terraform apply -var="memory=$MEMORY" -var="vcpu=$VCPU" -var="nr_hugepages=$NR_HUGEPAGES" -var="num_nodes=$NODES" -var="modprobe_nvme=$LIBVIRT_IMAGE" -var="qcow2_image=$LIBVIRT_IMAGE_PATH" -auto-approve
    popd
}
function terraform_destroy() {
    if  [ $PROVIDER == 'libvirt' ]; then
        for i in $(seq 2 $NODES); do
            virsh detach-disk ksnode-$i vdb 2>/dev/null 1>/dev/null || true
        done
    fi
    pushd $TERRA
    #terraform init
    terraform destroy -auto-approve || true
    localRegistry=$(ps a | grep docker-compose | grep -v grep | cut -d' ' -f1)
    [ "$localRegistry" != "" ] && kill $localRegistry
    popd
}

function install_mayastor() {
    installMayastorYaml
    waitForMsp
    #add_storage
    #create_pvc
}
function remove_mayastor() {
    delete_pvc
    remove_storage    
    removeMayastorYaml
}

case "$1" in
    prepare)
        terraform_setup_force
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
    remove_storage)
        remove_storage
        ;;
    restart)
        restartK8S
        ;;
    setup_force)
        terraform_setup_force
        ;;
    setup)
        terraform_setup
        ;;
    *)
        echo $"Usage: $0 {create|create_only|destroy|install|remove|reinstall|restart|test|tune|untune|add_storage|pvc_remove|install_only|reinstall_only}"
        exit 1
esac

echo "Done"

