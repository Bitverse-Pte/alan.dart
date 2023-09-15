import 'package:alan/alan.dart';
import 'package:alan/proto/cosmos/bank/v1beta1/export.dart' as bank;
import 'package:grpc/grpc.dart';

void main() async {
  // Create a wallet
  final networkInfo = NetworkInfo.fromHost(
    bech32Hrp: 'cosmos',
    lcdUrl: 'https://cosmos-rest.publicnode.com',
    grpcHost: 'cosmos-grpc.publicnode.com',
    grpcPort: 443,
    credentials: ChannelCredentials.secure(),
  );

  final from_mnemonic = [
    'lens',
    'merge',
    'apology',
    'vast',
    'reunion',
    'someone',
    'dutch',
    'pond',
    'entire',
    'gather',
    'swear',
    'time',
  ];
  final from_wallet = Wallet.derive(from_mnemonic, networkInfo);

  final to_mnemonic = [
    'gasp',
    'become',
    'thing',
    'view',
    'slow',
    'uncover',
    'derive',
    'private',
    'media',
    'bounce',
    'lunch',
    'network',
  ];
  final to_wallet = Wallet.derive(to_mnemonic, networkInfo);

  // 3. Create and sign the transaction
  final message = bank.MsgSend.create()
    ..fromAddress = from_wallet.bech32Address
    ..toAddress = to_wallet.bech32Address;
  message.amount.add(Coin.create()
    ..denom = 'uatom'
    ..amount = '100');

  // Compose the transaction fees
  /// 如果指定amount为100, 那么会出现Insufficient fees; got: 100uatom required: 500uatom: insufficient fee
  /// 那就需要给500uatom, 约为0.0005ATOM, 欧易钱包默认为0.002ATOM
  /// 此处需要多研究下
  final fee = Fee()..gasLimit = 200000.toInt64();
  fee.amount.add(
    Coin.create()
      ..amount = '100'
      ..denom = 'uatom',
  );

  final signer = TxSigner.fromNetworkInfo(networkInfo);
  final tx = await signer.createAndSign(from_wallet, [message], fee: fee);

  // 4. Broadcast the transaction
  final txSender = TxSender.fromNetworkInfo(networkInfo);
  final response = await txSender.broadcastTx(tx);

  // Check the result
  if (response.isSuccessful) {
    print('Tx sent successfully. Response: $response');
  } else {
    print('Tx errored: $response');
  }
}
