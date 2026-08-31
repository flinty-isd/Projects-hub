using System;

namespace SharePointReportingDashboard.Models
{
    /// <summary>Mirrors the RAID list schema (Implementation Specification 2.3).</summary>
    public class RaidItem
    {
        public string RaidId { get; set; }
        public string Type { get; set; }
        public string Area { get; set; }
        public string Description { get; set; }
        public string Likelihood { get; set; }
        public string Impact { get; set; }
        public string Rag { get; set; }
        public string Owner { get; set; }
        public DateTime? TargetDate { get; set; }
        public string Status { get; set; }
        public string RelatedSitePage { get; set; }
    }
}
