#!/bin/bash

MASTER_HOSTNAME=$1

# Shares
SHARE_HOME=/datahpc/
SHARE_DATA2=/datadrive/
#SHARE_DATA=/mnt/resource/


# Hpc User
HPC_USER=$2
HPC_UID=7007
HPC_GROUP=hpc
HPC_GID=7007


# Installs all required packages.
#
install_pkgs()
{
    pkgs="libXt libXext zlib zlib-devel bzip2 bzip2-devel bzip2-libs openssl openssl-devel openssl-libs gcc gcc-c++ nfs-utils rpcbind mdadm wget libtool libxml2-devel boost-devel"
    yum -y install $pkgs
}


setup_shares()
{
    mkdir -p $SHARE_HOME
    mkdir -p $SHARE_DATA2
    chmod 777 $SHARE_HOME
    chmod 777 $SHARE_DATA2
   
        echo "$MASTER_HOSTNAME:/home/hpc $SHARE_HOME    nfs    rw,auto,_netdev 0 0" >> /etc/fstab
        echo "$MASTER_HOSTNAME:$SHARE_DATA2 $SHARE_DATA2    nfs    rw,auto,_netdev 0 0" >> /etc/fstab
        mount -a
        mount | grep "^$MASTER_HOSTNAME:$SHARE_HOME"
        mount | grep "^$MASTER_HOSTNAME:$SHARE_DATA2"

}

# Adds a common HPC user to the node and configures public key SSh auth.
# The HPC user has a shared home directory (NFS share on master) and access
# to the data share.
#
setup_hpc_user()
{
    # disable selinux
    sed -i 's/enforcing/disabled/g' /etc/selinux/config
    setenforce permissive
    
    groupadd -g $HPC_GID $HPC_GROUP

    # Don't require password for HPC user sudo
    echo "$HPC_USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    
    # Disable tty requirement for sudo
    sed -i 's/^Defaults[ ]*requiretty/# Defaults requiretty/g' /etc/sudoers

    
    ##useradd -c "HPC User" -g $HPC_GROUP -s /bin/bash -u $HPC_UID $HPC_USER
    useradd -c "HPC User" -g $HPC_GROUP -d $SHARE_HOME -s /bin/bash -u $HPC_UID $HPC_USER
}

# Sets all common environment variables and system parameters.
#
setup_env()
{
    # Set unlimited mem lock
    echo "$HPC_USER hard memlock unlimited" >> /etc/security/limits.conf
    echo "$HPC_USER soft memlock unlimited" >> /etc/security/limits.conf
    
}

setup_torque()
{
    cp -rp /datadrive/torque/torque-6.0.2-1469811694_d9a3483_configured /tmp/.
    #cp -rp /datadrive/torque/torque-6.0.2-1469811694_d9a3483_configured /home/hpc/.
    cd /tmp/torque-6.0.2-1469811694_d9a3483_configured
    make install
    yes | cp /datadrive/torque/server_name  /var/spool/torque/
    cp /datadrive/torque/config /var/spool/torque/mom_priv/      
}

install_pkgs
setup_shares
setup_hpc_user
setup_env
setup_torque

