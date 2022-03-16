/**
 *@author       Mats Böhler
 *@created      30.01.2020
 *
 *
 *@description  hwRequestEvaluator
 *
 *
 *@changelog    30.01.2020 Mats Böhler - Created
 *
 *
 */


export default class hwRequestEvaluator {

    static instance;
    isExecuting = false;

    constructor(){
        if(hwRequestEvaluator.instance){
            return hwRequestEvaluator.instance;
        }
        else{
            hwRequestEvaluator.instance = this;
        }
    }
}