import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'lexora_rich_text_controller.dart';
import '../data/document_model.dart';
import '../data/document_repository.dart';
import '../../../services/ai_service.dart';
import '../../../services/ocr_service.dart';
import '../../../services/voice_service.dart';
import '../../../services/export_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_widgets.dart';

class EditorPage extends ConsumerStatefulWidget {
  final String? documentId;

  const EditorPage({Key? key, this.documentId}) : super(key: key);

  @override
  ConsumerState<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends ConsumerState<EditorPage> {
  late LexoraRichTextController _bodyController;
  final TextEditingController _titleController = TextEditingController();
  
  DocumentModel? _document;
  bool _isLoading = true;
  bool _isAutoSaving = false;
  String _saveStatus = 'Saqlanmoqda...';
  Timer? _debounceTimer;

  // Speech recognition state
  bool _isDictating = false;
  String _dictatedText = '';
  double _soundLevel = 0.0;
  
  // Undo/Redo Stacks
  final List<String> _undoStack = [];
  final List<String> _redoStack = [];
  String _lastContent = '';

  @override
  void initState() {
    super.initState();
    _bodyController = LexoraRichTextController();
    _bodyController.addListener(_onContentChanged);
    _titleController.addListener(_onTitleChanged);
    _loadDocument();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _bodyController.removeListener(_onContentChanged);
    _titleController.removeListener(_onTitleChanged);
    _bodyController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  // Load document based on ID
  Future<void> _loadDocument() async {
    setState(() => _isLoading = true);
    final docs = ref.read(documentListProvider);
    
    if (widget.documentId != null) {
      final doc = docs.firstWhere((d) => d.id == widget.documentId);
      _document = doc;
      _titleController.text = doc.title;
      _bodyController.text = doc.content;
      _lastContent = doc.content;
      _saveStatus = doc.isSynced ? 'Bulut bilan sinxronlandi' : 'Qurilmada saqlangan';
    } else {
      // Create fallback document
      _titleController.text = 'Mavzusiz Hujjat';
      _bodyController.text = '';
      _lastContent = '';
      _saveStatus = 'Yangi yaratildi';
    }
    
    setState(() => _isLoading = false);
  }

  // Debounced auto-save triggers
  void _onContentChanged() {
    final currentText = _bodyController.text;
    if (currentText == _lastContent) return;

    // Track Undo state
    if (_undoStack.isEmpty || _undoStack.last != _lastContent) {
      _undoStack.add(_lastContent);
      if (_undoStack.length > 30) _undoStack.removeAt(0); // Cap stack size
      _redoStack.clear();
    }

    _lastContent = currentText;

    _triggerAutoSave();
  }

  void _onTitleChanged() {
    _triggerAutoSave();
  }

  void _triggerAutoSave() {
    setState(() {
      _isAutoSaving = true;
      _saveStatus = 'Saqlanmoqda...';
    });

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1000), () async {
      if (!mounted) return;
      
      final title = _titleController.text.trim();
      final content = _bodyController.text;
      
      if (_document != null) {
        final updatedDoc = _document!.copyWith(
          title: title.isEmpty ? 'Mavzusiz Hujjat' : title,
          content: content,
        );
        
        await ref.read(documentListProvider.notifier).save(updatedDoc);
        _document = updatedDoc;
        
        if (mounted) {
          setState(() {
            _isAutoSaving = false;
            _saveStatus = updatedDoc.isSynced ? 'Sinxronlandi' : 'Saqlandi';
          });
        }
      }
    });
  }

