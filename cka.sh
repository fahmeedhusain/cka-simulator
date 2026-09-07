#!/usr/bin/env bash
# ==============================================================================
# CKA Exam Simulator CLI (Final, Hardened Release)
# Usage:
#   cka q<1-17>       - Display question text
#   cka setup<1-17>   - Configure lab environment for question
#   cka s<1-17>       - Display step-by-step solution
#   cka grade<1-17>   - Grade single question and give feedback
#   cka grade-all     - End-to-end exam evaluation across all 17 questions
# ==============================================================================

set -u

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

TOTAL_POINTS=0
PASSED_POINTS=0

print_banner() {
  echo -e "${CYAN}${BOLD}================================================================${NC}"
  echo -e "${CYAN}${BOLD}  $1${NC}"
  echo -e "${CYAN}${BOLD}================================================================${NC}"
}

pass() {
  echo -e "  [${GREEN}PASSED${NC}] $1"
  ((PASSED_POINTS++))
}

fail() {
  echo -e "  [${RED}FAILED${NC}] $1"
  echo -e "\n  ${YELLOW}${BOLD}Remediation & Correct Solution:${NC}"
  echo -e "$2\n"
}

# ==============================================================================
# 1. QUESTIONS
# ==============================================================================
show_q() {
  case "$1" in
    1) cat <<'QEOF'
[Question 1: MariaDB PVC & Recovery]
A user accidentally deleted the MariaDB Deployment in the mariadb namespace.
The deployment was configured with persistent storage. Your responsibility is
to re-establish the deployment while ensuring data is preserved by reusing the
available PersistentVolume.

Tasks:
1. A PersistentVolume already exists and is retained for reuse. Only one PV exists.
2. Create a Persistent Volume Claim (PVC) named mariadb in the mariadb namespace:
   - Access Mode: ReadWriteOnce
   - Storage: 250Mi
3. Edit the MariaDB Deployment file located at ~/mariadb-deploy.yaml to use the
   PVC created in the previous step.
4. Apply the updated Deployment file to the cluster.
5. Ensure the MariaDB Deployment is running and stable.
QEOF
;;
    2) cat <<'QEOF'
[Question 2: ArgoCD Helm Template]
Install Argo CD in a kubernetes cluster using helm while ensuring the CRDs
are not installed (as they are pre-installed).

Tasks:
1. Add the official Argo CD Helm repository named argocd (https://argoproj.github.io/argo-helm).
2. Create a namespace called argocd.
3. Generate a Helm template from the Argo CD chart version 7.7.3 for the argocd namespace.
4. Ensure that CRDs are not installed by configuring the chart accordingly.
5. Save the generated YAML manifest to /root/argo-helm.yaml.
QEOF
;;
    3) cat <<'QEOF'
[Question 3: WordPress Sidecar]
Update the existing wordpress deployment adding a sidecar container named sidecar
using the busybox:stable image to the existing pod.

Tasks:
1. The new sidecar container has to run: /bin/sh -c "tail -f /var/log/wordpress.log"
2. Use a volume mounted at /var/log to make the log file wordpress.log available
   to the co-located container.
QEOF
;;
    4) cat <<'QEOF'
[Question 4: WordPress Equal Resource Distribution]
Adjust the Pod resource requests and limits of the WordPress deployment to ensure stable operation.

Tasks:
1. Scale down the wordpress deployment to 0 replicas.
2. Edit the deployment and divide the node resources evenly across all 3 pods.
3. Assign fair and equal CPU and memory to each Pod. Add sufficient overhead.
4. Ensure both init containers and main containers use exactly the same resource requests and limits.
5. Scale the deployment back to 3 replicas.
QEOF
;;
    5) cat <<'QEOF'
[Question 5: Horizontal Pod Autoscaler (HPA)]
Create a new HorizontalPodAutoscaler (HPA) named apache-server in the autoscale namespace.

Tasks:
1. Target the existing deployment called apache-deployment in the autoscale namespace.
2. Target 50% CPU usage per Pod.
3. Configure minimum 1 pod and maximum 4 pods.
4. Set the downscale stabilization window to 30 seconds.
QEOF
;;
    6) cat <<'QEOF'
[Question 6: CRD Documentation Extraction]
Tasks:
1. Create a list of all cert-manager CRDs and save it to /root/resources.yaml.
2. Using kubectl, extract the documentation for the subject specification field of the
   Certificate Custom Resource and save it to /root/subject.yaml.
QEOF
;;
    7) cat <<'QEOF'
[Question 7: PriorityClass & Deployment Patch]
Tasks:
1. Create a new PriorityClass named high-priority for user workloads. The value should
   be exactly one less than the highest existing user-defined priority class.
2. Patch the existing deployment busybox-logger in the priority namespace to use the
   newly created high-priority class.
QEOF
;;
    8) cat <<'QEOF'
[Question 8: CNI Installation]
Install and configure a CNI of your choice that meets the specified requirements:
Options:
- Flannel (v0.26.1) using https://github.com/flannel-io/flannel/releases/download/v0.26.1/kube-flannel.yml
- Calico (v3.28.2) using https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/tigera-operator.yaml

Requirements:
1. Let pods communicate with each other.
2. Support network policy enforcement.
3. Install from manifest.
QEOF
;;
    9) cat <<'QEOF'
[Question 9: cri-dockerd Setup]
Tasks:
1. Install the debian package ~/cri-dockerd.deb using dpkg.
2. Enable and start the cri-docker service.
3. Configure these sysctl parameters persistently:
   - net.bridge.bridge-nf-call-iptables = 1
   - net.ipv6.conf.all.forwarding = 1
   - net.ipv4.ip_forward = 1
   - net.netfilter.nf_conntrack_max = 131072
QEOF
;;
    10) cat <<'QEOF'
[Question 10: Taints and Tolerations]
Tasks:
1. Add a taint to node01: key=PERMISSION, value=granted, Type=NoSchedule.
2. Schedule a Pod on node01 adding the correct toleration to the spec so it can be deployed.
QEOF
;;
    11) cat <<'QEOF'
