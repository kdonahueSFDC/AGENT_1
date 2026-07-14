public with sharing class GetRequestStatus {
  @InvocableMethod(
    label='Get IT Request Status'
    description='Retrieves the status of an IT Request by ID or Request Number (e.g., IT-00001)'
    callout=false
  )
  public static List<ResponseWrapper> getStatus(List<RequestWrapper> requests) {
    List<ResponseWrapper> responses = new List<ResponseWrapper>();

    for (RequestWrapper req : requests) {
      ResponseWrapper response = new ResponseWrapper();
      response.found = false;

      if (String.isBlank(req.recordIdOrName)) {
        response.message = 'No ID or Request Number provided.';
        responses.add(response);
        continue;
      }

      try {
        IT_Request__c record = null;

        // Check if input looks like a Salesforce ID (15 or 18 chars)
        String input = req.recordIdOrName.trim();
        Boolean isId = (input.length() == 15 || input.length() == 18);

        if (isId) {
          try {
            Id recordId = Id.valueOf(input);
            List<IT_Request__c> records = [
              SELECT Id, Name, Status__c, Assigned_Tier__c
              FROM IT_Request__c
              WHERE Id = :recordId
              WITH SECURITY_ENFORCED
              LIMIT 1
            ];

            if (!records.isEmpty()) {
              record = records[0];
            }
          } catch (Exception e) {
            // Invalid ID format, try as Name
            isId = false;
          }
        }

        // If not an ID or ID query failed, try by Name
        if (record == null) {
          List<IT_Request__c> records = [
            SELECT Id, Name, Status__c, Assigned_Tier__c
            FROM IT_Request__c
            WHERE Name = :input
            WITH SECURITY_ENFORCED
            LIMIT 1
          ];

          if (!records.isEmpty()) {
            record = records[0];
          }
        }

        if (record != null) {
          response.found = true;
          response.recordId = record.Id;
          response.recordName = record.Name;
          response.status = record.Status__c;
          response.assignedTier = record.Assigned_Tier__c;
          response.message =
            'Request ' +
            record.Name +
            ' is currently \'' +
            record.Status__c +
            '\' assigned to ' +
            record.Assigned_Tier__c +
            '.';
        } else {
          response.message = 'No IT request found matching \'' + input + '\'.';
        }
      } catch (Exception e) {
        response.message = 'Error retrieving IT request: ' + e.getMessage();
      }

      responses.add(response);
    }

    return responses;
  }

  public class RequestWrapper {
    @InvocableVariable(
      label='Record ID or Request Number'
      description='Either the Salesforce ID or the Request Number (e.g., IT-00001) of the IT Request'
      required=true
    )
    public String recordIdOrName;
  }

  public class ResponseWrapper {
    @InvocableVariable(
      label='Record ID'
      description='Salesforce ID of the IT Request record (null if not found)'
    )
    public Id recordId;

    @InvocableVariable(
      label='Record Name'
      description='IT Request number (e.g., IT-00001) (null if not found)'
    )
    public String recordName;

    @InvocableVariable(
      label='Status'
      description='Current status of the IT Request (null if not found)'
    )
    public String status;

    @InvocableVariable(
      label='Assigned Tier'
      description='Current assigned tier (null if not found)'
    )
    public String assignedTier;

    @InvocableVariable(
      label='Found'
      description='Whether the IT Request was found'
    )
    public Boolean found;

    @InvocableVariable(
      label='Message'
      description='Status message or error message'
    )
    public String message;
  }
}
