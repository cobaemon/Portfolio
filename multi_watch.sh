#!/bin/bash

output1=$(kubectl get nodes -A)
output2=$(kubectl get pods -A)
output3=$(kubectl get deploy -A)
output4=$(kubectl get services -A)

echo "Output of kubectl get node:"
echo "$output1"
echo ""
echo "Output of kubectl get pod:"
echo "$output2"
echo ""
echo "Output of kubectl get deploy:"
echo "$output3"
echo ""
echo "Output of kubectl get service:"
echo "$output4"
