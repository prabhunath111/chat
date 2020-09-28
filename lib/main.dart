/*
import 'package:flutter/material.dart';

void main() => runApp(MaterialApp(
  home: HomePage(),
));

class HomePage extends StatefulWidget {


  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  List msg = [];


  @override
  void initState() {
    // TODO: implement initState
    super.initState();

  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat"),
      ),
      body: ListView.builder(
        itemCount: msg.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: msg[index]!=null?msg[index]:''
            );
          }
      )
    );
  }
}
*/
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:adhara_socket_io/adhara_socket_io.dart';

void main() => runApp(MaterialApp(
  debugShowCheckedModeBanner: false,
  home: HomePage(),
));

const String URI = "http://192.168.43.199:3000/";

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> toPrint = ["trying to connect"];
  SocketIOManager manager;
  Map<String, SocketIO> sockets = {};
  Map<String, bool> _isProbablyConnected = {};

  TextEditingController _textEditingController = TextEditingController();
  ScrollController _scrollController = ScrollController();
  List msglist = [];
  var sendingmessage='';

  @override
  void initState() {
    super.initState();
    manager = SocketIOManager();
    initSocket("default");
  }

  _scrollToBottom() {
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  initSocket(String identifier) async {
    setState(() => _isProbablyConnected[identifier] = true);
    SocketIO socket = await manager.createInstance(SocketOptions(
      //Socket IO server URI
        URI,
        nameSpace: (identifier == "namespaced")?"/adhara":"/",
        //Query params - can be used for authentication
        query: {
          "auth": "--SOME AUTH STRING---",
          "info": "new connection from adhara-socketio",
          "timestamp": DateTime.now().toString()
        },
        //Enable or disable platform channel logging
        enableLogging: false,
        transports: [Transports.WEB_SOCKET/*, Transports.POLLING*/] //Enable required transport
    ));
    socket.onConnect((data) {
      pprint("connected...");
      pprint(data);
//      sendMessage(identifier);
    });
    socket.onConnectError(pprint);
    socket.onConnectTimeout(pprint);
    socket.onError(pprint);
    socket.onDisconnect(pprint);
    socket.on("type:string", (data) => pprint("type:string | $data"));
    socket.on("type:bool", (data) => pprint("type:bool | $data"));
    socket.on("type:number", (data) => pprint("type:number | $data"));
    socket.on("type:object", (data) => pprint("type:object | $data"));
    socket.on("type:list", (data) => pprint("type:list | $data"));
    socket.on("message", (data) {
      pprint("receive message $data");
    });
    socket.connect();
    sockets[identifier] = socket;
  }

  bool isProbablyConnected(String identifier){
    return _isProbablyConnected[identifier]??false;
  }

  disconnect(String identifier) async {
    await manager.clearInstance(sockets[identifier]);
    setState(() => _isProbablyConnected[identifier] = false);
  }

  sendMessage(identifier) {

    // for clear the textform field
    WidgetsBinding.instance.addPostFrameCallback((_) => _textEditingController.clear());

    setState(() { });

    if (sockets[identifier] != null) {
      pprint("sending message from '$identifier'...");
      sockets[identifier].emit("message", [
        sendingmessage,
      ]);

      msglist.add(sendingmessage);
      _scrollToBottom();

      pprint("Message emitted from '$identifier'...");
    }

    setState(() {

    });

  }

  pprint(data) {
    setState(() {
      if (data is Map) {
        data = json.encode(data);
      }
      print(data);
      toPrint.add(data);
    });
  }

  @override
  Widget build(BuildContext context) {

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
          title: Text("Chat")
      ),
      body: Stack(
        children: <Widget>[
          ListView.builder(
              itemCount: msglist.length,
              itemBuilder: (context, index) {
                return Card(
                  color: Colors.blue,
                  child: ListTile(
                    title: Text(msglist[index]!=null?msglist[index]:''),
                  ),
                );
              }),
          Align(
            alignment: FractionalOffset.bottomCenter,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                IconButton(icon: Icon(Icons.insert_emoticon), onPressed: null),
                Expanded(
                  child: TextFormField(
                    controller: _textEditingController,
                    decoration: InputDecoration(
                        hintText: "Type a message",
                        border: InputBorder.none),
                    onChanged: (text) {
                      sendingmessage = text;
                      setState(() {

                      });
                    },
                  ),
                ),
                IconButton(icon: Icon(Icons.send), onPressed: () {

                  sendMessage('default');

                  print("Clicked...");

                }),
              ],
            ),
          )
        ],
      ),
    );
  }

}