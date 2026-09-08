#!/usr/bin/env bash
# ==============================================================================
# CKA Exam Simulator CLI - Final Kubeadm Edition (Interactive + CLI)
# Includes single-file baseline, safe resets, modernized declarative grading,
# and an interactive menu-driven mode.
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

# Place baseline file in the exact same directory as this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASELINE_FILE="$SCRIPT_DIR/.cka_baseline.txt"

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
# 1. BASELINE & RESET (KUBEADM SAFE)
# ==============================================================================
run_baseline() {
  print_banner "Taking Snapshot of Current Cluster State..."
  
  echo "Recording current cluster resources to $BASELINE_FILE..."
  > "$BASELINE_FILE" # clear existing
  kubectl get ns -o jsonpath='{range .items[*]}NS:{.metadata.name}{"\n"}{end}' >> "$BASELINE_FILE"
  kubectl get pv -o jsonpath='{range .items[*]}PV:{.metadata.name}{"\n"}{end}' 2>/dev/null >> "$BASELINE_FILE"
  kubectl get sc -o jsonpath='{range .items[*]}SC:{.metadata.name}{"\n"}{end}' 2>/dev/null >> "$BASELINE_FILE"
  kubectl get pc -o jsonpath='{range .items[*]}PC:{.metadata.name}{"\n"}{end}' 2>/dev/null >> "$BASELINE_FILE"
  kubectl get crd -o jsonpath='{range .items[*]}CRD:{.metadata.name}{"\n"}{end}' 2>/dev/null >> "$BASELINE_FILE"
  
  # Snapshot default namespace workloads
  kubectl get all -n default -o name 2>/dev/null | sed 's/^/DEFAULT:/' >> "$BASELINE_FILE"
  
  echo -e "${GREEN}Baseline saved. You can now safely run lab setups.${NC}"
}

purge_non_baseline() {
  local kind="$1"
  local prefix="$2"
  
  for item in $(kubectl get "$kind" -o name 2>/dev/null); do
    local name=${item#*/}
    if ! grep -q -w "^${prefix}:${name}$" "$BASELINE_FILE"; then
      echo "  - Deleting $kind: $name"
      kubectl delete "$kind" "$name" --ignore-not-found --wait=false >/dev/null 2>&1
    fi
  done
}

run_reset() {
  print_banner "Resetting Lab Environment (Diff against Baseline)"
  
  if [[ ! -f "$BASELINE_FILE" ]]; then
    echo -e "${RED}No baseline file found at $BASELINE_FILE! Please run 'cka baseline' first.${NC}"
    exit 1
  fi

  echo "1. Cleaning up Namespaces..."
  for ns in $(kubectl get ns -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'); do
    if ! grep -q -w "^NS:${ns}$" "$BASELINE_FILE"; then
      echo "  - Terminating namespace: $ns"
      kubectl delete ns "$ns" --ignore-not-found --wait=false >/dev/null 2>&1
    fi
  done

  echo "2. Cleaning up Default Namespace..."
  for item in $(kubectl get all -n default -o name 2>/dev/null); do
    if ! grep -q -w "^DEFAULT:${item}$" "$BASELINE_FILE"; then
      echo "  - Deleting resource: $item"
      kubectl delete "$item" -n default --ignore-not-found >/dev/null 2>&1
    fi
  done

  echo "3. Cleaning up Cluster-Scoped Resources..."
  purge_non_baseline "pv" "PV"
  purge_non_baseline "sc" "SC"
  purge_non_baseline "priorityclass" "PC"
  purge_non_baseline "crd" "CRD"

  echo "4. Reverting OS-Level Configurations..."
  systemctl disable --now cri-docker.service >/dev/null 2>&1 || true
  rm -f /etc/sysctl.d/kube.conf
  sysctl --system >/dev/null 2>&1
  dpkg -r cri-dockerd >/dev/null 2>&1 || true

  kubectl taint nodes node01 PERMISSION:NoSchedule- >/dev/null 2>&1 || true
  kubectl patch storageclass local-path -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}' >/dev/null 2>&1 || true

  if [[ -f /root/kube-apiserver.yaml.bak ]]; then
    cp /root/kube-apiserver.yaml.bak /etc/kubernetes/manifests/kube-apiserver.yaml
  fi

  sed -i '/ckaquestion.k8s.local/d' /etc/hosts 2>/dev/null || true

  echo "5. Cleaning up generated lab files..."
  rm -rf /root/resources.yaml /root/subject.yaml /root/argo-helm.yaml /root/network-policies ~/mariadb-deploy.yaml /root/cri-dockerd.deb /tmp/tls.* 2>/dev/null

  echo -e "${GREEN}Lab environment successfully reset to baseline!${NC}"
}

# ==============================================================================
# 2. QUESTIONS, TITLES & TEXT
# ==============================================================================
get_title() {
  case "$1" in
    1) echo "MariaDB PVC & Recovery" ;;
    2) echo "ArgoCD Helm Template" ;;
    3) echo "WordPress Sidecar" ;;
    4) echo "WordPress Equal Resource Distribution" ;;
    5) echo "Horizontal Pod Autoscaler (HPA)" ;;
    6) echo "CRD Documentation Extraction" ;;
    7) echo "PriorityClass & Deployment Patch" ;;
    8) echo "CNI Installation" ;;
    9) echo "cri-dockerd Setup" ;;
    10) echo "Taints and Tolerations" ;;
    11) echo "Gateway API Migration" ;;
    12) echo "Ingress & NodePort Service" ;;
    13) echo "Least Permissive Network Policy" ;;
    14) echo "StorageClass Management" ;;
    15) echo "Fix kube-apiserver etcd Port" ;;
    16) echo "Deployment Port & NodePort Service" ;;
    17) echo "Nginx TLSv1.3 Lockdown & Resolution" ;;
    *) echo "Unknown Question" ;;
  esac
}

