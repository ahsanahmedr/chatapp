// lib/helpers/notification_helper.dart
import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationHelper {
  static const _serviceAccountJson = {
     "type": "service_account",
  "project_id": "chatapp-756ef",
  "private_key_id": "eba120256ddf8317e34ccc607b3dbde846c7acd4",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDnEFuQ24T/+nOR\nFiInMEe14abF3ngTdZGJ2f0dS2s9zdT4xHchw7q9Qavrw8B/TI7g+BCkMA3P+SmM\nhnfxBaUTEsMuaO2OVtxSE7vo/CfKfMYiHAhoTcozE/g3Aqt4ZT03G09TNXBVKDC5\nh45+lURgO331X+GdJ3UVV6eBHcvWNFWILcaAv2CYKRP2RTtdhM0VVdGIobshwv9L\nl+MGyVAwo/36KCmXjXJy096QFeyDuLVxfC2wLHTW5X3fmZN7XNnK2roxmtTE6SgB\nsLKDd/akDbY5++WiNsENR8WyR4K+LfLItemThfjDZ0nQsudYlX6YJs84zlQkQ3tE\nQybqvHH7AgMBAAECggEAWCpbLfI9FOlNGHKwFHDtI97WolCJU698GXP2iyuAX4Q+\n+68HX/hNtDIvNdYrCMe/CuNMgkGdu5nweyDB+lLzkkwJ8pbx8ep9xcmm3Tb9vdsP\nROuaX6Yy/XtkriTUJavHiFPg2DifRLcBpIEvY2h0Px3kKXDs5uir2blo/jDO2svC\ndIYk85ADT4MDhqPcs0Fik7Dc8OLd7awmXGL6NNJ3ebx2+G9KG3StYxf8FO2TXcqt\nCNSwFfIZOeRnzKM/5zhZjvU7MxsF5eyM+PffesEmiYQX3HjtmCcWXkZzSRwtoEMX\nTmt05k89R/io5WerNhItRv41+xu2PS+WBhM9MHG8oQKBgQD/gnUQXsOtlcqZEyy8\njPXby5+f8hQR3LN3vnSp4y2TxkKgs4VB/8Q3HozAS9zUoBwMXm53MLkJye7hmP1P\nldm2moveBdLOHYfc5SvK3UCOTI+/2C94RuAJ7oPHI3Q7l9cFaX5q6z0ZkMl2TUoB\np/FAAOkgY1aL5QVWmMUndo2WGwKBgQDngeOhukTjJRx8EWPb8poNQB1jzLiZN5ul\nyXPYrgkuKmhmgYOEPK5a8HheRr6yo1i8y+1o6a6MGhtR0GjbpmgeRtkC5Tp8CSMN\nK5HTLvxm1c3ZyyiEN0ftYSV3859cqgUtH/Zy1Jxka05ukT/+JQFj9eABppGU9YKW\ngzc+sr/RoQKBgQCGB570yWEIC41NIvvSpHbLp1LCii/w9r7Fz4hPHbZo0BVfSwxa\nBJqe902KCcF7X8mWy2pS56II+n5upNwsBUVBPmykOJXOPTtpqmWAcvNMMekuD29H\nPpaDXzSNH5H3OL04P5Bq8Z8JbCPiBMUPfVNV6aRgsvtRQv+730N8Yfn/hQKBgQCF\ntusgdXLmc3/xVSYFWymJb7fJ9evFa232ItZLl7HrvUjRtAqfbWETW4NaiKgKi/hs\nC6lTiG1ttIKFDcgS3hmTKz6awoW2MJzTNZAjlybnyqP8ILCFNVzRCeRXVRp9riIR\nPz3cc1rlUWlayYBZrUwRTWmV6nx5uhg0ERPundXXIQKBgFiFozWnm5YeqoGME0K3\nMZct73x5wyNCWo+jX/h8a51UF4Dl/2jhhHri306jYeddIE0r6+I3hLwI2K6TpDxl\n9Fj/4v1i0QDi9SDtMY+bUU4ILyi0aRuOnG3170VrzlSCdDiwvfHc+GjLFHzTJuCy\nPxGXj8s+gEl5txl6gsgB8Tg/\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-fbsvc@chatapp-756ef.iam.gserviceaccount.com",
  "client_id": "115249622833187396071",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40chatapp-756ef.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
  };

  static Future<void> sendPushNotification({
    required String receiverUid,
     required String senderUid, 
    required String senderName,
    required String messageText,
  }) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(receiverUid)
          .get();
      final receiverToken = doc.data()?['fcmToken'];
      if (receiverToken == null) return;

      final credentials = ServiceAccountCredentials.fromJson(_serviceAccountJson);
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final authClient = await clientViaServiceAccount(credentials, scopes);
      final accessToken = authClient.credentials.accessToken.data;
      authClient.close();

      final response = await http.post(
        Uri.parse(
          'https://fcm.googleapis.com/v1/projects/chatapp-756ef/messages:send',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'message': {
            'token': receiverToken,
            'notification': {
              'title': senderName,
              'body': messageText,
            },
            'android': {
              'notification': {
                'channel_id': 'chat_messages',
                'sound': 'default',
              },
            },
            'data': {
  'click_action': 'FLUTTER_NOTIFICATION_CLICK',
  'senderUid': senderUid,  // receiver ko notification ja rahi hai
                               // toh US ke liye sender = current user
  'senderName': senderName,
  'senderEmail': '',
            },
          },
        }),
      );

      log(response.statusCode == 200
          ? '✅ Notification sent!'
          : '❌ Error: ${response.body}');
    } catch (e) {
      log('Notification error: $e');
    }
  }
}