#!/bin/bash

output1=$(kubectl get namespace -A)
output2=$(kubectl get sc -A)
output3=$(kubectl get pvc -A)

echo "Output of kubectl get namespace:"
echo "$output1"
echo ""
echo "Output of kubectl get sc:"
echo "$output2"
echo ""
echo "Output of kubectl get pvc:"
echo "$output3"
