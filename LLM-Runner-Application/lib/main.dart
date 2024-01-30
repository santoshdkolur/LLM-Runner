import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Neumorphic Chat App',
      theme: _buildNeumorphicTheme(),
      home: InitialScreen(),
    );
  }

  ThemeData _buildNeumorphicTheme() {
    return ThemeData(
      primarySwatch: Colors.blueGrey,
      backgroundColor: Colors.grey[200],
      scaffoldBackgroundColor: Colors.grey[200],
      appBarTheme: AppBarTheme(
        elevation: 5,
        color: Colors.blueGrey,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      colorScheme: ColorScheme.light(
        primary: Colors.blueGrey,
        secondary: Colors.blueAccent,
      ),
    );
  }
}

class InitialScreen extends StatefulWidget {
  @override
  _InitialScreenState createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  TextEditingController _customOllamaUrlController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Initial Screen'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: _customOllamaUrlController,
            decoration: InputDecoration(
              labelText: 'Enter Ollama URL',
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              String customUrl = _customOllamaUrlController.text.trim();

              // Validate the custom URL
              bool isValid = await _validateOllamaURL(customUrl);

              if (isValid) {
                // Navigate to ChatScreen with custom URL
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ChatScreen(customOllamaUrl: customUrl),
                  ),
                );
              } else {
                // Show error if URL is not valid
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text('Error'),
                      content: Text('Invalid Ollama URL'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('OK'),
                        ),
                      ],
                    );
                  },
                );
              }
            },
            child: Text('Next'),
          ),
        ],
      ),
    );
  }

  Future<bool> _validateOllamaURL(String url) async {
    try {
      final response = await http.get(Uri.parse('$url/api/tags'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

class ChatScreen extends StatefulWidget {
  final String customOllamaUrl;

  ChatScreen({Key? key, required this.customOllamaUrl}) : super(key: key);

  @override
  State createState() => ChatScreenState(customOllamaUrl: customOllamaUrl);
}

class ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  List<List<Map<String, dynamic>>> _allSessions = [[]];
  int _selectedSessionIndex = 0;
  String _selectedModel = '';
  List<String> _availableModels = [];
  late SharedPreferences _preferences;
  bool _isLoading = false;
  String _customOllamaUrl;

  ChatScreenState({required String customOllamaUrl})
      : _customOllamaUrl = customOllamaUrl;

  @override
  void initState() {
    super.initState();
    _initSharedPreferences();
    _fetchAvailableModels();
  }

  Future<void> _initSharedPreferences() async {
    _preferences = await SharedPreferences.getInstance();
    _loadAllSessions();
  }

  void _loadAllSessions() {
    for (int i = 0;; i++) {
      final chatHistory = _preferences.getStringList('chat_history_$i');
      if (chatHistory == null) {
        break;
      }
      setState(() {
        _allSessions.add(chatHistory
            .map((message) => Map<String, dynamic>.from(jsonDecode(message)))
            .toList());
      });
    }
  }

  Future<void> _fetchAvailableModels() async {
    String ollamaTagsEndpoint = '$_customOllamaUrl/api/tags';

    try {
      final response = await http.get(Uri.parse(ollamaTagsEndpoint));

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        List<dynamic> models = jsonResponse['models'];

        setState(() {
          _availableModels =
              models.map<String>((model) => model['name'] as String).toList();

          if (_availableModels.isNotEmpty) {
            _selectedModel =
                _availableModels.first; // Default to the first model
          }
        });
      }
    } catch (error) {
      _showErrorPopup('Error during fetching available models: $error');
    }
  }

  Future<void> _sendMessage(String message) async {
    setState(() {
      _isLoading = true;
    });

    String ollamaChatEndpoint =
        '$_customOllamaUrl/api/chat'; // Updated endpoint

    try {
      final response = await http.post(
        Uri.parse(ollamaChatEndpoint),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(<String, dynamic>{
          'model': _selectedModel,
          'messages': [
            ..._allSessions[_selectedSessionIndex]
                .map((msg) => {'role': 'assistant', 'content': msg['text']}),
            {'role': 'user', 'content': message},
          ],
          "stream": false
        }),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        Map<String, dynamic> messageData = data['message'];
        _addMessage(messageData['content'], false);
      } else {
        _showErrorPopup(
            'Failed to send message. Status code: ${response.statusCode}');
      }
    } catch (error) {
      _showErrorPopup('Error during the message sending: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorPopup(String errorMessage) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _addMessage(String text, bool isUser) {
    setState(() {
      _allSessions[_selectedSessionIndex].insert(
        0,
        {'text': text, 'isUser': isUser, 'timestamp': DateTime.now()},
      );
      _saveAllSessions();
    });
  }

  void _saveAllSessions() {
    for (int i = 0; i < _allSessions.length; i++) {
      final chatHistory = _allSessions[i].map((message) {
        // Check if the message has a timestamp, if yes, convert it to a formatted String
        if (message.containsKey('timestamp') &&
            message['timestamp'] is DateTime) {
          final timestamp = (message['timestamp'] as DateTime);
          final formattedTimestamp =
              DateFormat('h:mm a MMMM d, y').format(timestamp);
          message['timestamp'] = formattedTimestamp;
        }
        return jsonEncode(message);
      }).toList();
      _preferences.setStringList('chat_history_$i', chatHistory);
    }
  }

  void _startNewSession() {
    setState(() {
      _allSessions.add([]);
      _selectedSessionIndex = _allSessions.length - 1;
    });
  }

  void _deleteSession(int index) {
    setState(() {
      _allSessions.removeAt(index);
      if (_allSessions.isEmpty) {
        _allSessions.add([]);
      }
      _selectedSessionIndex =
          _selectedSessionIndex.clamp(0, _allSessions.length - 1);
      _saveAllSessions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chat App',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          _buildModelDropdown(),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _startNewSession,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blueGrey, // Change color to neumorphic style
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chat History',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  SizedBox(height: 8),
                ],
              ),
            ),
            for (int i = 0; i < _allSessions.length; i++)
              Dismissible(
                key: UniqueKey(),
                background: Container(
                  color: Colors.red,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.delete,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                onDismissed: (direction) {
                  _deleteSession(i);
                },
                child: ListTile(
                  title: Text(
                    'Session ${_allSessions[i].isNotEmpty ? _allSessions[i][0]['timestamp'] : i}',
                  ),
                  onTap: () {
                    setState(() {
                      _selectedSessionIndex = i;
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _allSessions[_selectedSessionIndex].length,
              itemBuilder: (context, index) {
                final message = _allSessions[_selectedSessionIndex][index];
                return _buildMessage(message['text'], message['isUser']);
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessage(String text, bool isUser) {
    final alignment =
        isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final backgroundColor = isUser ? Color(0xff1f3b6b) : Colors.greenAccent;

    return Container(
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Icon(isUser ? Icons.person : Icons.android,
                  color: Colors.grey, size: 16),
              SizedBox(width: 4),
              Container(
                width: MediaQuery.of(context).size.width * 0.7,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Wrap(
                  children: [
                    Text(
                      text,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: TextStyle(fontSize: 14), // Decrease font size
              maxLines: null, // Make text box resizable
              decoration: const InputDecoration(
                hintText: 'Type your message...',
              ),
            ),
          ),
          _isLoading
              ? CircularProgressIndicator()
              : IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    String message = _messageController.text.trim();
                    if (message.isNotEmpty) {
                      _sendMessage(message);
                      _addMessage(message, true);
                      _messageController.clear();
                    }
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildModelDropdown() {
    return DropdownButton<String>(
      value: _selectedModel,
      onChanged: (String? newValue) {
        setState(() {
          _selectedModel = newValue!;
        });
      },
      items: _availableModels.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }
}

class CustomURLScreen extends StatefulWidget {
  const CustomURLScreen({Key? key}) : super(key: key);

  @override
  State createState() => CustomURLScreenState();
}

class CustomURLScreenState extends State<CustomURLScreen> {
  TextEditingController _customURLController = TextEditingController();
  bool _isValidURL = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Custom Ollama URL'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _customURLController,
              decoration: InputDecoration(
                labelText: 'Enter Custom Ollama URL',
                errorText: _isValidURL ? null : 'Invalid URL',
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                String customURL = _customURLController.text.trim();
                bool isValid = await _validateOllamaURL(customURL);
                if (isValid) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ChatScreen(customOllamaUrl: customURL),
                    ),
                  );
                } else {
                  setState(() {
                    _isValidURL = false;
                  });
                }
              },
              child: Text('Next'),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _validateOllamaURL(String url) async {
    try {
      final response = await http.get(Uri.parse('$url/api/tags'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
