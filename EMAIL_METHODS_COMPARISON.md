# Email Alert Setup - Methods Comparison

## Method 1: Direct Secret Patch (apply-email-simple.ps1)

### How it works:
```powershell
.\apply-email-simple.ps1 -Email 'vovudn95@gmail.com' -AppPassword 'password'
```

1. Create Alertmanager YAML config
2. Encode to base64
3. Patch Secret directly: `alertmanager-kube-prometheus-stack-alertmanager`
4. Delete Alertmanager pod to reload

### Pros:
- ✅ Quick and simple
- ✅ One command setup
- ✅ No additional files

### Cons:
- ❌ Not GitOps-friendly
- ❌ Manual Secret management
- ❌ Config not version controlled
- ❌ Can be overwritten by Helm upgrades
- ❌ Requires pod restart

---

## Method 2: AlertmanagerConfig CRD (Recommended)

### How it works:
```powershell
.\setup-email-gitops.ps1
```

1. Create Secret with Gmail password in `monitoring` namespace
2. Create AlertmanagerConfig in `demo` namespace
3. Prometheus Operator watches and reconciles
4. Generates full Alertmanager config automatically
5. Alertmanager reloads config automatically

### Architecture:
```
k8s-monitoring/
  alertmanager-config.yaml    # Secret + AlertmanagerConfig

argocd/apps/
  alertmanager-config.yaml    # ArgoCD Application

Prometheus Operator watches AlertmanagerConfig
  ↓
Generates Alertmanager config
  ↓
Updates Secret automatically
  ↓
Alertmanager reloads (no restart needed)
```

### Pros:
- ✅ **GitOps-friendly** - All config in Git
- ✅ **Declarative** - Kubernetes CRD
- ✅ **Version controlled** - Track changes
- ✅ **ArgoCD managed** - Auto-sync
- ✅ **Namespace-scoped** - Isolated config
- ✅ **No pod restart** - Auto-reload
- ✅ **Multi-environment** - Easy to replicate

### Cons:
- ⚠️ Requires understanding of CRDs
- ⚠️ More files to manage
- ⚠️ Prometheus Operator dependency

---

## Comparison Table

| Feature | Direct Secret Patch | AlertmanagerConfig CRD |
|---------|-------------------|----------------------|
| **Setup Time** | 1 minute | 2-3 minutes |
| **GitOps** | ❌ No | ✅ Yes |
| **Version Control** | ❌ No | ✅ Yes |
| **ArgoCD Managed** | ❌ No | ✅ Yes |
| **Declarative** | ❌ No | ✅ Yes |
| **Pod Restart Required** | ✅ Yes | ❌ No |
| **Helm-safe** | ❌ Can be overwritten | ✅ Safe |
| **Multi-namespace** | ❌ Global only | ✅ Per namespace |
| **Learning Curve** | Easy | Medium |

---

## When to Use Each Method

### Use Direct Secret Patch When:
- Quick testing
- One-time setup
- Dev/local environment
- Don't need GitOps

### Use AlertmanagerConfig When:
- Production environment
- Need GitOps workflow
- Multiple environments (dev/staging/prod)
- Team collaboration (Git-based)
- Want infrastructure as code

---

## File Structure Comparison

### Method 1: Direct Secret Patch
```
apply-email-simple.ps1          # Setup script
```

### Method 2: AlertmanagerConfig
```
k8s-monitoring/
  alertmanager-config.yaml      # Secret + AlertmanagerConfig

argocd/apps/
  alertmanager-config.yaml      # ArgoCD Application

setup-email-gitops.ps1           # Interactive setup
SETUP_EMAIL_GITOPS.md           # Documentation
```

---

## Migration Path

If you started with Method 1, you can migrate to Method 2:

### Step 1: Remove old config
```powershell
# The AlertmanagerConfig will take precedence
# Old config in main Secret will be ignored
```

### Step 2: Setup AlertmanagerConfig
```powershell
.\setup-email-gitops.ps1
```

### Step 3: Verify
```powershell
kubectl -n demo get alertmanagerconfig email-alerts
kubectl -n monitoring logs -l app.kubernetes.io/name=alertmanager --tail=50
```

No conflict - AlertmanagerConfig adds its config separately.

---

## Recommendation for Lab 4

**For Learning:** Start with Method 1 (Direct Secret Patch)
- Quick to test
- See immediate results
- Understand Alertmanager config structure

**For Production/Real Project:** Use Method 2 (AlertmanagerConfig)
- Follow GitOps best practices
- Version controlled
- Team-friendly
- Professional approach

**Current Project:** Method 2 is ready!
```powershell
.\setup-email-gitops.ps1
```

---

## Quick Start - Method 2

```powershell
# 1. Run interactive setup
.\setup-email-gitops.ps1

# 2. Select deployment method:
#    Option 1: Direct apply (for testing)
#    Option 2: GitOps via ArgoCD (recommended)

# 3. Wait 1-2 minutes

# 4. Check Prometheus alerts
kubectl -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090
# http://localhost:9090/alerts

# 5. Check email inbox
# Subject: 🔥 [FIRING] HighErrorRate
```

---

## Summary

| | Method 1 | Method 2 |
|---|---|---|
| **Best for** | Quick testing | Production GitOps |
| **Complexity** | Low | Medium |
| **Maintainability** | Low | High |
| **GitOps score** | 0/10 | 10/10 |
| **Recommendation** | Dev/Test | **Production ⭐** |

**→ For Lab 4 completion: Both methods work!**

**→ For professional DevOps: Use Method 2 (AlertmanagerConfig)**
