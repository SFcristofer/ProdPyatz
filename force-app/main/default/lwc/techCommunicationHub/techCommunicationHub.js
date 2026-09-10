import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import STAGE_FIELD from '@salesforce/schema/Opportunity.StageName';
import SUBETAPA_FIELD from '@salesforce/schema/Opportunity.Subetapa__c';
import getEmailTemplatesByFolders from '@salesforce/apex/CommunicationController.getEmailTemplatesByFolders';
import getAvailableAttachments from '@salesforce/apex/CommunicationController.getAvailableAttachments';
import sendEmailWithAttachments from '@salesforce/apex/CommunicationController.sendEmailWithAttachments';
import renderTemplate from '@salesforce/apex/CommunicationController.renderTemplate';
import getEmailEngagementDetails from '@salesforce/apex/CommunicationController.getEmailEngagementDetails';
import getContactsFromLatestQuoteSedes from '@salesforce/apex/CommunicationController.getContactsFromLatestQuoteSedes';
import getInternalTeam from '@salesforce/apex/CommunicationController.getInternalTeam';
import searchInternalUsers from '@salesforce/apex/CommunicationController.searchInternalUsers';
import getPyatzQueues from '@salesforce/apex/CommunicationController.getPyatzQueues';
import sendInternalEmail from '@salesforce/apex/CommunicationController.sendInternalEmail';
import { refreshApex } from '@salesforce/apex';

export default class TechCommunicationHub extends NavigationMixin(LightningElement) {
    @api recordId; // Opportunity ID
    @api folderName; // Nombre de la carpeta de plantillas a filtrar (opcional)

    @track selectedFolder = '';
    @track selectedTemplateId = '';
    @track templates = [];
    @track availableAttachments = { quotes: [], surveys: [], files: [], fichas: [] };
    @track selectedAttachments = [];
    @track sedeContacts = [];
    @track internalContacts = [];
    
    @track attSections = {
        quotes: true,
        surveys: true,
        files: true,
        fichas: true
    };

    toggleAttSection(event) {
        const sec = event.currentTarget.dataset.sec;
        this.attSections[sec] = !this.attSections[sec];
    }
    
    get iconQuotes() { return this.attSections.quotes ? 'utility:chevrondown' : 'utility:chevronright'; }
    get iconSurveys() { return this.attSections.surveys ? 'utility:chevrondown' : 'utility:chevronright'; }
    get iconFiles() { return this.attSections.files ? 'utility:chevrondown' : 'utility:chevronright'; }
    get iconFichas() { return this.attSections.fichas ? 'utility:chevrondown' : 'utility:chevronright'; }

    @track toEmail = '';
    @track ccEmail = '';
    @track bccEmail = '';
    @track subject = '';
    @track emailBody = '';
    @track isLoadingTemplates = false;
    @track isLoadingAttachments = false;
    @track isSending = false;
    
    @track currentSubetapa = '';
    @track currentStage = '';

    // Internal Mode Properties
    @track pyatzQueues = [];
    @track selectedQueueIds = [];
    @track selectedUserPills = [];
    @track userSearchTerm = '';
    @track userSearchResults = [];

    get isInternalMode() {
        return this.folderName === 'Enhorabuena';
    }

    get acceptedFormats() {
        return ['.pdf', '.png', '.jpg', '.jpeg', '.docx', '.xlsx', '.csv'];
    }

