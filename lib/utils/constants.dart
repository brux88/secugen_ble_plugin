const String CHANNEL = 'com.fdxpro.secugenfplib/fingerprintReader';

const String METHOD_GET_VERSION = 'cmdGetVersion';
const String METHOD_SET_POWER_OFF_TIME_2H = 'cmdSetPowerOffTime2H';
const String METHOD_SET_VERIFY_LEVEL = 'cmdSetVerifyLevel';
const String METHOD_GET_VERIFY_LEVEL = 'cmdGetVerifyLevel';
const String METHOD_GET_HEADER = 'getHeader';
const String METHOD_MAKE_RECORD_START = "cmdMakeRecordStart";
const String METHOD_MAKE_RECORD_CONT = "cmdMakeRecordCont";
const String METHOD_MAKE_RECORD_END = "cmdMakeRecordEnd";
const String METHOD_LOAD_MATCH_TEMPLATE = "cmdLoadMatchTemplate";
const String METHOD_LOAD_MATCH_TEMPLATE_WITH_EXTRADATA =
    "cmdLoadMatchTemplateWithExtraData";
const String METHOD_GET_TEMPLATE = "cmdGetTemplate";
const String METHOD_FP_REGISTER_START = "cmdFPRegisterStart";
const String METHOD_FP_REGISTER_END = "cmdFPRegisterEnd";
const String METHOD_FP_DELETE = "cmdFPDelete";
const String METHOD_FP_VERIFY = "cmdFPVerify";
const String METHOD_FP_IDENTIFY = "cmdFPIdentify";
const String METHOD_FP_CAPTURE = "cmdFPCapture";
const String METHOD_FP_CAPTURE_USE_WSQ = "cmdFPCaptureUseWSQ";
const String METHOD_INSTANT_VERIFY = "cmdInstantVerify";
const String METHOD_INSTANT_VERIFY_WITH_EXTRADATA =
    "cmdInstantVerifyWithExtraData";
const String METHOD_SERIAL_NUMBER = "cmdGetSerialNumber";
const String METHOD_SET_SYSTEM_INFO = "cmdSetSystemInfo";
const String METHOD_SET_SYSTEM_INFO_WITH_PARAM2 = "cmdSetSystemInfoWithParam2";
const String METHOD_PARSE_RESPONSE = "parseResponse";

const String ERROR_NOT_SUPPORTED = '101';
const String ERROR_INITIALIZATION_FAILED = '102';
const String ERROR_SENSOR_NOT_FOUND = '103';
const String ERROR_SMART_CAPTURE_ENABLED = '201';
const String ERROR_OUT_OF_RANGE = '202';
const String ERROR_NO_FINGERPRINT = '301';
const String ERROR_TEMPLATE_INITIALIZE_FAILED = '302';
const String ERROR_TEMPLATE_MATCHING_FAILED = '303';
