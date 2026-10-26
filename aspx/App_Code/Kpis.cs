using System;
using System.Collections.Generic;
using System.Linq;

namespace SharePointPmDashboard.App_Code
{
    /// <summary>Pure helper functions computing dashboard KPIs, mirroring kpis.py.</summary>
    public static class Kpis
    {
        private static readonly HashSet<string> DoneStatuses = new HashSet<string>(
            new[] { "done", "completed", "closed" }, StringComparer.OrdinalIgnoreCase);

        public static double AveragePercentComplete(List<TaskItem> tasks)
        {
            if (tasks == null || tasks.Count == 0)
            {
                return 0.0;
            }
            return Math.Round(tasks.Average(t => t.PercentComplete) * 100, 1);
        }

        public static int OverdueCount(List<TaskItem> tasks, DateTime asOf)
        {
            if (tasks == null)
            {
                return 0;
            }
            return tasks.Count(t =>
                t.DueDate.HasValue &&
                t.DueDate.Value < asOf &&
                !DoneStatuses.Contains(t.Status ?? ""));
        }

        public static List<KeyValuePair<string, int>> TasksByStatus(List<TaskItem> tasks)
        {
            if (tasks == null)
            {
                return new List<KeyValuePair<string, int>>();
            }
            return tasks
                .GroupBy(t => t.Status ?? "")
                .Select(g => new KeyValuePair<string, int>(g.Key, g.Count()))
                .OrderByDescending(kv => kv.Value)
                .ToList();
        }

        public static List<KeyValuePair<string, int>> TasksByOwner(List<TaskItem> tasks)
        {
            if (tasks == null)
            {
                return new List<KeyValuePair<string, int>>();
            }
            return tasks
                .GroupBy(t => t.AssignedTo ?? "")
                .Select(g => new KeyValuePair<string, int>(g.Key, g.Count()))
                .OrderByDescending(kv => kv.Value)
                .ToList();
        }

        public static int OpenRiskCount(List<RiskItem> risks)
        {
            if (risks == null)
            {
                return 0;
            }
            return risks.Count(r => !DoneStatuses.Contains(r.Status ?? ""));
        }
    }
}
