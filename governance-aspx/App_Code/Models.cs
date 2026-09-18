using System;

namespace ItGovernanceSite.App_Code
{
    public class PolicyItem
    {
        public string Title { get; set; }
        public string Category { get; set; }
        public string Owner { get; set; }
        public string Status { get; set; }
        public string Version { get; set; }
        public DateTime? LastReviewed { get; set; }
        public DateTime? NextReview { get; set; }
    }

    public class ControlItem
    {
        public string ControlId { get; set; }
        public string Title { get; set; }
        public string Framework { get; set; }
        public string Owner { get; set; }
        public string Status { get; set; }
        public DateTime? LastAssessed { get; set; }
    }

    public class FindingItem
    {
        public string Title { get; set; }
        public string Severity { get; set; }
        public string Source { get; set; }
        public string Owner { get; set; }
        public string Status { get; set; }
        public DateTime? RaisedDate { get; set; }
        public DateTime? DueDate { get; set; }
    }

    public class GovernanceRiskItem
    {
        public string Title { get; set; }
        public string Category { get; set; }
        public string Owner { get; set; }
        public string Treatment { get; set; }
        public string Status { get; set; }
        public int Likelihood { get; set; }
        public int Impact { get; set; }

        /// <summary>Standard 5x5 risk score. 15+ is treated as a high risk.</summary>
        public int Score
        {
            get { return Likelihood * Impact; }
        }
    }

    public class ExceptionItem
    {
        public string Title { get; set; }
        public string PolicyRef { get; set; }
        public string RequestedBy { get; set; }
        public string Approver { get; set; }
        public string Status { get; set; }
        public DateTime? ExpiryDate { get; set; }
    }
}
