@isTest
public class ExperienceControllerTest {
    
    @testSetup
    static void setup() {
        List<Experience__c> experiences = new List<Experience__c>{
            new Experience__c(
                Name = 'Test Experience 1',
                Type__c = 'Cultural Tours & Workshops',
                Location__c = 'Test Location 1',
                Price__c = 100.00,
                Capacity__c = 20
            ),
            new Experience__c(
                Name = 'Test Experience 2',
                Type__c = 'Nightlife & Entertainment',
                Location__c = 'Test Location 2',
                Price__c = 150.00,
                Capacity__c = 30
            ),
            new Experience__c(
                Name = 'Test Experience 3',
                Type__c = 'Adventure',
                Location__c = 'Test Location 3',
                Price__c = 200.00,
                Capacity__c = 15
            )
        };
        insert experiences;
    }

    @isTest
    static void getRecentExperiences_works() {
        Test.startTest();
        ExperienceController.PaginatedResult result = ExperienceController.getRecentExperiences(1, 5);
        Test.stopTest();

        Assert.isNotNull(result, 'Result should not be null');
        Assert.isNotNull(result.records, 'Records should not be null');
        Assert.areEqual(3, result.totalRecords, 'Should have 3 total records');
        Assert.areEqual(1, result.totalPages, 'Should have 1 page');
        Assert.areEqual(1, result.currentPage, 'Should be on page 1');
        Assert.areEqual(5, result.pageSize, 'Page size should be 5');
        Assert.areEqual(3, result.records.size(), 'Should return 3 records');
    }

    @isTest
    static void getRecentExperiences_pagination_works() {
        Test.startTest();
        ExperienceController.PaginatedResult page1 = ExperienceController.getRecentExperiences(1, 2);
        ExperienceController.PaginatedResult page2 = ExperienceController.getRecentExperiences(2, 2);
        Test.stopTest();

        Assert.areEqual(2, page1.records.size(), 'Page 1 should have 2 records');
        Assert.areEqual(1, page2.records.size(), 'Page 2 should have 1 record');
        Assert.areEqual(2, page1.totalPages, 'Should have 2 total pages');
        Assert.areEqual(2, page2.totalPages, 'Should have 2 total pages');
    }

    @isTest
    static void getRecentExperiences_invalidPageNumber_defaultsToOne() {
        Test.startTest();
        ExperienceController.PaginatedResult result = ExperienceController.getRecentExperiences(0, 5);
        Test.stopTest();

        Assert.areEqual(1, result.currentPage, 'Invalid page number should default to 1');
    }

    @isTest
    static void getRecentExperiences_invalidPageSize_defaultsToFive() {
        Test.startTest();
        ExperienceController.PaginatedResult result = ExperienceController.getRecentExperiences(1, 0);
        Test.stopTest();

        Assert.areEqual(5, result.pageSize, 'Invalid page size should default to 5');
    }

    @isTest
    static void getRecentExperiences_nullParameters_handled() {
        Test.startTest();
        ExperienceController.PaginatedResult result = ExperienceController.getRecentExperiences(null, null);
        Test.stopTest();

        Assert.isNotNull(result, 'Result should not be null');
        Assert.areEqual(1, result.currentPage, 'Null page number should default to 1');
        Assert.areEqual(5, result.pageSize, 'Null page size should default to 5');
    }
}