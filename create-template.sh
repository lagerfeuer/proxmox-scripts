!/bin/bash

set -euo pipefail

NAME="debian-13"
STORAGE="local-lvm"
DEFAULT_DISK_SIZE="10G"

IMAGE_URL="https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2"
IMAGE_SHA_URL="https://cloud.debian.org/images/cloud/trixie/latest/SHA512SUMS"

OUTDIR="/tmp/proxmox-images"
mkdir -p "${OUTDIR}"

IMAGE_NAME="$(basename ${IMAGE_URL})"
IMAGE_PATH="${OUTDIR}/${IMAGE_NAME}"
SHA_FILE="${OUTDIR}/SHA512SUMS"

if [[ ! -f "${IMAGE_PATH}" ]]; then
    curl -Lo "${IMAGE_PATH}" "${IMAGE_URL}"
fi
if [[ ! -f "${SHA_FILE}" ]]; then
    curl -Lo "${SHA_FILE}" "${IMAGE_SHA_URL}"
fi

(
    cd "${OUTDIR}"
    sha512sum --ignore-missing -c "${SHA_FILE}" # TODO: delete image if this check fails
)

qm create 5000 --memory 2048 --core 1 --name "${NAME}" --net0 virtio,bridge=vmbr0
cd /var/lib/vz/template/iso/
qm importdisk 5000 "${IMAGE_PATH}" "${STORAGE}"
qm set 5000 --scsihw virtio-scsi-pci --scsi0 "${STORAGE}:5000/vm-5000-disk-0.raw"
qm set 5000 --ide2 "${STORAGE}:cloudinit"
qm set 5000 --boot c --bootdisk scsi0
qm set 5000 --serial0 socket --vga serial0

qm disk resize 5000 scsi0 "${DEFAULT_DISK_SIZE}"
