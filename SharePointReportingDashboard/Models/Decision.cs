using System;

namespace SharePointReportingDashboard.Models
{
    /// <summary>Mirrors the Decisions list schema (Implementation Specification 2.3).</summary>
    public class Decision
    {
        public string DecisionId { get; set; }
        public string DecisionText { get; set; }
        public DateTime Date { get; set; }
        public string Owner { get; set; }
        public string Rationale { get; set; }
        public string Status { get; set; }
        public string RelatedSitePage { get; set; }
    }
}
