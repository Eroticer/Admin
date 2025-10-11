#!/bin/bash

echo "=== Final Network Lab Test ==="

test_trace() {
    local from=$1
    local to=$2
    local description=$3
    
    echo "=== $description ==="
    echo "Traceroute from $from to $to:"
    vagrant ssh $from -c "traceroute -n -m 5 $to" 2>/dev/null
    echo ""
}

echo "1. Testing internet routing paths..."
test_trace office1Server "8.8.8.8" "Internet path from Office1"
test_trace office2Server "8.8.8.8" "Internet path from Office2" 
test_trace centralServer "8.8.8.8" "Internet path from Central"

echo "2. Testing cross-office routing..."
test_trace office1Server "192.168.1.2" "Office1 -> Office2 path"
test_trace office2Server "192.168.2.130" "Office2 -> Office1 path"
test_trace centralServer "192.168.2.130" "Central -> Office1 path"

echo "3. Displaying final routing tables..."
for machine in inetRouter centralRouter office1Router office2Router centralServer office1Server office2Server; do
    echo "--- $machine Final Routes ---"
    vagrant ssh $machine -c "ip route" 2>/dev/null
    echo ""
done

echo "=== Final Test Complete ==="
