public with sharing class ITRequestSLABreachBatch implements Database.Batchable<sObject> {
  public Database.QueryLocator start(Database.BatchableContext bc) {
    return Database.getQueryLocator(
      [
        SELECT
          Id,
          Name,
          Employee_Name__c,
          Priority__c,
          Status__c,
          Due_By__c,
          Issue_Description__c
        FROM IT_Request__c
        WHERE
          Status__c != 'Resolved'
          AND Due_By__c != NULL
          AND Due_By__c < :Datetime.now()
          AND SLA_Breach_Notified__c = FALSE
        WITH USER_MODE
      ]
    );
  }

  public void execute(
    Database.BatchableContext bc,
    List<IT_Request__c> breachedRequests
  ) {
    if (breachedRequests.isEmpty()) {
      return;
    }

    // Build email messages
    List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

    for (IT_Request__c request : breachedRequests) {
      Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
      email.setToAddresses(new List<String>{ 'it-tier2@example.com' });
      email.setSubject('SLA BREACH: IT Request ' + request.Name);

      String body =
        'ALERT: IT Request ' +
        request.Name +
        ' has breached its SLA deadline.\n\n' +
        'Request Details:\n' +
        '- Employee: ' +
        request.Employee_Name__c +
        '\n' +
        '- Priority: ' +
        request.Priority__c +
        '\n' +
        '- Status: ' +
        request.Status__c +
        '\n' +
        '- Due By: ' +
        request.Due_By__c +
        '\n' +
        '- Issue: ' +
        request.Issue_Description__c +
        '\n\n' +
        'Immediate action is required to address this overdue request.';

      email.setPlainTextBody(body);
      emails.add(email);
    }

    processBreaches(breachedRequests, emails);
  }

  public void finish(Database.BatchableContext bc) {
    // No post-processing needed
  }

  @TestVisible
  private static void processBreaches(
    List<IT_Request__c> breachedRequests,
    List<Messaging.SingleEmailMessage> emails
  ) {
    Messaging.SendEmailResult[] results = Messaging.sendEmail(emails, false);

    List<IT_Request__c> recordsToUpdate = new List<IT_Request__c>();
    for (Integer i = 0; i < results.size(); i++) {
      if (results[i].isSuccess()) {
        recordsToUpdate.add(
          new IT_Request__c(
            Id = breachedRequests[i].Id,
            SLA_Breach_Notified__c = true
          )
        );
      }
    }

    if (!recordsToUpdate.isEmpty()) {
      Database.update(recordsToUpdate, false);
    }
  }
}