[Question 11: Gateway API Migration]
Migrate an existing Ingress configuration (ingress named web) to the Kubernetes Gateway API.

Tasks:
1. Create a Gateway resource named web-gateway with hostname gateway.web.k8s.local
   maintaining existing TLS and listener configuration from ingress web.
2. Create an HTTPRoute resource named web-route with hostname gateway.web.k8s.local
   maintaining existing routing rules from ingress web.
Note: GatewayClass nginx-class is already installed.
QEOF
;;
    12) cat <<'QEOF'
[Question 12: Ingress & NodePort Service]
Tasks:
1. Expose the existing deployment echo in namespace echo-sound with a service called
   echo-service using Service Port 8080 type=NodePort.
2. Create a new ingress resource named echo in namespace echo-sound for http://example.org/echo.
QEOF
;;
    13) cat <<'QEOF'
[Question 13: Least Permissive Network Policy]
Tasks:
1. Inspect the NetworkPolicy files in /root/network-policies.
2. Decide which policy allows interaction between frontend and backend deployments
   in the least permissive way and deploy it to the backend namespace.
QEOF
;;
    14) cat <<'QEOF'
[Question 14: StorageClass Management]
Tasks:
1. Create a new StorageClass named local-storage with provisioner rancher.io/local-path.
   Set volumeBindingMode to WaitForFirstConsumer. Do not make it default yet.
2. Patch the StorageClass to make it the default StorageClass.
3. Ensure local-storage is the only default class.
QEOF
;;
    15) cat <<'QEOF'
[Question 15: Fix kube-apiserver etcd Port]
After a cluster migration, the controlplane kube-apiserver is not coming up because
it is pointing to etcd peer port 2380.
Task: Fix it.
QEOF
;;
    16) cat <<'QEOF'
[Question 16: Deployment Port & NodePort Service]
Tasks:
1. Configure deployment nodeport-deployment in namespace relative so it can be exposed
   on port 80, name=http, protocol TCP.
2. Create a Service named nodeport-service exposing container port 80, protocol TCP,
   NodePort 30080 in namespace relative.
QEOF
;;
    17) cat <<'QEOF'
[Question 17: Nginx TLSv1.3 Lockdown & Resolution]
Tasks:
1. In namespace nginx-static, configure the ConfigMap nginx-config to only support TLSv1.3.
2. Add the IP address of the service to /etc/hosts named ckaquestion.k8s.local.
3. Restart deployment and verify TLSv1.2 fails while TLSv1.3 succeeds.
QEOF
;;
    *) echo -e "${RED}Invalid question index. Use q1 through q17.${NC}" ;;
  esac
}

# ==============================================================================
# 2. LAB SETUPS
# ==============================================================================
run_setup() {
  case "$1" in
    1)
      print_banner "Setting up Lab 1 (MariaDB Storage)"
      kubectl create ns mariadb --dry-run=client -o yaml | kubectl apply -f -
      kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mariadb-pv
  labels:
    app: mariadb
spec:
  capacity:
    storage: 250Mi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: standard
  hostPath:
    path: /mnt/data/mariadb
EOF
      kubectl delete deployment mariadb -n mariadb --ignore-not-found 2>/dev/null
      kubectl delete pvc mariadb -n mariadb --ignore-not-found 2>/dev/null
      claim_ref=$(kubectl get pv mariadb-pv -o jsonpath='{.spec.claimRef.name}' 2>/dev/null || true)
      if [ -n "$claim_ref" ]; then
        kubectl patch pv mariadb-pv --type=json -p '[{"op":"remove","path":"/spec/claimRef"}]'
      fi
      cat <<'EOF' > ~/mariadb-deploy.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mariadb
  namespace: mariadb
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mariadb
  template:
    metadata:
      labels:
        app: mariadb
    spec:
      containers:
      - name: mariadb
        image: mariadb:10.6
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: rootpass
        volumeMounts:
        - name: mariadb-storage
          mountPath: /var/lib/mysql
      volumes:
      - name: mariadb-storage
        persistentVolumeClaim:
          claimName: ""
EOF
      echo -e "${GREEN}Lab 1 ready. Deployment file placed at ~/mariadb-deploy.yaml.${NC}"
      ;;
    2)
      print_banner "Setting up Lab 2 (ArgoCD)"
      echo -e "${GREEN}Lab 2 uses standard environment. No pre-adjustments needed.${NC}"
      ;;
    3)
      print_banner "Setting up Lab 3 (WordPress Sidecar)"
      cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wordpress
  labels:
    app: wordpress
spec:
  replicas: 1
  selector:
    matchLabels:
      app: wordpress
  template:
    metadata:
      labels:
        app: wordpress
    spec:
      containers:
      - name: wordpress
        image: wordpress:php8.2-apache
        command: ["/bin/sh", "-c", "while true; do echo 'WordPress is running...' >> /var/log/wordpress.log; sleep 5; done"]
        ports:
        - containerPort: 80
EOF
      cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: wordpress
spec:
  selector:
    app: wordpress
  ports:
  - port: 80
    targetPort: 80
EOF
      echo -e "${GREEN}Lab 3 ready. WordPress deployment created in default namespace.${NC}"
      ;;
    4)
      print_banner "Setting up Lab 4 (WordPress Resources)"
      cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wordpress
spec:
  replicas: 3
  selector:
    matchLabels:
      app: wordpress
  template:
    metadata:
      labels:
        app: wordpress
    spec:
      initContainers:
      - name: init-setup
        image: busybox
        command: ["sh", "-c", "echo 'Preparing environment...' && sleep 5"]
      containers:
      - name: wordpress
        image: wordpress:6.2-apache
        ports:
        - containerPort: 80
EOF
      echo -e "${GREEN}Lab 4 ready. WordPress deployment created with initContainer.${NC}"
      ;;
    5)
      print_banner "Setting up Lab 5 (HPA)"
      kubectl create namespace autoscale --dry-run=client -o yaml | kubectl apply -f -
      kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml >/dev/null 2>&1 || true
      kubectl patch deployment metrics-server -n kube-system --type='json' \
        -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]' 2>/dev/null || true
      cat <<EOF | kubectl apply -n autoscale -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: apache-deployment
  namespace: autoscale