show_q() {
  case "$1" in
    1) echo -e "[Question 1: MariaDB PVC & Recovery]\nA user accidentally deleted the MariaDB Deployment in the mariadb namespace.\nTasks:\n1. Re-use existing retained PV.\n2. Create PVC named mariadb (ReadWriteOnce, 250Mi) in mariadb namespace.\n3. Edit ~/mariadb-deploy.yaml to use PVC, apply, and ensure it runs." ;;
    2) echo -e "[Question 2: ArgoCD Helm Template]\nTasks:\n1. Add Argo CD Helm repository (https://argoproj.github.io/argo-helm).\n2. Create argocd namespace.\n3. Generate template (version 7.7.3) ensuring CRDs are NOT installed.\n4. Save to /root/argo-helm.yaml." ;;
    3) echo -e "[Question 3: WordPress Sidecar]\nUpdate existing wordpress deployment adding a sidecar (busybox:stable).\nTasks:\n1. Command: /bin/sh -c \"tail -f /var/log/wordpress.log\"\n2. Mount shared volume at /var/log for both containers." ;;
    4) echo -e "[Question 4: WordPress Equal Resource Distribution]\nAdjust Pod resources to ensure stable operation.\nTasks:\n1. Scale down to 0, evenly divide CPU/Mem across 3 pods.\n2. Ensure both init containers and main containers use exact same requests/limits.\n3. Scale back to 3 replicas." ;;
    5) echo -e "[Question 5: Horizontal Pod Autoscaler (HPA)]\nTasks: Create HPA named apache-server in autoscale targeting apache-deployment.\nSet 50% CPU usage, 1-4 pods, 30s downscale window." ;;
    6) echo -e "[Question 6: CRD Documentation Extraction]\nTasks:\n1. List all cert-manager CRDs -> /root/resources.yaml.\n2. Extract explain doc for Certificate spec.subject -> /root/subject.yaml." ;;
    7) echo -e "[Question 7: PriorityClass & Deployment Patch]\nTasks: Create high-priority class (value exactly one less than highest user-defined class).\nPatch busybox-logger deployment in priority namespace to use it." ;;
    8) echo -e "[Question 8: CNI Installation]\nTasks: Install Calico or Flannel ensuring pods communicate AND network policies are enforced." ;;
    9) echo -e "[Question 9: cri-dockerd Setup]\nTasks: Install ~/cri-dockerd.deb, start service, configure persistent sysctl forwarding rules." ;;
    10) echo -e "[Question 10: Taints and Tolerations]\nTasks: Add PERMISSION=granted:NoSchedule to node01. Deploy pod tolerating it on node01." ;;
    11) echo -e "[Question 11: Gateway API Migration]\nTasks: Migrate ingress web to Gateway web-gateway and HTTPRoute web-route on gateway.web.k8s.local." ;;
    12) echo -e "[Question 12: Ingress & NodePort Service]\nTasks: Expose echo deployment in echo-sound on NodePort 8080. Create Ingress routing /echo." ;;
    13) echo -e "[Question 13: Least Permissive Network Policy]\nTasks: Select least permissive policy from /root/network-policies to allow frontend->backend traffic. Apply it." ;;
    14) echo -e "[Question 14: StorageClass Management]\nTasks: Create local-storage SC (WaitForFirstConsumer). Make it the ONLY default SC." ;;
    15) echo -e "[Question 15: Fix kube-apiserver etcd Port]\nTask: kube-apiserver is pointing to 2380. Fix it so the cluster recovers." ;;
    16) echo -e "[Question 16: Deployment Port & NodePort Service]\nTasks: Configure nodeport-deployment port 80. Create nodeport-service routing to it on NodePort 30080." ;;
    17) echo -e "[Question 17: Nginx TLSv1.3 Lockdown & Resolution]\nTasks: Edit nginx-config to only support TLSv1.3. Add service IP to /etc/hosts for ckaquestion.k8s.local. Restart deployment." ;;
    *) echo -e "${RED}Invalid question index. Use q1 through q17.${NC}" ;;
  esac
}

