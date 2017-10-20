#!/bin/bash

MASTER_HOSTNAME=$1

# Shares
SHARE_HOME=/share/home
# SHARE_DATA=/share/data
SHARE_DATA=/mnt/resource/


# Hpc User
HPC_USER=$2
HPC_UID=7007
HPC_GROUP=hpc
HPC_GID=7007


# Installs all required packages.
#
install_pkgs()
{
    pkgs="libXt libXext"
    yum -y install $pkgs
}


setup_shares()
{
    mkdir -p $SHARE_HOME
    mkdir -p $SHARE_DATA

   
        echo "$MASTER_HOSTNAME:$SHARE_HOME $SHARE_HOME    nfs4    rw,auto,_netdev 0 0" >> /etc/fstab
        echo "$MASTER_HOSTNAME:$SHARE_DATA $SHARE_DATA    nfs4    rw,auto,_netdev 0 0" >> /etc/fstab
        mount -a
        mount | grep "^$MASTER_HOSTNAME:$SHARE_HOME"
        mount | grep "^$MASTER_HOSTNAME:$SHARE_DATA"

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

    
    useradd -c "HPC User" -g $HPC_GROUP -d $SHARE_HOME/$HPC_USER -s /bin/bash -u $HPC_UID $HPC_USER
    
}

# Sets all common environment variables and system parameters.
#
setup_env()
{
    # Set unlimited mem lock
    echo "$HPC_USER hard memlock unlimited" >> /etc/security/limits.conf
    echo "$HPC_USER soft memlock unlimited" >> /etc/security/limits.conf

    # Intel MPI config for IB
    echo "# IB Config for MPI" > /etc/profile.d/hpc.sh
    echo "export I_MPI_FABRICS=shm:dapl" >> /etc/profile.d/hpc.sh
    echo "export I_MPI_DAPL_PROVIDER=ofa-v2-ib0" >> /etc/profile.d/hpc.sh
    echo "export I_MPI_DYNAMIC_CONNECTION=0" >> /etc/profile.d/hpc.sh
	echo "source /opt/intel/compilers_and_libraries_2017.2.174/linux/mpi/bin64/mpivars.sh" >> /etc/profile.d/hpc.sh
    
}

setup_torque()
{
    cp -rp /mnt/resource/torque/torque-6.0.2-1469811694_d9a3483 ~
    cd ~/torque-6.0.2-1469811694_d9a3483
    ./configure
    make
    make install
    yes | cp /mnt/resource/torque/server_name  /var/spool/torque/
    cp /mnt/resource/torque/config /var/spool/torque/mom_priv/
      
}

install_pkgs
setup_shares
setup_hpc_user
setup_env
setup_torque



