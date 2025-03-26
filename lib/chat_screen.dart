import 'package:flutter/material.dart';
import 'package:smartcare/app_colors.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io'; // تأكد من إضافة هذا الاستيراد
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isSending = false;

  // متغير لحفظ الصورة المختارة
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes; // متغير جديد لتخزين بايتات الصورة على الويب

  // قائمة الكلمات المفتاحية
  final List<String> _keywords = [
    'Track my request',
    'I need help',
    'I need maintenance',
    'I need Feedback',
    'Other'
  ];

  // لتحديد ما إذا تم اختيار كلمة مفتاحية
  bool _isKeywordSelected = false;

  // لتحديد ما إذا كان المستخدم يتابع طلبًا
  bool _isTrackingRequest = false;

  // رقم الطلب الذي يتم تتبعه
  String _trackingRequestNumber = '';

  // لتغيير hintText بناءً على حالة التطبيق
  String _inputHint = 'Type a message...';

  // قائمة أرقام الطلبات الوهمية
  final List<String> _mockRequestNumbers = [
    '12345',
    '67890',
  ];

  Future<File?> _compressImage(File file) async {
    if (kIsWeb) {
      // لا نقوم بضغط الصورة على الويب
      return file;
    }
    final compressedFile = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      '${file.parent.path}/temp_${file.path.split('/').last}',
      quality: 50, // يمكنك تعديل الجودة حسب الحاجة (0-100)
      minWidth: 800, // العرض الأدنى للصورة بعد الضغط
      minHeight: 800, // الارتفاع الأدنى للصورة بعد الضغط
    );
    return compressedFile;
  }

  // متغيرات جديدة لإدارة مؤشر التحميل
  Timer? _loadingTimer;
  int? _loadingMessageIndex;
  List<String> _loadingDots = ['.', '..', '...'];
  int _currentDot = 0;

  @override
  void initState() {
    super.initState();
    // إضافة رسالة ترحيبية تلقائية
    _messages.add({'text': 'How can I assist you?', 'isUser': false});
  }

  @override
  void dispose() {
    _controller.dispose();
    _loadingTimer?.cancel();
    super.dispose();
  }

  Future<void> _sendMessage({String? text, XFile? image}) async {
    if ((text == null || text.isEmpty) && image == null) return;

    setState(() {
      if (text != null && text.isNotEmpty) {
        _messages.add({'text': text, 'isUser': true});
      }
      if (image != null) {
        _messages.add({'text': 'Sending image...', 'isUser': true});
      }
      // إضافة رسالة تحميل من الذكاء الاصطناعي
      _messages.add({
        'text': _loadingDots[_currentDot],
        'isUser': false,
        'isLoading': true
      });
      _loadingMessageIndex = _messages.length - 1;
      _isSending = true;
    });

    // بدء مؤقت لتحديث مؤشر التحميل
    _loadingTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      setState(() {
        _currentDot = (_currentDot + 1) % _loadingDots.length;
        if (_loadingMessageIndex != null) {
          _messages[_loadingMessageIndex!]['text'] = _loadingDots[_currentDot];
        }
      });
    });

    try {
      // تحضير البيانات للإرسال للباكيند
      Map<String, dynamic> requestBody = {};

      // إضافة النص إذا وجد
      if (text != null && text.isNotEmpty) {
        requestBody['text'] = text;
      }

      // إضافة الصورة إذا وجدت
      if (image != null) {
        Uint8List imageBytes;
        if (kIsWeb) {
          imageBytes = await image.readAsBytes();
        } else {
          final bytes = await image.readAsBytes();
          imageBytes = bytes;
        }
        final base64Image = base64Encode(imageBytes);
        requestBody['image'] = base64Image;
      }

      // إضافة معرف المستخدم (اختياري)
      // requestBody['userId'] = 'user_id_here'; // يمكن إضافة معرف المستخدم إذا كان متاحًا

      // الاتصال بالباكيند
      final response = await http.post(
        Uri.parse(
            'https://21f7-46-153-121-70.ngrok-free.app/chat'), // قم بتغيير الرابط إلى عنوان الباكيند الخاص بك
        // 'https://smart-care-backend-i2pg.onrender.com/chat'), // قم بتغيير الرابط إلى عنوان الباكيند الخاص بك
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        final aiResponse = data['message'] ?? 'No response from AI';

        setState(() {
          if (_loadingMessageIndex != null) {
            _messages[_loadingMessageIndex!]['text'] = aiResponse;
            _messages[_loadingMessageIndex!].remove('isLoading');
            _loadingMessageIndex = null;
          } else {
            _messages.add({'text': aiResponse, 'isUser': false});
          }
        });
      } else {
        print(response.body);
        setState(() {
          if (_loadingMessageIndex != null) {
            _messages[_loadingMessageIndex!]['text'] =
                'Error fetching response';
            _messages[_loadingMessageIndex!].remove('isLoading');
            _loadingMessageIndex = null;
          } else {
            _messages.add({'text': 'Error fetching response', 'isUser': false});
          }
        });
      }
    } catch (e) {
      setState(() {
        if (_loadingMessageIndex != null) {
          _messages[_loadingMessageIndex!]['text'] = 'Failed to send message';
          _messages[_loadingMessageIndex!].remove('isLoading');
          _loadingMessageIndex = null;
        } else {
          _messages.add({'text': 'Failed to send message', 'isUser': false});
        }
      });
    } finally {
      setState(() {
        _isSending = false;
        _selectedImage = null;
        _selectedImageBytes = null;
      });
      // إيقاف المؤقت بعد الانتهاء
      _loadingTimer?.cancel();
      _loadingTimer = null;
      _currentDot = 0;
    }
  }

