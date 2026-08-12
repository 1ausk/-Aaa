import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const TranslatorApp());
}

class TranslatorApp extends StatelessWidget {
  const TranslatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مترجم ومحلل المصطلحات',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
        primaryColor: const Color(0xFF007ACC),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // نص افتراضي للتجربة واختبار فصل الكلمات الشائعة في الأكواد والملفات
  String currentText = "getUserData calculate_total_amount fetchTextFromApi";
  bool isLoading = false;
  List<Map<String, String>> processedWords = [];

  // تفكيك الكلمات الملتصقة (camelCase & snake_case)
  String splitJoinedWords(String text) {
    String step1 = text.replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'), (match) => '${match[1]} ${match[2]}');
    String step2 = step1.replaceAllMapped(
        RegExp(r'([a-zA-Z])(_)([a-zA-Z])'), (match) => '${match[1]} ${match[3]}');
    return step2;
  }

  // معالجة الكلمات والاتصال بمحرك الترجمة والشرح
  Future<void> processAndTranslate() async {
    setState(() {
      isLoading = true;
      processedWords.clear();
    });

    List<String> rawTokens = currentText.split(RegExp(r'\s+'));

    for (String token in rawTokens) {
      if (token.trim().isEmpty) continue;

      String cleanedText = splitJoinedWords(token);
      String translation = await fetchTranslation(cleanedText);

      setState(() {
        processedWords.add({
          'original': token,
          'separated': cleanedText,
          'translation': translation,
        });
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  // الاتصال بمحرك الترجمة المجاني وسريع الاستجابة
  Future<String> fetchTranslation(String text) async {
    try {
      final url = Uri.parse(
          'https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(text)}&langpair=en|ar');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String translated = data['responseData']['translatedText'] ?? '—';
        return translated.length > 20 ? '${translated.substring(0, 18)}..' : translated;
      }
      return '—';
    } catch (e) {
      return 'خطأ بالترجمة';
    }
  }

  // قائمة التطبيقات الشائعة لفتحها عبر بروتوكول Deep Links
  void _showAppSelectionDialog() {
    final Map<String, String> apps = {
      'متصفح Chrome': 'https://google.com',
      'تطبيق WhatsApp': 'whatsapp://',
      'ملفات Google Drive': 'https://drive.google.com',
      'محرر النصوص (سحابي)': 'https://vscode.dev',
    };

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF252526),
          title: const Text('اختر التطبيق المفتوح', textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: apps.entries.map((entry) {
              return ListTile(
                title: Text(entry.key, style: const TextStyle(color: Colors.white)),
                trailing: const Icon(Icons.open_in_new, color: Color(0xFF007ACC)),
                onTap: () async {
                  Navigator.pop(context);
                  final Uri uri = Uri.parse(entry.value);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('تعذر فتح ${entry.key}')),
                    );
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المترجم والشرح الفوري'),
        backgroundColor: const Color(0xFF252526),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // شريط الأزرار الرئيسي (الزر الأول والزر الثاني)
          Container(
            padding: const EdgeInsets.all(12.0),
            color: const Color(0xFF252526),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007ACC),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _showAppSelectionDialog,
                    icon: const Icon(Icons.apps, color: Colors.white),
                    label: const Text('اختر التطبيق',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: processAndTranslate,
                    icon: const Icon(Icons.translate, color: Colors.white),
                    label: const Text('ترجمة وشرح',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          
          // عرض النتائج والكلمات المفككة
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : processedWords.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextField(
                            maxLines: 5,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'أدخل أو الصق النص/الكود هنا للتجربة...',
                              hintStyle: TextStyle(color: Colors.grey),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) => currentText = val,
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 12,
                          children: processedWords.map((item) {
                            return Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2D3748),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.blueGrey.shade700),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    item['translation']!,
                                    style: const TextStyle(
                                        color: Colors.tealAccent,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item['separated']!,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontFamily: 'monospace'),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
