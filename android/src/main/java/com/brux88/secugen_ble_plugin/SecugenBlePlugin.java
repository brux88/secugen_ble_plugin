package com.brux88.secugen_ble_plugin;
import com.google.gson.Gson;
import com.google.gson.JsonObject;
import androidx.annotation.NonNull;
import android.src.main.java.com.brux88.secugen_ble_plugin.fmssdk.FMSAPI;
import android.src.main.java.com.brux88.secugen_ble_plugin.fmssdk.FMSHeader;
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


  private final String METHOD_SET_POWER_OFF_TIME_2H = "cmdSetPowerOffTime2H";
  private final String METHOD_GET_VERSION = "cmdGetVersion";
  private final String METHOD_PARSE_RESPONSE = "parseResponse";
  private final String METHOD_GET_TEMPLATE = "cmdGetTemplate";
  private final String METHOD_INSTANT_VERIFY_WITH_EXTRADATA = "cmdInstantVerifyWithExtraData";
 //private final String METHOD_MAKE_RECORD_START = "cmdMakeRecordStart";
 // private final String METHOD_MAKE_RECORD_CONT = "cmdMakeRecordCont";
 // private final String METHOD_MAKE_RECORD_END = "cmdMakeRecordEnd";
 // private final String METHOD_LOAD_MATCH_TEMPLATE = "cmdLoadMatchTemplate";
 // private final String METHOD_LOAD_MATCH_TEMPLATE_WITH_EXTRADATA = "cmdLoadMatchTemplateWithExtraData";
 // private final String METHOD_FP_REGISTER_START = "cmdFPRegisterStart";
 // private final String METHOD_FP_REGISTER_END = "cmdFPRegisterEnd";
 // private final String METHOD_FP_DELETE = "cmdFPDelete";
 // private final String METHOD_FP_VERIFY = "cmdFPVerify";
 // private final String METHOD_FP_IDENTIFY = "cmdFPIdentify";
 // private final String METHOD_FP_CAPTURE = "cmdFPCapture";
 // private final String METHOD_FP_CAPTURE_USE_WSQ = "cmdFPCaptureUseWSQ";
 // private final String METHOD_INSTANT_VERIFY = "cmdInstantVerify";
 // private final String METHOD_SERIAL_NUMBER = "cmdGetSerialNumber";
 // private final String METHOD_SET_SYSTEM_INFO = "cmdSetSystemInfo";
 // private final String METHOD_SET_SYSTEM_INFO_WITH_PARAM2 = "cmdSetSystemInfoWithParam2";
 // private final String METHOD_GET_HEADER = "getHeader";

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
      case METHOD_PARSE_RESPONSE:
         var parseResponse = FMSAPI.parseResponse((byte[]) call.arguments);
         result.success(parseResponse);
        break;
      case METHOD_GET_VERSION:
          getVersion(result,  call.arguments);
        break;
      case METHOD_SET_POWER_OFF_TIME_2H:
          setPowerOffTime2H(result,  call.arguments);
        break;
      case METHOD_INSTANT_VERIFY_WITH_EXTRADATA:
         instantVerifyExtraData(result,  call.arguments);
        break;
      case METHOD_GET_TEMPLATE:
          getTemplate(result,  call.arguments);
        break;           
      default:
        result.notImplemented();
        break;
    }

  }
  private void getTemplate(MethodChannel.Result result,  Object arguments) {
     byte[] captureBytes  = FMSAPI.cmdGetTemplate();
     var ires = FMSAPI.parseResponse(captureBytes);
     Log.e(TAG, "GET TEMPLATE RESULT----- " + ires);
     result.success(captureBytes);
  }

  private void getVersion(MethodChannel.Result result,  Object arguments) {
    byte[] versionBytes  = FMSAPI.cmdGetVersion();
    var i = FMSAPI.parseResponse(versionBytes);
    Log.e(TAG, "VERSION RESULT----- " + i);
    result.success(versionBytes);
  }

   private void setPowerOffTime2H(MethodChannel.Result result,  Object arguments) {
    byte[] versionBytes  = FMSAPI.cmdSetPowerOffTime2H();
    var i = FMSAPI.parseResponse(versionBytes);
    Log.e(TAG, "SET POWER OFF TIME RESULT----- " + i);
    result.success(versionBytes);
  }

  private void instantVerifyExtraData(MethodChannel.Result result,  Object arguments) {
    var numberOfTemplateInt = (int) ((ArrayList<?>) arguments).get(0);
    short numberOfTemplate = (short) numberOfTemplateInt;

    var extraDataSize = (int) ((ArrayList<?>) arguments).get(1);
    var extraData = (byte[]) ((ArrayList<?>) arguments).get(2);
    Log.e(TAG, "instantVerifyExtraData numberOfTemplate----- " + numberOfTemplate);
    Log.e(TAG, "instantVerifyExtraData extraDataSize----- " + extraDataSize);
    Log.e(TAG, "instantVerifyExtraData extraData----- " + extraData);
    var resultInstantVerify = FMSAPI.cmdInstantVerify(numberOfTemplate,extraDataSize,extraData);
    var ilog = FMSAPI.parseResponse(resultInstantVerify);
    Log.e(TAG, "instantVerifyExtraData RESULT ----- " + ilog);
    result.success(resultInstantVerify);
  }





  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }
}
