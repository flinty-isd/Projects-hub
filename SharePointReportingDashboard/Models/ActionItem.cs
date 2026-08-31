using System;

namespace SharePointReportingDashboard.Models
{
    /// <summary>Mirrors the Actions list schema (Implementation Specification 2.3).</summary>
    public class ActionItem
    {
        public string ActionId { get; set; }
        public string Action { get; set; }
        public string Owner { get; set; }
        public DateTime DueDate { get; set; }
        public string Status { get; set; }
        public string Rag { get; set; }
        public string Source { get; set; }
        public string RelatedSitePage { get; set; }

        public bool IsOverdue => Status != "Closed" && DueDate.Date < DateTime.UtcNow.Date;
    }
}
