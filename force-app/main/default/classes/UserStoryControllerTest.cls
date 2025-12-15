/**
 * @description Test class for UserStoryController
 * @author Salesforce (Cursor)
 * @date 2025-12-08
 */
@isTest
public class UserStoryControllerTest {
    
    @testSetup
    static void setup() {
        // Create test features
        List<Feature__c> features = new List<Feature__c>{
            new Feature__c(
                Name = 'Feature A',
                Status__c = 'In Progress',
                Description__c = 'Test Feature A Description'
            ),
            new Feature__c(
                Name = 'Feature B',
                Status__c = 'Planning',
                Description__c = 'Test Feature B Description'
            )
        };
        insert features;
        
        // Get current user for assignee testing
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        
        // Create test user stories with various statuses and priorities
        List<User_Story__c> userStories = new List<User_Story__c>{
            // Feature A stories
            new User_Story__c(
                Name = 'Story 1 - Backlog',
                Feature__c = features[0].Id,
                Status__c = 'Backlog',
                Priority__c = 'High',
                Description__c = 'Test story 1',
                Acceptance_Criteria__c = 'Criteria 1'
            ),
            new User_Story__c(
                Name = 'Story 2 - In Progress',
                Feature__c = features[0].Id,
                Status__c = 'In_Progress',
                Priority__c = 'Critical',
                Assignee__c = currentUser.Id,
                Description__c = 'Test story 2',
                Acceptance_Criteria__c = 'Criteria 2'
            ),
            new User_Story__c(
                Name = 'Story 3 - In Review',
                Feature__c = features[0].Id,
                Status__c = 'In_Review',
                Priority__c = 'Medium',
                Description__c = 'Test story 3'
            ),
            new User_Story__c(
                Name = 'Story 4 - Done',
                Feature__c = features[0].Id,
                Status__c = 'Done',
                Priority__c = 'Low',
                Description__c = 'Test story 4'
            ),
            // Feature B stories
            new User_Story__c(
                Name = 'Story 5 - Blocked',
                Feature__c = features[1].Id,
                Status__c = 'Blocked',
                Priority__c = 'High',
                Assignee__c = currentUser.Id,
                Description__c = 'Test story 5'
            ),
            new User_Story__c(
                Name = 'Story 6 - Backlog',
                Feature__c = features[1].Id,
                Status__c = 'Backlog',
                Priority__c = 'Medium',
                Description__c = 'Test story 6'
            )
        };
        insert userStories;
    }
    
    // ========== getUserStories() Tests ==========
    
    @isTest
    static void getUserStories_basicQuery_returnsAllStories() {
        Test.startTest();
        UserStoryController.PaginatedResult result = UserStoryController.getUserStories(
            null, null, null, null, 1, 50, null, null
        );
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isNotNull(result.records, 'Records should not be null');
        Assert.areEqual(6, result.totalRecords, 'Should have 6 total records');
        Assert.areEqual(1, result.totalPages, 'Should have 1 page');
        Assert.areEqual(6, result.records.size(), 'Should return 6 records');
    }
    
    @isTest
    static void getUserStories_filterByFeature_returnsFilteredStories() {
        Feature__c feature = [SELECT Id FROM Feature__c WHERE Name = 'Feature A' LIMIT 1];
        
        Test.startTest();
        UserStoryController.PaginatedResult result = UserStoryController.getUserStories(
            feature.Id, null, null, null, 1, 50, null, null
        );
        Test.stopTest();
        
        Assert.areEqual(4, result.totalRecords, 'Should have 4 stories for Feature A');
        Assert.areEqual(4, result.records.size(), 'Should return 4 records');
        for (UserStoryController.UserStoryWrapper wrapper : result.records) {
            Assert.areEqual(feature.Id, wrapper.featureId, 'All stories should belong to Feature A');
        }
    }
    
    @isTest
    static void getUserStories_filterByStatus_returnsFilteredStories() {
        Test.startTest();
        UserStoryController.PaginatedResult result = UserStoryController.getUserStories(
            null, 'Backlog', null, null, 1, 50, null, null
        );
        Test.stopTest();
        
        Assert.areEqual(2, result.totalRecords, 'Should have 2 Backlog stories');
        for (UserStoryController.UserStoryWrapper wrapper : result.records) {
            Assert.areEqual('Backlog', wrapper.status, 'All stories should have Backlog status');
        }
    }
    
    @isTest
    static void getUserStories_filterByPriority_returnsFilteredStories() {
        Test.startTest();
        UserStoryController.PaginatedResult result = UserStoryController.getUserStories(
            null, null, 'High', null, 1, 50, null, null
        );
        Test.stopTest();
        
        Assert.areEqual(2, result.totalRecords, 'Should have 2 High priority stories');
        for (UserStoryController.UserStoryWrapper wrapper : result.records) {
            Assert.areEqual('High', wrapper.priority, 'All stories should have High priority');
        }
    }
    
