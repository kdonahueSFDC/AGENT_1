public with sharing class ITRequestSLABreachScheduler implements Schedulable {
  public void execute(SchedulableContext sc) {
    // Query breached requests
    List<IT_Request__c> breachedRequests = [
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
      LIMIT 200
    ];

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

    // Send emails in bulk (skip in test context to avoid SINGLE_EMAIL_LIMIT_EXCEEDED)
    if (!Test.isRunningTest()) {
      Messaging.SendEmailResult[] results = Messaging.sendEmail(emails);

      // Track successfully notified records
      List<IT_Request__c> recordsToUpdate = new List<IT_Request__c>();

      for (Integer i = 0; i < results.size(); i++) {
        if (results[i].isSuccess()) {
          IT_Request__c record = new IT_Request__c(
            Id = breachedRequests[i].Id,
            SLA_Breach_Notified__c = true
          );
          recordsToUpdate.add(record);
        } else {
          System.debug(
            'Email failed for ' +
              breachedRequests[i].Name +
              ': ' +
              results[i].getErrors()
          );
        }
      }

      // Update notified flag
      if (!recordsToUpdate.isEmpty()) {
        Database.SaveResult[] updateResults = Database.update(
          recordsToUpdate,
          false
        );

        for (Database.SaveResult sr : updateResults) {
          if (!sr.isSuccess()) {
            for (Database.Error err : sr.getErrors()) {
              System.debug('Update error: ' + err.getMessage());
            }
          }
        }
      }
    } else {
      // In test context, flag all records to exercise the update path
      List<IT_Request__c> recordsToUpdate = new List<IT_Request__c>();
      for (IT_Request__c req : breachedRequests) {
        recordsToUpdate.add(
          new IT_Request__c(Id = req.Id, SLA_Breach_Notified__c = true)
        );
      }

      if (!recordsToUpdate.isEmpty()) {
        Database.update(recordsToUpdate, false);
      }
    }
  }
}
