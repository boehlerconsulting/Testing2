/**
 *@author       Mats Böhler
 *@created      03.04.2019
 *@version      1.0
 *@since        45.0
 *
 *
 *@description  hwFieldInputValidator
 *
 *
 *@changelog    03.04.2019 Mats Böhler - Created
 *
 *
 */

const validateRechtsform = ( po_Field, po_InputComponent ) => {
    let isValid = false;

    return isValid;
};

const validateIban = ( po_Field, po_InputComponent ) => {

    return validateIbanValue(po_Field.isCheckbox ? po_InputComponent.checked : po_InputComponent.value);
};

function validateIbanValue(value) { // use an IIFE
    // A "constant" lookup table of IBAN lengths per country
    // (the funky formatting is just to make it fit better in the answer here on CR)

    var input = value;

    var CODE_LENGTHS = {
        AD: 24, AE: 23, AT: 20, AZ: 28, BA: 20, BE: 16, BG: 22, BH: 22, BR: 29,
        CH: 21, CR: 21, CY: 28, CZ: 24, DE: 22, DK: 18, DO: 28, EE: 20, ES: 24,
        FI: 18, FO: 18, FR: 27, GB: 22, GI: 23, GL: 18, GR: 27, GT: 28, HR: 21,
        HU: 28, IE: 22, IL: 23, IS: 26, IT: 27, JO: 30, KW: 30, KZ: 20, LB: 28,
        LI: 21, LT: 20, LU: 20, LV: 21, MC: 27, MD: 24, ME: 22, MK: 19, MR: 27,
        MT: 31, MU: 30, NL: 18, NO: 15, PK: 24, PL: 28, PS: 29, PT: 25, QA: 29,
        RO: 24, RS: 22, SA: 24, SE: 24, SI: 19, SK: 24, SM: 27, TN: 24, TR: 26
    };

    // return a function that does the actual work
    var iban = String(input).replace(/\s/g, "").toUpperCase().replace(/[^A-Z0-9]/g, ''), // keep only alphanumeric characters
        code = iban.match(/^([A-Z]{2})(\d{2})([A-Z\d]+)$/),           // match and capture (1) the country code, (2) the check digits, and (3) the rest
        digits;

    // check syntax and length
    if (!code || iban.length !== CODE_LENGTHS[code[1]]) {
        return false;
    }

    // rearrange country code and check digits, and convert chars to ints
    digits = (code[3] + code[1] + code[2]).replace(/[A-Z]/g, function (letter) {
        return letter.charCodeAt(0) - 55;
    });

    // final check
    return mod97(digits) === 1;
}


// piece-wise mod97 using 9 digit "chunks", as per Wikipedia's example:
// http://en.wikipedia.org/wiki/International_Bank_Account_Number#Modulo_operation_on_IBAN
function mod97(string) {
    var checksum = string.slice(0, 2),
        fragment;

    for (var offset = 2; offset < string.length; offset += 7) {
        fragment = String(checksum) + string.substring(offset, offset + 7);
        checksum = parseInt(fragment, 10) % 97;
    }

    return checksum;
}

export {
    validateRechtsform,
    validateIban,
};