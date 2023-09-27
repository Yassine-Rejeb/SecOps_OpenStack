#!/bin/bash

# Check if at least one VM IP address is provided as an argument
if [ $# -eq 0 ]; then
    echo "Usage: $0 <VM_IP1> <VM_IP2> <VM_IP3>"
    exit 1
fi

# Function to check if SSH server is available
check_ssh() {
    nc -z -w 1 "$1" 22
}

# Create an array of VM IP addresses from command-line arguments
vms=("$@")

# Loop until all SSH servers are unreachable or the list is empty
while [ ${#vms[@]} -gt 0 ]; do
    for ((i = 0; i < ${#vms[@]}; i++)); do
        vm_ip="${vms[i]}"
        if check_ssh "$vm_ip"; then
            echo "SSH server on $vm_ip is running."
            unset 'vms[i]'  # Remove the VM from the list
            vms=("${vms[@]}")  # Re-index the array
        fi
    done

    if [ ${#vms[@]} -eq 0 ]; then
        echo "All SSH servers are running."
        break
    fi

    sleep 5
done
