using System;

namespace SharePointReportingDashboard.Models
{
    public class SiteSummary
    {
        public string Title { get; set; }
        public string Url { get; set; }
        public string Owner { get; set; }
        public string Template { get; set; }
        public int ListCount { get; set; }
        public int ItemCount { get; set; }
        public double StorageUsedMb { get; set; }
        public DateTime LastModifiedUtc { get; set; }
    }
}
