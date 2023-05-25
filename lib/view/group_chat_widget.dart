//import 'dart:io';
import 'dart:convert';
import 'dart:io';
import 'package:mime/mime.dart';
import 'package:dio/dio.dart';
import 'package:dio/src/form_data.dart' as FormData;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:realtime_chat/controller/ConvsCntlr.dart';
import 'package:realtime_chat/model/Message.dart';
import 'package:realtime_chat/model/User.dart';
import 'package:get/get_connect/http/src/multipart/form_data.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http_parser/http_parser.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;

import 'package:dio/src/multipart_file.dart' as MultipartFile;

import 'package:http/http.dart' as http;

import '../model/Conversation.dart';

class GroupChatWidget extends StatefulWidget {
  // Completely Done for now
  ConversationController convsController;
  User currentUser;
  int convsIndex;
  final dio = Dio();
  IO.Socket socket;

  GroupChatWidget(
      this.convsController, this.currentUser, this.socket, this.convsIndex,
      {super.key});

  @override
  State<GroupChatWidget> createState() => _GroupChatWidgetState();
}

class _GroupChatWidgetState extends State<GroupChatWidget> {
  @override
  initState() {
    super.initState();
    print("widget.conversation.id:"+widget.convsController.conversations[widget.convsIndex].id.toString());
/*
    var messageList =
        widget.convsController.conversations[widget.convsIndex].messages;

    if (!(messageList![messageList.length - 1]
        .seenBy!
        .contains(widget.currentUser.id!))) {
      print("Message Seen at Initial State");

      String convsId =
      widget.convsController.conversations[widget.convsIndex].id.toString();

      String convsType =
      widget.convsController.conversations[widget.convsIndex].type.toString();
      String messageId = widget
          .convsController
          .conversations[widget.convsIndex]
          .messages![widget.convsController.conversations[widget.convsIndex]
          .messages!.length -
          1]
          .id
          .toString();

      widget.convsController.seenMessage(convsId, convsType, messageId, widget.socket, widget.currentUser.id!);

    }*/

     receiveMessage(); //Check if last message has not seen yet...

  }

  receiveMessage() {
    //Receive Message Seen Info

    // String notifyMessageSeenEvent =
    //     'notifyMessageSeen=${widget.convsController.conversations[convsIndex].id}';

    String notifyMessageSeenEvent ="notifyMessageSeen?convsId=${widget.convsController.conversations[widget.convsIndex].id}&convsType=Group";


    widget.socket.on(notifyMessageSeenEvent, (data)
    {
      print("Other User Has Seen Message: ");
      var jsonMap = data as Map<String, dynamic>;

      if (!widget
          .convsController
          .conversations[widget.convsIndex]
          .messages![widget.convsController.conversations[widget.convsIndex]
          .messages!.length -
          1]
          .seenBy!.contains(jsonMap['newUserId'])) {


      widget
          .convsController
          .conversations[widget.convsIndex]
          .messages![widget.convsController.conversations[widget.convsIndex]
          .messages!.length -
          1]
          .seenBy!
          .add(jsonMap['newUserId']);
      widget.convsController.conversations.refresh();

    }
    });



    Conversation convs = widget.convsController.conversations[widget.convsIndex];
    String receiveMessageEvent = "receiveMessage?convsId=${convs.id}&convsType=Group";

    //Receive Message from Server that actually sent by other Client.
    widget.socket.on(receiveMessageEvent, (data) {


      print("ReceiveMessageCalled");
      print("widget.currentUser.id: "+widget.currentUser.id.toString());

      var jsonMap = data as Map<String, dynamic>;

      if(jsonMap['fromId']!=widget.currentUser.id!){


      var seenByList = jsonMap['seenBy'].toList();

      List<String> seenBy = <String>[];

      for (var i = 0; i < seenByList.length; i++) {
        //Convert And Reassign Existing SeenBy Data...
        seenBy.add(seenByList[i]);
        print("seenByList[${i}]"+seenByList[i].toString());

      }

      if (!(seenBy.contains(widget.currentUser.id!))) {
        seenBy.add(widget.currentUser.id!);

        widget.convsController.conversations[widget.convsIndex].messages!.add(
            Message(
                id: jsonMap['id'],
                fromId: jsonMap['fromId'],
                toId: jsonMap['toId'],
                text: jsonMap['text'],
                seenBy: seenBy,
                imageUrl: jsonMap['imageUrl'],
                createdAt: jsonMap['createdAt'],
                updatedAt: jsonMap['updatedAt']));

        String convsId = widget
            .convsController.conversations[widget.convsIndex].id
            .toString();

        String convsType = widget
            .convsController.conversations[widget.convsIndex].type
            .toString();

        String messageId = widget
            .convsController
            .conversations[widget.convsIndex]
            .messages![widget.convsController.conversations[widget.convsIndex]
            .messages!.length -
            1]
            .id
            .toString();

        widget.convsController.seenMessage(convsId, convsType, messageId, widget.socket, widget.currentUser.id!);
        print(jsonMap);
      }
    }

    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
          appBar: AppBar(leading: BackButton(
              color: Colors.black,
            onPressed: ()=> Navigator.of(context, rootNavigator: true).pop(),
          ), title: Align( alignment: Alignment.center,
            child: Column(children: <Widget>[
              Container( margin: EdgeInsets.only(bottom: 5),
                child: Text(widget.convsController.conversations[widget.convsIndex].title.toString(),
                style: TextStyle(fontSize: 20, color: Colors.black),),
              ),
              Text("Neways Internationl (S&IT)", style: TextStyle(fontSize: 10),),]),
          ),
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.call),
                tooltip: 'Call Now',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('This feature is coming soon!')));
                },
              ),

            ],),
          body: MessageListWidget(widget.convsController, widget.currentUser, widget.socket, widget.convsIndex),
        );
  }
}