spec:
  replicas: 1
  selector:
    matchLabels:
      app: apache
  template:
    metadata:
      labels:
        app: apache
    spec:
      containers:
      - name: apache
        image: httpd
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 100m
          limits:
            cpu: 200m
EOF
      kubectl expose deployment apache-deployment -n autoscale --port=80 --target-port=80 --dry-run=client -o yaml | kubectl apply -f -
      echo -e "${GREEN}Lab 5 ready. Deployment and Service created in autoscale namespace.${NC}"
      ;;
    6)
      print_banner "Setting up Lab 6 (Cert-Manager CRDs)"
      kubectl create ns cert-manager --dry-run=client -o yaml | kubectl apply -f -
      kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.0/cert-manager.crds.yaml >/dev/null 2>&1
      cat <<EOF | kubectl apply -n cert-manager -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cert-manager
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cert-manager
  template:
    metadata:
      labels:
        app: cert-manager
    spec:
      containers:
      - name: cert-manager
        image: quay.io/jetstack/cert-manager-controller:v1.14.0
        args: ["--v=2"]
EOF
      echo -e "${GREEN}Lab 6 ready. Cert-Manager CRDs installed.${NC}"
      ;;
    7)
      print_banner "Setting up Lab 7 (PriorityClass)"
      kubectl create namespace priority --dry-run=client -o yaml | kubectl apply -f -
      cat <<EOF | kubectl apply -f -
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: user-critical
value: 1000
globalDefault: false
description: "Highest user-defined priority class"
EOF
      cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: busybox-logger
  namespace: priority
spec:
  replicas: 1
  selector:
    matchLabels:
      app: busybox-logger
  template:
    metadata:
      labels:
        app: busybox-logger
    spec:
      containers:
      - name: busybox
        image: busybox
        command: ["sh", "-c", "while true; do echo 'logging...'; sleep 5; done"]
EOF
      echo -e "${GREEN}Lab 7 ready. PriorityClass 'user-critical' (1000) and busybox-logger created.${NC}"
      ;;
    8)
      print_banner "Setting up Lab 8 (CNI)"
      echo -e "${GREEN}Lab 8 uses default cluster playground.${NC}"
      ;;
    9)
      print_banner "Setting up Lab 9 (cri-dockerd)"
      wget -q https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.20/cri-dockerd_0.3.20.3-0.debian-bullseye_amd64.deb -O /root/cri-dockerd.deb
      echo -e "${GREEN}Downloaded debian package to /root/cri-dockerd.deb.${NC}"
      ;;
    10)
      print_banner "Setting up Lab 10 (Taints & Tolerations)"
      echo -e "${GREEN}Lab 10 uses default cluster playground.${NC}"
      ;;
    11)
      print_banner "Setting up Lab 11 (Gateway API)"
      kubectl apply -k "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v1.1.0" >/dev/null 2>&1
      cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-deployment
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: web
        image: nginx
        ports:
        - containerPort: 80
EOF
      cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  selector:
    app: web
  ports:
  - name: http
    port: 80
    targetPort: 80
EOF
      openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /tmp/tls.key -out /tmp/tls.crt -subj "/CN=gateway.web.k8s.local/O=web" >/dev/null 2>&1
      kubectl create secret tls web-tls --cert=/tmp/tls.crt --key=/tmp/tls.key --dry-run=client -o yaml | kubectl apply -f -
      rm -f /tmp/tls.key /tmp/tls.crt
      cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  tls:
  - hosts:
    - gateway.web.k8s.local
    secretName: web-tls
  rules:
  - host: gateway.web.k8s.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
EOF
      cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: nginx-class
spec:
  controllerName: example.net/nginx-gateway-controller
EOF
      echo -e "${GREEN}Lab 11 ready. Ingress 'web', Secret 'web-tls', and GatewayClass 'nginx-class' created.${NC}"
      ;;
    12)
      print_banner "Setting up Lab 12 (Ingress & Echo Service)"
      kubectl create ns echo-sound --dry-run=client -o yaml | kubectl apply -f -
      cat <<EOF | kubectl -n echo-sound apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: echo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: echo
  template:
    metadata:
      labels:
        app: echo
    spec:
      containers:
      - name: echo
        image: gcr.io/google_containers/echoserver:1.10
        ports:
        - containerPort: 8080
EOF
      echo -e "${GREEN}Lab 12 ready. Echo deployment running in echo-sound namespace.${NC}"
      ;;
    13)
      print_banner "Setting up Lab 13 (NetworkPolicy Selection)"
      kubectl create namespace frontend --dry-run=client -o yaml | kubectl apply -f -
      kubectl create namespace backend --dry-run=client -o yaml | kubectl apply -f -
      kubectl label namespace frontend name=frontend --overwrite
      kubectl label namespace backend name=backend --overwrite

      cat <<EOF | kubectl apply -n backend -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-deployment
  namespace: backend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: nginx
        ports:
        - containerPort: 80
EOF
      kubectl expose deployment backend-deployment -n backend --port=80 --target-port=80 --name=backend-service --dry-run=client -o yaml | kubectl apply -f -

      cat <<EOF | kubectl apply -n frontend -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-deployment
  namespace: frontend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: curlimages/curl
        command: ["sleep", "3600"]
EOF
      mkdir -p /root/network-policies
      cat <<EOF > /root/network-policies/network-policy-1.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: policy-x
  namespace: backend
spec:
  podSelector: {}
  ingress:
  - {}
  policyTypes:
  - Ingress
EOF
      cat <<EOF > /root/network-policies/network-policy-2.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: policy-y
  namespace: backend
spec:
  podSelector:
    matchLabels:
      app: backend
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: frontend
    - ipBlock:
        cidr: 172.16.0.0/16
    ports:
    - protocol: TCP
      port: 80
  policyTypes:
  - Ingress
EOF
      cat <<EOF > /root/network-policies/network-policy-3.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: policy-z
  namespace: backend
