@isTest
private class AccountDashboardControllerTest {

    @TestSetup
    static void makeData() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Pricebook2 pb = new Pricebook2(Name = 'Test PB', IsActive = true);
        insert pb;

        Opportunity opp = new Opportunity(
            Name = 'Test Opp', AccountId = acc.Id,
            StageName = 'Prospecting', CloseDate = Date.today().addDays(30),
            Pricebook2Id = pb.Id
        );
        insert opp;

        Quote q = new Quote(
            Name = 'Test Quote', OpportunityId = opp.Id,
            Pricebook2Id = pb.Id, Status = 'Pendiente'
        );
        insert q;
    }

    @isTest
    static void testGetDashboardData_empty() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        Map<String, Object> result = AccountDashboardController.getDashboardData(acc.Id);
        Test.stopTest();
        System.assertNotEquals(null, result);
        System.assertEquals(0, (Integer)result.get('woTotal'));
        System.assertEquals(1, (Integer)result.get('quoteTotal'));
        System.assertEquals(0, (Integer)result.get('scTotal'));
        
    }

    
}