using System;

namespace SharePointReportingDashboard.Models
{
    /// <summary>Mirrors the Page Delivery Register list schema (Implementation Specification 2.2).</summary>
    public class PageDeliveryItem
    {
        public string PageId { get; set; }
        public string PageName { get; set; }
        public string BusinessArea { get; set; }
        public string ScopeClassification { get; set; }
        public string ExistingUrl { get; set; }
        public string TargetUrl { get; set; }
        public string Disposition { get; set; }
        public string ContentOwner { get; set; }
        public string DeliveryOwner { get; set; }
        public string Priority { get; set; }
        public string DeliveryStatus { get; set; }
        public bool? DesignApproved { get; set; }
        public bool? ContentReady { get; set; }
        public string UatStatus { get; set; }
        public bool? BusinessSignOff { get; set; }
        public DateTime? TargetGoLive { get; set; }
        public string RelatedActionRisk { get; set; }
    }
}
