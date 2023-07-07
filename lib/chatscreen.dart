// ignore_for_file: file_names
// ignore: library_prefixes

// ignore: library_prefixes
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/material.dart';
import 'package:connectivity/connectivity.dart';

class Chatscreen extends StatefulWidget {
  const Chatscreen({super.key});
  @override
  State<Chatscreen> createState() => _ChatscreenState();
}

class Message {
  final String sender;
  final String text;

  Message({required this.sender, required this.text});
}

class _ChatscreenState extends State<Chatscreen> {
  late IO.Socket socket;
  bool hasInternet = true;
  // ignore: prefer_typing_uninitialized_variables
  var fcmtoken;

  @override
  void initState() {
    noti();
    checkInternetConnection();
    initSocket();
    super.initState();
  }

  void noti() async {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    fcmtoken = fcmToken;
    print(fcmToken);
  }

  Future<void> sendnoti(map) async {
    var url = Uri.parse('https://fcm.googleapis.com/fcm/send');
    try {
      final prefs = await SharedPreferences.getInstance();
      var list = prefs.getStringList('myList');
      // List stringNumbers = list.map((list) => list.toString()).toList();
      // List lis1 = list;
      var payload = {
        "registration_ids": list,
        "notification": {"body": map["message"], "title": map["name"]}
      };
      var response = await http.post(url,
          headers: {
            'Authorization':
                'key=AAAAP9t-lWQ:APA91bHLTtfgxINBClD9GU_7lUYnQE66JND0BM-7X2s5ljDXtT6sLtxtr7jmVDf9QlW1MXl51oV2aTyMrCLk-bMJaOZmAiln6P7v53XAQN85iz-W4dNky1EMQX3bwBkcQlFQs45e8IDe',
            'Content-Type': 'application/json'
          }, // Set the desired content type
          body: json.encode(payload));

      if (response.statusCode == 200) {
        // API call successful
        var responseData = response.body;
        // Process the response data
        print(responseData);
      } else {
        // API call failed
        print('Request failed with status: ${response.statusCode}');
      }
    } catch (error) {
      // Error occurred during the API call
      print('Error: $error');
    }
  }

