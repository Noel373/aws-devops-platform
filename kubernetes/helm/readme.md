Install AWS Load Balancer Controller with Helm

helm repo add eks https://aws.github.io/eks-charts
helm repo update


helm install aws-load-balancer-controller eks/aws-load-balancer-controller `
  -n kube-system `
  --set clusterName=petclinic-eks `
  --set serviceAccount.create=false `
  --set serviceAccount.name=aws-load-balancer-controller `
  --set region=eu-north-1 `
  --set vpcId=vpc-0a6062da9bfe4c5a0