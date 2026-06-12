# Setup Email Alert - GitOps Way (AlertmanagerConfig)

## Overview

Instead of patching Alertmanager Secret directly, we use `AlertmanagerConfig` CRD for GitOps-friendly email configuration.

**Advantages:**
- ✅ Version controlled in Git
- ✅ Declarative configuration
- ✅ Can be managed by ArgoCD
- ✅ Namespace-scoped (isolated)
- ✅ No manual Secret patching

---

## Step 1: Get Gmail App Password

1. Go to: https://myaccount.google.com/security
2. Enable **2-Step Verification**
3. Search for "App passwords"
4. Select:
   - App: **Mail**
   - Device: **Windows Computer**
5. Click **Generate**
6. Copy the 16-character password (e.g., `abcd efgh ijkl mnop`)

---

## Step 2: Edit Email Configuration

Open the file:
```powershell
notepad k8s-monitoring\alertmanager-config.yaml
```

**Find this line:**
```yaml
smtp-password: "your-gmail-app-password-here"
```

**Replace with your Gmail App Password:**
```yaml
smtp-password: "abcdefghijklmnop"  # Remove spaces from Gmail password
```

**Save the file.**

---

## Step 3: Apply Configuration

### Option 1: Direct Apply (Quick)

```powershell
kubectl apply -f k8s-monitoring\alertmanager-config.yaml
```

This will:
1. Create Secret `alertmanager-email-secret` in `monitoring` namespace
2. Create AlertmanagerConfig `email-alerts` in `demo` namespace

### Option 2: GitOps via ArgoCD (Recommended)

**a) Create ArgoCD Application:**

```powershell
notepad argocd\apps\alertmanager-config.yaml
```

Paste:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: alertmanager-config
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/vovudn/gitops.git
    targetRevision: main
    path: k8s-monitoring
  destination:
    server: https://kubernetes.default.svc
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

**b) Commit and push:**

```powershell
git add k8s-monitoring\alertmanager-config.yaml argocd\apps\alertmanager-config.yaml
git commit -m "feat: add AlertmanagerConfig for email alerts"
git push
```

**c) Apply ArgoCD Application:**

```powershell
kubectl apply -f argocd\apps\alertmanager-config.yaml
```

---

## Step 4: Verify Configuration

### Check Secret Created:
```powershell
kubectl -n monitoring get secret alertmanager-email-secret
```

### Check AlertmanagerConfig Created:
```powershell
kubectl -n demo get alertmanagerconfig email-alerts
```

### Check Prometheus Operator Reconciled:
```powershell
kubectl -n monitoring logs -l app.kubernetes.io/name=prometheus-operator --tail=50 | Select-String "AlertmanagerConfig"
```

### Verify Alertmanager Config Updated:
```powershell
kubectl -n monitoring get secret alertmanager-kube-prometheus-stack-alertmanager -o jsonpath='{.data.alertmanager\.yaml}' | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) } | Select-String "vovudn95|smtp.gmail.com"
```

Should show:
```
smtp.gmail.com:587
vovudn95@gmail.com
```

---

## Step 5: Test Email Alert

### Current Status:
- v3-error deployed with ERROR_RATE=0.15 (15%)
- Load pod generating traffic
- Alert should fire in 1-2 minutes

### Monitor Alert:
```powershell
kubectl -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090
```

Open: http://localhost:9090/alerts

Find: **HighErrorRate** → Status: **FIRING** (red) 🔥

### Check Email Sent:
```powershell
kubectl -n monitoring logs -l app.kubernetes.io/name=alertmanager --tail=100 | Select-String "email|sent|vovudn95"
```

Look for: `"Successfully sent email"`

### Check Inbox:
- To: vovudn95@gmail.com
- Subject: 🔥 [FIRING] HighErrorRate
- Check **Spam folder** too!

---

## Troubleshooting

### Issue 1: AlertmanagerConfig Not Reconciled

**Check if Prometheus Operator recognizes it:**

```powershell
kubectl -n demo get alertmanagerconfig email-alerts -o yaml
```

Check `status` section for errors.

**Common issue:** Wrong namespace or missing labels.

**Fix:** Ensure AlertmanagerConfig is in same namespace as PrometheusRule (`demo`).

### Issue 2: Secret Not Found

**Error in Alertmanager logs:**
```
secret "alertmanager-email-secret" not found
```

**Fix:** Secret must be in `monitoring` namespace (where Alertmanager runs):
```powershell
kubectl -n monitoring get secret alertmanager-email-secret
```

