@isTest
private class GetRequestStatusTest {

    @TestSetup
    static void setup() {
        // Create 10 test IT_Request__c records
        List<IT_Request__c> testRequests = new List<IT_Request__c>();

        for (Integer i = 0; i < 10; i++) {
            IT_Request__c request = new IT_Request__c();
            request.Employee_Name__c = 'Test Employee ' + i;
            request.Issue_Description__c = 'Test issue ' + i;
            request.Priority__c = 'Medium';
            request.Status__c = (Math.mod(i, 2) == 0) ? 'New' : 'In Progress';
            request.Assigned_Tier__c = (Math.mod(i, 3) == 0) ? 'Tier 2' : 'Tier 1';
            testRequests.add(request);
        }

        insert testRequests;
    }

    @isTest
    static void testGetStatusById() {
        // Query a test record
        IT_Request__c testRecord = [
            SELECT Id, Name, Status__c, Assigned_Tier__c
            FROM IT_Request__c
            LIMIT 1
        ];

        // Create request wrapper with record ID
        GetRequestStatus.RequestWrapper request = new GetRequestStatus.RequestWrapper();
        request.recordIdOrName = testRecord.Id;

        Test.startTest();
        List<GetRequestStatus.ResponseWrapper> responses = GetRequestStatus.getStatus(
            new List<GetRequestStatus.RequestWrapper>{ request }
        );
        Test.stopTest();

        // Assertions
        System.assertEquals(1, responses.size(), 'Should return 1 response');
        GetRequestStatus.ResponseWrapper response = responses[0];

        System.assertEquals(true, response.found, 'Record should be found');
        System.assertEquals(testRecord.Id, response.recordId, 'Record ID should match');
        System.assertEquals(testRecord.Name, response.recordName, 'Record name should match');
        System.assertEquals(testRecord.Status__c, response.status, 'Status should match');
        System.assertEquals(testRecord.Assigned_Tier__c, response.assignedTier, 'Assigned tier should match');
        System.assert(response.message.contains(testRecord.Name), 'Message should contain record name');
        System.assert(response.message.contains(testRecord.Status__c), 'Message should contain status');
    }

    @isTest
    static void testGetStatusByName() {
        // Query a test record
        IT_Request__c testRecord = [
            SELECT Id, Name, Status__c, Assigned_Tier__c
            FROM IT_Request__c
            LIMIT 1
        ];

        // Create request wrapper with record Name
        GetRequestStatus.RequestWrapper request = new GetRequestStatus.RequestWrapper();
        request.recordIdOrName = testRecord.Name;

        Test.startTest();
        List<GetRequestStatus.ResponseWrapper> responses = GetRequestStatus.getStatus(
            new List<GetRequestStatus.RequestWrapper>{ request }
        );
        Test.stopTest();

        // Assertions
        System.assertEquals(1, responses.size(), 'Should return 1 response');
        GetRequestStatus.ResponseWrapper response = responses[0];

        System.assertEquals(true, response.found, 'Record should be found');
        System.assertEquals(testRecord.Id, response.recordId, 'Record ID should match');
        System.assertEquals(testRecord.Name, response.recordName, 'Record name should match');
        System.assertEquals(testRecord.Status__c, response.status, 'Status should match');
        System.assertEquals(testRecord.Assigned_Tier__c, response.assignedTier, 'Assigned tier should match');
        System.assert(response.message.contains(testRecord.Name), 'Message should contain record name');
    }

    @isTest
    static void testGetStatusNotFound() {
        // Test with non-existent record ID
        GetRequestStatus.RequestWrapper request1 = new GetRequestStatus.RequestWrapper();
        request1.recordIdOrName = 'a00000000000000AAA'; // Fake ID

        // Test with non-existent record Name
        GetRequestStatus.RequestWrapper request2 = new GetRequestStatus.RequestWrapper();
        request2.recordIdOrName = 'IT-99999';

        Test.startTest();
        List<GetRequestStatus.ResponseWrapper> responses = GetRequestStatus.getStatus(
            new List<GetRequestStatus.RequestWrapper>{ request1, request2 }
        );
        Test.stopTest();

        // Assertions
        System.assertEquals(2, responses.size(), 'Should return 2 responses');

        for (GetRequestStatus.ResponseWrapper response : responses) {
            System.assertEquals(false, response.found, 'Record should not be found');
            System.assertEquals(null, response.recordId, 'Record ID should be null');
            System.assertEquals(null, response.recordName, 'Record name should be null');
            System.assertEquals(null, response.status, 'Status should be null');
            System.assertEquals(null, response.assignedTier, 'Assigned tier should be null');
            System.assert(response.message.contains('No IT request found'), 'Message should indicate not found');
        }
    }