spec:
  podSelector:
    matchLabels:
      app: backend
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: frontend
      podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 80
  policyTypes:
  - Ingress
EOF
      echo -e "${GREEN}Lab 13 ready. Policy candidates generated in /root/network-policies.${NC}"
      ;;
    14)
      print_banner "Setting up Lab 14 (StorageClass Defaults)"
      echo -e "${GREEN}Lab 14 uses default cluster storage.${NC}"
      ;;
    15)
      print_banner "Setting up Lab 15 (Broken API Server Port)"
      cp /etc/kubernetes/manifests/kube-apiserver.yaml /root/kube-apiserver.yaml.bak 2>/dev/null || true
      sed -i 's/:2379/:2380/g' /etc/kubernetes/manifests/kube-apiserver.yaml
      echo -e "${GREEN}Lab 15 ready. kube-apiserver switched to 2380 and temporarily broken.${NC}"
      ;;
    16)
      print_banner "Setting up Lab 16 (NodePort Relative)"
      kubectl create namespace relative --dry-run=client -o yaml | kubectl apply -f -
      kubectl -n relative create deployment nodeport-deployment --image=nginx --replicas=2 --dry-run=client -o yaml | kubectl apply -f -
      echo -e "${GREEN}Lab 16 ready. nodeport-deployment running in namespace relative.${NC}"
      ;;
    17)
      print_banner "Setting up Lab 17 (TLS Lockdown)"
      kubectl create namespace nginx-static --dry-run=client -o yaml | kubectl apply -f -
      openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /tmp/tls.key -out /tmp/tls.crt -subj "/CN=ckaquestion.k8s.local" >/dev/null 2>&1
      kubectl -n nginx-static create secret tls nginx-tls --cert=/tmp/tls.crt --key=/tmp/tls.key --dry-run=client -o yaml | kubectl apply -f -
      rm -f /tmp/tls.key /tmp/tls.crt

      cat <<EOF | kubectl -n nginx-static apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
data:
  nginx.conf: |
    events {}
    http {
      server {
        listen 443 ssl;
        ssl_certificate /etc/nginx/tls/tls.crt;
        ssl_certificate_key /etc/nginx/tls/tls.key;
        ssl_protocols TLSv1.2 TLSv1.3;
        location / {
          return 200 "Hello TLS\n";
        }
      }
    }
EOF
      cat <<EOF | kubectl -n nginx-static apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-static
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx-static
  template:
    metadata:
      labels:
        app: nginx-static
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        volumeMounts:
        - name: config
          mountPath: /etc/nginx/nginx.conf
          subPath: nginx.conf
        - name: tls
          mountPath: /etc/nginx/tls
      volumes:
      - name: config
        configMap:
          name: nginx-config
      - name: tls
        secret:
          secretName: nginx-tls
EOF
      kubectl -n nginx-static expose deployment nginx-static --port=443 --target-port=443 --name=nginx-static --dry-run=client -o yaml | kubectl apply -f -
      echo -e "${GREEN}Lab 17 ready. nginx-static deployment and service active.${NC}"
      ;;
    *) echo -e "${RED}Invalid setup option. Use setup1 through setup17.${NC}" ;;
  esac
}

# ==============================================================================
# 3. SOLUTIONS
# ==============================================================================
show_s() {
  case "$1" in
    1) cat <<'SOUT'
# Step 1: create PVC with no storageClass
cat <<'EOF' > pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mariadb
  namespace: mariadb
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 250Mi
EOF
kubectl apply -f pvc.yaml

# Step 2: ensure deployment uses the PVC
# Edit ~/mariadb-deploy.yaml and set persistentVolumeClaim.claimName: mariadb
kubectl apply -f ~/mariadb-deploy.yaml
SOUT
;;
    2) cat <<'SOUT'
kubectl create namespace argocd
helm repo add argocd https://argoproj.github.io/argo-helm
helm repo update
helm template argocd argocd/argo-cd --version 7.7.3 --set crds.install=false --namespace argocd > /root/argo-helm.yaml
SOUT
;;
    3) cat <<'SOUT'
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wordpress
spec:
  template:
    spec:
      volumes:
      - name: log
        emptyDir: {}
      containers:
      - name: wordpress
        volumeMounts:
        - name: log
          mountPath: /var/log
      - name: sidecar
        image: busybox:stable
        command: ["/bin/sh","-c","tail -f /var/log/wordpress.log"]
        volumeMounts:
        - name: log
          mountPath: /var/log
EOF
kubectl rollout status deployment wordpress
SOUT
;;
    4) cat <<'SOUT'
kubectl scale deployment wordpress --replicas 0
kubectl edit deployment wordpress
# Under both containers[] and initContainers[] configure identical resources:
# resources:
#   requests:
#     cpu: "300m"
#     memory: "600Mi"
#   limits:
#     cpu: "400m"
#     memory: "700Mi"
kubectl scale deployment wordpress --replicas 3
kubectl rollout status deployment wordpress
SOUT
;;
    5) cat <<'SOUT'
cat <<'EOF' > hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: apache-server
  namespace: autoscale
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: apache-deployment
  minReplicas: 1
  maxReplicas: 4
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 30
EOF
kubectl apply -f hpa.yaml
SOUT
;;
    6) cat <<'SOUT'
kubectl get crd | grep cert-manager | tee /root/resources.yaml
kubectl explain certificate.spec.subject | tee /root/subject.yaml
SOUT
;;
    7) cat <<'SOUT'
kubectl create priorityclass high-priority --value=999 --description="high priority"
kubectl patch deployment busybox-logger -n priority -p '{"spec":{"template":{"spec":{"priorityClassName":"high-priority"}}}}'
SOUT
;;
    8) cat <<'SOUT'
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/tigera-operator.yaml
SOUT
;;
    9) cat <<'SOUT'
sudo dpkg -i /root/cri-dockerd.deb
sudo systemctl enable --now cri-docker.service

sudo tee /etc/sysctl.d/kube.conf >/dev/null <<'EOF'
net.bridge.bridge-nf-call-iptables=1
net.ipv6.conf.all.forwarding=1
net.ipv4.ip_forward=1
net.netfilter.nf_conntrack_max=131072
EOF
sudo sysctl --system
SOUT
;;
    10) cat <<'SOUT'