    handleUploadFinished(event) {
        // Los archivos han sido cargados al registro actual (Opportunity)
        const uploadedFiles = event.detail.files;
        
        let fileNames = uploadedFiles.map(file => file.name).join(', ');
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Éxito',
                message: uploadedFiles.length + ' archivo(s) subido(s) correctamente: ' + fileNames,
                variant: 'success',
            }),
        );
        
        // Refrescar la lista de adjuntos disponibles para el correo
        this.loadAttachments();
    }

    @wire(getRecord, { recordId: '$recordId', fields: [STAGE_FIELD, SUBETAPA_FIELD] })
    wiredOpp({ error, data }) {
        if (data) {
            this.currentStage = getFieldValue(data, STAGE_FIELD) || '';
            this.currentSubetapa = getFieldValue(data, SUBETAPA_FIELD) || '';
        } else if (error) {
            console.error('Error fetching opp stage:', error);
        }
    }

    get showInternalTeam() {
        const stageStr = this.currentStage ? this.currentStage.toLowerCase() : '';
        const subStr = this.currentSubetapa ? this.currentSubetapa.toLowerCase() : '';
        // Mostramos el equipo interno solo si la etapa/subetapa incluye enhorabuena o ganada
        return stageStr.includes('enhorabuena') || subStr.includes('enhorabuena') || stageStr.includes('cerrada ganada') || stageStr.includes('closed won');
    }

    // --- ESTADO DE ENGAGEMENT ---
    @track showEngagementModal = false;
    @track isLoadingEngagement = false;
    @track engagementDetails = [];

    connectedCallback() {
        // Si se recibe una carpeta específica, la seleccionamos por defecto
        if (this.folderName) {
            this.selectedFolder = this.folderName;
        }
    }

    handleShowEngagement() {
        this.showEngagementModal = true;
        this.loadEngagementHistory();
    }

    handleCloseEngagement() {
        this.showEngagementModal = false;
    }

    loadEngagementHistory() {
        this.isLoadingEngagement = true;
        getEmailEngagementDetails({ oppId: this.recordId })
            .then(result => {
                // Procesamos para añadir iconos dinámicos
                this.engagementDetails = result.map(email => ({
                    ...email,
                    iconName: email.isOpened ? 'standard:task2' : 'standard:email',
                    iconVariant: email.isOpened ? 'success' : '',
                    recipients: email.recipients.map(r => ({
                        ...r,
                        icon: r.type === 'Principal' ? 'standard:contact' : 'standard:groups'
                    }))
                }));
                this.isLoadingEngagement = false;
            })
            .catch(error => {
                console.error('Error loading engagement:', error);
                this.isLoadingEngagement = false;
            });
    }

    // --- MANEJADORES DE ACTIVIDAD NATIVA ---
    handleLogCall() {
        this.navigateToGlobalAction('LogACall');
    }

    handleNewTask() {
        this.navigateToGlobalAction('NewTask');
    }

    handleNewEvent() {
        this.navigateToGlobalAction('NewEvent');
    }

    navigateToGlobalAction(actionName) {
        // Navegación nativa autorizada por Salesforce para evitar errores de CSP
        this[NavigationMixin.Navigate]({
            type: 'standard__quickAction',
            attributes: {
                apiName: `Global.${actionName}`
            },
            state: {
                recordId: this.recordId,
                contextId: this.recordId,
                defaultFieldValues: `WhatId=${this.recordId}`
            }
        });
    }

    get folderOptions() {
        if (this.folderName) {
            return [{ label: this.folderName, value: this.folderName }];
        }
        return [
            { label: 'Pyatz - CORREOS A CLIENTES', value: 'Pyatz-CORREOS A CLIENTES' },
            { label: 'Pyatz - CORREOS INTERNOS', value: 'Pyatz-CORREOS INTERNOS' }
        ];
    }

    @wire(getEmailTemplatesByFolders, { folderNames: '$computedFolderNames' })
    wiredTemplates({ error, data }) {
        if (data) {
            this.templates = data;
        } else if (error) {
            console.error('Error loading templates:', error);
        }
    }

    get computedFolderNames() {
        return this.folderName ? [this.folderName] : ['Pyatz-CORREOS A CLIENTES', 'Pyatz-CORREOS INTERNOS'];
    }

    wiredAttachmentsResult;

    @wire(getAvailableAttachments, { oppId: '$recordId' })
    wiredAttachments(result) {
        this.wiredAttachmentsResult = result;
        this.isLoadingAttachments = true;
        if (result.data) {
            this.availableAttachments = result.data;
            this.isLoadingAttachments = false;
        } else if (result.error) {
            console.error('Error loading attachments:', result.error);
            this.isLoadingAttachments = false;
        }
    }

    loadAttachments() {
        if (this.wiredAttachmentsResult) {
            this.isLoadingAttachments = true;
            refreshApex(this.wiredAttachmentsResult).finally(() => {
                this.isLoadingAttachments = false;
            });
        }
    }

    @wire(getContactsFromLatestQuoteSedes, { oppId: '$recordId' })
    wiredSedeContacts({ error, data }) {
        if (data) {
            let preselectedEmails = [];
            this.sedeContacts = data.map(con => {
                let isSelected = (con.selected === 'true');
                if (isSelected && con.email) {
                    preselectedEmails.push(con.email);
                }
                return { ...con, isChecked: isSelected };
            });
            
            if (preselectedEmails.length > 0) {
                let currentEmails = this.toEmail ? this.toEmail.split(',').map(e => e.trim()).filter(e => e) : [];
                preselectedEmails.forEach(email => {
                    if (!currentEmails.includes(email)) {
                        currentEmails.push(email);
                    }
                });
                this.toEmail = currentEmails.join(', ');
            }
        } else if (error) {
            console.error('Error loading sede contacts:', error);
        }
    }

    @wire(getInternalTeam, { oppId: '$recordId' })
    wiredInternalTeam({ error, data }) {
        if (data) {
            this.internalContacts = data;
        } else if (error) {
            console.error('Error loading internal team:', error);
        }
    }

    @wire(getPyatzQueues)
    wiredQueues({ error, data }) {
        if (data) {
            this.pyatzQueues = data;
        } else if (error) {
            console.error('Error loading queues:', error);
        }
    }

    handleUserSearchChange(event) {
        this.userSearchTerm = event.target.value;
        if (this.userSearchTerm.length >= 2) {
            searchInternalUsers({ searchTerm: this.userSearchTerm })
                .then(result => {
                    this.userSearchResults = result;
                })
                .catch(error => {
                    console.error('Error searching users', error);
                });
        } else {
            this.userSearchResults = [];
        }
    }

    handleSelectUser(event) {
        const userId = event.currentTarget.dataset.id;
        const userName = event.currentTarget.dataset.name;
        
        if (!this.selectedUserPills.some(p => p.id === userId)) {
            this.selectedUserPills = [...this.selectedUserPills, { id: userId, label: userName, name: userId }];
        }
        
        this.userSearchTerm = '';
        this.userSearchResults = [];
    }

    handleRemoveUserPill(event) {
        const userId = event.detail.item.name;
        this.selectedUserPills = this.selectedUserPills.filter(p => p.id !== userId);
    }

    handleQueueToggle(event) {
        const queueId = event.target.dataset.id;
        const checked = event.target.checked;
        if (checked) {
            if (!this.selectedQueueIds.includes(queueId)) this.selectedQueueIds.push(queueId);
        } else {
            this.selectedQueueIds = this.selectedQueueIds.filter(id => id !== queueId);
        }
    }

    handleQuickAddContact(event) {
        const email = event.target.dataset.email;
        const checked = event.target.checked;
        let currentEmails = this.toEmail ? this.toEmail.split(',').map(e => e.trim()).filter(e => e) : [];
        if (checked) {
            if (!currentEmails.includes(email)) currentEmails.push(email);
        } else {
            currentEmails = currentEmails.filter(e => e !== email);
        }
        this.toEmail = currentEmails.join(', ');
    }

    get filteredTemplates() {
        if (!this.selectedFolder) return [];
        return this.templates
            .filter(t => t.folder === this.selectedFolder)
            .map(t => ({ label: t.name, value: t.id }));
    }

    get isTemplateDisabled() {
        return !this.selectedFolder;
    }

    get isSendDisabled() {
        if (this.isInternalMode) {
            return (!this.selectedUserPills.length && !this.selectedQueueIds.length) || !this.subject || this.isSending;
        }
        return !this.toEmail || !this.subject || this.isSending;
    }

    handleFolderChange(event) {
        this.selectedFolder = event.detail.value;
        this.selectedTemplateId = '';
    }

    handleTemplateChange(event) {
        this.selectedTemplateId = event.detail.value;
        this.loadTemplateContent();
    }

    async loadTemplateContent() {
        if (!this.selectedTemplateId) return;
        
        try {
            // Buscamos el contexto de ID (Preferimos una Quote para que las variables de la plantilla se llenen)
            let contextId = this.recordId;
            const selectedQuotes = this.selectedAttachments.filter(a => a.type === 'Quote');
            
            if (selectedQuotes.length > 0) {
                contextId = selectedQuotes[0].id;
            } else if (this.availableAttachments.quotes && this.availableAttachments.quotes.length > 0) {
                // Si no hay seleccionada, usamos la primera disponible por defecto para el renderizado
                contextId = this.availableAttachments.quotes[0].id;
            }

            const content = await renderTemplate({ 
                templateId: this.selectedTemplateId, 
                quoteId: contextId 
            });
            this.emailBody = content;
            this._currentDraftBody = ''; // Resetear el borrador para que tome la nueva plantilla
            
            // Actualizar asunto automáticamente si la plantilla lo tiene o usar el nombre de la plantilla
            const tpl = this.templates.find(t => t.id === this.selectedTemplateId);
            if (tpl) this.subject = tpl.name;
            
        } catch (error) {
            console.error('Error rendering template:', error);
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error al cargar plantilla',
                message: 'No se pudo procesar la plantilla. Verifique que la oportunidad tenga al menos un presupuesto.',
                variant: 'warning'
            }));
        }
    }

    handleAttachmentToggle(event) {
        const attId = event.target.dataset.id;
        const type = event.target.dataset.type;
        const name = event.target.label;
        const checked = event.target.checked;

        if (checked) {
            this.selectedAttachments.push({ id: attId, type: type, name: name });
        } else {
            this.selectedAttachments = this.selectedAttachments.filter(a => a.id !== attId || a.type !== type);
        }
    }

    handleEmailChange(event) { this.toEmail = event.detail.value; }
    handleCcChange(event) { this.ccEmail = event.detail.value; }
    handleBccChange(event) { this.bccEmail = event.detail.value; }
    handleSubjectChange(event) { this.subject = event.detail.value; }
    // Almacena el cuerpo sin causar un re-render continuo
    _currentDraftBody = '';

    handleBodyChange(event) { 
        this._currentDraftBody = event.detail.value; 
    }

    handleSendEmail() {
        this.isSending = true;
        const finalBody = this._currentDraftBody || this.emailBody;

        if (this.isInternalMode) {
            const userIds = this.selectedUserPills.map(p => p.id);
            sendInternalEmail({
                oppId: this.recordId,
                toEmail: this.toEmail,
                ccEmail: this.ccEmail,
                bccEmail: this.bccEmail,
                subject: this.subject,
                body: finalBody,
                queueIds: this.selectedQueueIds,
                userIds: userIds,
                selectedAttachments: this.selectedAttachments
            })
            .then(() => { this.handleSendSuccess(); })
            .catch(error => { this.handleSendError(error); });
        } else {
            sendEmailWithAttachments({
                oppId: this.recordId,
                toEmail: this.toEmail,
                ccEmail: this.ccEmail,
                subject: this.subject,
                body: finalBody,
                selectedAttachments: this.selectedAttachments
            })
            .then(() => { this.handleSendSuccess(); })
            .catch(error => { this.handleSendError(error); });
        }
    }

    handleSendSuccess() {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Éxito',
            message: 'Correo enviado correctamente y registrado en la actividad.',
            variant: 'success'
        }));
        this.isSending = false;
        
        this.clearForm();

        this.dispatchEvent(new CustomEvent('fasesuccess', {
            detail: { phase: 'Negociación' }
        }));
    }

    handleSendError(error) {
        this.isSending = false;
        console.error('Error enviando:', error);
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message: error.body ? error.body.message : error.message,
            variant: 'error'
        }));
    }

    clearForm() {
        this.toEmail = '';
        this.ccEmail = '';
        this.bccEmail = '';
        this.subject = '';
        this.emailBody = '';
        this.selectedAttachments = [];
        this.selectedTemplateId = '';
        this.selectedFolder = '';
        this.selectedUserPills = [];
        this.selectedQueueIds = [];
        this.userSearchTerm = '';
        this.userSearchResults = [];
        
        // Desmarcar checkboxes de adjuntos en el DOM
        const checkboxes = this.template.querySelectorAll('lightning-input[data-type]');
        checkboxes.forEach(cb => {
            cb.checked = false;
        });

        // Desmarcar contactos
        const contactChecks = this.template.querySelectorAll('lightning-input[data-email]');
        contactChecks.forEach(cb => {
            cb.checked = false;
        });
    }
}