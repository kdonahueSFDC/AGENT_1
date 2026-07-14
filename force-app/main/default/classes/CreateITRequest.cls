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

    List<IT_Request__c> requestsToInsert = new List<IT_Request__c>();

    for (RequestWrapper req : requests) {
      IT_Request__c itRequest = new IT_Request__c();
      itRequest.Employee_Name__c = req.employeeName;
      itRequest.Issue_Description__c = req.issueDescription;

      // Default priority to Medium if null or empty
      if (String.isBlank(req.priority)) {
        itRequest.Priority__c = 'Medium';
      } else {
        itRequest.Priority__c = req.priority;
      }

      itRequest.Status__c = 'New';

      requestsToInsert.add(itRequest);
    }

    // Insert records with FLS enforcement
    SObjectAccessDecision decision = Security.stripInaccessible(
      AccessType.CREATABLE,
      requestsToInsert
    );
    List<IT_Request__c> stripped = (List<IT_Request__c>) decision.getRecords();
    Database.SaveResult[] saveResults = Database.insert(stripped, false);

    // Query back to get the auto-generated Name field
    Set<Id> successIds = new Set<Id>();
    for (Integer i = 0; i < saveResults.size(); i++) {
      if (saveResults[i].isSuccess()) {
        successIds.add(saveResults[i].getId());
      }
    }

    Map<Id, IT_Request__c> insertedRecords = new Map<Id, IT_Request__c>();
    if (!successIds.isEmpty()) {
      insertedRecords = new Map<Id, IT_Request__c>(
        [
          SELECT Id, Name, Employee_Name__c
          FROM IT_Request__c
          WHERE Id IN :successIds
          WITH SECURITY_ENFORCED
        ]
      );
    }

    // Build responses
    for (Integer i = 0; i < saveResults.size(); i++) {
      ResponseWrapper response = new ResponseWrapper();

      if (saveResults[i].isSuccess()) {
        Id recordId = saveResults[i].getId();
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
        for (Database.Error err : saveResults[i].getErrors()) {
          errorMsg += err.getMessage() + ' ';
        }
        response.message = errorMsg.trim();
      }

      responses.add(response);
    }

    return responses;
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
