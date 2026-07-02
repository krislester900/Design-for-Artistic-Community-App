import 'dart:async';
import 'package:flutter/foundation.dart';

typedef PaginatedItems<T> = List<T>;
typedef PaginatedResponse<T> = ({
  PaginatedItems<T> items,
  bool hasMore,
  int? nextPage,
  int totalCount,
});

class PaginationService {
  static const int _defaultPageSize = 20;
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoading = false;
  final int pageSize;

  PaginationService({this.pageSize = _defaultPageSize});

  int get currentPage => _currentPage;
  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;

  void reset() {
    _currentPage = 0;
    _hasMore = true;
    _isLoading = false;
  }

  Future<PaginatedResponse<T>> fetchPage<T>({
    required Future<PaginatedResponse<T>> Function(int page, int pageSize) fetcher,
  }) async {
    if (_isLoading || !_hasMore) {
      return (items: <T>[], hasMore: false, nextPage: null, totalCount: 0);
    }

    _isLoading = true;

    try {
      final response = await fetcher(_currentPage, pageSize);
      
      _currentPage++;
      _hasMore = response.hasMore;
      
      return response;
    } finally {
      _isLoading = false;
    }
  }
}

class PaginatedController<T> extends ChangeNotifier {
  final PaginationService _pagination = PaginationService();
  final Future<PaginatedResponse<T>> Function(int page, int pageSize) _fetcher;
  
  PaginatedItems<T> _items = [];
  bool get hasMore => _pagination.hasMore;
  bool get isLoading => _pagination.isLoading;
  PaginatedItems<T> get items => List.unmodifiable(_items);

  PaginatedController(this._fetcher);

  Future<void> loadInitial() async {
    _pagination.reset();
    _items = [];
    
    final response = await _pagination.fetchPage(fetcher: _fetcher);
    _items = response.items;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_pagination.isLoading || !_pagination.hasMore) return;

    final response = await _pagination.fetchPage(fetcher: _fetcher);
    _items.addAll(response.items);
    notifyListeners();
  }

  void refresh() {
    _pagination.reset();
    _items = [];
    notifyListeners();
    loadInitial();
  }
}