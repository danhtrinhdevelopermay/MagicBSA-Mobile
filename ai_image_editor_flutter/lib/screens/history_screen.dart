import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/history_item.dart';
import '../services/history_service.dart';
import '../widgets/result_widget.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<HistoryItem> _allHistory = [];
  List<HistoryItem> _filteredHistory = [];
  bool _isLoading = true;
  String _selectedFilter = 'Tất cả';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<HistoryItem> history = await HistoryService.getHistory();
      setState(() {
        _allHistory = history;
        _filteredHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải lịch sử: $e')),
        );
      }
    }
  }

  void _filterHistory(String filter) {
    setState(() {
      _selectedFilter = filter;
      if (filter == 'Tất cả') {
        _filteredHistory = _allHistory;
      } else {
        String operationKey = _getOperationKey(filter);
        _filteredHistory = _allHistory.where((item) => item.operation == operationKey).toList();
      }
    });
  }

  String _getOperationKey(String displayName) {
    switch (displayName) {
      case 'Xóa nền':
        return 'removeBackground';
      case 'Xóa text':
        return 'removeText';
      case 'Dọn dẹp':
        return 'cleanup';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ));
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Main content
            Expanded(
              child: _buildHistoryContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(
                colors: [Color(0xFF6366f1), Color(0xFF8b5cf6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(
              Icons.history,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Lịch sử chỉnh sửa',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1e293b),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Filter tabs
          _buildFilterTabs(),
          const SizedBox(height: 16),
          
          // History list
          Expanded(
            child: _buildHistoryList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    List<String> filters = ['Tất cả', 'Xóa nền', 'Xóa text', 'Dọn dẹp'];
    
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: filters.map((filter) => _buildFilterTab(filter, _selectedFilter == filter)).toList(),
      ),
    );
  }

  Widget _buildFilterTab(String title, bool isActive) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _filterHistory(title),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: isActive ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ] : null,
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? const Color(0xFF6366f1) : const Color(0xFF64748b),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366f1)),
        ),
      );
    }

    if (_filteredHistory.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 120), // Add padding for navigation
      itemCount: _filteredHistory.length,
      itemBuilder: (context, index) {
        final item = _filteredHistory[index];
        return _buildHistoryItem(item);
      },
    );
  }

  Widget _buildHistoryItem(HistoryItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () => _viewHistoryItem(item),
        child: Row(
          children: [
            // Thumbnail - show actual processed image
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  item.processedImageData,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: _getGradientForType(item.operation).colors.first,
                      child: Icon(
                        _getIconForType(item.operation),
                        color: Colors.white,
                        size: 24,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1e293b),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(item.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748b),
                    ),
                  ),
                ],
              ),
            ),
            
            // Action buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _downloadHistoryItem(item),
                  icon: const Icon(
                    Icons.download_outlined,
                    size: 20,
                    color: Color(0xFF64748b),
                  ),
                ),
                IconButton(
                  onPressed: () => _shareHistoryItem(item),
                  icon: const Icon(
                    Icons.share_outlined,
                    size: 20,
                    color: Color(0xFF64748b),
                  ),
                ),
                IconButton(
                  onPressed: () => _deleteHistoryItem(item),
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Color(0xFFef4444),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.history,
              size: 40,
              color: Color(0xFF94a3b8),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chưa có lịch sử chỉnh sửa',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748b),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Các ảnh bạn đã chỉnh sửa sẽ xuất hiện ở đây',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF94a3b8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  LinearGradient _getGradientForType(String type) {
    switch (type) {
      case 'background_removal':
        return const LinearGradient(
          colors: [Color(0xFF6366f1), Color(0xFF8b5cf6)],
        );
      case 'cleanup':
        return const LinearGradient(
          colors: [Color(0xFF8b5cf6), Color(0xFFec4899)],
        );
      case 'text_to_image':
        return const LinearGradient(
          colors: [Color(0xFFec4899), Color(0xFFf97316)],
        );
      case 'uncrop':
        return const LinearGradient(
          colors: [Color(0xFF10b981), Color(0xFF3b82f6)],
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF6366f1), Color(0xFF8b5cf6)],
        );
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'background_removal':
        return Icons.layers_clear;
      case 'cleanup':
        return Icons.cleaning_services;
      case 'text_to_image':
        return Icons.text_fields;
      case 'uncrop':
        return Icons.crop_free;
      default:
        return Icons.image;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays == 1) {
      return 'Hôm qua';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _viewHistoryItem(HistoryItem item) {
    if (item.originalImageData != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultWidget(
            originalImageData: item.originalImageData!,
            processedImage: item.processedImageData,
            onStartOver: () => Navigator.pop(context),
          ),
        ),
      );
    }
  }

  Future<void> _downloadHistoryItem(HistoryItem item) async {
    try {
      await HistoryService.downloadHistoryItem(item);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã tải ảnh về thư mục Downloads')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải ảnh: $e')),
        );
      }
    }
  }

  Future<void> _shareHistoryItem(HistoryItem item) async {
    try {
      await HistoryService.shareHistoryItem(item);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi chia sẻ: $e')),
        );
      }
    }
  }

  Future<void> _deleteHistoryItem(HistoryItem item) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa ảnh khỏi lịch sử'),
        content: const Text('Bạn có chắc muốn xóa ảnh này khỏi lịch sử không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await HistoryService.deleteHistoryItem(item.id);
        await _loadHistory(); // Reload history
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa ảnh khỏi lịch sử')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi xóa: $e')),
          );
        }
      }
    }
  }
}