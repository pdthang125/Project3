/// Parsed receipt data extracted from OCR text
class ParsedReceiptData {
  final double? totalAmount;
  final DateTime? date;
  final String? merchantName;
  final String rawText;

  const ParsedReceiptData({
    this.totalAmount,
    this.date,
    this.merchantName,
    required this.rawText,
  });

  ParsedReceiptData copyWith({
    double? totalAmount,
    DateTime? date,
    String? merchantName,
    String? rawText,
  }) =>
      ParsedReceiptData(
        totalAmount: totalAmount ?? this.totalAmount,
        date: date ?? this.date,
        merchantName: merchantName ?? this.merchantName,
        rawText: rawText ?? this.rawText,
      );
}

/// Regex heuristics engine for Vietnamese receipts
class ReceiptParser {
  ReceiptParser._();

  static ParsedReceiptData parse(String rawText) {
    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    return ParsedReceiptData(
      totalAmount: _extractAmount(lines),
      date: _extractDate(rawText),
      merchantName: _extractMerchantName(lines),
      rawText: rawText,
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  static const _diacritics = {
    'a': 'àáạảãâầấậẩẫăằắặẳẵ',
    'e': 'èéẹẻẽêềếệểễ',
    'i': 'ìíịỉĩ',
    'o': 'òóọỏõôồốộổỗơờớợởỡ',
    'u': 'ùúụủũưừứựửữ',
    'y': 'ỳýỵỷỹ',
    'd': 'đ',
  };

  /// lowercase + bỏ dấu để regex không phụ thuộc OCR đọc đúng dấu
  static String _fold(String s) {
    var r = s.toLowerCase();
    _diacritics.forEach((base, chars) {
      for (final c in chars.split('')) {
        r = r.replaceAll(c, base);
      }
    });
    return r;
  }

  // ─── Amount ───────────────────────────────────────────────────────────────

  // Dòng chứa số tiền cuối cùng cần trả
  static final _totalKw = RegExp(
    r'tong\s*(cong|tien|thanh\s*toan|so\s*tien)|thanh\s*toan|phai\s*tra|'
    r'can\s*thanh\s*toan|grand\s*total|\btotal\b|amount\s*due|\btong\b',
  );

  // Dòng KHÔNG được lấy số tiền
  static final _badLineKw = RegExp(
    r'tam\s*tinh|subtotal|vat|thue|giam\s*gia|discount|khach\s*dua|tien\s*thua|'
    r'tra\s*lai|change|cash|so\s*luong|tel|sdt|dt:|hotline|fax|mst|ma\s*so|'
    r'barcode|so\s*hd|invoice\s*no|diem|point',
  );

  static final _numPattern = RegExp(
    r'(?<![\d.,])(\d{1,3}(?:[.,]\d{3})+(?:[.,]\d{1,2})?|[1-9]\d{3,9})(?!\d)',
  );

  static double? _extractAmount(List<String> lines) {
    final folded = lines.map(_fold).toList();

    // Chiến lược 1: dòng có từ khóa "tổng"/"thanh toán" → lấy dòng CUỐI cùng
    // (vì có thể có "tổng tiền hàng" rồi giảm giá rồi "tổng thanh toán")
    double? found;
    for (var i = 0; i < lines.length; i++) {
      if (!_totalKw.hasMatch(folded[i])) continue;
      if (_badLineKw.hasMatch(folded[i])) continue;

      var amount = _lastAmountIn(lines[i]);
      // nhãn và số bị tách dòng → xem tối đa 2 dòng kế tiếp
      for (var k = 1; amount == null && k <= 2 && i + k < lines.length; k++) {
        if (_badLineKw.hasMatch(folded[i + k])) break;
        amount = _lastAmountIn(lines[i + k]);
      }
      if (amount != null) found = amount;
    }
    if (found != null) return found;

    // Chiến lược 2: số lớn nhất trên các dòng "sạch"
    double? best;
    for (var i = 0; i < lines.length; i++) {
      if (_badLineKw.hasMatch(folded[i])) continue;
      final v = _lastAmountIn(lines[i]);
      if (v != null && v >= 1000 && v <= 1e9 && (best == null || v > best)) {
        best = v;
      }
    }
    return best;
  }

  /// Số cuối cùng trong dòng (cột giá luôn nằm bên phải)
  static double? _lastAmountIn(String line) {
    final matches = _numPattern.allMatches(line).toList();
    if (matches.isEmpty) return null;
    return _normalizeAmount(matches.last.group(1)!);
  }

  /// "150.000" | "150,000" | "150.000,00" → 150000
  static double? _normalizeAmount(String raw) {
    var s = raw.trim();
    final dec = RegExp(r'[.,]\d{1,2}$').firstMatch(s); // phần thập phân
    if (dec != null) s = s.substring(0, dec.start);
    s = s.replaceAll(RegExp(r'[.,]'), '');
    return double.tryParse(s);
  }

  // ─── Date ─────────────────────────────────────────────────────────────────

  static DateTime? _extractDate(String text) {
    final t = _fold(text);

    // 15/03/2024, 15-03-24, 15.03.2024
    final dmy = RegExp(r'(?<!\d)(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{4}|\d{2})(?!\d)');
    for (final m in dmy.allMatches(t)) {
      var y = int.parse(m.group(3)!);
      if (m.group(3)!.length == 2) y += 2000;
      final d = _tryDate(y, int.parse(m.group(2)!), int.parse(m.group(1)!));
      if (d != null) return d;
    }
    // 2024-03-15
    final ymd = RegExp(r'(?<!\d)(\d{4})[/\-.](\d{1,2})[/\-.](\d{1,2})(?!\d)');
    for (final m in ymd.allMatches(t)) {
      final d = _tryDate(int.parse(m.group(1)!), int.parse(m.group(2)!),
          int.parse(m.group(3)!));
      if (d != null) return d;
    }
    // Ngày 15 tháng 03 năm 2024
    final long = RegExp(r'ngay\s*(\d{1,2})\s*thang\s*(\d{1,2})\s*nam\s*(\d{4})');
    for (final m in long.allMatches(t)) {
      final d = _tryDate(int.parse(m.group(3)!), int.parse(m.group(2)!),
          int.parse(m.group(1)!));
      if (d != null) return d;
    }
    return null;
  }

  static DateTime? _tryDate(int y, int m, int d) {
    final maxYear = DateTime.now().year + 1;
    if (y < 2000 || y > maxYear || m < 1 || m > 12 || d < 1 || d > 31) {
      return null;
    }
    final dt = DateTime(y, m, d);
    return (dt.day == d && dt.month == m) ? dt : null;
  }

  // ─── Merchant ─────────────────────────────────────────────────────────────

  // Mở rộng database thương hiệu với nhiều tên Việt Nam và quốc tế hơn
  static const _brands = {
    // Siêu thị & Cửa hàng tiện lợi
    'winmart': 'WinMart', 'vinmart': 'VinMart', 'winmart+': 'WinMart+',
    'circle k': 'Circle K', 'gs25': 'GS25', 'familymart': 'FamilyMart',
    'family mart': 'FamilyMart', 'bach hoa xanh': 'Bách Hóa Xanh',
    'bhx': 'Bách Hóa Xanh', 'coopmart': 'Co.opmart', 'co.opmart': 'Co.opmart',
    'co.op': 'Co.op', 'coop food': 'Co.op Food', 'lotte': 'Lotte Mart',
    'aeon': 'AEON', 'big c': 'Big C', 'mega market': 'MM Mega Market',
    'mm mega': 'MM Mega Market', 'mini stop': 'MiniStop', 'ministop': 'MiniStop',
    '7-eleven': '7-Eleven', '7 eleven': '7-Eleven', 'satra': 'Satra',
    
    // Cà phê & Trà sữa
    'highlands': 'Highlands Coffee', 'highland': 'Highlands Coffee',
    'starbucks': 'Starbucks', 'phuc long': 'Phúc Long', 'phuclong': 'Phúc Long',
    'coffee house': 'The Coffee House', 'the coffee house': 'The Coffee House',
    'katinat': 'Katinat', 'gong cha': 'Gong Cha', 'gongcha': 'Gong Cha',
    'tocotoco': 'TocoToco', 'toco toco': 'TocoToco', 'ding tea': 'Ding Tea',
    'dingtea': 'Ding Tea', 'phindi': 'Phindi', 'trung nguyen': 'Trung Nguyên',
    'cong caphe': 'Cộng Cà Phê', 'cong ca phe': 'Cộng Cà Phê',
    'passio': 'Passio Coffee', 'bobapop': 'Bobapop', 'royaltea': 'Royaltea',
    
    // Thức ăn nhanh
    'kfc': 'KFC', 'lotteria': 'Lotteria', 'jollibee': 'Jollibee',
    'mcdonald': "McDonald's", 'mcdonalds': "McDonald's", 'burger king': 'Burger King',
    'pizza': 'Pizza', 'pizza hut': 'Pizza Hut', 'domino': "Domino's Pizza",
    'popeyes': 'Popeyes', 'texas chicken': 'Texas Chicken', 'subway': 'Subway',
    'pizza 4p': "Pizza 4P's", '4ps': "Pizza 4P's",
    
    // Nhà hàng & Quán ăn
    'com tam': 'Cơm Tấm', 'pho': 'Phở', 'bun': 'Bún', 'banh mi': 'Bánh Mì',
    'quan an': 'Quán Ăn', 'nha hang': 'Nhà Hàng', 'hotpot': 'Lẩu',
    'kichi': 'Kichi Kichi', 'manwah': 'Manwah', 'hutong': 'Hutong',
    'gogi house': 'Gogi House', 'sumo bbq': 'Sumo BBQ', 'king bbq': 'King BBQ',
    
    // Giao hàng & Ride-hailing
    'grab': 'Grab', 'grabfood': 'GrabFood', 'grab food': 'GrabFood',
    'be group': 'Be', 'be food': 'Be Food', 'shopeefood': 'ShopeeFood',
    'shopee food': 'ShopeeFood', 'gojek': 'Gojek', 'baemin': 'Baemin',
    'now': 'Now.vn', 'loship': 'Loship',
    
    // Nhà thuốc
    'guardian': 'Guardian', 'pharmacity': 'Pharmacity', 'medicare': 'Medicare',
    'long chau': 'Long Châu', 'phano': 'Phano', 'nha thuoc': 'Nhà Thuốc',
    
    // Sách & Văn phòng phẩm
    'fahasa': 'Fahasa', 'phuong nam': 'Phương Nam', 'tiki': 'Tiki',
    'vpp': 'Văn Phòng Phẩm', 'hong ha': 'Hồng Hà',
    
    // Thời trang
    'routine': 'Routine', 'coolmate': 'Coolmate', 'canifa': 'Canifa',
    'uniqlo': 'UNIQLO', 'h&m': 'H&M', 'zara': 'ZARA',
    
    // Điện tử & Công nghệ
    'thegioididong': 'Thế Giới Di Động', 'the gioi di dong': 'Thế Giới Di Động',
    'tgdd': 'Thế Giới Di Động', 'dien may xanh': 'Điện Máy Xanh',
    'dienmayxanh': 'Điện Máy Xanh', 'dmx': 'Điện Máy Xanh',
    'fpt shop': 'FPT Shop', 'fptshop': 'FPT Shop', 'cellphones': 'CellphoneS',
    
    // Xăng dầu
    'petrolimex': 'Petrolimex', 'pvoil': 'PV Oil', 'total': 'Total',
    'shell': 'Shell', 'caltex': 'Caltex',
  };

  // Cải thiện pattern bỏ qua các dòng không phải tên cửa hàng
  static final _skipLine = RegExp(
    r'dia\s*chi|\bdc\b|\btel\b|sdt|\bdt\b|hotline|fax|\bmst\b|ma\s*so|website|'
    r'www|http|@|hoa\s*don|phieu|receipt|invoice|\bbill\b|ban\s*hang|cam\s*on|'
    r'thanh\s*toan|\bso\s*hd|ngay|gio\b|quay|thu\s*ngan|ma\s*don|stt|'
    r'duong|phuong|quan\s|huyen|tinh\s|thanh\s*pho|\btp\b|khu\s*pho|'
    r'^\d+\s*[a-z]?[/,]|bien\s*nhan|bien\s*lai|phieu\s*thu|so\s*dien\s*thoai|'
    r'email|van\s*phong|chi\s*nhanh|tong\s*dai|cskh|giao\s*hang|van\s*chuyen',
  );

  // Thêm pattern nhận dạng nhãn tốt hơn
  static final _merchantLabelPattern = RegExp(
    r'(?:cua\s*hang|ten\s*cua\s*hang|ten\s*ch|ch\s*:|store|shop|merchant|'
    r'nha\s*hang|quan|cafe|restaurant)\s*[:\-]\s*(.+)',
    caseSensitive: false,
  );

  static String? _extractMerchantName(List<String> lines) {
    if (lines.isEmpty) return null;
    final head = lines.take(20).toList(); // Tăng từ 15 lên 20 dòng

    // 1. Nhận diện thương hiệu quen thuộc (tìm kiếm chính xác hơn)
    for (final l in head) {
      final f = _fold(l);
      // Tìm exact match hoặc whole word match
      for (final e in _brands.entries) {
        // Whole word boundary check
        final pattern = RegExp(r'\b' + RegExp.escape(e.key) + r'\b');
        if (pattern.hasMatch(f)) {
          return e.value;
        }
      }
    }

    // 2. Nhãn "Cửa hàng: XYZ" hoặc "Store: XYZ"
    for (final l in head) {
      final m = _merchantLabelPattern.firstMatch(_fold(l));
      if (m != null) {
        final start = l.length - m.group(1)!.length;
        if (start >= 0 && start < l.length) {
          final extracted = _clean(l.substring(start));
          if (extracted.length >= 3) return extracted;
        }
      }
    }

    // 3. Chấm điểm các dòng đầu (cải thiện scoring)
    String? best;
    var bestScore = -999.0;
    for (var i = 0; i < head.length; i++) {
      final l = head[i];
      final f = _fold(l);
      final letters = RegExp(r'[A-Za-zÀ-ỹ]').allMatches(l).length;
      final digits = RegExp(r'\d').allMatches(l).length;
      final length = l.length;
      
      // Điều kiện cơ bản
      if (letters < 3 || length > 70) continue;
      if (length < 3) continue;
      if (digits / length > 0.3) continue; // Tăng tolerance cho số
      if (_skipLine.hasMatch(f)) continue;

      var score = 12.0 - i; // Ưu tiên dòng đầu
      
      // Điểm thưởng cho đặc điểm tên cửa hàng
      final upper = RegExp(r'[A-ZÀ-Ỹ]').allMatches(l).length;
      if (upper / letters > 0.7) score += 6; // Tên thường IN HOA
      if (upper / letters > 0.5 && upper / letters <= 0.7) score += 3; // Title Case
      
      // Độ dài lý tưởng
      if (length >= 5 && length <= 35) score += 4;
      if (length > 35 && length <= 50) score += 2;
      
      // Phạt điểm cho các dấu hiệu xấu
      if (l.contains(',')) score -= 6; // Có thể là địa chỉ
      if (RegExp(r'[\d\-/]').allMatches(l).length > 3) score -= 4; // Nhiều ký tự số/ngăn cách
      if (f.contains('so') || f.contains('no.')) score -= 3; // Có từ "số"
      
      // Điểm thưởng cho vị trí đặc biệt
      if (i == 0) score += 5; // Dòng đầu tiên
      if (i == 1) score += 3; // Dòng thứ hai
      
      // Điểm thưởng nếu có từ khóa liên quan
      if (RegExp(r'cafe|coffee|shop|store|mart|restaurant').hasMatch(f)) {
        score += 4;
      }
      
      if (score > bestScore) {
        bestScore = score;
        best = l;
      }
    }
    
    return best != null ? _clean(best) : null;
  }

  static String _clean(String raw) {
    var c = raw
        .replaceAll(RegExp(r'^[\s*\-_=#.]+|[\s*\-_=#.]+$'), '')
        .trim();
    
    // Loại bỏ các ký tự đặc biệt không cần thiết ở đầu/cuối
    c = c.replaceAll(RegExp(r'^[:\-\.,;]+|[:\-\.,;]+$'), '').trim();
    
    // Nếu kết quả quá ngắn, trả về gốc
    return c.length >= 3 ? c : raw;
  }
}