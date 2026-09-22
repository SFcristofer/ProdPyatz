@isTest
private class OperationsControllerTest {

    @TestSetup
    static void makeData() {
        Account acc = new Account(Name = 'OpsCtrl Account');
        insert acc;
        Opportunity opp = new Opportunity(
            Name = 'OpsCtrl Opp', AccountId = acc.Id,
            StageName = 'Prospecting', CloseDate = Date.today().addDays(30)
        );
        insert opp;
    }

    @isTest
    static void testGetOpportunitiesList() {
        Test.startTest();
        List<Map<String, Object>> result = OperationsController.getOpportunitiesList('');
        Test.stopTest();
        System.assert(result.size() >= 1);
    }

    @isTest
    static void testGetOpportunitiesByAccount() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        List<Map<String, Object>> result = OperationsController.getOpportunitiesByAccount(acc.Id);
        Test.stopTest();
        System.assertEquals(1, result.size());
    }

    @isTest
    static void testGetChecklist() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        List<Map<String, Object>> result = OperationsController.getChecklist(opp.Id, 'General');
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetEvidenceGallery() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        List<Map<String, Object>> result = OperationsController.getEvidenceGallery(opp.Id);
        Test.stopTest();
        System.assertEquals(0, result.size());
    }

    @isTest
    static void testGetCalendarData() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        Map<String, Object> result = OperationsController.getCalendarData(
            opp.Id,
            String.valueOf(Date.today().addDays(-1)),
            String.valueOf(Date.today().addDays(7))
        );
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetTacticalHistory() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        List<Map<String, Object>> result = OperationsController.getTacticalHistory(opp.Id);
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testUpdateTaskActivity() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Task t = new Task(Subject = 'Test', WhatId = opp.Id, Status = 'Open');
        insert t;
        Test.startTest();
        OperationsController.updateTaskActivity(t.Id, 'Completed', 'Done');
        Test.stopTest();
        Task updated = [SELECT Status FROM Task WHERE Id = :t.Id];
        System.assertEquals('Completed', updated.Status);
    }

    @isTest
    static void testSaveStageTracking() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        OperationsController.saveStageTracking(opp.Id, 'StageA', 'SubA', 'Ok');
        Test.stopTest();
        List<Seguimiento_Etapas_Pyatz__c> items = [SELECT Id FROM Seguimiento_Etapas_Pyatz__c WHERE Oportunidad__c = :opp.Id];
        System.assertEquals(1, items.size());
    }

    @isTest
    static void testGetActionTimeline() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        List<Map<String, Object>> result = OperationsController.getActionTimeline(opp.Id);
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetProcessHistory() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        List<Seguimiento_Etapas_Pyatz__c> result = OperationsController.getProcessHistory(opp.Id);
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testSaveNote() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        Id noteId = OperationsController.saveNote(opp.Id, 'Title', 'Content');
        Test.stopTest();
        System.assertNotEquals(null, noteId);
    }

    @isTest
    static void testGetOpenOpportunities() {
        Test.startTest();
        List<Map<String, String>> result = OperationsController.getOpenOpportunities();
        Test.stopTest();
        System.assert(result.size() >= 1);
    }

    @isTest
    static void testRenameUploadedFile() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        ContentVersion cv = new ContentVersion(
            Title = 'rename_me.pdf', PathOnClient = 'rename_me.pdf',
            VersionData = Blob.valueOf('data'), IsMajorVersion = true
        );
        insert cv;
        Id docId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        insert new ContentDocumentLink(ContentDocumentId = docId, LinkedEntityId = opp.Id, ShareType = 'V', Visibility = 'AllUsers');
        Test.startTest();
        OperationsController.renameUploadedFile(docId, 'CL_DOC');
        Test.stopTest();
        ContentDocument doc = [SELECT Title FROM ContentDocument WHERE Id = :docId];
        System.assert(doc.Title.contains('[CL_DOC]'));
    }

    @isTest
    static void testCloneOpportunity() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Product2 prod = new Product2(Name = 'Test Prod', IsActive = true);
        insert prod;
        PricebookEntry pbe = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = prod.Id, UnitPrice = 100, IsActive = true);
        insert pbe;
        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = opp.Id, PricebookEntryId = pbe.Id, Quantity = 1, UnitPrice = 100);
        insert oli;
        
        Levantamiento_Tecnico__c lev = new Levantamiento_Tecnico__c(Oportunidad__c = opp.Id, Tipo_Servicio__c = 'BIOENZIMÁTICO');
        insert lev;
        
        Quote q = new Quote(Name = 'Test Quote', OpportunityId = opp.Id, Pricebook2Id = Test.getStandardPricebookId());
        insert q;
        QuoteLineItem qli = new QuoteLineItem(QuoteId = q.Id, PricebookEntryId = pbe.Id, Quantity = 1, UnitPrice = 100);
        insert qli;
        
        Test.startTest();
        Id clonedId = OperationsController.cloneOpportunity(opp.Id);
        Test.stopTest();
        
        Opportunity clonedOpp = [SELECT Name, StageName, Subetapa__c FROM Opportunity WHERE Id = :clonedId];
        System.assert(clonedOpp.Name.contains('(Copia)'));
        
        List<OpportunityLineItem> clonedOlis = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :clonedId];
        System.assertEquals(1, clonedOlis.size());
        
        List<Levantamiento_Tecnico__c> clonedLevs = [SELECT Id FROM Levantamiento_Tecnico__c WHERE Oportunidad__c = :clonedId];
        System.assertEquals(1, clonedLevs.size());
        
        List<Quote> clonedQuotes = [SELECT Id FROM Quote WHERE OpportunityId = :clonedId];
        System.assertEquals(1, clonedQuotes.size());
        
        List<QuoteLineItem> clonedQlis = [SELECT Id FROM QuoteLineItem WHERE QuoteId = :clonedQuotes[0].Id];
        System.assertEquals(1, clonedQlis.size());
    }
}