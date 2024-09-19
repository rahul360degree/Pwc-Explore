/**
 * @Description       : 
 * @Author            : Varun Rajpoot
 * @last modified on  : 10-18-2023
 * @last modified by  : Varun Rajpoot
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   09-25-2023   Varun Rajpoot   Initial Version
**/
import { LightningElement, track, api, wire } from 'lwc';
import getAccountTeamMember from '@salesforce/apex/ApplianceVisitController.getAccountTeamMember';
import getConfig from '@salesforce/apex/ApplianceVisitController.getVisitRecordConfig';
import createPJP from '@salesforce/apex/ApplianceVisitController.createPJP';
import createVisits from '@salesforce/apex/ApplianceVisitController.createVisits';
import getUserDetail from '@salesforce/apex/ApplianceVisitController.getUserDetail';

import { getObjectInfo } from "lightning/uiObjectInfoApi";
import Visit_Object from "@salesforce/schema/Dealer_Visit__c";

import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const dayNameMap = new Map([
    ['0', 'Sun'],
    ['1', "Mon"],
    ['2', "Tue"],
    ['3', "Wed"],
    ['4', "Thu"],
    ['5', "Fri"],
    ['6', "Sat"]
]);

const monthNames = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
const today = new Date();
export default class CreateAppliancesVisits extends NavigationMixin(LightningElement) {
    @track holiday = [];
    @track calendarArray = [["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]];
    error;
    config;
    accountMember;
    pjpRecord;
    showSpinner = true;
    connectedCallback() {
        this.createCalander();
    }

    @wire(getAccountTeamMember, {})
    wiredAccountTeam({ error, data }) {
        if (data) {
            this.accountMember = data;
        } else if (error) {
            this.error = error;
        }
    }

    @wire(getConfig)
    wiredConfig({ error, data }) {
        if (data) {
            this.config = data;
        } else if (error) {
            this.error = error;
        }
    }

    @wire(getUserDetail)
    userInfo;

    @wire(getObjectInfo, { objectApiName: Visit_Object })
    objectInfo;
    get recordTypeId() {
        const rtIds = this.objectInfo.data.recordTypeInfos;
        return Object.keys(rtIds).find((rti) => rtIds[rti].name === "Display Share");
    }

    get todaysDate() {
        return today.getDate();
    }

    get todaysMonth() {
        return monthNames[today.getMonth()];
    }

    createCalander() {
        const daysInMonth = this.getDaysInMonth(today);
        let weekArray = [];

        for (let monthDay = 1; monthDay <= daysInMonth; monthDay++) {
            const dayofWeek = this.getWeekDay(today, monthDay)
            weekArray[dayofWeek] = monthDay;

            if (dayofWeek >= 6 || daysInMonth == monthDay) {
                this.calendarArray.push(weekArray);
                weekArray = new Array();
            }
            if (monthDay == 1 && dayofWeek > 1) {
                for (let prevMonthDay = 0; prevMonthDay < dayofWeek; prevMonthDay++) {
                    weekArray[prevMonthDay] = ' ';
                }
            }
            if (dayofWeek == 0 || monthDay <= this.todaysDate) {
                this.addHoliday(monthDay);
            }
        }
        this.showSpinner = false;
    }

    getWeekDay(date, monthDay) {
        return new Date(date.getFullYear(), date.getMonth(), monthDay).getDay();
    }

    getDaysInMonth(date) {
        return new Date(date.getFullYear(), date.getMonth() + 1, 0).getDate();
    }
    addHoliday(monthDay) {
        this.holiday.push(monthDay);
    }
    getLastDayOfMonth() {
        return (new Date(today.getFullYear(), today.getMonth() + 1, 0, 22));
    }
    // addholdiay(event) {
    //     let holiday = event.currentTarget.dataset.id;
    // }

    handleHolidayClick(event) {
        this.holiday = event.detail.holiday;
        this.getWorkingDay();
    }

    getWorkingDay() {
        let arryCopy = [...this.calendarArray];
        arryCopy.shift();
        let workingdays = [];
        for (let a of arryCopy) {
            for (let b of a) {
                if (!this.holiday.includes(b) && b !== ' ') {
                    workingdays.push(b);
                }
            }
        }
        console.log(workingdays);
        return workingdays;
    }

    createVisits() {
        this.showSpinner = true;
        this.createPJP();
    }


    // Naming convention PJP: User Name-Area Code-Month/Year
    createPJP() {
        let pjp = {
            sobjectType: 'PJP__c',
            'Name': this.userInfo.data.Name + '-' + this.userInfo.data.Area_Code__c + '-' + (today.getMonth() + 1) + '/' + ('' + today.getFullYear()).slice(2),
            'Start_Date__c': today,
            'End_Date__c': this.getLastDayOfMonth(),
            'Business_Unit__c': 'H'

        }
        if (!this.pjpRecord) {
            createPJP({ record: pjp })
                .then(result => {
                    this.displayToast('Success', 'PJP has been created succesfully. Visit creation is in progress. Kindly wait.');

                    this.pjpRecord = result;
                    const workingDaysArray = this.getWorkingDay();
                    let temp = this.prepareVisitMap(workingDaysArray);
                    this.prepareVisitRecords(temp, workingDaysArray);
                })
                .catch(error => {
                    console.log(error);
                    this.showSpinner = false;
                    this.displayToast('Error', error.body.message);
                })
        }

    }

    prepareVisitMap(workingDaysArray) {
        let visitCounter = 0;
        const accountWithVisits = new Map();
        const accountWithName = new Map();
        for (let member of this.accountMember) {
            const key = (member.Account.RecordType.DeveloperName == 'Retailer') ? (member.TeamMemberRole + '-Retailer- ' + member.Account.Retailer_Category__c) : (member.TeamMemberRole + '-Dealer- ' + member.Account.Dealer_Category__c);
            const maxVisitAllowed = this.config[key];
            if (typeof maxVisitAllowed !== 'undefined') {
                accountWithVisits.set(member.AccountId, maxVisitAllowed);
                accountWithName.set(member.AccountId, member.Account.Name);
                if (!isNaN(maxVisitAllowed)) {
                    visitCounter = visitCounter + maxVisitAllowed;
                }
            }
        }
        const maxVisitPerDay = Math.ceil(visitCounter / workingDaysArray.length);
        //maxVisitPerDay ,map

        return ({ maxVisitPerDay, accountWithVisits, visitCounter, accountWithName });
    }

    prepareVisitRecords(visitMap, workingDaysArray) {
        let visitCreated = 0;
        let dayPostionInArray = 0;
        let dailyVisitCreatedCounter = 0;
        let date = today.getFullYear() + '-' + (today.getMonth() + 1);
        let recordArray = [];
        const recordTypeId = this.recordTypeId;

        let visitCycle = 1;
        for (let i = 0; i < visitMap.visitCounter; i = visitCreated) {

            for (let [key, value] of visitMap.accountWithVisits) {
                visitCreated++;
                let day = date + '-' + workingDaysArray[dayPostionInArray];
                // Dealer Visit Name: Account Name-Month/Year-Visit<No>
                const namePostfix = (today.getMonth() + 1) + '/' + ('' + today.getFullYear()).slice(2) + '-' + 'Visit ' + (visitCreated);
                let name = visitMap.accountWithName.get(key);
                name = name.length > 70 ? name.slice(0, 20) : name;
                name = name + '-' + namePostfix;
                recordArray.push(
                    {
                        'sobjectType': 'Dealer_Visit__c',
                        'Visit_Due_Date__c': new Date(day),
                        'Account_Information__c': key,
                        'PJP__c': this.pjpRecord.Id,
                        'RecordTypeId': recordTypeId,
                        'Name': name,
                        'View_All_Accounts__c': true
                    });
                if (visitCycle == value) {
                    visitMap.accountWithVisits.delete(key);

                } else {
                    visitMap.accountWithVisits.set(key, value++);
                }

                dailyVisitCreatedCounter++;
                if (dailyVisitCreatedCounter == visitMap.maxVisitPerDay) {
                    dayPostionInArray++;
                    dailyVisitCreatedCounter = 0;
                }
                //visitCreated++;
            }
            visitCycle++;
        }


        console.log(recordArray);
        if (recordArray) {
            createVisits({ records: recordArray })
                .then(success => {
                    console.log(success);
                    this.navigateToRecordDetail();
                    this.showSpinner = false;
                })
                .catch(error => {
                    console.log(error);
                    this.showSpinner = false;
                    this.displayToast('Error', error.body.message);
                })
        }
    }

    navigateToRecordDetail() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.pjpRecord.Id,
                objectApiName: 'PJP__c',
                actionName: 'view'
            }
        });
    }

    handleCancel() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'PJP__c',
                actionName: 'home'
            }
        });
    }
    displayToast(type, message) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: type,
                message: message,
                variant: type
            })
        );
    }
}