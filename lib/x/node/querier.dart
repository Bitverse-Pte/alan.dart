import 'package:alan/queries/lcd_client.dart';
import 'package:alan/wallet/network_info.dart';

class NodeInfo extends BaseJsonResp {
  String? id;

  /// 对应字段 listen_addr
  String? listenAddr;

  /// 对应chain_id
  String network = '';
  String? version;
  String? channels;
  String? moniker;

  /// 对应字段cosmos_sdk_version
  String? cosmosSdkVersion;

  @override
  void fromJson(json) {
    // 获取 "account" 键的值，然后使用工厂构造函数创建 Account 对象
    Map<String, dynamic> map = json['node_info'];
    id = map['id'];
    listenAddr = map['listen_addr'];
    network = map['network'] ?? '';
    version = map['version'];
    channels = map['channels'];
    moniker = map['moniker'];
    cosmosSdkVersion = json['cosmos_sdk_version'];
  }
}

/// Allows to query a full node for its information.
class NodeQuerier {
  /// jc: don't support gRPC call. Error code: 2, codeName: UNKNOWN, message: Please, use http node to access this data
  // final tendermint.ServiceClient _client;
  //
  // NodeQuerier({required tendermint.ServiceClient client}) : _client = client;
  //
  // /// Builds a new [NodeQuerier] given a [ClientChannel].
  // factory NodeQuerier.build(grpc.GrpcOrGrpcWebClientChannel channel) {
  //   return NodeQuerier(client: tendermint.ServiceClient(channel));
  // }
  //
  // /// Queries the node info of the chain based on the given [lcdEndpoint].
  // Future<DefaultNodeInfo> getNodeInfo() async {
  //   final request = tendermint.GetNodeInfoRequest();
  //
  //   final response = await _client.getNodeInfo(request);
  //   if (!response.hasDefaultNodeInfo()) {
  //     throw Exception('Invalid node info response');
  //   }
  //
  //   return response.defaultNodeInfo;
  // }

  final LcdClient _lcdClient;

  NodeQuerier({required LcdClient lcdClient}) : _lcdClient = lcdClient;

  /// Builds a new [NodeQuerier] given a [ClientChannel].
  factory NodeQuerier.build(LCDInfo lcdInfo) {
    LcdClient lcdClient = LcdClient();
    lcdClient.init(lcdInfo);
    return NodeQuerier(lcdClient: lcdClient);
  }

  /// Queries the node info of the chain based on the given [lcdEndpoint].
  Future<NodeInfo> getNodeInfo() async {
    QueryResult<NodeInfo> queryResult = await _lcdClient.jsonGet(path: "/node_info", result: NodeInfo());
    if (queryResult.result == null) {
      throw Exception('Invalid node info response');
    }

    return queryResult.result!;
  }
}
