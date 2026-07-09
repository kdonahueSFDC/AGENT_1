public with sharing class EscalateRequest {

    @InvocableMethod(
        label='Escalate IT Request'
        description='Escalates an IT Request to Tier 2 and sets status to Escalated'
        callout=false
    )
    public static List<ResponseWrapper> escalateRequests(List<RequestWrapper> requests) {
        List<ResponseWrapper> responses = new List<ResponseWrapper>();

        Set<Id> recordIds = new Set<Id>();
        for (RequestWrapper req : requests) {
            if (req.recordId != null) {
                recordIds.add(req.recordId);
            }
        }

        if (recordIds.isEmpty()) {
            ResponseWrapper response = new ResponseWrapper();
            response.success = false;
            response.message = 'No valid Record IDs provided.';
            responses.add(response);
            return responses;
        }

        // Query existing records
        Map<Id, IT_Request__c> recordsMap = new Map<Id, IT_Request__c>(
            [SELECT Id, Name, Status__c, Assigned_Tier__c
             FROM IT_Request__c
             WHERE Id IN :recordIds]
        );

        List<IT_Request__c> recordsToUpdate = new List<IT_Request__c>();

        for (RequestWrapper req : requests) {
            ResponseWrapper response = new ResponseWrapper();

            if (req.recordId == null) {
                response.success = false;
                response.message = 'Record ID is required.';
                responses.add(response);
                continue;
            }

            IT_Request__c record = recordsMap.get(req.recordId);

            if (record == null) {
                response.success = false;
                response.recordId = req.recordId;
                response.message = 'No IT request found with ID: ' + req.recordId;
                responses.add(response);
                continue;
            }

            // Update the record
            record.Status__c = 'Escalated';
            record.Assigned_Tier__c = 'Tier 2';
            recordsToUpdate.add(record);

            // Prepare response (will be finalized after DML)
            response.recordId = record.Id;
            response.recordName = record.Name;
            responses.add(response);
        }

        if (!recordsToUpdate.isEmpty()) {
            // Perform update - sharing rules enforced by 'with sharing' class declaration
            Database.SaveResult[] saveResults = Database.update(recordsToUpdate, false);

            // Update responses with results
            Integer responseIndex = 0;
            for (Integer i = 0; i < saveResults.size(); i++) {
                // Find the corresponding response (skip any responses already marked as failed)
                while (responseIndex < responses.size() && responses[responseIndex].success != null && !responses[responseIndex].success) {
                    responseIndex++;
                }

                if (responseIndex < responses.size()) {
                    ResponseWrapper response = responses[responseIndex];

                    if (saveResults[i].isSuccess()) {
                        response.success = true;
                        response.status = 'Escalated';
                        response.assignedTier = 'Tier 2';
                        response.message = 'Successfully escalated IT request ' +
                            response.recordName + ' to Tier 2.';
                    } else {
                        response.success = false;
                        String errorMsg = 'Failed to escalate: ';
                        for (Database.Error err : saveResults[i].getErrors()) {
                            errorMsg += err.getMessage() + ' ';
                        }
                        response.message = errorMsg.trim();
                    }
                    responseIndex++;
                }
            }
        }

        return responses;
    }

    public class RequestWrapper {
        @InvocableVariable(
            label='Record ID'
            description='Salesforce ID of the IT Request to escalate'
            required=true
        )
        public Id recordId;
    }

    public class ResponseWrapper {
        @InvocableVariable(
            label='Record ID'
            description='Salesforce ID of the IT Request'
        )
        public Id recordId;

        @InvocableVariable(
            label='Record Name'
            description='IT Request number (e.g., IT-00001)'
        )
        public String recordName;

        @InvocableVariable(
            label='Status'
            description='Status after escalation (should be Escalated)'
        )
        public String status;

        @InvocableVariable(
            label='Assigned Tier'
            description='Assigned tier after escalation (should be Tier 2)'
        )
        public String assignedTier;

        @InvocableVariable(
            label='Success'
            description='Whether the escalation was successful'
        )
        public Boolean success;

        @InvocableVariable(
            label='Message'
            description='Confirmation or error message'
        )
        public String message;
    }
}