kubectl taint nodes node01 PERMISSION=granted:NoSchedule

cat <<'EOF' > pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
  - name: nginx
    image: nginx
  tolerations:
  - key: PERMISSION
    operator: Equal
    value: granted
    effect: NoSchedule
EOF
kubectl apply -f pod.yaml
SOUT
;;
    11) cat <<'SOUT'
cat <<'EOF' > gw.yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: web-gateway
spec:
  gatewayClassName: nginx-class
  listeners:
  - name: https
    protocol: HTTPS
    port: 443
    hostname: gateway.web.k8s.local
    tls:
      mode: Terminate
      certificateRefs:
      - kind: Secret
        name: web-tls
EOF
kubectl apply -f gw.yaml

cat <<'EOF' > http.yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: web-route
spec:
  parentRefs:
  - name: web-gateway
  hostnames:
  - "gateway.web.k8s.local"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: web-service
      port: 80
EOF
kubectl apply -f http.yaml
SOUT
;;
    12) cat <<'SOUT'
kubectl expose deployment echo -n echo-sound --name echo-service --type NodePort --port 8080 --target-port 8080

cat <<'EOF' > ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: echo
  namespace: echo-sound
spec:
  rules:
  - host: example.org
    http:
      paths:
      - path: /echo
        pathType: Prefix
        backend:
          service:
            name: echo-service
            port:
              number: 8080
EOF
kubectl apply -f ingress.yaml
SOUT
;;
    13) cat <<'SOUT'
kubectl apply -f /root/network-policies/network-policy-3.yaml
SOUT
;;
    14) cat <<'SOUT'
cat <<'EOF' > sc.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-storage
  annotations:
    storageclass.kubernetes.io/is-default-class: "false"
provisioner: rancher.io/local-path
volumeBindingMode: WaitForFirstConsumer
EOF
kubectl apply -f sc.yaml

kubectl patch storageclass local-storage -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
kubectl patch storageclass local-path -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
SOUT
;;
    15) cat <<'SOUT'
sudo vi /etc/kubernetes/manifests/kube-apiserver.yaml
# Change: --etcd-servers=https://127.0.0.1:2380
# To:     --etcd-servers=https://127.0.0.1:2379
SOUT
;;
    16) cat <<'SOUT'
kubectl patch deployment nodeport-deployment -n relative -p '{
  "spec":{"template":{"spec":{"containers":[{
    "name":"nginx",
    "ports":[{"name":"http","containerPort":80,"protocol":"TCP"}]
  }]}}}}'

cat <<'EOF' > svc.yaml
apiVersion: v1
kind: Service
metadata:
  name: nodeport-service
  namespace: relative
spec:
  type: NodePort
  selector:
    app: nodeport-deployment
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
    nodePort: 30080
EOF
kubectl apply -f svc.yaml
SOUT
;;
    17) cat <<'SOUT'
# Step 1: Remove TLSv1.2 from nginx-config ConfigMap
kubectl edit cm -n nginx-static nginx-config

# Step 2: Add IP to /etc/hosts
IP=$(kubectl get svc -n nginx-static nginx-static -o jsonpath='{.spec.clusterIP}')
echo "$IP ckaquestion.k8s.local" | sudo tee -a /etc/hosts

# Step 3: Restart deployment
kubectl rollout restart -n nginx-static deployment nginx-static
SOUT
;;
    *) echo -e "${RED}Invalid solution index. Use s1 through s17.${NC}" ;;
  esac
}

