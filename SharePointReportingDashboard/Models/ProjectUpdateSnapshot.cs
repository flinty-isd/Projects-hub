using System;

namespace SharePointReportingDashboard.Models
{
    /// <summary>Mirrors the Project Updates list schema (Implementation Specification 2.3) - appended weekly, never overwritten.</summary>
    public class ProjectUpdateSnapshot
    {
        public DateTime SnapshotDate { get; set; }
        public int SitesComplete { get; set; }
        public int RemainingSites { get; set; }
        public string OverallRag { get; set; }
        public int OpenRisks { get; set; }
        public int OverdueActions { get; set; }
        public int PagesOutstanding { get; set; }
        public string Commentary { get; set; }
    }
}
