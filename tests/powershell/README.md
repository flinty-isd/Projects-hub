# PowerShell tests

Runs the provisioning and formatting scripts for real and checks what they did,
without a SharePoint tenant.

```
pwsh -NoProfile -File tests/powershell/Invoke-DeployTests.ps1
pwsh -NoProfile -File tests/powershell/Invoke-DeployTests.ps1 -SyntaxOnly
```

`modules/PnP.PowerShell` is a stand-in for the real module. It records every
cmdlet call and keeps enough state — lists, fields, views, pages — that the
scripts' "create it only if missing" branches take both paths across a first run
and a re-run. The scripts import it unmodified; they don't know it isn't real.

## What this catches

- A script that doesn't parse.
- A field created against a list that doesn't exist yet, or formatting pointed
  at a column nobody provisioned — the two folders drifting apart.
- A column internal name containing a space, which SharePoint would silently
  encode to `Assigned_x0020_To` and every client would then read back empty.
- Malformed JSON handed to `CustomFormatter`, and any formatter file that never
  gets applied.
- Sample data outside the ranges the KPI logic assumes: `PercentComplete` is
  0–1, `Likelihood` and `Impact` are 1–5.
- A re-run duplicating instead of no-opping.
- Certificate auth not actually bypassing the interactive prompt, and a
  certificate supplied without `-Tenant` failing loudly rather than falling back
  to a browser prompt no build agent can answer.

## What it does not catch

Anything about the real API. The stub accepts whatever parameters it's given, so
a cmdlet parameter that doesn't exist in real PnP.PowerShell passes here and
fails on the tenant. Permissions, throttling, and the List web part property
shape are all outside its reach. Green here means the logic holds; it does not
mean the deploy will work.

## Keeping the stub honest

If a script starts calling a PnP cmdlet the stub doesn't define, the run fails
with a command-not-found rather than silently skipping — which is the intent.
Add the new cmdlet to `modules/PnP.PowerShell/PnP.PowerShell.psm1`, returning
whatever shape the calling code reads, and record the call so it can be
asserted on.
