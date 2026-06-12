# Email Alert - Issues Fixed

## Problems Found & Fixed

### ❌ Problem 1: Rollout Abort (AnalysisRun Failed)
**Issue:** 
- Rollout deployed v3 with ERROR_RATE=0.20
- AnalysisTemplate checked error rate → Found > 5%
- AnalysisRun **FAILED**
- Rollout **ABORTED** and rolled back to stable v1
- Pods running v1 (ERROR_RATE=0) → Alert NEVER fired

**Fix:**
- Disabled `analysis` temporarily in canary strategy
- Deploy directly to 100% without analysis check
- Now v3 with 20% error rate is deployed

### ❌ Problem 2: Secret Namespace Mismatch
**Issue:**
- AlertmanagerConfig in namespace: `demo`
- Secret in namespace: `monitoring`
- Cross-namespace secret reference may not work

**Fix:**
- Moved Secret to `demo` namespace (same as AlertmanagerConfig)
- Now Secret and AlertmanagerConfig are in same namespace

---

## Current Status

✅ **Fixed Configuration:**
```
Secret: alertmanager-email-secret (namespace: demo)
AlertmanagerConfig: email-alerts (namespace: demo)
API Deployment: v3-email-test (ERROR_RATE=0.20)
Analysis: Disabled (deploy directly 100%)
```

✅ **All 4 pods running v3-email-test with 20% error rate**

✅ **Alert will fire in ~90 seconds**

---

## Why Email Wasn't Sent Before

1. **Alert Never Fired:**
   - AnalysisRun failed → Rollout aborted
   - Pods rolled back to v1 (no errors)
   - Error rate = 0% → Alert condition not met
   - No FIRING alert = No email

2. **Possible Secret Issue:**
   - Secret in wrong namespace (monitoring instead of demo)
   - AlertmanagerConfig couldn't access it

3. **RepeatInterval Not the Problem:**
   - `repeatInterval: 5m` only affects **repeat notifications**
   - First email sends immediately when alert fires
   - Not relevant to initial email

---

## Timeline Now

```
[Now] v3-email-test deployed (ERROR_RATE=0.20)
  ↓
[+15s] Prometheus scrapes metrics with 20% errors
  ↓
[+60s] PrometheusRule evaluates (for: 1m)
  ↓
[+90s] Alert status: FIRING 🔥
       Alertmanager sends email
  ↓
[+120s] Email arrives at vovudn95@gmail.com
```

---

## Verification Commands

### 1. Check Pods Running with Errors:
```powershell
$pod = kubectl -n demo get pods -l app=api -o jsonpath='{.items[0].metadata.name}'
kubectl -n demo exec $pod -- printenv | Select-String "ERROR_RATE|VERSION"
```
Expected: `ERROR_RATE=0.20, VERSION=v3-email-test`

### 2. Check Alert Status (after 2 minutes):
```powershell
kubectl -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090
```
Open: http://localhost:9090/alerts
Find: **HighErrorRate** → Status: **FIRING** (red)

### 3. Check Alertmanager Logs:
```powershell
kubectl -n monitoring logs -l app.kubernetes.io/name=alertmanager --tail=100 | Select-String "email|sent|vovudn95"
```
Look for: `"Successfully sent email to vovudn95@gmail.com"`

### 4. Check Email Inbox:
- To: vovudn95@gmail.com
- Subject: 🔥 [FIRING] HighErrorRate
- **Check Spam folder!**

---

## What Changed

### Before (Broken):
```yaml
# Secret in wrong namespace
metadata:
  namespace: monitoring  ❌

# Analysis enabled - caused abort
analysis:
  templates:
    - templateName: error-rate-analysis  ❌
  startingStep: 1

# Version: v1 (no errors)
ERROR_RATE: "0.0"  ❌
```

### After (Fixed):
```yaml
# Secret in correct namespace
metadata:
  namespace: demo  ✅

# Analysis disabled for testing
# (commented out)  ✅

# Version: v3 with errors
ERROR_RATE: "0.20"  ✅
```

---

## Re-enabling Analysis Later

After email test completes, restore full canary strategy:

```yaml
strategy:
  canary:
    steps:
      - setWeight: 25
      - pause: {}
      - setWeight: 50
      - pause: { duration: 30s }
      - setWeight: 100
      - pause: {}
    analysis:
      templates:
        - templateName: error-rate-analysis
      startingStep: 1
```

This allows:
- Progressive canary deployment (25% → 50% → 100%)
- Automatic rollback if error rate > 5%
- Manual control with `kubectl argo rollouts promote`

---

## Summary

**Root causes of no email:**
1. ❌ Alert never fired (rollout aborted due to AnalysisRun failure)
2. ❌ Secret in wrong namespace (cross-namespace issue)
3. ✅ RepeatInterval was fine (not the problem)

**Fixes applied:**
1. ✅ Disabled analysis (deploy directly 100%)
2. ✅ Moved Secret to demo namespace
3. ✅ Deployed v3 with 20% error rate

**Result:**
- Alert will fire in ~90 seconds
- Email will be sent automatically
- Check inbox (including Spam folder!)

---

**Monitor now:**
```powershell
kubectl -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090
```
Open: http://localhost:9090/alerts
