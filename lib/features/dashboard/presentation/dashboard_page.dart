import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/routes/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_widgets.dart';
import '../../editor/data/document_model.dart';
import '../../editor/data/document_repository.dart';
import '../../../services/local_auth_service.dart';
import '../../../services/export_service.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  bool _isGridView = false;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _renameController = TextEditingController();

  late AnimationController _fabController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _fabAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _renameController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _createNewDocument() async {
    final uuid = const Uuid().v4();
    final newDoc = DocumentModel(
      id: uuid,
      title: 'Yangi Hujjat', // Untitled Document in Uzbek
      content: '',
      userId: '',
      lastModified: DateTime.now(),
    );

    await ref.read(documentListProvider.notifier).save(newDoc);
    if (mounted) {
      Navigator.pushNamed(context, AppRoutes.editor, arguments: newDoc.id);
    }
  }

  void _renameDocDialog(DocumentModel doc) {
    _renameController.text = doc.title;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Hujjat nomini o'zgartirish"),
          content: LexoraTextField(
            controller: _renameController,
            label: "Hujjat nomi",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Bekor qilish", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                final newTitle = _renameController.text.trim();
                if (newTitle.isNotEmpty) {
                  await ref.read(documentListProvider.notifier).rename(doc.id, newTitle);
                  if (mounted) {
                    Navigator.pop(context);
                    LexoraSnackbar.show(context, message: "Nom o'zgartirildi!");
                  }
                }
              },
              child: const Text("Saqlash"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _shareDoc(DocumentModel doc) async {
    try {
      final exportService = ref.read(exportServiceProvider);
      final file = await exportService.exportAsTxt(doc.title, doc.content);
      await exportService.shareFile(file, doc.title);
    } catch (e) {
      LexoraSnackbar.show(context, message: e.toString().replaceFirst("Exception: ", ""), type: SnackbarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final docs = ref.watch(documentListProvider);
    final isGuest = ref.watch(guestModeProvider);
    final user = ref.watch(authServiceProvider).currentUser;

    // Filter documents
    final filteredDocs = docs.where((doc) {
      final query = _searchQuery.toLowerCase().trim();
      return doc.title.toLowerCase().contains(query) || doc.content.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              "LexoraAI",
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: CircleAvatar(
              radius: 18,
              backgroundColor: theme.primaryColor.withOpacity(0.1),
              child: Icon(
                isGuest ? Icons.person_outline_rounded : Icons.person_rounded,
                size: 20,
                color: theme.primaryColor,
              ),
            ),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => ref.read(documentListProvider.notifier).refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting & Subheading
                  Text(
                    isGuest ? "Salom, Mehmon!" : "Xayrli kun!",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    "Ijodingizni bugun boshlang",
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quick AI Shortcuts
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionCard(
                          icon: Icons.add_rounded,
                          title: "Yangi hujjat",
                          subtitle: "Yozishni boshlash",
                          gradient: AppTheme.primaryGradient,
                          onTap: _createNewDocument,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildQuickActionCard(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: "AI Chat",
                          subtitle: "Muloqot qilish",
                          gradient: AppTheme.aiGradient,
                          onTap: () => Navigator.pushNamed(context, AppRoutes.aiChat),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: theme.textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: "Hujjatlarni qidirish...",
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.transparent,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title of List & Layout Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _searchQuery.isNotEmpty ? "Qidiruv natijalari" : "Oxirgi hujjatlar",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      IconButton(
                        icon: Icon(_isGridView ? Icons.list_rounded : Icons.grid_view_rounded),
                        onPressed: () => setState(() => _isGridView = !_isGridView),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Documents Render
                  if (filteredDocs.isEmpty)
                    _buildEmptyState(theme, isDark)
                  else if (_isGridView)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredDocs.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.85,
                      ),
                      itemBuilder: (context, idx) => _buildGridDocCard(context, filteredDocs[idx], theme, isDark),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredDocs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, idx) => _buildListDocCard(context, filteredDocs[idx], theme, isDark),
                    ),
                ],
              ),
            ),
          ),
          
          // Pulsing AI Floating Action Button
          Positioned(
            bottom: 30,
            right: 20,
            child: ScaleTransition(
              scale: _fabAnimation,
              child: FloatingActionButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.aiChat),
                elevation: 10,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                backgroundColor: const Color(0xFF8B5CF6),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: AppTheme.aiGradient,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          CircleAvatar(
            radius: 40,
            backgroundColor: theme.primaryColor.withOpacity(0.05),
            child: Icon(Icons.description_outlined, color: theme.primaryColor, size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            "Hujjatlar topilmadi",
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty 
                ? "Qidiruv bo'yicha hujjat topilmadi. Boshqa kalit so'z sinab ko'ring." 
                : "Hozircha hech qanday hujjat yaratilmagan. Yangi yaratish tugmasini bosing.",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildListDocCard(BuildContext context, DocumentModel doc, ThemeData theme, bool isDark) {
    final formattedDate = DateFormat('dd.MM.yyyy HH:mm').format(doc.lastModified);
    return Card(
      elevation: 1.5,
      child: ListTile(
        onTap: () => Navigator.pushNamed(context, AppRoutes.editor, arguments: doc.id),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.primaryColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.article_rounded, color: theme.primaryColor, size: 24),
        ),
        title: Text(
          doc.title,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Text(
              formattedDate,
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
            ),
            const SizedBox(width: 8),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(shape: BoxShape.circle, color: theme.dividerColor),
            ),
            const SizedBox(width: 8),
            Text(
              "${doc.wordCount} so'z",
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
            ),
            if (doc.isSynced) ...[
              const SizedBox(width: 8),
              const Icon(Icons.cloud_done_rounded, size: 14, color: Colors.green),
            ]
          ],
        ),
        trailing: _buildPopupMenu(doc, theme),
      ),
    );
  }

  Widget _buildGridDocCard(BuildContext context, DocumentModel doc, ThemeData theme, bool isDark) {
    final formattedDate = DateFormat('dd.MM.yyyy').format(doc.lastModified);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor, width: 1.2),
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, AppRoutes.editor, arguments: doc.id),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.article_rounded, color: theme.primaryColor, size: 28),
                _buildPopupMenu(doc, theme),
              ],
            ),
            const Spacer(),
            Text(
              doc.title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formattedDate,
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11),
                ),
                Text(
                  "${doc.wordCount} so'z",
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPopupMenu(DocumentModel doc, ThemeData theme) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (value) async {
        if (value == 'rename') {
          _renameDocDialog(doc);
        } else if (value == 'delete') {
          await ref.read(documentListProvider.notifier).delete(doc.id);
          if (mounted) LexoraSnackbar.show(context, message: "Hujjat o'chirildi!");
        } else if (value == 'share') {
          await _shareDoc(doc);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'rename',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 20),
              SizedBox(width: 10),
              Text("Nomini o'zgartirish"),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'share',
          child: Row(
            children: [
              Icon(Icons.share_outlined, size: 20),
              SizedBox(width: 10),
              Text("Ulashish (Share)"),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
              SizedBox(width: 10),
              Text("O'chirish", style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }
}
