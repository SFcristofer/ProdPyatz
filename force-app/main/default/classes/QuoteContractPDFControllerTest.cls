@isTest
private class QuoteContractPDFControllerTest {

    @TestSetup
    static void makeData() {
        Account acc = new Account(Name = 'Contract PDF Account');
        insert acc;
        Pricebook2 pb = new Pricebook2(Id = Test.getStandardPricebookId());
        Opportunity opp = new Opportunity(
            Name = 'Contract PDF Opp', AccountId = acc.Id, Pricebook2Id = pb.Id,
            StageName = 'Prospecting', CloseDate = Date.today().addDays(30)
        );
        insert opp;
        Quote q = new Quote(
            Name = 'Contract PDF Quote', OpportunityId = opp.Id,
            Pricebook2Id = pb.Id, Status = 'Draft'
        );
        insert q;
    }

    @isTest
    static void testConstructor_basic() {
        Quote q = [SELECT Id FROM Quote LIMIT 1];
        PageReference page = Page.QuoteContractPDF;
        Test.setCurrentPage(page);
        ApexPages.currentPage().getParameters().put('id', q.Id);
        Test.startTest();
        QuoteContractPDFController ctrl = new QuoteContractPDFController(
            new ApexPages.StandardController(q)
        );
        Test.stopTest();
        System.assertNotEquals(null, ctrl.quoteRecord);
        System.assertNotEquals(null, ctrl.fechaHoy);
    }

    @isTest
    static void testConstructor_withParams() {
        Quote q = [SELECT Id FROM Quote LIMIT 1];
        PageReference page = Page.QuoteContractPDF;
        Test.setCurrentPage(page);
        ApexPages.currentPage().getParameters().put('id', q.Id);
        ApexPages.currentPage().getParameters().put('show_total', 'false');
        ApexPages.currentPage().getParameters().put('show_line_prices', 'true');
        ApexPages.currentPage().getParameters().put('clientSigner', 'Juan Test');
        Test.startTest();
        QuoteContractPDFController ctrl = new QuoteContractPDFController(
            new ApexPages.StandardController(q)
        );
        Test.stopTest();
        System.assertEquals(false, ctrl.config.get('show_total'));
        System.assertEquals('Juan Test', ctrl.firmanteCliente);
    }

    @isTest
    static void testConstructor_withCreatedByParam() {
        Quote q = [SELECT Id FROM Quote LIMIT 1];
        PageReference page = Page.QuoteContractPDF;
        Test.setCurrentPage(page);
        ApexPages.currentPage().getParameters().put('id', q.Id);
        ApexPages.currentPage().getParameters().put('createdBy', UserInfo.getUserId());
        Test.startTest();
        QuoteContractPDFController ctrl = new QuoteContractPDFController(
            new ApexPages.StandardController(q)
        );
        Test.stopTest();
        System.assertNotEquals(null, ctrl.firmanteNombre);
    }

