using System;

namespace SharePointPmDashboard.App_Code
{
    public class TaskItem
    {
        public string Title { get; set; }
        public string Status { get; set; }
        public string AssignedTo { get; set; }
        public DateTime? StartDate { get; set; }
        public DateTime? DueDate { get; set; }
        public double PercentComplete { get; set; }
        public string Priority { get; set; }
    }

    public class RiskItem
    {
        public string Title { get; set; }
        public string Severity { get; set; }
        public string Owner { get; set; }
        public string Status { get; set; }
        public string Description { get; set; }
    }
}