  void checkInternetConnection() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    setState(() {
      hasInternet = (connectivityResult != ConnectivityResult.none);
      print(hasInternet);
    });
  }

  void fcmtokenfun(newMessage) async {
    final prefs = await SharedPreferences.getInstance();

    List<String>? list = prefs.getStringList('myList');
    // print(list);
    if (list != null) {
      List<String> copyList = List.from(list);
      // print("isNotEmpty");
      for (var element in copyList) {
        // print(element);
        if (element != newMessage["fcm"]) {
          list.add('${newMessage["fcm"]}');
          // print(list);

          await prefs.setStringList('myList', list);
        } else {
          // print("yes list");
        }
      }
    } else {
      // ignore: prefer_typing_uninitialized_variables
      List<String> list = [];
      // var token = newMessage["fcm"];
      // print(token);
      list.add('${newMessage["fcm"]}');

      await prefs.setStringList('myList', list);
      print(list);
      print("empty");
    }
  }

  initSocket() {
    checkInternetConnection();
    if (hasInternet) {
      socket = IO.io('https://websocket-c8r4.onrender.com', <String, dynamic>{
        'transports': ['websocket']
      });
      socket.on('connect', (_) {
        print('connect');
      });
      socket.on("connect_error", (msg) => print(msg));
      // socket.on('event', (data) => print(data));
      socket.on('disconnect', (_) => print('disconnect'));
      socket.on('fromServer', (_) => print(_));
      // random id
      socket.on('message', (newMessage) async {
        scroll();
        setState(() {
          text.add(
              {"sender": newMessage["name"], "Text": newMessage["message"]});
        });
        print(newMessage["fcm"]);
        fcmtokenfun(newMessage);
      });
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('No Internet'),
            content: const Text('Please check your internet connection.'),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  void dispose() {
    // Disconnect from the socket server
    socket.disconnect();
    super.dispose();
  }

  void sendMessage() {
    checkInternetConnection();
    // Emit the 'message' event to the server
    if (hasInternet) {
      var message = textController.text;
      var map = {"name": username.text, "message": message, "fcm": fcmtoken};

      // print(map);
      socket.emit('message', map);
      textController.clear();
      sendnoti(map);
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('No Internet'),
            content: const Text('Please check your internet connection.'),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  TextEditingController textController = TextEditingController();
  TextEditingController username = TextEditingController();
  // Map text = {};
  List text = [];
  final ScrollController _scrollController = ScrollController();
  late bool showAlert;

  // get name => null;
  void scroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.fastOutSlowIn,
      );
    });
  }

  // void fun() {
  //   setState(() {
  //     var message = textController.text;
  //     // text.addaddEntry("sender": 'Me', "text": ttext);
  //     // text["sender"] = "me";
  //     // text["Text"] = ttext;
  //     // var mess = text;
  //     text.add({"sender": username.text, "Text": message});
  //     // var mess = text[0];
  //     print(text);
  //   });
  // }
  // final ScrollController listScrollController = ScrollController();

  // @override
  // void initState() {
  //   _scrollController.addListener(_scrollListener);
  //   super.initState();
  // }

  // _scrollListener() {
  //   FocusScope.of(context).requestFocus(FocusNode());
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   backgroundColor: Color.fromARGB(255, 255, 255, 255),
      //   foregroundColor: Color.fromARGB(255, 0, 0, 0),
      //   title: Row(
      //     children: [
      //       const Text('Free Chat'),
      //       const SizedBox(width: 60),
      //       Expanded(
      //         child: TextField(
      //           style: const TextStyle(color: Colors.white),
      //           controller: username,
      //           decoration: const InputDecoration(
      //             fillColor: Colors.white,
      //             focusColor: Colors.white,
      //             hintText: 'Search',
      //           ),
      //         ),
      //       ),
      //     ],
      //   ),
      // ),
      body: Container(
        color: const Color.fromARGB(255, 12, 30, 61),
        child: Column(children: [
          SizedBox(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(50),
                  bottomRight: Radius.circular(50),
                ),
                border: Border.all(color: Colors.black, width: 2),
                color: Colors.white,
              ),
              padding: const EdgeInsets.only(top: 10),
              margin: const EdgeInsets.symmetric(horizontal: 3.0),
              child: Row(
                children: [
                  const Padding(padding: EdgeInsets.only(left: 10, right: 10)),
                  const Text(
                    'Free Chat',
                    style: TextStyle(
                        fontSize: 20.0, // Set the desired font size
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 60),
                  Expanded(
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          showAlert = value.isNotEmpty;
                        });
                      },
                      // style: const TextStyle(color: Colors.white),
                      controller: username,
                      decoration: InputDecoration(
                          hintText: 'Enter Your Name',
                          border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: BorderRadius.circular(50))),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3.0),
              decoration: const BoxDecoration(
                color: Colors.white,

                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(50),
                  bottomRight: Radius.circular(50),
                  topRight: Radius.circular(50),
                  topLeft: Radius.circular(50),
                ),
                // Other decoration properties
              ),
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                // reverse: true,
                shrinkWrap: true,
                controller: _scrollController,
                itemCount: text.length,

                itemBuilder: (context, index) {
                  return ListTile(
                    title: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                          crossAxisAlignment:
                              text[index]["sender"] == username.text
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                          children: [
                            Text(
                              text[index]["sender"],
                              style: const TextStyle(
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Material(
                              borderRadius: BorderRadius.circular(12.0),
                              elevation: 5.0,
                              color: text[index]["sender"] == username.text
                                  ? Colors.lightBlueAccent
                                  : Colors.grey,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10.0, vertical: 8.0),
                                child: Text(
                                  text[index]["Text"],
                                  style: const TextStyle(
                                    fontSize: 16.0,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ]),
                    ),
                  );
                },
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 12, 30, 61),

              // Other decoration properties
            ),
            // height: 100,
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    controller: textController,
                    decoration: InputDecoration(
                      hintText: "Type here...",
                      hintStyle: const TextStyle(
                          color: Color.fromARGB(163, 255, 253, 253)),
                      filled: true,
                      fillColor: const Color.fromARGB(255, 17, 42, 86),
                      border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(50)),
                    ),
                    onTap: () {
                      scroll();
                    },
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(left: 5),
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(
                        255, 17, 42, 86), // Set the desired background color
                    shape: BoxShape
                        .circle, // Set the shape of the container to a circle
                  ),
                  child: IconButton(
                    // style: Colors.accents,
                    color: Colors.white,
                    icon: const Icon(Icons.send),
                    onPressed: () {
                      if (username.text.isEmpty) {
                        showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text("!Name"),
                                content: const Text("Enter your name"),
                                actions: [
                                  TextButton(
                                    child: const Text('OK'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              );
                            });
                      } else {
                        scroll();
                        // fun();
                        sendMessage();
                      }
                    },
                  ),
                )
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