  // Toolbar actions
  void _insertFormatting(String prefix, [String suffix = '']) {
    final text = _bodyController.text;
    final selection = _bodyController.selection;
    
    if (selection.start == -1 || selection.end == -1) {
      // Insert at current cursor
      final cursor = selection.baseOffset == -1 ? text.length : selection.baseOffset;
      final newText = text.substring(0, cursor) + prefix + suffix + text.substring(cursor);
      _bodyController.text = newText;
      _bodyController.selection = TextSelection.collapsed(offset: cursor + prefix.length);
      return;
    }

    final selectedText = text.substring(selection.start, selection.end);
    final replacement = prefix + selectedText + suffix;
    final newText = text.replaceRange(selection.start, selection.end, replacement);
    
    _bodyController.value = TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: selection.start,
        extentOffset: selection.start + replacement.length,
      ),
    );
  }

  void _insertLineStart(String marker) {
    final text = _bodyController.text;
    final selection = _bodyController.selection;
    if (selection.start == -1) return;

    // Find the start of the current paragraph line
    int lineStart = selection.start;
    while (lineStart > 0 && text[lineStart - 1] != '\n') {
      lineStart--;
    }

    final newText = text.replaceRange(lineStart, lineStart, marker);
    _bodyController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + marker.length),
    );
  }

  // Undo / Redo logic
  void _undo() {
    if (_undoStack.isNotEmpty) {
      final previous = _undoStack.removeLast();
      _redoStack.add(_bodyController.text);
      _lastContent = previous;
      
      // Update controller without triggering listener recursion
      _bodyController.removeListener(_onContentChanged);
      _bodyController.text = previous;
      _bodyController.addListener(_onContentChanged);
      
      _triggerAutoSave();
    }
  }

  void _redo() {
    if (_redoStack.isNotEmpty) {
      final next = _redoStack.removeLast();
      _undoStack.add(_bodyController.text);
      _lastContent = next;
      
      _bodyController.removeListener(_onContentChanged);
      _bodyController.text = next;
      _bodyController.addListener(_onContentChanged);
      
      _triggerAutoSave();
    }
  }

  // Speech Recognition Overlay Dialog
  void _startSpeechDictation() async {
    final voiceService = ref.read(voiceServiceProvider);
    
    try {
      final success = await voiceService.initSpeech();
      if (!success) {
        if (mounted) LexoraSnackbar.show(context, message: "Mikrofonga ruxsat olish muvaffaqiyatsiz tugadi.", type: SnackbarType.error);
        return;
      }
      
      setState(() {
        _isDictating = true;
        _dictatedText = '';
        _soundLevel = 0.0;
      });

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                title: Row(
                  children: [
                    const Icon(Icons.mic_rounded, color: Colors.red),
                    const SizedBox(width: 10),
                    const Text("Ovoz orqali yozish"),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Mikrofon tinglamoqda. Uzbek va boshqa tillarda gapiring.",
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    
                    // Decibel Animated Amplitude Indicator
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red.withOpacity(0.1 + (_soundLevel / 40.0).clamp(0.0, 0.8)),
                        ),
                        child: const Icon(Icons.mic, size: 36, color: Colors.red),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          _dictatedText.isEmpty ? "Gapiring..." : _dictatedText,
                          style: TextStyle(
                            fontSize: 16, 
                            fontStyle: _dictatedText.isEmpty ? FontStyle.italic : FontStyle.normal,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () async {
                      await voiceService.cancelListening();
                      Navigator.pop(context);
                      setState(() => _isDictating = false);
                    },
                    child: const Text("Bekor qilish", style: TextStyle(color: Colors.grey)),
                  ),
                  TextButton(
                    onPressed: () async {
                      await voiceService.stopListening();
                      Navigator.pop(context);
                      setState(() => _isDictating = false);
                      _insertTextAtCursor(_dictatedText);
                    },
                    child: const Text("Matnni kiritish", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              );
            },
          );
        },
      );

      // Start actual listening
      await voiceService.startListening(
        onResult: (words) {
          setState(() => _dictatedText = words);
          // Redraw dialog content
          try {
            Navigator.of(context, rootNavigator: true).setState(() {});
          } catch (_) {}
        },
        onSoundLevel: (level) {
          setState(() => _soundLevel = level);
        },
        onComplete: () {
          // Finished auto-timeout listening
        }
      );
    } catch (e) {
      setState(() => _isDictating = false);
      LexoraSnackbar.show(context, message: e.toString().replaceFirst("Exception: ", ""), type: SnackbarType.error);
    }
  }

  void _insertTextAtCursor(String textToInsert) {
    if (textToInsert.trim().isEmpty) return;
    
    final currentText = _bodyController.text;
    final selection = _bodyController.selection;
    final cursor = selection.baseOffset == -1 ? currentText.length : selection.baseOffset;
    
    final newText = currentText.substring(0, cursor) + " " + textToInsert + currentText.substring(cursor);
    _bodyController.text = newText;
    _bodyController.selection = TextSelection.collapsed(offset: cursor + textToInsert.length + 1);
  }

  // Camera/Gallery OCR extraction
  void _triggerOCRScan(ImageSource source) async {
    final ocrService = ref.read(ocrServiceProvider);
    
    setState(() => _isAutoSaving = true);
    
    try {
      final file = await ocrService.pickImage(source);
      if (file == null) return;
      
      // Show processing loading toast
      if (mounted) {
        LexoraSnackbar.show(context, message: "Rasm tahlil qilinmoqda, kuting...", type: SnackbarType.ai);
      }
      
      final text = await ocrService.extractText(file);
      
      if (mounted) {
        _insertTextAtCursor(text);
        LexoraSnackbar.show(context, message: "Matn muvaffaqiyatli aniqlandi va kiritildi!", type: SnackbarType.success);
      }
    } catch (e) {
      if (mounted) {
        LexoraSnackbar.show(context, message: e.toString().replaceFirst("Exception: ", ""), type: SnackbarType.error);
      }
    } finally {
      if (mounted) setState(() => _isAutoSaving = false);
    }
  }

  // AI assistant triggers sheet
  void _openAIAssistantSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Aqlli AI yordamchisi",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Taqdim etilgan matnni tahlil qilish uchun quyidagi AI vositalarini tanlang:",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.spellcheck_rounded, color: Colors.blue),
                title: const Text("Imlo va Grammar xatolarni tekshirish (Uzbek)"),
                onTap: () {
                  Navigator.pop(context);
                  _runAIFeature((ai) => ai.checkGrammar(_bodyController.text), "Grammar tahlil");
                },
              ),
              ListTile(
                leading: const Icon(Icons.summarize_outlined, color: Colors.green),
                title: const Text("Matnni qisqacha xulosa qilish (Summary)"),
                onTap: () {
                  Navigator.pop(context);
                  _runAIFeature((ai) => ai.summarizeText(_bodyController.text), "Xulosa tuzish");
                },
              ),
              ListTile(
                leading: const Icon(Icons.star_purple500_rounded, color: Colors.purple),
                title: const Text("Matnni professional uslubga keltirish (Polish)"),
                onTap: () {
                  Navigator.pop(context);
                  _runAIFeature((ai) => ai.changeTone(_bodyController.text), "Professional uslub");
                },
              ),
              ListTile(
                leading: const Icon(Icons.translate_rounded, color: Colors.orange),
                title: const Text("Matnni tarjima qilish (Uzbek ↔ English)"),
                onTap: () {
                  Navigator.pop(context);
                  _runAIFeature(
                    (ai) => ai.translate(_bodyController.text, "Uzbek", "English"),
                    "Tarjima qilish"
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Run AI operations with beautiful review bottom sheets
  Future<void> _runAIFeature(Future<String> Function(AIService) action, String featureTitle) async {
    final aiService = ref.read(aiServiceProvider);
    
    // Show glassmorphic loader dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: LexoraLoader(statusText: "Matn Muharriri matnni qayta ishlamoqda..."),
      ),
    );

    try {
      final response = await action(aiService);
      
      if (mounted) {
        Navigator.pop(context); // dismiss loader
        _showAIReviewSheet(featureTitle, response);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // dismiss loader
        LexoraSnackbar.show(
          context, 
          message: e.toString().replaceFirst("Exception: ", ""), 
          type: SnackbarType.error
        );
      }
    }
  }

  void _showAIReviewSheet(String title, String aiOutput) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).dividerColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          aiOutput,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: LexoraButton(
                          text: "Hujjatga qo'shish",
                          isSecondary: true,
                          onPressed: () {
                            Navigator.pop(context);
                            _insertTextAtCursor("\n\n$aiOutput");
                            LexoraSnackbar.show(context, message: "AI matni hujjatga qo'shildi!");
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: LexoraButton(
                          text: "Matnni almashtirish",
                          onPressed: () {
                            Navigator.pop(context);
                            _bodyController.text = aiOutput;
                            LexoraSnackbar.show(context, message: "Hujjat matni yangilandi!");
                          },
                        ),
                      ),
                    ],
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Trigger exports
  void _openExportOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hujjatni eksport qilish",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red),
                title: const Text("PDF formatida ulashish"),
                onTap: () async {
                  Navigator.pop(context);
                  _exportDoc((export) => export.exportAsPdf(_titleController.text, _bodyController.text));
                },
              ),
              ListTile(
                leading: const Icon(Icons.text_snippet_rounded, color: Colors.blue),
                title: const Text("TXT formatida ulashish"),
                onTap: () {
                  Navigator.pop(context);
                  _exportDoc((export) => export.exportAsTxt(_titleController.text, _bodyController.text));
                },
              ),
              ListTile(
                leading: const Icon(Icons.print_rounded, color: Colors.purple),
                title: const Text("Hujjatni chop etish (Print)"),
                onTap: () async {
                  Navigator.pop(context);
                  final export = ref.read(exportServiceProvider);
                  try {
                    final pdfFile = await export.exportAsPdf(_titleController.text, _bodyController.text);
                    await export.printDocument(pdfFile);
                  } catch (e) {
                    LexoraSnackbar.show(context, message: e.toString(), type: SnackbarType.error);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _exportDoc(Future<File> Function(ExportService) action) async {
    final export = ref.read(exportServiceProvider);
    
    try {
      final file = await action(export);
      await export.shareFile(file, _titleController.text);
    } catch (e) {
      if (mounted) {
        LexoraSnackbar.show(
          context, 
          message: e.toString().replaceFirst("Exception: ", ""), 
          type: SnackbarType.error
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: LexoraLoader(statusText: "Hujjat yuklanmoqda...")),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              _titleController.text.isEmpty ? "Mavzusiz Hujjat" : _titleController.text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              _saveStatus,
              style: TextStyle(
                fontSize: 11, 
                color: _isAutoSaving ? theme.primaryColor : Colors.grey,
                fontWeight: FontWeight.w600
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF8B5CF6)),
            onPressed: _openAIAssistantSheet,
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _openExportOptions,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Document Stats Ribbon
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                border: Border(bottom: BorderSide(color: theme.dividerColor, width: 0.5)),
              ),
              child: Row(
                children: [
                  Icon(Icons.query_stats_rounded, size: 16, color: theme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    "${_bodyController.text.trim().isEmpty ? 0 : _bodyController.text.trim().split(RegExp(r'\s+')).length} so'z",
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    "${_bodyController.text.length} belgi",
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.undo_rounded, size: 20),
                    onPressed: _undoStack.isNotEmpty ? _undo : null,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.redo_rounded, size: 20),
                    onPressed: _redoStack.isNotEmpty ? _redo : null,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Document Inputs (Title + Body)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                      decoration: const InputDecoration(
                        hintText: "Hujjat nomi...",
                        filled: false,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _bodyController,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.6,
                        letterSpacing: 0.3,
                      ),
                      decoration: const InputDecoration(
                        hintText: "Yozishni boshlang. Markdown sintaksisi qo'llab-quvvatlanadi...",
                        filled: false,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Premium Custom Editing Toolbar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  )
                ],
              ),
              child: Column(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildToolbarItem(Icons.format_bold_rounded, "Bold", () => _insertFormatting('**', '**')),
                        _buildToolbarItem(Icons.format_italic_rounded, "Italic", () => _insertFormatting('*', '*')),
                        _buildToolbarItem(Icons.format_underlined_rounded, "Underline", () => _insertFormatting('_', '_')),
                        _buildToolbarItem(Icons.code_rounded, "Code", () => _insertFormatting('`', '`')),
                        _buildToolbarItem(Icons.title_rounded, "H1", () => _insertLineStart('# ')),
                        _buildToolbarItem(Icons.text_fields_rounded, "H2", () => _insertLineStart('## ')),
                        _buildToolbarItem(Icons.format_list_bulleted_rounded, "Bullets", () => _insertLineStart('* ')),
                        _buildToolbarItem(Icons.format_list_numbered_rounded, "Numbers", () => _insertLineStart('1. ')),
                        _buildToolbarItem(Icons.format_quote_rounded, "Quote", () => _insertLineStart('> ')),
                      ],
                    ),
                  ),
                  const Divider(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Voice to Text
                      IconButton(
                        icon: const Icon(Icons.mic_none_rounded, color: Colors.red),
                        onPressed: _startSpeechDictation,
                      ),
                      
                      // OCR Scanning actions
                      IconButton(
                        icon: const Icon(Icons.camera_alt_outlined, color: Colors.green),
                        onPressed: () => _triggerOCRScan(ImageSource.camera),
                      ),
                      IconButton(
                        icon: const Icon(Icons.photo_library_outlined, color: Colors.blue),
                        onPressed: () => _triggerOCRScan(ImageSource.gallery),
                      ),
                      
                      // AI Shortcut
                      IconButton(
                        icon: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF8B5CF6)),
                        onPressed: _openAIAssistantSheet,
                      ),
                      
                      // Clear Screen / Immersive writing option
                      IconButton(
                        icon: const Icon(Icons.keyboard_hide_outlined),
                        onPressed: () => FocusScope.of(context).unfocus(),
                      ),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildToolbarItem(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 4),
                Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