// Optional: Add this method for tracking requests through the backend endpoint
  Future<void> _trackRequest(String requestNumber) async {
    try {
      final response = await http.post(
        Uri.parse('https://21f7-46-153-121-70.ngrok-free.app/track-request'),
        // Uri.parse('https://smart-care-backend-i2pg.onrender.com/track-request'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'requestNumber': requestNumber,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        if (data['status'] == 'success') {
          final requestData = data['data'];

          String statusMessage = '';
          if (requestData['status'] == 'قيد المعالجة') {
            statusMessage =
                'حالة طلبك رقم $requestNumber هي قيد المعالجة، والتاريخ المتوقع للانتهاء هو ${requestData['expectedDate']}. ${requestData['description']}';
          } else {
            statusMessage =
                'تم اكتمال طلبك رقم $requestNumber بتاريخ ${requestData['completionDate']}. ${requestData['description']}';
          }

          // إضافة الرد لقائمة الرسائل
          setState(() {
            _messages.add({'text': statusMessage, 'isUser': false});
          });
        } else {
          setState(() {
            _messages.add({'text': 'حدث خطأ في تتبع الطلب', 'isUser': false});
          });
        }
      } else {
        setState(() {
          _messages.add({'text': 'رقم الطلب غير موجود', 'isUser': false});
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({'text': 'فشل الاتصال بالخادم', 'isUser': false});
      });
    }
  }

  Future<void> _handleSend() async {
    if (_isTrackingRequest) {
      // إذا كان المستخدم يتابع طلبًا، تأكد من إدخال رقم الطلب
      if (_controller.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter your request number.')),
        );
        return;
      }
      _trackingRequestNumber = _controller.text;
      setState(() {
        _isTrackingRequest = false;
        _inputHint = 'Type a message...';
      });
      // إرسال رسالة تتبع الطلب مع رقم الطلب
      String trackMessage = 'Track my request $_trackingRequestNumber';
      await _sendMessage(text: trackMessage);
      _controller.clear();
      return;
    }
    await _sendMessage(text: _controller.text, image: _selectedImage);
    _controller.clear();
  }

  Future<void> _handleSendImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    if (kIsWeb) {
      // على الويب، نستخدم بايتات الصورة مباشرة
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImage = image;
        _selectedImageBytes = bytes;
      });
      await _sendMessage(image: _selectedImage);
    } else {
      File imageFile = File(image.path);

      // ضغط الصورة
      File? compressedImage = await _compressImage(imageFile);

      if (compressedImage != null) {
        setState(() {
          _selectedImage = XFile(compressedImage.path);
        });
        await _sendMessage(image: _selectedImage);
      } else {
        // إذا فشل الضغط، استخدم الصورة الأصلية
        setState(() {
          _selectedImage = image;
        });
        await _sendMessage(image: _selectedImage);
      }
    }
  }

  // دالة لحذف الصورة المختارة
  void _removeSelectedImage() {
    setState(() {
      _selectedImage = null;
      _selectedImageBytes = null;
    });
  }

  // دالة لمعالجة اختيار الكلمة المفتاحية
  Future<void> _handleKeywordSelection(String keyword) async {
    if (keyword == 'Track my request') {
      // عرض مربع اختيار رقم الطلب من الأرقام الوهمية
      String? selectedNumber = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Select Request Number'),
            content: Container(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _mockRequestNumbers.length,
                itemBuilder: (BuildContext context, int index) {
                  return ListTile(
                    title: Text(_mockRequestNumbers[index]),
                    onTap: () {
                      Navigator.of(context).pop(_mockRequestNumbers[index]);
                    },
                  );
                },
              ),
            ),
          );
        },
      );

      if (selectedNumber != null) {
        setState(() {
          _isKeywordSelected = true;
          _isTrackingRequest =
              false; // تغيير ليصبح false لأننا سنستخدم الباكيند مباشرة
          _inputHint = 'Type a message...';
          // إضافة رسالة توضيحية في الدردشة
          _messages.add({
            'text': 'Tracking request number: $selectedNumber',
            'isUser': true
          });
        });
        // استخدام الدالة الجديدة لتتبع الطلبات
        await _trackRequest(selectedNumber);
      }
    } else {
      setState(() {
        _isKeywordSelected = true;
      });
      await _sendMessage(text: keyword);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Report a Problem',
          style: TextStyle(
            color: AppColors.subtitleColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(
          color: AppColors.iconColor,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          children: [
            // عرض الصورة المختارة إذا وجدت
            if (_selectedImage != null)
              Container(
                padding: EdgeInsets.all(8.0),
                child: Stack(
                  children: [
                    kIsWeb && _selectedImageBytes != null
                        ? Image.memory(
                            _selectedImageBytes!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            File(_selectedImage!.path),
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                    Positioned(
                      right: -10,
                      top: -10,
                      child: IconButton(
                        icon: Icon(Icons.close, color: Colors.red),
                        onPressed: _removeSelectedImage,
                      ),
                    ),
                  ],
                ),
              ),
            // عرض قائمة الرسائل
            Expanded(
              child: ListView.builder(
                reverse: false,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isUser = message['isUser'] as bool;
                  final isLoading = message['isLoading'] ?? false;
                  return Row(
                    mainAxisAlignment: isUser
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: [
                      if (!isUser)
                        Image.asset(
                          'assets/chatbot_svgrepo.png',
                          width: 40,
                        ),
                      Container(
                        margin:
                            EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        padding: EdgeInsets.all(12),
                        constraints: BoxConstraints(maxWidth: 250),
                        decoration: BoxDecoration(
                          color: isUser
                              ? Color(0xFF4C837A).withOpacity(0.3)
                              : Color(0xFFB0B0B0).withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: isLoading
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    message['text'],
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ],
                              )
                            : message['text']
                                    .toString()
                                    .startsWith('data:image')
                                ? Image.memory(
                                    base64Decode(
                                      message['text']
                                          .toString()
                                          .split('base64,')[1],
                                    ),
                                    width: 150,
                                    height: 150,
                                  )
                                : Text(
                                    message['text'],
                                    style: TextStyle(color: Colors.black),
                                  ),
                      ),
                    ],
                  );
                },
              ),
            ),
            // عرض كلمات مفتاحية إذا لم يتم اختيار أي كلمة بعد أو في حالة تتبع طلب
            if (!_isKeywordSelected || _isTrackingRequest)
              Container(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _keywords.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5.0),
                      child: ChoiceChip(
                        label: Text(_keywords[index]),
                        selected: false,
                        onSelected: (_) {
                          _handleKeywordSelection(_keywords[index]);
                        },
                        backgroundColor: Color(0xffC3CE28).withOpacity(0.3),
                        selectedColor: Colors.blue[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          side: BorderSide(color: Colors.transparent),
                        ),
                      ),
                    );
                  },
                ),
              ),
            // عرض TextField بناءً على حالة التطبيق
            if (_isTrackingRequest)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: _inputHint,
                          filled: true,
                          fillColor: Colors.grey[200], // خلفية رصاصية
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none, // إزالة الحدود
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send),
                      onPressed: _isSending ? null : _handleSend,
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: EdgeInsets.all(8.0),
                child: TextField(
                  controller: _controller,
                  enabled: _isKeywordSelected && !_isTrackingRequest,
                  decoration: InputDecoration(
                    hintText: _inputHint,
                    filled: true,
                    fillColor: Colors.grey[200], // خلفية رصاصية
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none, // إزالة الحدود
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min, // لضمان عدم توسع الصف
                      children: [
                        IconButton(
                          icon: Icon(Icons.photo),
                          onPressed: _handleSendImage,
                        ),
                        IconButton(
                          icon: Icon(Icons.send),
                          onPressed: _isSending ? null : _handleSend,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