class MessageListWidget extends StatefulWidget {
  ConversationController convsController;
  User currentUser;
  IO.Socket socket;
  int convsIndex;
  final dio = Dio();

  MessageListWidget(
      this.convsController, this.currentUser, this.socket, this.convsIndex,
      {super.key});

  @override
  State<MessageListWidget> createState() => _MessageListWidgetState();
}

class _MessageListWidgetState extends State<MessageListWidget> {


  @override
  Widget build(BuildContext context) {

    return Column(
      children: <Widget>[
        Expanded(child: GetX<ConversationController>(
          builder: (controller) {

            var items = widget
                .convsController.conversations[widget.convsIndex].messages;

            return ListView.builder(
              reverse: true,
              itemCount: items!.length,
              itemBuilder: (context, index) {
                final reversedIndex = items.length - 1 - index;
                final item = items[reversedIndex];
                List<String>? seenBy = item.seenBy;

                bool hasSeen = true;
                /*if (item.seenBy!.contains(widget.selectedUser.id)) {
                  hasSeen = true;
                }*/

                print("SeenByNow1: " + item.seenBy.toString());

                int position =
                getLastSendMessageIndex(widget.currentUser.id!, items);

                bool isLastSendMessage = reversedIndex == position;

                String createdAtDate =  item.createdAt!.toString().substring(0, 10);

                bool hasMessagesAtSameDay = false;
                if(reversedIndex>0){
                  String createdAtPreviousDate =  items[reversedIndex-1].createdAt!.substring(0, 10);
                  if(createdAtPreviousDate==createdAtDate) hasMessagesAtSameDay = true;
                }
                return Column(children: [
                  Visibility( child: Container( margin: EdgeInsets.fromLTRB(0, 50, 0, 10),
                    child: DecoratedBox(decoration: BoxDecoration(color: Colors.blueGrey[400], borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(10, 3, 10, 3),
                        child: Text( item.createdAt.toString(), style: TextStyle(color: Colors.white),),
                      ),
                    ),
                  ), visible: !hasMessagesAtSameDay,),


                  item.fromId == widget.currentUser.id? ChatBubble(
                      item: item,
                      isCurrentUser: true,
                      hasSeen: hasSeen,
                      isLastSendMessage: isLastSendMessage) : ChatBubble(
                      item: item,
                      isCurrentUser: false,
                      hasSeen: hasSeen,
                      isLastSendMessage: isLastSendMessage)

                ],);



              },
            );
          },
        )),
        ChatMessageTypingField(widget.convsController, widget.currentUser, widget.socket, widget.convsIndex),
      ],
    );
  }
}

int getLastSendMessageIndex(String currentUserId, var items) {
  int result = 0;
  for (var i = items.length - 1; i >= 0; i--) {
    if (items[i].fromId == currentUserId) {
      result = i;
      break;
    }
  }
  return result;
}

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    Key? key,
    required this.item,
    required this.isCurrentUser,
    required this.hasSeen,
    required this.isLastSendMessage,
  }) : super(key: key);
  final Message item;
  final bool isCurrentUser;
  final bool hasSeen;
  final bool isLastSendMessage;

  @override
  Widget build(BuildContext context) {


    Message message = item;

    // String seenUsersListText = "";
    // for(int i=0; i<message.seenBy!.length; i++){
    //   seenUsersListText+=message.seenBy![i]
    // }


    return Padding(
      // add some padding
      padding: EdgeInsets.fromLTRB(
        isCurrentUser ? 64.0 : 16.0,
        4,
        isCurrentUser ? 16.0 : 64.0,
        4,
      ),
      child: Column(children: [
        Align(
          // align the child within the container
            alignment:
            isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Column(children: [

              DecoratedBox(
                // chat bubble decoration
                  decoration: BoxDecoration(

                    color: isCurrentUser ? Colors.blue : Colors.grey[300],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: (message.imageUrl != null &&
                            message.imageUrl!.length > 0)
                            ? Image.network(message.imageUrl.toString())
                            : Text(
                          message.text.toString(),
                          style: Theme.of(context)
                              .textTheme
                              .bodyText1!
                              .copyWith(
                              color: isCurrentUser
                                  ? Colors.white
                                  : Colors.black87),
                        ),
                      ),
                    ],
                  )),
            ],)

        ),
        Visibility(
          visible: isLastSendMessage&&message.seenBy!.length>1,
          child: Container(
            alignment: Alignment.bottomRight,
            margin: EdgeInsets.fromLTRB(0, 5, 0, 0),
            child: Text("Seen (${message.seenBy!.length})",style: TextStyle(fontSize: 12),),
          ),
        )
      ]),
    );
  }
}