# ==============================================================================
# 3. LAB SETUPS
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
# 4. SOLUTIONS
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
# Standard approach:
kubectl edit deployment wordpress
# Add sidecar container under spec.template.spec.containers (or initContainers with restartPolicy: Always)
# Ensure volumeMounts point to the identical volume name as the wordpress container.
SOUT
;;
    4) cat <<'SOUT'
kubectl scale deployment wordpress --replicas 0
kubectl edit deployment wordpress
# Under both containers[] and initContainers[] configure identical CPU/Mem blocks
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
# 5. HARDENED GRADING FUNCTIONS (Outcome-Based)
# ==============================================================================
grade_q1() {
  ((TOTAL_POINTS++))
  pvc_status=$(kubectl get pvc mariadb -n mariadb -o jsonpath='{.status.phase}' 2>/dev/null)
  pv_claim=$(kubectl get pv mariadb-pv -o jsonpath='{.spec.claimRef.name}' 2>/dev/null)
  ready_replicas=$(kubectl get deployment mariadb -n mariadb -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
  mounted_claim=$(kubectl get deployment mariadb -n mariadb -o jsonpath='{.spec.template.spec.volumes[*].persistentVolumeClaim.claimName}' 2>/dev/null)

  if [[ "$pvc_status" == "Bound" ]] && [[ "$pv_claim" == "mariadb" ]] && \
     [[ "${ready_replicas:-0}" -ge 1 ]] && [[ "$mounted_claim" == *"mariadb"* ]]; then
    pass "Question 1: MariaDB PVC bound and deployment running."
  else
    fail "Question 1: MariaDB PVC missing, unbound, or deployment misconfigured." "$(show_s 1)"
  fi
}

grade_q2() {
  ((TOTAL_POINTS++))
  manifest_file="/root/argo-helm.yaml"
  file_valid=0
  if [[ -s "$manifest_file" ]]; then
    crd_lines=$(grep -c "kind: CustomResourceDefinition" "$manifest_file" || true)
    has_deploy=$(grep -c "kind: Deployment" "$manifest_file" || true)
    has_sa=$(grep -c "kind: ServiceAccount" "$manifest_file" || true)
    
    if [[ "${crd_lines:-0}" -eq 0 ]] && [[ "${has_deploy:-0}" -gt 0 ]] && [[ "${has_sa:-0}" -gt 0 ]]; then
      file_valid=1
    fi
  fi

  if [[ "$file_valid" -eq 1 ]]; then
    pass "Question 2: /root/argo-helm.yaml successfully generated without CRDs."
  else
    fail "Question 2: Helm template missing or CRDs still present." "$(show_s 2)"
  fi
}

grade_q3() {
  ((TOTAL_POINTS++))
  
  # Standard sidecar pattern
  sc_img_std=$(kubectl get deployment wordpress -o jsonpath='{.spec.template.spec.containers[?(@.name=="sidecar")].image}' 2>/dev/null)
  wp_mount_std=$(kubectl get deployment wordpress -o jsonpath='{.spec.template.spec.containers[?(@.name=="wordpress")].volumeMounts[?(@.mountPath=="/var/log")].name}' 2>/dev/null)
  sc_mount_std=$(kubectl get deployment wordpress -o jsonpath='{.spec.template.spec.containers[?(@.name=="sidecar")].volumeMounts[?(@.mountPath=="/var/log")].name}' 2>/dev/null)
  
  # Native Sidecar pattern (initContainers + RestartAlways)
  sc_img_init=$(kubectl get deployment wordpress -o jsonpath='{.spec.template.spec.initContainers[?(@.name=="sidecar")].image}' 2>/dev/null)
  sc_restart_init=$(kubectl get deployment wordpress -o jsonpath='{.spec.template.spec.initContainers[?(@.name=="sidecar")].restartPolicy}' 2>/dev/null)
  sc_mount_init=$(kubectl get deployment wordpress -o jsonpath='{.spec.template.spec.initContainers[?(@.name=="sidecar")].volumeMounts[?(@.mountPath=="/var/log")].name}' 2>/dev/null)
  
  ready=$(kubectl get deployment wordpress -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
  valid_sidecar=0

  if [[ "$sc_img_std" == *"busybox"* ]] && [[ -n "$wp_mount_std" ]] && [[ "$wp_mount_std" == "$sc_mount_std" ]]; then
    valid_sidecar=1
  elif [[ "$sc_img_init" == *"busybox"* ]] && [[ "$sc_restart_init" == "Always" ]] && [[ -n "$wp_mount_std" ]] && [[ "$wp_mount_std" == "$sc_mount_init" ]]; then
    valid_sidecar=1
  fi

  if [[ "$valid_sidecar" -eq 1 ]] && [[ "${ready:-0}" -ge 1 ]]; then
    pass "Question 3: Sidecar correctly attached (standard or native initContainer) sharing /var/log volume."
  else
    fail "Question 3: WordPress sidecar container or shared volume not configured properly." "$(show_s 3)"
  fi
}

grade_q4() {
  ((TOTAL_POINTS++))
  replicas=$(kubectl get deployment wordpress -o jsonpath='{.spec.replicas}' 2>/dev/null)
  ready=$(kubectl get deployment wordpress -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
  c_req_cpu=$(kubectl get deployment wordpress -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}' 2>/dev/null)
  init_req_cpu=$(kubectl get deployment wordpress -o jsonpath='{.spec.template.spec.initContainers[0].resources.requests.cpu}' 2>/dev/null)

  if [[ "${replicas:-0}" -eq 3 ]] && [[ "${ready:-0}" -eq 3 ]] && [[ -n "$c_req_cpu" ]] && [[ "$c_req_cpu" == "$init_req_cpu" ]]; then
    pass "Question 4: WordPress scaled to 3 with equivalent initContainer resources."
  else
    fail "Question 4: WordPress replicas != 3 or resource mismatch between init and application." "$(show_s 4)"
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
  bad_port=$(grep "2380" /etc/kubernetes/manifests/kube-apiserver.yaml 2>/dev/null || true)

  if [[ "${api_healthy:-0}" -ge 1 ]] && [[ -z "$bad_port" ]]; then
    pass "Question 15: kube-apiserver port restored and cluster healthy."
  else
    fail "Question 15: kube-apiserver manifest still references peer port 2380 or API down." "$(show_s 15)"
  fi
}

grade_q16() {
  ((TOTAL_POINTS++))
  c_name=$(kubectl get deployment nodeport-deployment -n relative -o jsonpath='{.spec.template.spec.containers[0].ports[?(@.containerPort==80)].name}' 2>/dev/null)
  s_type=$(kubectl get svc nodeport-service -n relative -o jsonpath='{.spec.type}' 2>/dev/null)
  s_nodeport=$(kubectl get svc nodeport-service -n relative -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)

  if [[ "$c_name" == "http" ]] && [[ "$s_type" == "NodePort" ]] && [[ "${s_nodeport:-0}" -eq 30080 ]]; then
    pass "Question 16: Deployment configured on port 80 (http) and nodeport-service routing on 30080."
  else
    fail "Question 16: Deployment container port or Service nodePort mismatch in namespace relative." "$(show_s 16)"
  fi
}

grade_q17() {
  ((TOTAL_POINTS++))
  hosts_line=$(grep "ckaquestion.k8s.local" /etc/hosts || true)
  cm_tls=$(kubectl get cm nginx-config -n nginx-static -o yaml 2>/dev/null || true)

  if [[ -n "$hosts_line" ]] && [[ "$cm_tls" == *"TLSv1.3"* ]] && [[ "$cm_tls" != *"TLSv1.2"* ]]; then
    pass "Question 17: ConfigMap enforces TLSv1.3 only, and /etc/hosts resolves."
  else
    fail "Question 17: TLSv1.2 is still allowed, or /etc/hosts missing domain mapping." "$(show_s 17)"
  fi
}

run_grade_single() {
  local num="$1"
  print_banner "Evaluating Question $num"
  TOTAL_POINTS=0
  PASSED_POINTS=0
  
  if type "grade_q${num}" &>/dev/null; then
    "grade_q${num}"
  fi

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
# 6. INTERACTIVE MODE
# ==============================================================================
interactive_mode() {
  if [[ ! -f "$BASELINE_FILE" ]]; then
    echo -e "${YELLOW}Warning: No baseline file found at $BASELINE_FILE.${NC}"
    echo -e "It is highly recommended to run '${BOLD}cka baseline${NC}' first to allow clean resets.\n"
    read -p "Press Enter to continue anyway..." 
  fi

  while true; do
    clear
    print_banner "CKA Exam Simulator - Interactive Mode"
    echo "Select a scenario to practice (or type 'q' to quit):"
    echo ""
    for i in $(seq 1 17); do
      printf "  %2d - %s\n" "$i" "$(get_title "$i")"
    done
    echo ""
    read -p "Enter question number (1-17, q to quit): " choice
    
    if [[ "$choice" == "q" || "$choice" == "Q" ]]; then
      echo -e "\nExiting simulator. Good luck on your CKA!"
      exit 0
    fi

    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt 17 ]; then
      echo -e "\n${RED}Invalid input. Press Enter to try again.${NC}"
      read
      continue
    fi

    clear
    print_banner "Scenario $choice: $(get_title "$choice")"
    show_q "$choice"
    echo ""
    run_setup "$choice"
    
    echo -e "\n${CYAN}${BOLD}The lab environment is ready.${NC}"
    echo -e "Switch to your terminal, solve the scenario, and return here when finished."
    
    while true; do
      echo ""
      read -p "Ready to grade Question $choice? (Y/N): " grade_choice
      case "$grade_choice" in
        [Yy]* ) 
          run_grade_single "$choice"
          break;;
        [Nn]* ) 
          echo "Take your time. Waiting..."
          ;;
        * ) echo "Please answer yes or no.";;
      esac
    done

    echo ""
    read -p "Try another scenario? (Y/N): " cont_choice
    case "$cont_choice" in
      [Nn]* ) 
        echo -e "\nExiting simulator. Good luck on your CKA!"
        exit 0;;
    esac
  done
}

# ==============================================================================
# 7. CLI DISPATCHER
# ==============================================================================
if [[ $# -eq 0 ]]; then
  interactive_mode
  exit 0
fi

ACTION="${1}"
case "$ACTION" in
  baseline)
    run_baseline
    ;;
  reset)
    run_reset
    ;;
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
  help|-h|--help)
    echo -e "${CYAN}CKA Simulator Commands:${NC}"
    echo "  (No args)      : Launch interactive menu-driven mode"
    echo "  cka baseline   : Snapshot the cluster state BEFORE doing labs (CRITICAL FOR KUBEADM)"
    echo "  cka reset      : Safely teardown all lab resources based on baseline diff"
    echo "  cka q<N>       : Display text for Question N"
    echo "  cka setup<N>   : Prepare lab environment for Question N"
    echo "  cka s<N>       : Print the reference solution for Question N"
    echo "  cka grade<N>   : Grade Question N and show detailed remediation"
    echo "  cka grade-all  : Grade entire exam (all 17 questions) with overall score"
    ;;
  *)
    echo -e "${RED}Unknown command: $ACTION${NC}"
    echo "Run 'cka help' for a list of available commands."
    exit 1
    ;;
esac