    @isTest
    static void testConstructor_withSelectedItems() {
        Quote q = [SELECT Id FROM Quote LIMIT 1];
        Pricebook2 pb = new Pricebook2(Id = Test.getStandardPricebookId());
        Product2 prod = new Product2(Name = 'PDF Prod', IsActive = true);
        insert prod;
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pb.Id, Product2Id = prod.Id, UnitPrice = 100, IsActive = true
        );
        insert pbe;
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = q.Id, PricebookEntryId = pbe.Id, Quantity = 1, UnitPrice = 100
        );
        insert qli;

        PageReference page = Page.QuoteContractPDF;
        Test.setCurrentPage(page);
        ApexPages.currentPage().getParameters().put('id', q.Id);
        ApexPages.currentPage().getParameters().put('selectedItems', qli.Id);
        Test.startTest();
        QuoteContractPDFController ctrl = new QuoteContractPDFController(
            new ApexPages.StandardController(q)
        );
        Test.stopTest();
        System.assertNotEquals(null, ctrl.selectedLineItems);
        System.assert(ctrl.totalContrato > 0);
    }

    @isTest
    static void testGetQuoteLineItems() {
        Quote q = [SELECT Id FROM Quote LIMIT 1];
        Test.startTest();
        List<QuoteLineItem> result = QuoteContractPDFController.getQuoteLineItems(q.Id);
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testConstructor_textFormattingPlainText() {
        Account acc = new Account(Name = 'Contract PDF Account TextFmt');
        insert acc;
        Pricebook2 pb = new Pricebook2(Id = Test.getStandardPricebookId());
        Opportunity opp = new Opportunity(
            Name = 'Contract PDF Opp TextFmt', AccountId = acc.Id, Pricebook2Id = pb.Id,
            StageName = 'Prospecting', CloseDate = Date.today().addDays(30)
        );
        insert opp;
        Quote q = new Quote(
            Name = 'Contract PDF Quote TextFmt', OpportunityId = opp.Id, Pricebook2Id = pb.Id, Status = 'Draft',
            Introduction_Text__c = 'Encabezado:\nPrimera linea\nSegunda linea',
            Description = 'Parte uno - Parte dos - Parte tres',
            Show_Warranty__c = true,
            Warranty_Text__c = '<div style="color:red;">Encabezado</div><p style="margin:0;">Contenido</p><p>&nbsp;</p><ul style="padding:0;"><li style="margin:1px;">Item uno</li></ul>'
        );
        insert q;

        Product2 prod = new Product2(Name = 'PDF Prod TextFmt', IsActive = true);
        insert prod;
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pb.Id, Product2Id = prod.Id, UnitPrice = 50, IsActive = true
        );
        insert pbe;
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = q.Id, PricebookEntryId = pbe.Id, Quantity = 2, UnitPrice = 50,
            Descripcion_Detallada__c = 'Detalle simple de una sola linea'
        );
        insert qli;

        PageReference page = Page.QuoteContractPDF;
        Test.setCurrentPage(page);
        ApexPages.currentPage().getParameters().put('id', q.Id);
        Test.startTest();
        QuoteContractPDFController ctrl = new QuoteContractPDFController(
            new ApexPages.StandardController(q)
        );
        Test.stopTest();
        System.assertNotEquals(null, ctrl.quoteRecord.Introduction_Text__c);
        System.assertNotEquals(null, ctrl.quoteRecord.Warranty_Text__c);
        System.assertNotEquals(null, ctrl.selectedLineItems[0].Descripcion_Detallada__c);
    }

    @isTest
    static void testConstructor_textFormattingHtmlContent() {
        Account acc = new Account(Name = 'Contract PDF Account Html');
        insert acc;
        Pricebook2 pb = new Pricebook2(Id = Test.getStandardPricebookId());
        Opportunity opp = new Opportunity(
            Name = 'Contract PDF Opp Html', AccountId = acc.Id, Pricebook2Id = pb.Id,
            StageName = 'Prospecting', CloseDate = Date.today().addDays(30)
        );
        insert opp;
        Quote q = new Quote(
            Name = 'Contract PDF Quote Html', OpportunityId = opp.Id, Pricebook2Id = pb.Id, Status = 'Draft',
            Description = '<p>Descripcion ya en HTML</p>'
        );
        insert q;

        Product2 prod = new Product2(Name = 'PDF Prod Html', IsActive = true);
        insert prod;
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pb.Id, Product2Id = prod.Id, UnitPrice = 20, IsActive = true
        );
        insert pbe;
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = q.Id, PricebookEntryId = pbe.Id, Quantity = 1, UnitPrice = 20,
            Descripcion_Detallada__c = '<p>Detalle ya en HTML</p>'
        );
        insert qli;

        PageReference page = Page.QuoteContractPDF;
        Test.setCurrentPage(page);
        ApexPages.currentPage().getParameters().put('id', q.Id);
        Test.startTest();
        QuoteContractPDFController ctrl = new QuoteContractPDFController(
            new ApexPages.StandardController(q)
        );
        Test.stopTest();
        System.assertNotEquals(null, ctrl.quoteRecord.Description);
    }

    @isTest
    static void testConstructor_withManagerSigner() {
        Quote q = [SELECT Id FROM Quote LIMIT 1];
        PageReference page = Page.QuoteContractPDF;
        Test.setCurrentPage(page);
        ApexPages.currentPage().getParameters().put('id', q.Id);
        ApexPages.currentPage().getParameters().put('managedBy', UserInfo.getUserId());
        ApexPages.currentPage().getParameters().put('sigSource', 'manager');
        Test.startTest();
        QuoteContractPDFController ctrl = new QuoteContractPDFController(
            new ApexPages.StandardController(q)
        );
        Test.stopTest();
        System.assertNotEquals(null, ctrl.firmanteNombre);
    }

    @isTest
    static void testConstructor_withMarkersData() {
        Account acc = new Account(Name = 'Contract PDF Account Markers');
        insert acc;
        Pricebook2 pb = new Pricebook2(Id = Test.getStandardPricebookId());
        Opportunity opp = new Opportunity(
            Name = 'Contract PDF Opp Markers', AccountId = acc.Id, Pricebook2Id = pb.Id,
            StageName = 'Prospecting', CloseDate = Date.today().addDays(30)
        );
        insert opp;

        Map<String, Object> markers = new Map<String, Object>{
            'pagoTransferencia' => true,
            'pagoTarjeta' => true,
            'trabajoPuntual' => true,
            'ventaProducto' => true,
            'trabajoMantenimiento' => true,
            'observacionesPago' => 'Pago a 30 dias'
        };
        String encoded = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(markers)));

        Quote q = new Quote(
            Name = 'Contract PDF Quote Markers', OpportunityId = opp.Id, Pricebook2Id = pb.Id, Status = 'Draft',
            Markers_Data__c = encoded
        );
        insert q;

        PageReference page = Page.QuoteContractPDF;
        Test.setCurrentPage(page);
        ApexPages.currentPage().getParameters().put('id', q.Id);
        Test.startTest();
        QuoteContractPDFController ctrl = new QuoteContractPDFController(
            new ApexPages.StandardController(q)
        );
        Test.stopTest();
        System.assertEquals('Pago a 30 dias', ctrl.descripcionPago);
        System.assert(ctrl.metodoPago.contains('Transferencia'));
        System.assert(ctrl.tipoTrabajo.contains('Trabajo Puntual'));
    }

    @isTest
    static void testConstructor_withMarkersDataNoObservaciones() {
        Account acc = new Account(Name = 'Contract PDF Account MarkersNoObs');
        insert acc;
        Pricebook2 pb = new Pricebook2(Id = Test.getStandardPricebookId());
        Opportunity opp = new Opportunity(
            Name = 'Contract PDF Opp MarkersNoObs', AccountId = acc.Id, Pricebook2Id = pb.Id,
            StageName = 'Prospecting', CloseDate = Date.today().addDays(30)
        );
        insert opp;

        Map<String, Object> markers = new Map<String, Object>{
            'pagoTransferencia' => false,
            'pagoTarjeta' => false,
            'trabajoPuntual' => false,
            'ventaProducto' => false,
            'trabajoMantenimiento' => false
        };
        String encoded = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(markers)));

        Quote q = new Quote(
            Name = 'Contract PDF Quote MarkersNoObs', OpportunityId = opp.Id, Pricebook2Id = pb.Id, Status = 'Draft',
            Description = 'Descripcion de respaldo',
            Markers_Data__c = encoded
        );
        insert q;

        PageReference page = Page.QuoteContractPDF;
        Test.setCurrentPage(page);
        ApexPages.currentPage().getParameters().put('id', q.Id);
        Test.startTest();
        QuoteContractPDFController ctrl = new QuoteContractPDFController(
            new ApexPages.StandardController(q)
        );
        Test.stopTest();
        System.assertEquals('A convenir', ctrl.metodoPago);
        System.assertEquals('N/A', ctrl.tipoTrabajo);
        System.assertEquals('Descripcion de respaldo', ctrl.descripcionPago);
    }

    @isTest
    static void testConstructor_withInvalidMarkersData() {
        Account acc = new Account(Name = 'Contract PDF Account MarkersInvalid');
        insert acc;
        Pricebook2 pb = new Pricebook2(Id = Test.getStandardPricebookId());
        Opportunity opp = new Opportunity(
            Name = 'Contract PDF Opp MarkersInvalid', AccountId = acc.Id, Pricebook2Id = pb.Id,
            StageName = 'Prospecting', CloseDate = Date.today().addDays(30)
        );
        insert opp;

        Quote q = new Quote(
            Name = 'Contract PDF Quote MarkersInvalid', OpportunityId = opp.Id, Pricebook2Id = pb.Id, Status = 'Draft',
            Markers_Data__c = '###not-valid-base64###'
        );
        insert q;

        PageReference page = Page.QuoteContractPDF;
        Test.setCurrentPage(page);
        ApexPages.currentPage().getParameters().put('id', q.Id);
        Test.startTest();
        QuoteContractPDFController ctrl = new QuoteContractPDFController(
            new ApexPages.StandardController(q)
        );
        Test.stopTest();
        System.assertEquals('A convenir', ctrl.metodoPago);
        System.assertEquals('N/A', ctrl.tipoTrabajo);
    }
}