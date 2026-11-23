using System;
using System.Collections.Generic;
using System.Linq;

namespace ItGovernanceSite.App_Code
{
    /// <summary>Pure functions computing the governance KPIs surfaced across the site.</summary>
    public static class GovernanceKpis
    {
        private static readonly HashSet<string> ClosedFindingStatuses = new HashSet<string>(
            new[] { "closed", "resolved", "done" }, StringComparer.OrdinalIgnoreCase);

        // ---- Policies ----

        /// <summary>A policy is current when it has a next-review date still in the future.
        /// Policies with no next-review date count as not current.</summary>
        public static int PoliciesDueForReview(List<PolicyItem> policies, DateTime asOf)
        {
            if (policies == null)
            {
                return 0;
            }
            return policies.Count(p => !p.NextReview.HasValue || p.NextReview.Value < asOf);
        }

        public static double PolicyCurrencyRate(List<PolicyItem> policies, DateTime asOf)
        {
            if (policies == null || policies.Count == 0)
            {
                return 0.0;
            }
            var current = policies.Count - PoliciesDueForReview(policies, asOf);
            return Math.Round((double)current / policies.Count * 100, 1);
        }

        public static List<KeyValuePair<string, int>> PoliciesByStatus(List<PolicyItem> policies)
        {
            if (policies == null)
            {
                return new List<KeyValuePair<string, int>>();
            }
            return policies
                .GroupBy(p => p.Status ?? "")
                .Select(g => new KeyValuePair<string, int>(g.Key, g.Count()))
                .OrderByDescending(kv => kv.Value)
                .ToList();
        }

        // ---- Controls ----

        /// <summary>Share of assessed controls that are fully compliant. Controls with a
        /// "Not Assessed" status are excluded from the denominator.</summary>
        public static double ComplianceRate(List<ControlItem> controls)
        {
            if (controls == null)
            {
                return 0.0;
            }
            var assessed = controls.Where(c => !string.Equals(c.Status, "Not Assessed", StringComparison.OrdinalIgnoreCase)).ToList();
            if (assessed.Count == 0)
            {
                return 0.0;
            }
            var compliant = assessed.Count(c => string.Equals(c.Status, "Compliant", StringComparison.OrdinalIgnoreCase));
            return Math.Round((double)compliant / assessed.Count * 100, 1);
        }

        public static int NonCompliantCount(List<ControlItem> controls)
        {
            if (controls == null)
            {
                return 0;
            }
            return controls.Count(c => string.Equals(c.Status, "Non-Compliant", StringComparison.OrdinalIgnoreCase));
        }

        public static int NotAssessedCount(List<ControlItem> controls)
        {
            if (controls == null)
            {
                return 0;
            }
            return controls.Count(c => string.Equals(c.Status, "Not Assessed", StringComparison.OrdinalIgnoreCase));
        }

        public static List<KeyValuePair<string, int>> ControlsByFramework(List<ControlItem> controls)
        {
            if (controls == null)
            {
                return new List<KeyValuePair<string, int>>();
            }
            return controls
                .GroupBy(c => c.Framework ?? "")
                .Select(g => new KeyValuePair<string, int>(g.Key, g.Count()))
                .OrderByDescending(kv => kv.Value)
                .ToList();
        }

        public static List<KeyValuePair<string, int>> ControlsByStatus(List<ControlItem> controls)
        {
            if (controls == null)
            {
                return new List<KeyValuePair<string, int>>();
            }
            return controls
                .GroupBy(c => c.Status ?? "")
                .Select(g => new KeyValuePair<string, int>(g.Key, g.Count()))
                .OrderByDescending(kv => kv.Value)
                .ToList();
        }

        // ---- Findings ----

        public static bool IsFindingOpen(FindingItem finding)
        {
            return finding != null && !ClosedFindingStatuses.Contains(finding.Status ?? "");
        }

        public static int OpenFindingCount(List<FindingItem> findings)
        {
            if (findings == null)
            {
                return 0;
            }
            return findings.Count(IsFindingOpen);
        }

        public static int OverdueFindingCount(List<FindingItem> findings, DateTime asOf)
        {
            if (findings == null)
            {
                return 0;
            }
            return findings.Count(f => IsFindingOpen(f) && f.DueDate.HasValue && f.DueDate.Value < asOf);
        }

        /// <summary>Open findings rated Critical or High — the ones governance forums escalate.</summary>
        public static int OpenHighSeverityCount(List<FindingItem> findings)
        {
            if (findings == null)
            {
                return 0;
            }
            return findings.Count(f => IsFindingOpen(f) &&
                (string.Equals(f.Severity, "Critical", StringComparison.OrdinalIgnoreCase) ||
                 string.Equals(f.Severity, "High", StringComparison.OrdinalIgnoreCase)));
        }

        public static List<KeyValuePair<string, int>> FindingsBySeverity(List<FindingItem> findings)
        {
            if (findings == null)
            {
                return new List<KeyValuePair<string, int>>();
            }
            return findings
                .GroupBy(f => f.Severity ?? "")
                .Select(g => new KeyValuePair<string, int>(g.Key, g.Count()))
                .OrderByDescending(kv => kv.Value)
                .ToList();
        }

        // ---- Risks ----

        /// <summary>Open risks scoring 15 or above on the 5x5 likelihood x impact grid.</summary>
        public static int HighRiskCount(List<GovernanceRiskItem> risks)
        {
            if (risks == null)
            {
                return 0;
            }
            return risks.Count(r => !string.Equals(r.Status, "Closed", StringComparison.OrdinalIgnoreCase) && r.Score >= 15);
        }

        public static List<KeyValuePair<string, int>> RisksByCategory(List<GovernanceRiskItem> risks)
        {
            if (risks == null)
            {
                return new List<KeyValuePair<string, int>>();
            }
            return risks
                .GroupBy(r => r.Category ?? "")
                .Select(g => new KeyValuePair<string, int>(g.Key, g.Count()))
                .OrderByDescending(kv => kv.Value)
                .ToList();
        }

        // ---- Exceptions ----

        public static int ActiveExceptionCount(List<ExceptionItem> exceptions)
        {
            if (exceptions == null)
            {
                return 0;
            }
            return exceptions.Count(x => string.Equals(x.Status, "Active", StringComparison.OrdinalIgnoreCase));
        }

        /// <summary>Active exceptions expiring within the given window — these need
        /// renewal or closure before they lapse silently.</summary>
        public static int ExpiringSoonCount(List<ExceptionItem> exceptions, DateTime asOf, int withinDays)
        {
            if (exceptions == null)
            {
                return 0;
            }
            var cutoff = asOf.AddDays(withinDays);
            return exceptions.Count(x =>
                string.Equals(x.Status, "Active", StringComparison.OrdinalIgnoreCase) &&
                x.ExpiryDate.HasValue &&
                x.ExpiryDate.Value >= asOf &&
                x.ExpiryDate.Value <= cutoff);
        }
    }
}