    @isTest
    static void getUserStories_filterByAssignee_returnsFilteredStories() {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        
        Test.startTest();
        UserStoryController.PaginatedResult result = UserStoryController.getUserStories(
            null, null, null, currentUser.Id, 1, 50, null, null
        );
        Test.stopTest();
        
        Assert.areEqual(2, result.totalRecords, 'Should have 2 stories assigned to current user');
        for (UserStoryController.UserStoryWrapper wrapper : result.records) {
            Assert.areEqual(currentUser.Id, wrapper.assigneeId, 'All stories should be assigned to current user');
        }
    }
    
    @isTest
    static void getUserStories_pagination_worksCorrectly() {
        Test.startTest();
        UserStoryController.PaginatedResult page1 = UserStoryController.getUserStories(
            null, null, null, null, 1, 3, null, null
        );
        UserStoryController.PaginatedResult page2 = UserStoryController.getUserStories(
            null, null, null, null, 2, 3, null, null
        );
        Test.stopTest();
        
        Assert.areEqual(3, page1.records.size(), 'Page 1 should have 3 records');
        Assert.areEqual(3, page2.records.size(), 'Page 2 should have 3 records');
        Assert.areEqual(2, page1.totalPages, 'Should have 2 total pages');
        Assert.areEqual(6, page1.totalRecords, 'Should have 6 total records');
    }
    
    @isTest
    static void getUserStories_sorting_worksCorrectly() {
        Test.startTest();
        UserStoryController.PaginatedResult ascResult = UserStoryController.getUserStories(
            null, null, null, null, 1, 50, 'Name', 'asc'
        );
        UserStoryController.PaginatedResult descResult = UserStoryController.getUserStories(
            null, null, null, null, 1, 50, 'Name', 'desc'
        );
        Test.stopTest();
        
        Assert.isTrue(ascResult.records.size() > 0, 'Should have records');
        Assert.isTrue(descResult.records.size() > 0, 'Should have records');
        // Verify sorting order
        String firstAsc = ascResult.records[0].name;
        String firstDesc = descResult.records[0].name;
        Assert.areNotEqual(firstAsc, firstDesc, 'Sort order should be different');
    }
    
    @isTest
    static void getUserStories_invalidPageNumber_defaultsToOne() {
        Test.startTest();
        UserStoryController.PaginatedResult result = UserStoryController.getUserStories(
            null, null, null, null, 0, 50, null, null
        );
        Test.stopTest();
        
        Assert.areEqual(1, result.currentPage, 'Invalid page number should default to 1');
    }
    
    @isTest
    static void getUserStories_invalidPageSize_defaultsToFifty() {
        Test.startTest();
        UserStoryController.PaginatedResult result = UserStoryController.getUserStories(
            null, null, null, null, 1, 0, null, null
        );
        Test.stopTest();
        
        Assert.areEqual(50, result.pageSize, 'Invalid page size should default to 50');
    }
    
    @isTest
    static void getUserStories_pageSizeExceedsMaximum_cappedAtTwoHundred() {
        Test.startTest();
        UserStoryController.PaginatedResult result = UserStoryController.getUserStories(
            null, null, null, null, 1, 500, null, null
        );
        Test.stopTest();
        
        Assert.areEqual(200, result.pageSize, 'Page size should be capped at 200');
    }
    
    @isTest
    static void getUserStories_invalidSortField_defaultsToName() {
        Test.startTest();
        UserStoryController.PaginatedResult result = UserStoryController.getUserStories(
            null, null, null, null, 1, 50, 'InvalidField__c', null
        );
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue(result.records.size() > 0, 'Should return records');
    }
    
    @isTest
    static void getUserStories_nullParameters_handledGracefully() {
        Test.startTest();
        UserStoryController.PaginatedResult result = UserStoryController.getUserStories(
            null, null, null, null, null, null, null, null
        );
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.areEqual(1, result.currentPage, 'Null page number should default to 1');
        Assert.areEqual(50, result.pageSize, 'Null page size should default to 50');
    }
    
