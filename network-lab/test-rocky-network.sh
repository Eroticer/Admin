#!/bin/bash

echo "=== Testing Network Lab (Rocky Linux 9) ==="

test_connectivity() {
    local from=$1
    local to=$2
    local description=$3
    
    echo "Testing: $description"
    if vagrant ssh $from -c "ping -c 2 -W 1 $to" &>/dev/null; then
        echo "✓ SUCCESS: $from -> $to"
        return 0
    else
        echo "✗ FAILED: $from -> $to"
        return 1
    fi
}

echo "1. Testing basic connectivity..."
test_connectivity centralServer "192.168.0.1" "centralServer -> centralRouter"
test_connectivity office1Server "192.168.2.129" "office1Server -> office1Router"
test_connectivity office2Server "192.168.1.1" "office2Server -> office2Router"

echo "2. Testing cross-office connectivity..."
test_connectivity office1Server "192.168.1.2" "office1Server -> office2Server"
test_connectivity office2Server "192.168.2.130" "office2Server -> office1Server"
test_connectivity centralServer "192.168.2.130" "centralServer -> office1Server"

echo "3. Testing internet connectivity..."
test_connectivity centralServer "8.8.8.8" "centralServer -> Internet"
test_connectivity office1Server "8.8.8.8" "office1Server -> Internet"
test_connectivity office2Server "8.8.8.8" "office2Server -> Internet"

echo "4. Displaying network info..."
for machine in inetRouter centralRouter office1Router office2Router centralServer office1Server office2Server; do
    echo "--- $machine Network Info ---"
    vagrant ssh $machine -c "ip route" 2>/dev/null
    echo ""
done

echo "=== Testing Complete ==="
