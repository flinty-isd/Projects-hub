using System;

namespace SharePointReportingDashboard.Models
{
    /// <summary>Mirrors the Migration Register list schema (Implementation Specification 2.1).</summary>
    public class MigrationSite
    {
        public string SiteId { get; set; }
        public string SiteTitle { get; set; }
        public string SiteUrl { get; set; }
        public string Department { get; set; }
        public string Wave { get; set; }
        public string BusinessOwner { get; set; }
        public string MigrationOwner { get; set; }
        public string Status { get; set; }
        public string Readiness { get; set; }
        public int? ReadinessScore { get; set; }
        public DateTime? PlannedMigration { get; set; }
        public DateTime? ActualMigration { get; set; }
        public string UatStatus { get; set; }
        public string BusinessSignOff { get; set; }
        public string BlockerDependency { get; set; }
        public double? DataSizeGb { get; set; }
        public DateTime LastReviewed { get; set; }
    }
}