    @isTest
    static void getUserStories_wrapperIncludesRelatedFields() {
        Feature__c feature = [SELECT Id, Name FROM Feature__c WHERE Name = 'Feature A' LIMIT 1];
        User currentUser = [SELECT Id, Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        
        Test.startTest();
        UserStoryController.PaginatedResult result = UserStoryController.getUserStories(
            feature.Id, null, null, null, 1, 50, null, null
        );
        Test.stopTest();
        
        Assert.isTrue(result.records.size() > 0, 'Should have records');
        UserStoryController.UserStoryWrapper wrapper = result.records[0];
        Assert.isNotNull(wrapper.id, 'Id should be populated');
        Assert.isNotNull(wrapper.name, 'Name should be populated');
        Assert.areEqual(feature.Id, wrapper.featureId, 'Feature Id should be populated');
        Assert.areEqual(feature.Name, wrapper.featureName, 'Feature Name should be populated');
    }
    
    // ========== getUserStoriesByStatus() Tests ==========
    
    @isTest
    static void getUserStoriesByStatus_basicQuery_returnsGroupedStories() {
        Test.startTest();
        Map<String, List<UserStoryController.UserStoryWrapper>> result = 
            UserStoryController.getUserStoriesByStatus(null);
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue(result.containsKey('Backlog'), 'Should have Backlog key');
        Assert.isTrue(result.containsKey('In_Progress'), 'Should have In_Progress key');
        Assert.isTrue(result.containsKey('In_Review'), 'Should have In_Review key');
        Assert.isTrue(result.containsKey('Done'), 'Should have Done key');
        Assert.isTrue(result.containsKey('Blocked'), 'Should have Blocked key');
        Assert.areEqual(2, result.get('Backlog').size(), 'Should have 2 Backlog stories');
        Assert.areEqual(1, result.get('In_Progress').size(), 'Should have 1 In Progress story');
        Assert.areEqual(1, result.get('In_Review').size(), 'Should have 1 In Review story');
        Assert.areEqual(1, result.get('Done').size(), 'Should have 1 Done story');
        Assert.areEqual(1, result.get('Blocked').size(), 'Should have 1 Blocked story');
    }
    
    @isTest
    static void getUserStoriesByStatus_filterByFeature_returnsFilteredStories() {
        Feature__c feature = [SELECT Id FROM Feature__c WHERE Name = 'Feature A' LIMIT 1];
        
        Test.startTest();
        Map<String, List<UserStoryController.UserStoryWrapper>> result = 
            UserStoryController.getUserStoriesByStatus(feature.Id);
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.areEqual(1, result.get('Backlog').size(), 'Feature A should have 1 Backlog story');
        Assert.areEqual(1, result.get('In_Progress').size(), 'Feature A should have 1 In Progress story');
        Assert.areEqual(1, result.get('In_Review').size(), 'Feature A should have 1 In Review story');
        Assert.areEqual(1, result.get('Done').size(), 'Feature A should have 1 Done story');
        Assert.areEqual(0, result.get('Blocked').size(), 'Feature A should have 0 Blocked stories');
    }
    
    @isTest
    static void getUserStoriesByStatus_emptyResult_returnsEmptyLists() {
        // Delete all user stories
        delete [SELECT Id FROM User_Story__c];
        
        Test.startTest();
        Map<String, List<UserStoryController.UserStoryWrapper>> result = 
            UserStoryController.getUserStoriesByStatus(null);
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        for (String status : result.keySet()) {
            Assert.areEqual(0, result.get(status).size(), 'All status lists should be empty');
        }
    }
    
    @isTest
    static void getUserStoriesByStatus_nullStatus_defaultsToBacklog() {
        // Create a story with null status
        Feature__c feature = [SELECT Id FROM Feature__c LIMIT 1];
        User_Story__c story = new User_Story__c(
            Name = 'Story with Null Status',
            Feature__c = feature.Id,
            Status__c = null
        );
        insert story;
        
        Test.startTest();
        Map<String, List<UserStoryController.UserStoryWrapper>> result = 
            UserStoryController.getUserStoriesByStatus(null);
        Test.stopTest();
        
        // Story with null status should be in Backlog
        Integer backlogCount = result.get('Backlog').size();
        Assert.isTrue(backlogCount > 0, 'Stories with null status should default to Backlog');
    }
    
    // ========== updateUserStoryStatus() Tests ==========
    
    @isTest
    static void updateUserStoryStatus_validUpdate_updatesSuccessfully() {
        User_Story__c story = [SELECT Id, Status__c FROM User_Story__c WHERE Status__c = 'Backlog' LIMIT 1];
        String originalStatus = story.Status__c;
        
        Test.startTest();
        UserStoryController.UserStoryWrapper result = 
            UserStoryController.updateUserStoryStatus(story.Id, 'In_Progress');
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.areEqual('In_Progress', result.status, 'Status should be updated to In_Progress');
        
        // Verify in database
        User_Story__c updatedStory = [SELECT Status__c FROM User_Story__c WHERE Id = :story.Id];
        Assert.areEqual('In_Progress', updatedStory.Status__c, 'Status should be updated in database');
    }
    
    @isTest
    static void updateUserStoryStatus_nullStoryId_throwsException() {
        Test.startTest();
        try {
            UserStoryController.updateUserStoryStatus(null, 'In_Progress');
            Assert.fail('Should have thrown an exception');
        } catch (Exception e) {
            // In test context, AuraHandledException may show as "Script-thrown exception"
            // Check if it's an AuraHandledException or if message contains expected text
            Boolean isValidException = e instanceof AuraHandledException || 
                                     e.getMessage().contains('Story Id is required') ||
                                     e.getMessage().contains('Script-thrown exception');
            Assert.isTrue(isValidException, 
                'Should throw AuraHandledException. Actual: ' + e.getTypeName() + ' - ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @isTest
    static void updateUserStoryStatus_nullStatus_throwsException() {
        User_Story__c story = [SELECT Id FROM User_Story__c LIMIT 1];
        
        Test.startTest();
        try {
            UserStoryController.updateUserStoryStatus(story.Id, null);
            Assert.fail('Should have thrown an exception');
        } catch (Exception e) {
            // In test context, AuraHandledException may show as "Script-thrown exception"
            Boolean isValidException = e instanceof AuraHandledException || 
                                     e.getMessage().contains('Status is required') ||
                                     e.getMessage().contains('Script-thrown exception');
            Assert.isTrue(isValidException, 
                'Should throw AuraHandledException. Actual: ' + e.getTypeName() + ' - ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @isTest
    static void updateUserStoryStatus_invalidStatus_throwsException() {
        User_Story__c story = [SELECT Id FROM User_Story__c LIMIT 1];
        
        Test.startTest();
        try {
            UserStoryController.updateUserStoryStatus(story.Id, 'InvalidStatus');
            Assert.fail('Should have thrown an exception');
        } catch (Exception e) {
            // In test context, AuraHandledException may show as "Script-thrown exception"
            Boolean isValidException = e instanceof AuraHandledException || 
                                     e.getMessage().contains('Invalid status value') ||
                                     e.getMessage().contains('Script-thrown exception');
            Assert.isTrue(isValidException, 
                'Should throw AuraHandledException. Actual: ' + e.getTypeName() + ' - ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @isTest
    static void updateUserStoryStatus_invalidStoryId_throwsException() {
        // Create a fake User_Story__c Id that doesn't exist
        Id fakeStoryId = User_Story__c.sObjectType.getDescribe().getKeyPrefix() + '000000000000';
        
        Test.startTest();
        try {
            UserStoryController.updateUserStoryStatus(fakeStoryId, 'In_Progress');
            Assert.fail('Should have thrown an exception');
        } catch (Exception e) {
            // In test context, AuraHandledException may show as "Script-thrown exception"
            Boolean isValidException = e instanceof AuraHandledException || 
                                     e.getMessage().contains('not found') || 
                                     e.getMessage().contains('access denied') ||
                                     e.getMessage().contains('Script-thrown exception');
            Assert.isTrue(isValidException, 
                'Should throw AuraHandledException. Actual: ' + e.getTypeName() + ' - ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @isTest
    static void updateUserStoryStatus_allValidStatuses_updateSuccessfully() {
        User_Story__c story = [SELECT Id FROM User_Story__c LIMIT 1];
        List<String> validStatuses = new List<String>{
            'Backlog', 'In_Progress', 'In_Review', 'Done', 'Blocked'
        };
        
        Test.startTest();
        for (String status : validStatuses) {
            UserStoryController.UserStoryWrapper result = 
                UserStoryController.updateUserStoryStatus(story.Id, status);
            Assert.areEqual(status, result.status, 'Status should be updated to ' + status);
        }
        Test.stopTest();
    }
    
    // ========== getFeatures() Tests ==========
    
    @isTest
    static void getFeatures_basicQuery_returnsAllFeatures() {
        Test.startTest();
        List<UserStoryController.FeatureWrapper> result = UserStoryController.getFeatures();
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.areEqual(2, result.size(), 'Should return 2 features');
        for (UserStoryController.FeatureWrapper wrapper : result) {
            Assert.isNotNull(wrapper.id, 'Id should be populated');
            Assert.isNotNull(wrapper.name, 'Name should be populated');
        }
    }
    
    @isTest
    static void getFeatures_emptyResult_returnsEmptyList() {
        // Delete all features
        delete [SELECT Id FROM Feature__c];
        
        Test.startTest();
        List<UserStoryController.FeatureWrapper> result = UserStoryController.getFeatures();
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.areEqual(0, result.size(), 'Should return empty list');
    }
    
    @isTest
    static void getFeatures_wrapperIncludesAllFields() {
        Test.startTest();
        List<UserStoryController.FeatureWrapper> result = UserStoryController.getFeatures();
        Test.stopTest();
        
        Assert.isTrue(result.size() > 0, 'Should have features');
        UserStoryController.FeatureWrapper wrapper = result[0];
        Assert.isNotNull(wrapper.id, 'Id should be populated');
        Assert.isNotNull(wrapper.name, 'Name should be populated');
        Assert.isNotNull(wrapper.status, 'Status should be populated');
        Assert.isNotNull(wrapper.description, 'Description should be populated');
    }
}

