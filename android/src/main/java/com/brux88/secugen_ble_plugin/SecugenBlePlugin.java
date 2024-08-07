package com.brux88.secugen_ble_plugin;

import androidx.annotation.NonNull;
import android.src.main.java.com.brux88.secugen_ble_plugin.fmssdk.FMSAPI;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import android.util.Log;
import java.util.ArrayList;
import java.util.Arrays;
/** SecugenBlePlugin */
public class SecugenBlePlugin implements FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel channel;
    private final String METHOD_INIT = "initializeDevice";


  private final String METHOD_GET_VERSION = "cmdGetVersion";
  private final String METHOD_MAKE_RECORD_START = "cmdMakeRecordStart";
  private final String METHOD_MAKE_RECORD_CONT = "cmdMakeRecordCont";
  private final String METHOD_MAKE_RECORD_END = "cmdMakeRecordEnd";
  private final String METHOD_LOAD_MATCH_TEMPLATE = "cmdLoadMatchTemplate";
  private final String METHOD_LOAD_MATCH_TEMPLATE_WITH_EXTRADATA = "cmdLoadMatchTemplateWithExtraData";
  private final String METHOD_GET_TEMPLATE = "cmdGetTemplate";
  private final String METHOD_FP_REGISTER_START = "cmdFPRegisterStart";
  private final String METHOD_FP_REGISTER_END = "cmdFPRegisterEnd";
  private final String METHOD_FP_DELETE = "cmdFPDelete";
  private final String METHOD_FP_VERIFY = "cmdFPVerify";
  private final String METHOD_FP_IDENTIFY = "cmdFPIdentify";
  private final String METHOD_FP_CAPTURE = "cmdFPCapture";
  private final String METHOD_FP_CAPTURE_USE_WSQ = "cmdFPCaptureUseWSQ";
  private final String METHOD_INSTANT_VERIFY = "cmdInstantVerify";
  private final String METHOD_INSTANT_VERIFY_WITH_EXTRADATA = "cmdInstantVerifyWithExtraData";
  private final String METHOD_SERIAL_NUMBER = "cmdGetSerialNumber";
  private final String METHOD_SET_SYSTEM_INFO = "cmdSetSystemInfo";
  private final String METHOD_SET_SYSTEM_INFO_WITH_PARAM2 = "cmdSetSystemInfoWithParam2";
  private final String METHOD_PARSE_RESPONSE = "parseResponse";

  private static final String TAG = "SecuGen Lib";
   private final static String ERROR_OUT_OF_RANGE = "202";
  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "secugen_ble_plugin");
    channel.setMethodCallHandler(this);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {


    if(call.method == null || call.method.isEmpty()) {
      result.notImplemented();
      return;
    }
    switch(call.method) {
      case METHOD_GET_VERSION:
         byte[] versionBytes  = FMSAPI.cmdGetVersion();
         var i = FMSAPI.parseResponse(versionBytes);
         Log.e(TAG, "VERSION ----- " + i);
         result.success("Android " + i);
        break;
      case METHOD_MAKE_RECORD_START:
         makeRecordStart(result, (int) call.arguments);
        break;

      case METHOD_MAKE_RECORD_CONT:
         makeRecordCont(result, (int) call.arguments);
        break;

      case METHOD_MAKE_RECORD_END:
         makeRecordEnd(result);
        break;

      case METHOD_LOAD_MATCH_TEMPLATE:
         loadMatchTemplate(result, (int) call.arguments);
        break;

      case METHOD_LOAD_MATCH_TEMPLATE_WITH_EXTRADATA:
         loadMatchTemplateWithExtraData(result, call.arguments);

        break;
      case METHOD_GET_TEMPLATE:
       // handleFingerprintCapturing(result, call.arguments);
        break;

      case METHOD_FP_REGISTER_START:
       // verifyFingerPrint(result, call.arguments);
        break;

      case METHOD_FP_REGISTER_END:
      //  getMatchingScore(result, call.arguments);
        break;

        

      default:
        result.notImplemented();
        break;
    }

    /*if (call.method.equals("getPlatformVersion")) {
      result.success("Android " + android.os.Build.VERSION.RELEASE);
    } else {
      result.notImplemented();
    }*/
  }

  private void makeRecordStart(MethodChannel.Result result, int fingerNumber) {

    
    if(!(fingerNumber >= 0 && fingerNumber <= 100)) {
      result.error(ERROR_OUT_OF_RANGE, "Finger Number is out of range!", null);
      return;
    }

    FMSAPI.cmdMakeRecordStart(fingerNumber);
    Log.e(TAG, "MakeRecordStart fingerNumber----- " + fingerNumber);
    result.success("Success -- MakeRecordStart Send");

  }
  private void makeRecordCont(MethodChannel.Result result, int fingerNumber) {

    
    if(!(fingerNumber >= 0 && fingerNumber <= 100)) {
      result.error(ERROR_OUT_OF_RANGE, "Finger Number is out of range!", null);
      return;
    }

    FMSAPI.cmdMakeRecordCont(fingerNumber);
    Log.e(TAG, "makeRecordCont fingerNumber----- " + fingerNumber);
    result.success("Success -- makeRecordCont Send");

  }
  private void makeRecordEnd(MethodChannel.Result result) {

    
   
    FMSAPI.cmdMakeRecordEnd();
    Log.e(TAG, "makeRecordEnd  ----- " );
    result.success("Success -- makeRecordEnd Send");

  }

  private static String bytesToHexString(byte[] bytes){
        StringBuilder sb = new StringBuilder();
        for(byte b : bytes){
            sb.append(String.format("%02x ", b&0xff));
        } return sb.toString();
  }


  private void loadMatchTemplate(MethodChannel.Result result, int extraDataSize) {
    FMSAPI.cmdLoadMatchTemplate(extraDataSize);
    Log.e(TAG, "loadMatchTemplate extraDataSize----- " + extraDataSize);
    result.success("Success -- loadMatchTemplate Send");
  }

  private void loadMatchTemplateWithExtraData(MethodChannel.Result result,  Object arguments) {


    var extraDataSize = (int) ((ArrayList<?>) arguments).get(0);
    var extraData = (byte[]) ((ArrayList<?>) arguments).get(1);
    Log.e(TAG, "loadMatchTemplateWithExtraData extraDataSize----- " + extraDataSize);
    Log.e(TAG, "loadMatchTemplateWithExtraData extraData----- " + extraData);

    FMSAPI.cmdLoadMatchTemplate(extraDataSize,extraData);
    result.success("Success -- loadMatchTemplateWithExtraData Send");
  }






  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }
}
