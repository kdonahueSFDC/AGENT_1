public with sharing class MyITRequestsController {
  private static final Set<String> OPEN_STATUSES = new Set<String>{
    'New',
    'In Progress',
    'Escalated'
  };

  @AuraEnabled(cacheable=true)
  public static List<RequestSummary> getMyRequests(
    String employeeEmail,
    String statusFilter
  ) {
    if (String.isBlank(employeeEmail)) {
      return new List<RequestSummary>();
    }
    String normalizedEmail = employeeEmail.trim().toLowerCase();

    List<IT_Request__c> records = [
      SELECT
        Id,
        Name,
        Employee_Email__c,
        Issue_Description__c,
        Priority__c,
        Status__c,
        Assigned_Tier__c,
        Due_By__c,
        SLA_Status__c,
        First_Response_At__c,
        Resolved_At__c,
        CreatedDate
      FROM IT_Request__c
      WHERE Employee_Email__c = :normalizedEmail
      WITH SECURITY_ENFORCED
      ORDER BY CreatedDate DESC
      LIMIT 200
    ];

    List<RequestSummary> results = new List<RequestSummary>();
    Boolean openOnly = 'Open'.equalsIgnoreCase(statusFilter);
    Boolean resolvedOnly = 'Resolved'.equalsIgnoreCase(statusFilter);

    for (IT_Request__c record : records) {
      if (openOnly && !OPEN_STATUSES.contains(record.Status__c)) {
        continue;
      }
      if (resolvedOnly && OPEN_STATUSES.contains(record.Status__c)) {
        continue;
      }
      results.add(new RequestSummary(record));
    }
    return results;
  }

  public class RequestSummary {
    @AuraEnabled
    public Id id;
    @AuraEnabled
    public String name;
    @AuraEnabled
    public String recordLink;
    @AuraEnabled
    public String issueDescription;
    @AuraEnabled
    public String priority;
    @AuraEnabled
    public String status;
    @AuraEnabled
    public String assignedTier;
    @AuraEnabled
    public String slaStatus;
    @AuraEnabled
    public String slaStatusClass;
    @AuraEnabled
    public DateTime dueBy;
    @AuraEnabled
    public DateTime firstResponseAt;
    @AuraEnabled
    public DateTime resolvedAt;
    @AuraEnabled
    public DateTime createdDate;

    public RequestSummary(IT_Request__c record) {
      this.id = record.Id;
      this.name = record.Name;
      this.recordLink = '/' + record.Id;
      this.issueDescription = record.Issue_Description__c;
      this.priority = record.Priority__c;
      this.status = record.Status__c;
      this.assignedTier = record.Assigned_Tier__c;
      this.slaStatus = record.SLA_Status__c;
      this.slaStatusClass = classifySlaStatus(record.SLA_Status__c);
      this.dueBy = record.Due_By__c;
      this.firstResponseAt = record.First_Response_At__c;
      this.resolvedAt = record.Resolved_At__c;
      this.createdDate = record.CreatedDate;
    }
  }

  @TestVisible
  private static String classifySlaStatus(String slaStatus) {
    if (String.isBlank(slaStatus)) {
      return 'slds-text-color_default';
    }
    if (slaStatus == 'Breached' || slaStatus == 'Missed') {
      return 'slds-text-color_error';
    }
    if (slaStatus == 'At Risk') {
      return 'slds-text-color_warning';
    }
    if (slaStatus == 'Met' || slaStatus == 'On Track') {
      return 'slds-text-color_success';
    }
    return 'slds-text-color_default';
  }
}