/*class SendMessageButton extends StatelessWidget {
  TextEditingController messageController;
  ConversationController convsController;
  String currentUserId;
  User selectedUser;
  IO.Socket socket;
  String imageUrl;

  SendMessageButton(this.convsController, this.messageController,
      this.currentUserId, this.selectedUser, this.socket, this.imageUrl,
      {super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Container(
        margin: EdgeInsets.all(5),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          "Send",
          style: TextStyle(fontSize: 25),
        ),
      ),
      onTap: () => {

      },
    );
  }
}*/

sendMessage(
    ConversationController convsController,
    String currentUserId,
    String messageText,
    String imageUrl,
    IO.Socket socket,
    int convsIndex) {

  List<String> seenBy = <String>[];
  seenBy.add(currentUserId);

  Message message = Message(
    id: "",
    fromId: currentUserId,
    toId: "all",
    text: messageText,
    seenBy: seenBy,
    imageUrl: imageUrl,
  );

  convsController.sendMessage(
      convsController.conversations[convsIndex].id!,convsController.conversations[convsIndex].type!, message, convsIndex, socket);

}


class ChatMessageTypingField extends StatefulWidget {
  ConversationController convsController;
  User currentUser;
  IO.Socket socket;
  int convsIndex;

  ChatMessageTypingField(this.convsController, this.currentUser, this.socket, this.convsIndex, { Key? key}) : super(key: key);

  @override
  _ChatMessageTypingFieldState createState() => _ChatMessageTypingFieldState();
}
class _ChatMessageTypingFieldState extends State<ChatMessageTypingField> {

  TextEditingController messageController = new TextEditingController();

  @override
  Widget build(BuildContext context) {

    return Container(
      margin: EdgeInsets.all(15.0),
      height: 61,
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(35.0),
                boxShadow: [
                  BoxShadow(
                      offset: Offset(0, 3),
                      blurRadius: 5,
                      color: Colors.grey)
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                      icon: Icon(Icons.face , color: Colors.blueAccent,), onPressed: () {}),
                  Expanded(
                    child: Material(
                      child: TextField(
                        controller: messageController,
                        decoration: InputDecoration(
                            hintText: "Type Something...",
                            hintStyle: TextStyle( color:     Colors.blueAccent),
                            border: InputBorder.none),
                        onChanged: (text){
                          setState(() {
                          });



                        },
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.photo ,  color: Colors.blueAccent),
                    onPressed: () {

                      _openGalleryAndUploadImage(
                          widget.convsController,
                          widget.currentUser.id!,
                          messageController,
                          "",
                          widget.socket, widget.convsIndex);

                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.attach_file ,  color: Colors.blueAccent),
                    onPressed: () {},
                  )
                ],
              ),
            ),
          ),
          SizedBox(width: 15),
          Container(
            padding: const EdgeInsets.all(15.0),
            decoration: BoxDecoration(
                color: Colors.blueAccent, shape: BoxShape.circle),
            child: InkWell(
              child: messageController.text.length>0? Icon(Icons.send, color: Colors.white) : Icon(Icons.keyboard_voice, color: Colors.white),
              onTap: (){
                if(messageController.text.length>0){
                  //Send Text Message
                  sendMessage(widget.convsController, widget.currentUser.id!, messageController.text, "",  widget.socket, widget.convsIndex);
                  messageController.text = "";
                }else{
                  //todo...Send Voice Message...



                }
              },
            ),
          )
        ],
      ),
    );

  }


  var file;
  void _openGalleryAndUploadImage(
      ConversationController convsController,
      String currentUserId,
      TextEditingController messageController,
      imageUrl,
      IO.Socket socket, int convsIndex) async {
    file = await ImagePicker()
        .pickImage(source: ImageSource.gallery); //pick an image
    //upload file...
    List<int> imageBytes = await file.readAsBytes();
    String base64Image = base64Encode(imageBytes);
    //String base64Image = base64Encode(file.readAsBytesSync());
    String filename = file.path.split('/').last;
    print(filename);

    final dio = Dio();
    try {
      var response = await dio.post(
          "https://nodejsrealtimechat.onrender.com/upload",
          data: {"image": base64Image, "name": filename});
      await sendMessage(convsController, currentUserId, messageController.text, response.data['url'], socket, convsIndex);
    } catch (e) {
      print(e.toString());
    }
  }
}