# ==============================================================================
# 4. GRADING FUNCTIONS
# ==============================================================================
grade_q1() {
  ((TOTAL_POINTS++))
  pvc_status=$(kubectl get pvc mariadb -n mariadb -o jsonpath='{.status.phase}' 2>/dev/null)
  pvc_mode=$(kubectl get pvc mariadb -n mariadb -o jsonpath='{.spec.accessModes[0]}' 2>/dev/null)
  pvc_storage=$(kubectl get pvc mariadb -n mariadb -o jsonpath='{.spec.resources.requests.storage}' 2>/dev/null)
  pv_claim=$(kubectl get pv mariadb-pv -o jsonpath='{.spec.claimRef.name}' 2>/dev/null)
  ready_replicas=$(kubectl get deployment mariadb -n mariadb -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
  mounted_claim=$(kubectl get deployment mariadb -n mariadb -o jsonpath='{.spec.template.spec.volumes[*].persistentVolumeClaim.claimName}' 2>/dev/null)

  if [[ "$pvc_status" == "Bound" ]] && [[ "$pvc_mode" == "ReadWriteOnce" ]] && [[ "$pvc_storage" == "250Mi" ]] && \
     [[ "$pv_claim" == "mariadb" ]] && [[ "${ready_replicas:-0}" -ge 1 ]] && [[ "$mounted_claim" == *"mariadb"* ]]; then
    pass "Question 1: MariaDB PVC bound to mariadb-pv and deployment running."
  else
    fail "Question 1: MariaDB PVC is missing, unbound, or deployment not using claim 'mariadb'." "$(show_s 1)"
  fi
}

grade_q2() {
  ((TOTAL_POINTS++))
  helm_repo=$(helm repo list 2>/dev/null | grep -E "https://argoproj\.github\.io/argo-helm" || true)
  ns_exists=$(kubectl get ns argocd --no-headers 2>/dev/null | wc -l)
  manifest_file="/root/argo-helm.yaml"

  file_valid=0
  if [[ -s "$manifest_file" ]]; then
    crd_lines=$(grep -c "kind: CustomResourceDefinition" "$manifest_file" || true)
    argo_deploy=$(grep -c "argo-cd-argocd-server" "$manifest_file" || true)
    if [[ "${crd_lines:-0}" -eq 0 ]] && [[ "${argo_deploy:-0}" -gt 0 ]]; then
      file_valid=1
    fi
  fi

  if [[ -n "$helm_repo" ]] && [[ "${ns_exists:-0}" -ge 1 ]] && [[ "$file_valid" -eq 1 ]]; then
    pass "Question 2: ArgoCD repo added, namespace created, and /root/argo-helm.yaml contains CRD-free template."
  else
    fail "Question 2: ArgoCD Helm setup or /root/argo-helm.yaml template incomplete." "$(show_s 2)"
  fi
}

grade_q3() {
  ((TOTAL_POINTS++))
  sc_img=$(kubectl get deployment wordpress -o jsonpath='{.spec.template.spec.containers[?(@.name=="sidecar")].image}' 2>/dev/null)
  sc_cmd=$(kubectl get deployment wordpress -o jsonpath='{.spec.template.spec.containers[?(@.name=="sidecar")].command[*]}' 2>/dev/null)
  wp_mount=$(kubectl get deployment wordpress -o jsonpath='{.spec.template.spec.containers[?(@.name=="wordpress")].volumeMounts[?(@.mountPath=="/var/log")].name}' 2>/dev/null)
  sc_mount=$(kubectl get deployment wordpress -o jsonpath='{.spec.template.spec.containers[?(@.name=="sidecar")].volumeMounts[?(@.mountPath=="/var/log")].name}' 2>/dev/null)
  ready=$(kubectl get deployment wordpress -o jsonpath='{.status.readyReplicas}' 2>/dev/null)

  if [[ "$sc_img" == "busybox:stable" ]] && [[ "$sc_cmd" == *"tail -f /var/log/wordpress.log"* ]] && \
     [[ -n "$wp_mount" ]] && [[ "$wp_mount" == "$sc_mount" ]] && [[ "${ready:-0}" -ge 1 ]]; then
    pass "Question 3: Sidecar attached sharing /var/log emptyDir volume."
  else
    fail "Question 3: WordPress sidecar container or shared volume not configured properly." "$(show_s 3)"
  fi
}

grade_q4() {
  ((TOTAL_POINTS++))
  replicas=$(kubectl get deployment wordpress -o jsonpath='{.spec.replicas}' 2>/dev/null)
  ready=$(kubectl get deployment wordpress -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
  c_req_cpu=$(kubectl get deployment wordpress -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}' 2>/dev/null)
  c_req_mem=$(kubectl get deployment wordpress -o jsonpath='{.spec.template.spec.containers[0].resources.requests.memory}' 2>/dev/null)
  init_req_cpu=$(kubectl get deployment wordpress -o jsonpath='{.spec.template.spec.initContainers[0].resources.requests.cpu}' 2>/dev/null)
  init_req_mem=$(kubectl get deployment wordpress -o jsonpath='{.spec.template.spec.initContainers[0].resources.requests.memory}' 2>/dev/null)

  if [[ "${replicas:-0}" -eq 3 ]] && [[ "${ready:-0}" -eq 3 ]] && [[ -n "$c_req_cpu" ]] && \
     [[ "$c_req_cpu" == "$init_req_cpu" ]] && [[ "$c_req_mem" == "$init_req_mem" ]]; then
    pass "Question 4: WordPress scaled to 3 replicas with equal resources for containers and initContainers."
  else
    fail "Question 4: WordPress replicas != 3 or resource mismatch between init and application container." "$(show_s 4)"
  fi
}

grade_q5() {
  ((TOTAL_POINTS++))
  target=$(kubectl get hpa apache-server -n autoscale -o jsonpath='{.spec.scaleTargetRef.name}' 2>/dev/null)
  min_r=$(kubectl get hpa apache-server -n autoscale -o jsonpath='{.spec.minReplicas}' 2>/dev/null)
  max_r=$(kubectl get hpa apache-server -n autoscale -o jsonpath='{.spec.maxReplicas}' 2>/dev/null)
  util=$(kubectl get hpa apache-server -n autoscale -o jsonpath='{.spec.metrics[?(@.type=="Resource")].resource.target.averageUtilization}' 2>/dev/null)
  stab=$(kubectl get hpa apache-server -n autoscale -o jsonpath='{.spec.behavior.scaleDown.stabilizationWindowSeconds}' 2>/dev/null)

  if [[ "$target" == "apache-deployment" ]] && [[ "${min_r:-0}" -eq 1 ]] && [[ "${max_r:-0}" -eq 4 ]] && \
     [[ "${util:-0}" -eq 50 ]] && [[ "${stab:-0}" -eq 30 ]]; then
    pass "Question 5: HPA apache-server configured for 50% CPU, 1-4 replicas, 30s downscale window."
  else
    fail "Question 5: HPA apache-server missing or spec does not match requirements." "$(show_s 5)"
  fi
}

grade_q6() {
  ((TOTAL_POINTS++))
  f1="/root/resources.yaml"
  f2="/root/subject.yaml"
  f1_ok=0; f2_ok=0
  [[ -s "$f1" ]] && grep -q "cert-manager" "$f1" && f1_ok=1
  [[ -s "$f2" ]] && grep -i -E "organizations|country|FIELD:" "$f2" && f2_ok=1

  if [[ "$f1_ok" -eq 1 ]] && [[ "$f2_ok" -eq 1 ]]; then
    pass "Question 6: CRD resources and subject explain documentation extracted to /root."
  else
    fail "Question 6: /root/resources.yaml or /root/subject.yaml missing or invalid." "$(show_s 6)"
  fi
}

grade_q7() {
  ((TOTAL_POINTS++))
  pc_val=$(kubectl get priorityclass high-priority -o jsonpath='{.value}' 2>/dev/null)
  dep_pc=$(kubectl get deployment busybox-logger -n priority -o jsonpath='{.spec.template.spec.priorityClassName}' 2>/dev/null)

  if [[ "$pc_val" == "999" ]] && [[ "$dep_pc" == "high-priority" ]]; then
    pass "Question 7: PriorityClass high-priority created (value: 999) and patched to busybox-logger."
  else
    fail "Question 7: PriorityClass high-priority missing, value != 999, or deployment not patched." "$(show_s 7)"
  fi
}

grade_q8() {
  ((TOTAL_POINTS++))
  tigera_pods=$(kubectl get pods -n tigera-operator --no-headers 2>/dev/null | grep -c "Running" || true)

  if [[ "${tigera_pods:-0}" -ge 1 ]]; then
    pass "Question 8: Calico Tigera Operator is running and supports NetworkPolicies."
  else
    fail "Question 8: Calico Tigera Operator not deployed." "$(show_s 8)"
  fi
}

grade_q9() {
  ((TOTAL_POINTS++))
  svc_status=$(systemctl is-active cri-docker.service 2>/dev/null || true)
  p1=$(sysctl -n net.bridge.bridge-nf-call-iptables 2>/dev/null || echo 0)
  p2=$(sysctl -n net.ipv6.conf.all.forwarding 2>/dev/null || echo 0)
  p3=$(sysctl -n net.ipv4.ip_forward 2>/dev/null || echo 0)
  p4=$(sysctl -n net.netfilter.nf_conntrack_max 2>/dev/null || echo 0)

  if [[ "$svc_status" == "active" ]] && [[ "${p1:-0}" -eq 1 ]] && [[ "${p2:-0}" -eq 1 ]] && \
     [[ "${p3:-0}" -eq 1 ]] && [[ "${p4:-0}" -ge 131072 ]]; then
    pass "Question 9: cri-dockerd service active and persistent sysctl network settings configured."
  else
    fail "Question 9: cri-dockerd service not active or sysctl settings incorrect." "$(show_s 9)"
  fi
}

grade_q10() {
  ((TOTAL_POINTS++))
  taint=$(kubectl get node node01 -o jsonpath='{.spec.taints[?(@.key=="PERMISSION")]}' 2>/dev/null)
  tolerant_pod=$(kubectl get pods -A -o jsonpath='{range .items[?(@.spec.nodeName=="node01")]}{.metadata.name}{" "}{.spec.tolerations[?(@.key=="PERMISSION")].key}{"\n"}{end}' 2>/dev/null | grep PERMISSION || true)

  if [[ "$taint" == *"PERMISSION"* ]] && [[ "$taint" == *"NoSchedule"* ]] && [[ -n "$tolerant_pod" ]]; then
    pass "Question 10: node01 tainted with PERMISSION=granted:NoSchedule and running tolerant pod."
  else
    fail "Question 10: node01 taint missing or no pod running on node01 with matching toleration." "$(show_s 10)"
  fi
}

grade_q11() {
  ((TOTAL_POINTS++))
  gw_name=$(kubectl get gateway web-gateway -o jsonpath='{.metadata.name}' 2>/dev/null)
  gw_class=$(kubectl get gateway web-gateway -o jsonpath='{.spec.gatewayClassName}' 2>/dev/null)
  gw_host=$(kubectl get gateway web-gateway -o jsonpath='{.spec.listeners[0].hostname}' 2>/dev/null)
  gw_secret=$(kubectl get gateway web-gateway -o jsonpath='{.spec.listeners[0].tls.certificateRefs[0].name}' 2>/dev/null)
  route_name=$(kubectl get httproute web-route -o jsonpath='{.metadata.name}' 2>/dev/null)
  route_backend=$(kubectl get httproute web-route -o jsonpath='{.spec.rules[0].backendRefs[0].name}' 2>/dev/null)

  if [[ "$gw_name" == "web-gateway" ]] && [[ "$gw_class" == "nginx-class" ]] && \
     [[ "$gw_host" == "gateway.web.k8s.local" ]] && [[ "$gw_secret" == "web-tls" ]] && \
     [[ "$route_name" == "web-route" ]] && [[ "$route_backend" == "web-service" ]]; then
    pass "Question 11: Gateway web-gateway and HTTPRoute web-route migrated with TLS and rules intact."
  else
    fail "Question 11: Gateway API resources missing or configuration mismatch." "$(show_s 11)"
  fi
}

grade_q12() {
  ((TOTAL_POINTS++))
  svc_type=$(kubectl get svc echo-service -n echo-sound -o jsonpath='{.spec.type}' 2>/dev/null)
  svc_port=$(kubectl get svc echo-service -n echo-sound -o jsonpath='{.spec.ports[0].port}' 2>/dev/null)
  ing_host=$(kubectl get ingress echo -n echo-sound -o jsonpath='{.spec.rules[0].host}' 2>/dev/null)
  ing_path=$(kubectl get ingress echo -n echo-sound -o jsonpath='{.spec.rules[0].http.paths[0].path}' 2>/dev/null)
  ing_backend=$(kubectl get ingress echo -n echo-sound -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.name}' 2>/dev/null)

  if [[ "$svc_type" == "NodePort" ]] && [[ "${svc_port:-0}" -eq 8080 ]] && \
     [[ "$ing_host" == "example.org" ]] && [[ "$ing_path" == "/echo" ]] && \
     [[ "$ing_backend" == "echo-service" ]]; then
    pass "Question 12: NodePort echo-service created and Ingress echo routing /echo."
  else
    fail "Question 12: NodePort echo-service or Ingress echo missing or misconfigured." "$(show_s 12)"
  fi
}

grade_q13() {
  ((TOTAL_POINTS++))
  has_policy3=0
  if kubectl get networkpolicy -n backend -o yaml 2>/dev/null | grep -q "app: frontend"; then
    has_policy3=1
  fi

  if [[ "$has_policy3" -eq 1 ]]; then
    pass "Question 13: Least-permissive policy-z (network-policy-3) deployed in namespace backend."
  else
    fail "Question 13: network-policy-3.yaml was not deployed to backend namespace." "$(show_s 13)"
  fi
}

grade_q14() {
  ((TOTAL_POINTS++))
  sc_prov=$(kubectl get sc local-storage -o jsonpath='{.provisioner}' 2>/dev/null)
  sc_mode=$(kubectl get sc local-storage -o jsonpath='{.volumeBindingMode}' 2>/dev/null)
  is_ls_default=$(kubectl get sc local-storage -o jsonpath='{.metadata.annotations.storageclass\.kubernetes\.io/is-default-class}' 2>/dev/null)
  is_lp_default=$(kubectl get sc local-path -o jsonpath='{.metadata.annotations.storageclass\.kubernetes\.io/is-default-class}' 2>/dev/null)

  if [[ "$sc_prov" == "rancher.io/local-path" ]] && [[ "$sc_mode" == "WaitForFirstConsumer" ]] && \
     [[ "$is_ls_default" == "true" ]] && [[ "$is_lp_default" != "true" ]]; then
    pass "Question 14: StorageClass local-storage created and set as exclusive default class."
  else
    fail "Question 14: local-storage missing, not set as default, or local-path is still marked default." "$(show_s 14)"
  fi
}

grade_q15() {
  ((TOTAL_POINTS++))
  api_healthy=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
  bad_port=$(grep "\--etcd-servers" /etc/kubernetes/manifests/kube-apiserver.yaml 2>/dev/null | grep -o "2380" || true)

  if [[ "${api_healthy:-0}" -ge 1 ]] && [[ -z "$bad_port" ]]; then
    pass "Question 15: kube-apiserver client port restored to 2379 and API server is healthy."
  else
    fail "Question 15: kube-apiserver manifest still references peer port 2380 or API server is down." "$(show_s 15)"
  fi
}

grade_q16() {
  ((TOTAL_POINTS++))
  c_name=$(kubectl get deployment nodeport-deployment -n relative -o jsonpath='{.spec.template.spec.containers[0].ports[?(@.containerPort==80)].name}' 2>/dev/null)
  s_type=$(kubectl get svc nodeport-service -n relative -o jsonpath='{.spec.type}' 2>/dev/null)
  s_nodeport=$(kubectl get svc nodeport-service -n relative -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)

  if [[ "$c_name" == "http" ]] && [[ "$s_type" == "NodePort" ]] && [[ "${s_nodeport:-0}" -eq 30080 ]]; then
    pass "Question 16: Deployment configured on port 80 (http) and Service nodeport-service routing on 30080."
  else
    fail "Question 16: Deployment container port or Service nodePort mismatch in namespace relative." "$(show_s 16)"
  fi
}

grade_q17() {
  ((TOTAL_POINTS++))
  hosts_line=$(grep "ckaquestion.k8s.local" /etc/hosts || true)
  cm_tls=$(kubectl get cm nginx-config -n nginx-static -o yaml 2>/dev/null | grep -i "ssl_protocols" || true)
  test_v12=$(curl -k --tls-max 1.2 https://ckaquestion.k8s.local 2>&1 || true)
  test_v13=$(curl -k --tlsv1.3 https://ckaquestion.k8s.local 2>&1 || true)

  tls12_rejected=0
  if echo "$test_v12" | grep -q -E "alert protocol version|SSL routines|handshake failure"; then
    tls12_rejected=1
  fi

  tls13_accepted=0
  if echo "$test_v13" | grep -q -E "<!DOCTYPE html>|<html|Welcome to nginx|Hello TLS"; then
    tls13_accepted=1
  fi

  if [[ -n "$hosts_line" ]] && [[ "$cm_tls" != *"TLSv1.2"* ]] && \
     [[ "${tls12_rejected:-0}" -eq 1 ]] && [[ "${tls13_accepted:-0}" -eq 1 ]]; then
    pass "Question 17: ConfigMap enforces TLSv1.3 only, hosts file resolves, and curl handshakes succeed."
  else
    fail "Question 17: TLSv1.2 is still allowed, /etc/hosts missing domain, or deployment not restarted." "$(show_s 17)"
  fi
}

run_grade_single() {
  local num="$1"
  print_banner "Evaluating Question $num"
  TOTAL_POINTS=0
  PASSED_POINTS=0
  "grade_q${num}"
  if [[ "$PASSED_POINTS" -eq 1 ]]; then
    echo -e "${GREEN}${BOLD}Question $num Status: PASSED (1/1)${NC}\n"
  else
    echo -e "${RED}${BOLD}Question $num Status: FAILED (0/1)${NC}\n"
  fi
}

run_grade_all() {
  print_banner "Running Full Exam Evaluation (All 17 Questions)"
  TOTAL_POINTS=0
  PASSED_POINTS=0
  for i in $(seq 1 17); do
    "grade_q${i}"
  done

  print_banner "EXAM SUMMARY: ${PASSED_POINTS} / ${TOTAL_POINTS} PASSED"
  PERCENTAGE=$(( PASSED_POINTS * 100 / TOTAL_POINTS ))

  if [[ "$PERCENTAGE" -ge 66 ]]; then
    echo -e "Final Score: ${BOLD}${PERCENTAGE}%${NC} - [${GREEN}${BOLD}PASS${NC}] (CKA passing threshold is 66%)\n"
  else
    echo -e "Final Score: ${BOLD}${PERCENTAGE}%${NC} - [${RED}${BOLD}FAIL${NC}] (CKA passing threshold is 66%)\n"
  fi
}

# ==============================================================================
# 5. CLI DISPATCHER
# ==============================================================================
ACTION="${1:-help}"

case "$ACTION" in
  q[1-9]|q1[0-7])
    NUM="${ACTION#q}"
    show_q "$NUM"
    ;;
  setup[1-9]|setup1[0-7])
    NUM="${ACTION#setup}"
    run_setup "$NUM"
    ;;
  s[1-9]|s1[0-7])
    NUM="${ACTION#s}"
    show_s "$NUM"
    ;;
  grade[1-9]|grade1[0-7])
    NUM="${ACTION#grade}"
    run_grade_single "$NUM"
    ;;
  grade-all)
    run_grade_all
    ;;
  *)
    echo -e "${CYAN}CKA Simulator Commands:${NC}"
    echo "  cka q<N>       : Display text for Question N (e.g., cka q1)"
    echo "  cka setup<N>   : Prepare lab environment for Question N (e.g., cka setup1)"
    echo "  cka s<N>       : Print the reference solution for Question N (e.g., cka s1)"
    echo "  cka grade<N>   : Grade Question N and show detailed remediation on error"
    echo "  cka grade-all  : Grade entire exam (all 17 questions) with overall score"
    ;;
esac