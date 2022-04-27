/**
 *@author       Mats Böhler
 *@created      02.04.2019
 *@version      1.0
 *@since        45.0
 *
 *
 *@description  hwStammdatensammlerActionCreator
 *
 *
 *@changelog    02.04.2019 Mats Böhler - Created
 *
 *
 */

const setFieldValue = ( pv_Value, pv_Field ) => ( {
    type:  "setFieldValue",
    value: pv_Value,
    field: pv_Field
} );

const setCurrentStep = ( pv_Value ) => ( {
    type:  "setCurrentStep",
    value: pv_Value
} );

const setSteps = ( pv_Value ) => ( {
    type:  "setSteps",
    value: pv_Value
} );

const setFormulaFields = ( pv_Value, pv_Field ) => ( {
    type:  "setFormulaFields",
    value: pv_Value,
    field: pv_Field
} );

const setStepDone = ( pv_Index ) => ( {
    type:  "setStepDone",
    index: pv_Index
} );

const setWarningFalse = ( pv_Index ) => ( {
    type:  "setWarningFalse",
    index: pv_Index
} );

const setButtonDisable = ( pv_Button ) => ( {
    type:  "setButtonDisable",
    button: pv_Button
} );

const setOeffnungszeiten = ( pv_ScreenIndex, pv_SectionIndex, pv_CategoryIndex, pv_WeekdayIndex, pv_Value, pv_FieldName, pv_Weekday ) => ( {
    type:  "setOeffnungszeiten",
    screenIndex: pv_ScreenIndex,
    sectionIndex: pv_SectionIndex,
    categoryIndex: pv_CategoryIndex,
    weekdayIndex: pv_WeekdayIndex,
    value: pv_Value,
    fieldName: pv_FieldName,
    weekday: pv_Weekday
} );

const setActiveSectionsEmpty = ( pv_screenIndex ) => ( {
    type:  "setActiveSectionsEmpty",
    screenIndex: pv_screenIndex
});

const setActiveSectionsAll = ( pv_screenIndex ) => ( {
    type:  "setActiveSectionsAll",
    screenIndex: pv_screenIndex
});

export {
    setFieldValue,
    setCurrentStep,
    setSteps,
    setFormulaFields,
    setStepDone,
    setWarningFalse,
    setButtonDisable,
    setOeffnungszeiten,
    setActiveSectionsEmpty,
    setActiveSectionsAll
};