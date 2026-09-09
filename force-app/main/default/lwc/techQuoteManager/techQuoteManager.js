import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';

export default class TechQuoteManager extends LightningElement {
    @api recordId;
    @track viewMode = 'list'; // 'list', '360' o 'quoteDirect'
    @track selectedRecordId = null;
    @track directQuoteId = null;
    @track directOppId = null;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference && currentPageReference.state) {
            const urlQuoteId = currentPageReference.state.c__quoteId;
            const urlRecordId = currentPageReference.state.c__recordId;
            if (urlQuoteId && this.directQuoteId !== urlQuoteId) {
                this.directQuoteId = urlQuoteId;
                this.directOppId = currentPageReference.state.c__oppId;
                this.viewMode = 'quoteDirect';
            } else if (urlRecordId && this.selectedRecordId !== urlRecordId) {
                this.selectedRecordId = urlRecordId;
                this.viewMode = '360';
            }
        }
    }

    // Al iniciar, si ya viene un recordId (ej: en una Record Page), ir directo al 360
    connectedCallback() {
        if (this.recordId) {
            this.selectedRecordId = this.recordId;
            this.viewMode = '360';
        }
    }

    // --- NAVEGACIÓN PREMIUM ---
    
    // Al seleccionar una oportunidad desde la lista
    handleSelectOpportunity(event) {
        this.selectedRecordId = event.detail;
        this.viewMode = '360';
    }

    // Al presionar el botón de volver al listado
    handleShowList() {
        this.selectedRecordId = null;
        this.directQuoteId = null;
        this.directOppId = null;
        this.viewMode = 'list';
    }

    // Getters para renderizado condicional
    get isListView() {
        return this.viewMode === 'list';
    }

    get is360View() {
        return this.viewMode === '360';
    }

    get isQuoteDirectView() {
        return this.viewMode === 'quoteDirect';
    }
}