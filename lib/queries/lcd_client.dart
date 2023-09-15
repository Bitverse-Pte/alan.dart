import 'dart:convert';
import 'package:alan/alan.dart';
import 'package:dio/dio.dart';

abstract class BaseJsonReq {
  Map<String, dynamic> toJson();
}

abstract class BaseJsonResp {
  void fromJson(dynamic json);
}

class StringJsonReq extends BaseJsonReq {
  final String _body;

  StringJsonReq(String body) : _body = body;

  @override
  Map<String, dynamic> toJson() {
    return jsonDecode(_body);
  }
}

class DynamicMapJsonReq extends BaseJsonReq {
  final Map<String, dynamic> _body;

  DynamicMapJsonReq(Map<String, dynamic> body) : _body = body;

  @override
  Map<String, dynamic> toJson() {
    return _body;
  }
}

class QueryResult<T> {
  QueryResult({
    required this.isSuccess,
    required this.code,
    this.errMessage,
    this.result,
  });

  factory QueryResult.error() => QueryResult<T>(isSuccess: false, code: -1);

  final bool isSuccess;
  final int code;
  final String? errMessage;
  final T? result;

  @override
  String toString() {
    return 'BResponse{isSuccess: $isSuccess, errMessage: $errMessage, code: $code, result: $result,}';
  }
}

const int defaultConnectTimeout = 10000;
const int defaultSendTimeout = 10000;
const int defaultReceiveTimeout = 10000;

class LcdClient {
  Dio? _dioClient;

  set baseUrl(LCDInfo lcdInfo) {
    _dioClient?.options.baseUrl = lcdInfo.fullUrl;
  }

  Dio? get dioClient => _dioClient;

  void init(
    LCDInfo lcdInfo, {
    int? connectTimeout,
    int? sendTimeout,
    int? receiveTimeout,
  }) {
    _dioClient = Dio(BaseOptions(
      baseUrl: lcdInfo.fullUrl,
      connectTimeout: connectTimeout ?? defaultConnectTimeout,
      sendTimeout: sendTimeout ?? defaultSendTimeout,
      receiveTimeout: receiveTimeout ?? defaultReceiveTimeout,
    ));
  }

  void addCustomHeaders(Map<String, dynamic> customHeaders) {
    _dioClient?.options.headers = <String, dynamic>{
      ...customHeaders,
      ...?_dioClient?.options.headers,
    };
  }

  Future<QueryResult<T>> jsonPost<T extends BaseJsonResp>({
    required String path,
    BaseJsonReq? req,
    required T result,
    CancelToken? cancelToken,
    Map<String, dynamic>? customHeaders,
  }) async {
    if (_dioClient?.options.baseUrl == null) {
      return QueryResult<T>.error();
    }
    try {
      await _sendDioRequest(
        path: path,
        body: req,
        result: result,
        method: 'POST',
        customHeaders: customHeaders,
      );
      return QueryResult<T>(
        isSuccess: true,
        result: result,
        code: 0,
      );
    } catch (e) {
      return QueryResult<T>.error();
    }
  }

  Future<QueryResult<T>> jsonGet<T extends BaseJsonResp>({
    required String path,
    BaseJsonReq? req,
    required T result,
    CancelToken? cancelToken,
    Map<String, dynamic>? customHeaders,
  }) async {
    if (_dioClient?.options.baseUrl == null) {
      return QueryResult<T>.error();
    }
    try {
      await _sendDioRequest(
        path: path,
        queryParameters: req?.toJson(),
        result: result,
        method: 'GET',
        cancelToken: cancelToken,
        customHeaders: customHeaders,
      );
      return QueryResult<T>(
        isSuccess: true,
        result: result,
        code: 0,
      );
    } catch (e) {
      return QueryResult<T>.error();
    }
  }

  Future<T> _sendDioRequest<T extends BaseJsonResp>({
    required String path,
    required T result,
    required String method,
    BaseJsonReq? body,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? customHeaders,
    CancelToken? cancelToken,
  }) async {
    String contentType = Headers.jsonContentType;

    final Response<dynamic>? response = await _dioClient?.request<dynamic>(
      path,
      data: body?.toJson(),
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      options: Options(
        method: method,
        contentType: contentType,
        headers: customHeaders,
      ),
      // ignore: body_might_complete_normally_catch_error
    ).catchError((dynamic e) {
      throw Exception("failed to get response from server $path, e:$e");
    });

    return _onResponse(response, result);
  }

  T _onResponse<T extends BaseJsonResp>(
    Response<dynamic>? response,
    T result,
  ) {
    try {
      // 防止解析失败
      result.fromJson(response?.data);
    } catch (e) {
      throw Exception("failed to parse response ${response?.data}");
    }

    return result;
  }
}
