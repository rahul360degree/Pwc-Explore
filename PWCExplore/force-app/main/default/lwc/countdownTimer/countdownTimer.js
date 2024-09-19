/**
 * @Description       : Count down inside the circle
 * @Author            : Varun Rajpoot
 * @last modified on  : 12-18-2023
 * @last modified by  : Varun Rajpoot
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   12-07-2023   Varun Rajpoot   Initial Version
**/
import { LightningElement,api } from 'lwc';

export default class CountdownTimer extends LightningElement {
    @api timer = 0;
    timercss = 'timerCountClass';
    circlecss = 'circle';
    connectedCallback(){
        console.log(this.timer);
        this.showTimer();
    }
    StartTimerHandler(){
        const startTime = new Date()
        window.localStorage.setItem('startTimer', startTime)
        return startTime
    }
    secondToHms(d){
        d = Number(d)
        const h = Math.floor(d / 3600);
        const m = Math.floor(d % 3600 / 60);
        const s = Math.floor(d % 3600 % 60);
        const hDisplay = h > 0 ? h + (h == 1 ? " hour, " : " hours, ") : "";
        const mDisplay = m > 0 ? m + (m == 1 ? " minute, " : " minutes, ") : "";
        const sDisplay = s > 0 ? s + (s == 1 ? " second" : " seconds") : "";
        return hDisplay + mDisplay + sDisplay; 
    }

    showTimer(){
        const startTime = new Date( window.localStorage.getItem("startTimer") || this.StartTimerHandler())
        let timerRef = window.setInterval(()=>{
            this.timer = this.timer-1;            
            if(this.timer == 0){
                window.clearInterval(timerRef);
                this.timer = 'Link Expired';
                this.timercss = 'timerExpired';
                this.circlecss = '';
            }
            console.log("Timer --> " + this.timer);
        }, 1000);

    }

}