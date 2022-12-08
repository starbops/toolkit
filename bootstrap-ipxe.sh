#!/usr/bin/env sh

NODE_COUNT=$1

# Configurables
# For bootstrap node
BOOTSTRAP_NODE_VCPUS=8
BOOTSTRAP_NODE_RAM=16384
BOOTSTRAP_NODE_DISK=200
# For remaining nodes
REMAINING_NODE_VPUCS=8
REMAINING_NODE_RAM=8192
REMAINING_NODE_DISK=200

# Sanity checks
if [ -z "$NODE_COUNT" ]; then
  echo "Please specify a valid number for the size of the desired cluster."
  exit 1
fi
if [ -x "$(which virt-install)" ]; then
  echo "virt-install is installed."
else
  echo "Please install virt-install first."
  exit 1
fi

# Create bootstrap node
echo "Creating bootstrap node..."
sudo virt-install \
    --name=node-0 \
    --description="Harvester node 0" \
    --osinfo=slem5.2 \
    --ram="$BOOTSTRAP_NODE_RAM" \
    --vcpus="$BOOTSTRAP_NODE_VCPUS" \
    --disk path=/var/lib/libvirt/images/node-0.img,bus=virtio,size="$BOOTSTRAP_NODE_DISK" \
    --pxe \
    --graphics=vnc \
    --noautoconsole \
    --network=bridge=br0,model=virtio,mac=52:54:00:00:00:01 \
    --network=bridge=br0,model=virtio,mac=52:54:00:00:00:02 \
    --network=network=default,model=virtio,mac=52:54:00:00:00:03 \
    --wait=-1

echo "Wait for the bootstrap node to be ready..."
sleep 120

# Create remaining nodes
for i in $(seq 1 $(($NODE_COUNT - 1))); do
  echo "Creating node $i..."
      sudo virt-install \
      --name=node-$i \
      --description="Harvester node $i" \
      --osinfo=slem5.2 \
      --ram="$REMAINING_NODE_RAM" \
      --vcpus="$REMAINING_NODE_VPUCS" \
      --disk path=/var/lib/libvirt/images/node-$i.img,bus=virtio,size="$REMAINING_NODE_DISK" \
      --pxe \
      --graphics=vnc \
      --noautoconsole \
      --network=bridge=br0,model=virtio,mac=52:54:00:00:0$i:01 \
      --network=bridge=br0,model=virtio,mac=52:54:00:00:0$i:02 \
      --network=network=default,model=virtio,mac=52:54:00:00:0$i:03 \
      --wait=-1
done

echo "Done."