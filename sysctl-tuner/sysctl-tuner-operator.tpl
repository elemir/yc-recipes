---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: sysctl-tuner-account

---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  name: sysctl-tuner-role
rules:
- apiGroups:
    - "*"
  resources:
    - "*"
  verbs:
    - "*"
- nonResourceURLs:
    - "*"
  verbs:
    - "*"

---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: sysctl-tune-role-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: sysctl-tuner-role
subjects:
  - kind: ServiceAccount
    name: sysctl-tuner-account
    namespace: sysctl-tuner

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: addon-operator
data:
  global: ""
  sysctlTunerEnabled: "true"
  sysctlTuner: |
    params:
      net.ipv4.tcp_timestamps: "0"
    sleep: "300"

---
apiVersion: v1
kind: Pod
metadata:
  name: sysctl-tuner-operator
spec:
  containers:
  - name: sysctl-tuner-operator
    image: %IMAGE%
    imagePullPolicy: Always
    env:
      - name: RLOG_LOG_LEVEL
        value: DEBUG
  serviceAccountName: sysctl-tuner-account
