public with sharing class CreateITRequest {
  @InvocableMethod(
    label='Create IT Request'
    description='Creates a new IT Request record with specified employee name, issue description, and priority'
    callout=false
  )
  public static List<ResponseWrapper> createRequests(
    List<RequestWrapper> requests
  ) {
    List<ResponseWrapper> responses = new List<ResponseWrapper>();

    // Step 1: Validate employee emails (bulkified)
    Map<Integer, String> emailValidationErrors = validateEmployeeEmails(
      requests
    );

    // Step 2: Build IT_Request__c records for valid requests
    List<IT_Request__c> requestsToInsert = new List<IT_Request__c>();
    Map<Integer, Integer> validIndexToRequestIndex = new Map<Integer, Integer>();

    for (Integer i = 0; i < requests.size(); i++) {
      if (emailValidationErrors.containsKey(i)) {
        // Skip invalid requests; we'll add error responses later
        continue;
      }

      RequestWrapper req = requests[i];
      IT_Request__c itRequest = new IT_Request__c();
      itRequest.Employee_Name__c = req.employeeName;
      itRequest.Issue_Description__c = req.issueDescription;

      // Populate Employee_Email__c (normalized to lowercase)
      if (!String.isBlank(req.employeeEmail)) {
        itRequest.Employee_Email__c = req.employeeEmail.trim().toLowerCase();
      }

      // Default priority to Medium if null or empty
      if (String.isBlank(req.priority)) {
        itRequest.Priority__c = 'Medium';
      } else {
        itRequest.Priority__c = req.priority;
      }

      itRequest.Status__c = 'New';

      validIndexToRequestIndex.put(requestsToInsert.size(), i);
      requestsToInsert.add(itRequest);
    }

    // Step 3: Insert valid records with FLS enforcement
    List<Database.SaveResult> saveResults = new List<Database.SaveResult>();
    Map<Integer, Id> validIndexToRecordId = new Map<Integer, Id>();

    if (!requestsToInsert.isEmpty()) {
      SObjectAccessDecision decision = Security.stripInaccessible(
        AccessType.CREATABLE,
        requestsToInsert
      );
      List<IT_Request__c> stripped = (List<IT_Request__c>) decision.getRecords();
      saveResults = Database.insert(stripped, false);

      // Map successful inserts
      for (Integer i = 0; i < saveResults.size(); i++) {
        if (saveResults[i].isSuccess()) {
          validIndexToRecordId.put(i, saveResults[i].getId());
        }
      }
    }

    // Step 4: Query back to get the auto-generated Name field
    Map<Id, IT_Request__c> insertedRecords = new Map<Id, IT_Request__c>();
    if (!validIndexToRecordId.isEmpty()) {
      insertedRecords = new Map<Id, IT_Request__c>(
        [
          SELECT Id, Name, Employee_Name__c, Employee_Email__c
          FROM IT_Request__c
          WHERE Id IN :validIndexToRecordId.values()
          WITH SECURITY_ENFORCED
        ]
      );
    }

    // Step 5: Send confirmation emails
    sendConfirmationEmails(insertedRecords.values());

    // Step 6: Build responses in original request order
    for (Integer i = 0; i < requests.size(); i++) {
      ResponseWrapper response = new ResponseWrapper();

      if (emailValidationErrors.containsKey(i)) {
        // Email validation failed
        response.message = emailValidationErrors.get(i);
      } else {
        // Find the corresponding save result
        Integer validIndex = getKeyByValue(validIndexToRequestIndex, i);

        if (validIndex != null && saveResults.size() > validIndex) {
          Database.SaveResult saveResult = saveResults[validIndex];

          if (saveResult.isSuccess()) {
            Id recordId = validIndexToRecordId.get(validIndex);
            IT_Request__c record = insertedRecords.get(recordId);

            response.recordId = recordId;
            response.recordName = record.Name;
            response.message =
              'Created IT request ' +
              record.Name +
              ' for ' +
              record.Employee_Name__c +
              '.';
          } else {
            // Handle DML errors
            String errorMsg = 'Failed to create IT request: ';
            for (Database.Error err : saveResult.getErrors()) {
              errorMsg += err.getMessage() + ' ';
            }
            response.message = errorMsg.trim();
          }
        }
      }

      responses.add(response);
    }

    return responses;
  }

  @TestVisible
  private static Map<Integer, String> validateEmployeeEmails(
    List<RequestWrapper> requests
  ) {
    Map<Integer, String> errors = new Map<Integer, String>();

    // Collect all non-blank emails
    Set<String> emailsToValidate = new Set<String>();
    Map<String, List<Integer>> emailToIndices = new Map<String, List<Integer>>();

    for (Integer i = 0; i < requests.size(); i++) {
      String email = requests[i].employeeEmail;
      if (!String.isBlank(email)) {
        String normalized = email.trim().toLowerCase();
        emailsToValidate.add(normalized);

        if (!emailToIndices.containsKey(normalized)) {
          emailToIndices.put(normalized, new List<Integer>());
        }
        emailToIndices.get(normalized).add(i);
      }
    }

    if (emailsToValidate.isEmpty()) {
      return errors;
    }

    // Bulkified validation: query Users and Contacts
    Set<String> validEmails = new Set<String>();

    for (User u : [
      SELECT Email
      FROM User
      WHERE Email IN :emailsToValidate AND IsActive = TRUE
      WITH USER_MODE
    ]) {
      validEmails.add(u.Email.toLowerCase());
    }

    for (Contact c : [
      SELECT Email
      FROM Contact
      WHERE Email IN :emailsToValidate
      WITH USER_MODE
    ]) {
      if (!String.isBlank(c.Email)) {
        validEmails.add(c.Email.toLowerCase());
      }
    }

    // Mark invalid emails
    for (String email : emailsToValidate) {
      if (!validEmails.contains(email)) {
        for (Integer index : emailToIndices.get(email)) {
          errors.put(
            index,
            'Employee email "' +
              email +
              '" is not associated with an active User or Contact.'
          );
        }
      }
    }

    return errors;
  }

  @TestVisible
  private static void sendConfirmationEmails(
    List<IT_Request__c> createdRequests
  ) {
    if (createdRequests.isEmpty()) {
      return;
    }

    // Get email template ID
    List<EmailTemplate> templates = [
      SELECT Id
      FROM EmailTemplate
      WHERE DeveloperName = 'IT_Request_Confirmation'
      WITH USER_MODE
      LIMIT 1
    ];

    if (templates.isEmpty()) {
      // No template found; skip email sending
      return;
    }

    Id templateId = templates[0].Id;

    // Build emails for requests with Employee_Email__c
    List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

    for (IT_Request__c req : createdRequests) {
      if (String.isBlank(req.Employee_Email__c)) {
        continue;
      }

      Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
      email.setToAddresses(new List<String>{ req.Employee_Email__c });
      email.setTemplateId(templateId);
      email.setTargetObjectId(UserInfo.getUserId()); // Required for templates
      email.setWhatId(req.Id);
      email.setSaveAsActivity(false);

      emails.add(email);
    }

    if (!emails.isEmpty()) {
      try {
        Messaging.sendEmail(emails, false);
      } catch (Exception e) {
        // Log error but don't fail the transaction
        System.debug('Failed to send confirmation emails: ' + e.getMessage());
      }
    }
  }

  @TestVisible
  private static Integer getKeyByValue(
    Map<Integer, Integer> mapToSearch,
    Integer value
  ) {
    for (Integer key : mapToSearch.keySet()) {
      if (mapToSearch.get(key) == value) {
        return key;
      }
    }
    return null;
  }

  public class RequestWrapper {
    @InvocableVariable(
      label='Employee Name'
      description='Name of the employee submitting the IT request'
      required=true
    )
    public String employeeName;

    @InvocableVariable(
      label='Issue Description'
      description='Detailed description of the IT issue or request'
      required=true
    )
    public String issueDescription;

    @InvocableVariable(
      label='Priority'
      description='Priority level: Low, Medium, High, or Critical. Defaults to Medium if not specified.'
      required=false
    )
    public String priority;

    @InvocableVariable(
      label='Employee Email'
      description='Email address of the employee for status notifications. Will be validated against active Users/Contacts.'
      required=false
    )
    public String employeeEmail;
  }

  public class ResponseWrapper {
    @InvocableVariable(
      label='Record ID'
      description='Salesforce ID of the created IT Request record'
    )
    public Id recordId;

    @InvocableVariable(
      label='Record Name'
      description='Auto-generated IT Request number (e.g., IT-00001)'
    )
    public String recordName;

    @InvocableVariable(
      label='Message'
      description='Confirmation or error message'
    )
    public String message;
  }
}