    @isTest
    static void testGetStatusBlankInput() {
        // Test with blank input
        GetRequestStatus.RequestWrapper request1 = new GetRequestStatus.RequestWrapper();
        request1.recordIdOrName = '';

        GetRequestStatus.RequestWrapper request2 = new GetRequestStatus.RequestWrapper();
        request2.recordIdOrName = null;

        Test.startTest();
        List<GetRequestStatus.ResponseWrapper> responses = GetRequestStatus.getStatus(
            new List<GetRequestStatus.RequestWrapper>{ request1, request2 }
        );
        Test.stopTest();

        // Assertions
        System.assertEquals(2, responses.size(), 'Should return 2 responses');

        for (GetRequestStatus.ResponseWrapper response : responses) {
            System.assertEquals(false, response.found, 'Record should not be found');
            System.assert(response.message.contains('No ID or Request Number provided'), 'Message should indicate missing input');
        }
    }

    @isTest
    static void testGetStatusMultipleRequests() {
        // Query multiple test records
        List<IT_Request__c> testRecords = [
            SELECT Id, Name, Status__c, Assigned_Tier__c
            FROM IT_Request__c
            LIMIT 5
        ];

        List<GetRequestStatus.RequestWrapper> requests = new List<GetRequestStatus.RequestWrapper>();

        // Query by ID for some, by Name for others
        for (Integer i = 0; i < testRecords.size(); i++) {
            GetRequestStatus.RequestWrapper request = new GetRequestStatus.RequestWrapper();
            if (Math.mod(i, 2) == 0) {
                request.recordIdOrName = testRecords[i].Id;
            } else {
                request.recordIdOrName = testRecords[i].Name;
            }
            requests.add(request);
        }

        Test.startTest();
        List<GetRequestStatus.ResponseWrapper> responses = GetRequestStatus.getStatus(requests);
        Test.stopTest();

        // Assertions
        System.assertEquals(5, responses.size(), 'Should return 5 responses');

        for (Integer i = 0; i < responses.size(); i++) {
            GetRequestStatus.ResponseWrapper response = responses[i];
            System.assertEquals(true, response.found, 'Record ' + i + ' should be found');
            System.assertEquals(testRecords[i].Id, response.recordId, 'Record ID should match for record ' + i);
            System.assertEquals(testRecords[i].Name, response.recordName, 'Record name should match for record ' + i);
            System.assertEquals(testRecords[i].Status__c, response.status, 'Status should match for record ' + i);
            System.assertEquals(testRecords[i].Assigned_Tier__c, response.assignedTier, 'Tier should match for record ' + i);
        }
    }

    @isTest
    static void testGetStatusWith15CharId() {
        // Query a test record
        IT_Request__c testRecord = [
            SELECT Id, Name, Status__c, Assigned_Tier__c
            FROM IT_Request__c
            LIMIT 1
        ];

        // Get 15-character ID
        String id15 = String.valueOf(testRecord.Id).substring(0, 15);

        // Create request wrapper with 15-char ID
        GetRequestStatus.RequestWrapper request = new GetRequestStatus.RequestWrapper();
        request.recordIdOrName = id15;

        Test.startTest();
        List<GetRequestStatus.ResponseWrapper> responses = GetRequestStatus.getStatus(
            new List<GetRequestStatus.RequestWrapper>{ request }
        );
        Test.stopTest();

        // Assertions
        System.assertEquals(1, responses.size(), 'Should return 1 response');
        GetRequestStatus.ResponseWrapper response = responses[0];

        System.assertEquals(true, response.found, 'Record should be found with 15-char ID');
        System.assertEquals(testRecord.Id, response.recordId, 'Record ID should match');
        System.assertEquals(testRecord.Name, response.recordName, 'Record name should match');
    }
}
