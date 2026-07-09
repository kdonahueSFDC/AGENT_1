@isTest
private class EscalateRequestTest {

    @TestSetup
    static void setup() {
        // Create 10 test IT_Request__c records
        List<IT_Request__c> testRequests = new List<IT_Request__c>();

        for (Integer i = 0; i < 10; i++) {
            IT_Request__c request = new IT_Request__c();
            request.Employee_Name__c = 'Test Employee ' + i;
            request.Issue_Description__c = 'Test issue ' + i;
            request.Priority__c = 'High';
            request.Status__c = 'In Progress';
            request.Assigned_Tier__c = 'Tier 1';
            testRequests.add(request);
        }

        insert testRequests;
    }

    @isTest
    static void testEscalateSingleRequest() {
        // Query a test record
        IT_Request__c testRecord = [
            SELECT Id, Name, Status__c, Assigned_Tier__c
            FROM IT_Request__c
            LIMIT 1
        ];

        // Verify initial state
        System.assertEquals('In Progress', testRecord.Status__c, 'Initial status should be In Progress');
        System.assertEquals('Tier 1', testRecord.Assigned_Tier__c, 'Initial tier should be Tier 1');

        // Create request wrapper
        EscalateRequest.RequestWrapper request = new EscalateRequest.RequestWrapper();
        request.recordId = testRecord.Id;

        Test.startTest();
        List<EscalateRequest.ResponseWrapper> responses = EscalateRequest.escalateRequests(
            new List<EscalateRequest.RequestWrapper>{ request }
        );
        Test.stopTest();

        // Assertions
        System.assertEquals(1, responses.size(), 'Should return 1 response');
        EscalateRequest.ResponseWrapper response = responses[0];

        System.assertEquals(true, response.success, 'Escalation should be successful');
        System.assertEquals(testRecord.Id, response.recordId, 'Record ID should match');
        System.assertEquals(testRecord.Name, response.recordName, 'Record name should match');
        System.assertEquals('Escalated', response.status, 'Status should be Escalated');
        System.assertEquals('Tier 2', response.assignedTier, 'Assigned tier should be Tier 2');
        System.assert(response.message.contains('Successfully escalated'), 'Message should confirm escalation');
        System.assert(response.message.contains(testRecord.Name), 'Message should include record name');

        // Verify record in database
        IT_Request__c updatedRecord = [
            SELECT Id, Status__c, Assigned_Tier__c
            FROM IT_Request__c
            WHERE Id = :testRecord.Id
        ];

        System.assertEquals('Escalated', updatedRecord.Status__c, 'Database status should be Escalated');
        System.assertEquals('Tier 2', updatedRecord.Assigned_Tier__c, 'Database tier should be Tier 2');
    }

    @isTest
    static void testEscalateMultipleRequests() {
        // Query multiple test records
        List<IT_Request__c> testRecords = [
            SELECT Id, Name, Status__c, Assigned_Tier__c
            FROM IT_Request__c
            LIMIT 5
        ];

        List<EscalateRequest.RequestWrapper> requests = new List<EscalateRequest.RequestWrapper>();

        for (IT_Request__c record : testRecords) {
            EscalateRequest.RequestWrapper request = new EscalateRequest.RequestWrapper();
            request.recordId = record.Id;
            requests.add(request);
        }

        Test.startTest();
        List<EscalateRequest.ResponseWrapper> responses = EscalateRequest.escalateRequests(requests);
        Test.stopTest();

        // Assertions
        System.assertEquals(5, responses.size(), 'Should return 5 responses');

        Set<Id> escalatedIds = new Set<Id>();
        for (Integer i = 0; i < responses.size(); i++) {
            EscalateRequest.ResponseWrapper response = responses[i];
            System.assertEquals(true, response.success, 'Escalation ' + i + ' should be successful');
            System.assertEquals('Escalated', response.status, 'Status should be Escalated for record ' + i);
            System.assertEquals('Tier 2', response.assignedTier, 'Tier should be Tier 2 for record ' + i);
            escalatedIds.add(response.recordId);
        }

        System.assertEquals(5, escalatedIds.size(), 'Should have 5 unique escalated record IDs');

        // Verify all records in database
        List<IT_Request__c> updatedRecords = [
            SELECT Id, Status__c, Assigned_Tier__c
            FROM IT_Request__c
            WHERE Id IN :escalatedIds
        ];

        System.assertEquals(5, updatedRecords.size(), 'Should have 5 updated records in database');

        for (IT_Request__c record : updatedRecords) {
            System.assertEquals('Escalated', record.Status__c, 'Database status should be Escalated');
            System.assertEquals('Tier 2', record.Assigned_Tier__c, 'Database tier should be Tier 2');
        }
    }

    @isTest
    static void testEscalateNonExistentRecord() {
        // Create request with non-existent record ID
        EscalateRequest.RequestWrapper request = new EscalateRequest.RequestWrapper();
        request.recordId = 'a00000000000000AAA'; // Fake ID format - will fail Id.valueOf

        Test.startTest();
        List<EscalateRequest.ResponseWrapper> responses = EscalateRequest.escalateRequests(
            new List<EscalateRequest.RequestWrapper>{ request }
        );
        Test.stopTest();

        // Assertions
        System.assertEquals(1, responses.size(), 'Should return 1 response');
        EscalateRequest.ResponseWrapper response = responses[0];

        System.assertEquals(false, response.success, 'Escalation should not be successful');
        System.assertNotEquals(null, response.message, 'Message should be populated');
        System.assert(
            response.message.contains('No IT request found') || response.message.contains('Error'),
            'Message should indicate record not found or error: ' + response.message
        );
    }

