import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:free_chat/chatscreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:free_chat/notificationservice/local_notification_service.dart';

Future<void> backgroundHandler(RemoteMessage message) async {
  // 	print(message.data.toString());
 	// print(message.notification!.title);
  LocalNotificationService.createanddisplaynotification(message);
  

	}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(backgroundHandler);
  // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  //   FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  //     // Handle foreground message
  // LocalNotificationService.createanddisplaynotification(message);
    
  //   });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
   LocalNotificationService.initialize(context);
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Free Chat',
      home: Chatscreen(),
    );
  }
}