If missing:
```powershell
kubectl apply -f k8s-monitoring\alertmanager-config.yaml
```

### Issue 3: Authentication Failed (535 Error)

**Error in Alertmanager logs:**
```
535 Authentication failed
```

**Causes:**
- Wrong Gmail App Password
- Not using App Password (using regular Gmail password)
- 2FA not enabled on Gmail

**Fix:**
1. Regenerate Gmail App Password
2. Update Secret:
```powershell
kubectl -n monitoring delete secret alertmanager-email-secret
# Edit k8s-monitoring\alertmanager-config.yaml with new password
kubectl apply -f k8s-monitoring\alertmanager-config.yaml
```

3. Restart Alertmanager:
```powershell
kubectl -n monitoring delete pod -l app.kubernetes.io/name=alertmanager
```

### Issue 4: Email Not Received

**Check Alertmanager config was updated:**

```powershell
kubectl -n monitoring exec alertmanager-kube-prometheus-stack-alertmanager-0 -- cat /etc/alertmanager/config/alertmanager.yaml.gz | gunzip
```

Should contain:
```yaml
receivers:
- name: demo-email-alerts-email-alerts
  email_configs:
  - to: vovudn95@gmail.com
    smarthost: smtp.gmail.com:587
```

If not found → Prometheus Operator didn't reconcile.

**Force reconciliation:**
```powershell
# Delete and recreate AlertmanagerConfig
kubectl -n demo delete alertmanagerconfig email-alerts
kubectl apply -f k8s-monitoring\alertmanager-config.yaml
```

---

## How AlertmanagerConfig Works

### Architecture:

```
AlertmanagerConfig (demo namespace)
  ↓
Prometheus Operator watches
  ↓
Generates Alertmanager config
  ↓
Updates Secret: alertmanager-kube-prometheus-stack-alertmanager
  ↓
Alertmanager reloads config
  ↓
Routes HighErrorRate alerts → email-alerts receiver
  ↓
Sends email via Gmail SMTP
```

### Namespace Rules:

1. **Secret**: Must be in `monitoring` namespace (where Alertmanager runs)
2. **AlertmanagerConfig**: In `demo` namespace (where PrometheusRule is)
3. **PrometheusRule**: In `demo` namespace (where API runs)

### Selector Matching:

Prometheus Operator matches AlertmanagerConfig by:
- Namespace
- Labels (if alertmanagerConfigSelector is set)

By default, kube-prometheus-stack watches ALL AlertmanagerConfigs.

---

## Alternative: Using Helm Values

If you prefer, you can also configure email in Helm values:

Edit: `argocd/apps/kube-prometheus-stack.yaml`

```yaml
spec:
  source:
    helm:
      values: |
        prometheus:
          prometheusSpec:
            serviceMonitorSelectorNilUsesHelmValues: false
        
        alertmanager:
          config:
            global:
              smtp_smarthost: 'smtp.gmail.com:587'
              smtp_from: 'vovudn95@gmail.com'
              smtp_auth_username: 'vovudn95@gmail.com'
              smtp_auth_password: 'your-app-password'
              smtp_require_tls: true
            
            receivers:
              - name: 'null'
              - name: 'email-alerts'
                email_configs:
                  - to: 'vovudn95@gmail.com'
            
            route:
              receiver: 'null'
              routes:
                - matchers:
                    - alertname = HighErrorRate
                  receiver: 'email-alerts'
```

**Pros:**
- Centralized in Helm chart
- Managed by ArgoCD

**Cons:**
- Password in Git (use SealedSecrets or external-secrets instead)
- Less flexible than AlertmanagerConfig

---

## Summary

**Recommended approach:**
1. Create Secret with Gmail App Password in `monitoring` namespace
2. Create AlertmanagerConfig in `demo` namespace
3. Let Prometheus Operator reconcile
4. Commit to Git for GitOps

**Benefits:**
- Declarative
- Version controlled
- No manual Secret patching
- Namespace-scoped isolation

---

## Quick Commands

```powershell
# Apply email config
kubectl apply -f k8s-monitoring\alertmanager-config.yaml

# Check status
kubectl -n demo get alertmanagerconfig email-alerts
kubectl -n monitoring get secret alertmanager-email-secret

# Watch Alertmanager logs
kubectl -n monitoring logs -l app.kubernetes.io/name=alertmanager -f

# Check alert firing
kubectl -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090
# Open: http://localhost:9090/alerts
```

**After setup → Wait 1-2 minutes → Check email! 📧**