    @isTest
    static void testEscalateNullRecordId() {
        // Create request with null record ID
        EscalateRequest.RequestWrapper request = new EscalateRequest.RequestWrapper();
        request.recordId = null;

        Test.startTest();
        List<EscalateRequest.ResponseWrapper> responses = EscalateRequest.escalateRequests(
            new List<EscalateRequest.RequestWrapper>{ request }
        );
        Test.stopTest();

        // Assertions
        System.assertEquals(1, responses.size(), 'Should return 1 response');
        EscalateRequest.ResponseWrapper response = responses[0];

        System.assertEquals(false, response.success, 'Escalation should not be successful');
        System.assertNotEquals(null, response.message, 'Message should be populated');
        System.assert(
            response.message.contains('Record ID is required') || response.message.contains('No valid Record IDs'),
            'Message should indicate record ID is required'
        );
    }

    @isTest
    static void testEscalateMixedValidAndInvalid() {
        // Query a valid test record
        IT_Request__c testRecord = [
            SELECT Id, Name
            FROM IT_Request__c
            LIMIT 1
        ];

        // Create mixed requests - valid and invalid
        List<EscalateRequest.RequestWrapper> requests = new List<EscalateRequest.RequestWrapper>();

        EscalateRequest.RequestWrapper validRequest = new EscalateRequest.RequestWrapper();
        validRequest.recordId = testRecord.Id;
        requests.add(validRequest);

        EscalateRequest.RequestWrapper nullRequest = new EscalateRequest.RequestWrapper();
        nullRequest.recordId = null;
        requests.add(nullRequest);

        Test.startTest();
        List<EscalateRequest.ResponseWrapper> responses = EscalateRequest.escalateRequests(requests);
        Test.stopTest();

        // Assertions
        System.assertEquals(2, responses.size(), 'Should return 2 responses');

        // First response should be successful
        System.assertEquals(true, responses[0].success, 'First escalation should be successful');
        System.assertEquals('Escalated', responses[0].status, 'First status should be Escalated');

        // Second response should fail
        System.assertEquals(false, responses[1].success, 'Second escalation should not be successful');
    }

    @isTest
    static void testEscalateAlreadyEscalatedRequest() {
        // Query a test record and escalate it
        IT_Request__c testRecord = [
            SELECT Id, Name
            FROM IT_Request__c
            LIMIT 1
        ];

        testRecord.Status__c = 'Escalated';
        testRecord.Assigned_Tier__c = 'Tier 2';
        update testRecord;

        // Try to escalate again
        EscalateRequest.RequestWrapper request = new EscalateRequest.RequestWrapper();
        request.recordId = testRecord.Id;

        Test.startTest();
        List<EscalateRequest.ResponseWrapper> responses = EscalateRequest.escalateRequests(
            new List<EscalateRequest.RequestWrapper>{ request }
        );
        Test.stopTest();

        // Assertions - should still succeed (idempotent operation)
        System.assertEquals(1, responses.size(), 'Should return 1 response');
        EscalateRequest.ResponseWrapper response = responses[0];

        System.assertEquals(true, response.success, 'Escalation should be successful');
        System.assertEquals('Escalated', response.status, 'Status should be Escalated');
        System.assertEquals('Tier 2', response.assignedTier, 'Assigned tier should be Tier 2');
    }

    @isTest
    static void testEscalateBulkRequests() {
        // Query all 10 test records
        List<IT_Request__c> testRecords = [
            SELECT Id, Name
            FROM IT_Request__c
        ];

        System.assertEquals(10, testRecords.size(), 'Should have 10 test records');

        List<EscalateRequest.RequestWrapper> requests = new List<EscalateRequest.RequestWrapper>();

        for (IT_Request__c record : testRecords) {
            EscalateRequest.RequestWrapper request = new EscalateRequest.RequestWrapper();
            request.recordId = record.Id;
            requests.add(request);
        }

        Test.startTest();
        List<EscalateRequest.ResponseWrapper> responses = EscalateRequest.escalateRequests(requests);
        Test.stopTest();

        // Assertions
        System.assertEquals(10, responses.size(), 'Should return 10 responses');

        for (Integer i = 0; i < responses.size(); i++) {
            EscalateRequest.ResponseWrapper response = responses[i];
            System.assertEquals(true, response.success, 'Escalation ' + i + ' should be successful');
            System.assertEquals('Escalated', response.status, 'Status should be Escalated for record ' + i);
            System.assertEquals('Tier 2', response.assignedTier, 'Tier should be Tier 2 for record ' + i);
        }

        // Verify all records in database
        List<IT_Request__c> updatedRecords = [
            SELECT Id, Status__c, Assigned_Tier__c
            FROM IT_Request__c
        ];

        System.assertEquals(10, updatedRecords.size(), 'Should have 10 updated records in database');

        for (IT_Request__c record : updatedRecords) {
            System.assertEquals('Escalated', record.Status__c, 'Database status should be Escalated');
            System.assertEquals('Tier 2', record.Assigned_Tier__c, 'Database tier should be Tier 2');
        }
    }
}
