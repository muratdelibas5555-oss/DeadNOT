import 'dart:ui';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DeadNotApp());
}

class DeadNotApp extends StatelessWidget {
  const DeadNotApp({super.key});
  @override
  Widget build(BuildContext context) {
    const Color darkBg = Color(0xFF131314);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: darkBg,
        fontFamily: 'Montserrat', // Ana font Montserrat olarak ayarlandı
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  List<Map<String, dynamic>> _courses = [];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('courses');
    if (data != null) {
      setState(
        () => _courses = List<Map<String, dynamic>>.from(json.decode(data)),
      );
    }
  }

  Future<void> _saveAllData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('courses', json.encode(_courses));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      GradesPage(courses: _courses, onUpdate: _saveAllData),
      AttendancePage(courses: _courses, onUpdate: _saveAllData),
      const CustomTimersPage(),
      const SchedulePage(),
      const HolidaysPage(),
    ];

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(index: _selectedIndex, children: pages),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(35),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: 75,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(35),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(CupertinoIcons.chart_pie, 0),
                      _buildNavItem(CupertinoIcons.person_badge_minus, 1),
                      _buildNavItem(CupertinoIcons.timer, 2),
                      _buildNavItem(CupertinoIcons.square_grid_2x2, 3),
                      _buildNavItem(CupertinoIcons.sparkles, 4),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF34C759).withValues(alpha: 0.1)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected ? const Color(0xFF34C759) : Colors.white54,
          size: 24,
        ),
      ),
    );
  }
}

// --- LOGO BİLEŞENİ (DeadNOT) ---
class DeadNotLogo extends StatelessWidget {
  final double fontSize;
  const DeadNotLogo({super.key, this.fontSize = 22});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: "Dead",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: fontSize,
            ),
          ),
          TextSpan(
            text: "NOT",
            style: TextStyle(
              color: const Color(0xFF34C759),
              fontWeight: FontWeight.w700,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
      style: const TextStyle(fontFamily: 'Montserrat'),
    );
  }
}

// --- SAYFA 1: NOTLAR ---
class GradesPage extends StatelessWidget {
  final List<Map<String, dynamic>> courses;
  final VoidCallback onUpdate;
  const GradesPage({super.key, required this.courses, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const DeadNotLogo(fontSize: 24), // ÖZEL LOGO BURADA
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 16),
            ),
            backgroundColor: Colors.transparent,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 200),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => CourseCard(
                  data: courses[i],
                  onChanged: onUpdate,
                  onDel: () {
                    courses.removeAt(i);
                    onUpdate();
                  },
                ),
                childCount: courses.length,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _AppleCapsuleBtn(
        text: "Ders Ekle",
        icon: CupertinoIcons.add,
        onTap: () => _showAdd(context),
      ),
    );
  }

  void _showAdd(BuildContext context) {
    TextEditingController c = TextEditingController();
    showAppleDialog(
      context,
      title: "Ders Ekle",
      content: _AppleInput(controller: c, hint: "Ders İsmi"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("İptal", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF34C759),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            if (c.text.isNotEmpty) {
              courses.add({
                'name': c.text,
                'vize': '',
                'final': '',
                'absent': 0,
              });
              onUpdate();
              Navigator.pop(context);
            }
          },
          child: const Text(
            "Ekle",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

// --- SAYFA 2: DEVAMSIZLIK ---
class AttendancePage extends StatelessWidget {
  final List<Map<String, dynamic>> courses;
  final VoidCallback onUpdate;
  const AttendancePage({
    super.key,
    required this.courses,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                "DEVAMSIZLIK",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              centerTitle: true,
            ),
            backgroundColor: Colors.transparent,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 150),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _PremiumCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        courses[i]['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          _ControlBtn(CupertinoIcons.minus, () {
                            if (courses[i]['absent'] > 0) {
                              courses[i]['absent']--;
                              onUpdate();
                            }
                          }),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: Text(
                              "${courses[i]['absent']}",
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: courses[i]['absent'] >= 5
                                    ? Colors.redAccent
                                    : const Color(0xFF34C759),
                              ),
                            ),
                          ),
                          _ControlBtn(CupertinoIcons.plus, () {
                            courses[i]['absent']++;
                            onUpdate();
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
                childCount: courses.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- SAYFA 3: SAYAÇLAR ---
class CustomTimersPage extends StatefulWidget {
  const CustomTimersPage({super.key});
  @override
  State<CustomTimersPage> createState() => _CustomTimersPageState();
}

class _CustomTimersPageState extends State<CustomTimersPage> {
  List<Map<String, dynamic>> _timers = [];
  @override
  void initState() {
    super.initState();
    _load();
  }

  _load() async {
    final SharedPreferences p = await SharedPreferences.getInstance();
    final String? d = p.getString('custom_timers');
    if (d != null)
      setState(() => _timers = List<Map<String, dynamic>>.from(json.decode(d)));
  }

  _save() async {
    final SharedPreferences p = await SharedPreferences.getInstance();
    await p.setString('custom_timers', json.encode(_timers));
  }

  void _add() async {
    DateTime? pick = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF34C759),
            onPrimary: Colors.black,
            surface: Color(0xFF1C1C1E),
          ),
        ),
        child: child!,
      ),
    );
    if (!mounted) return;
    if (pick != null) {
      TextEditingController c = TextEditingController();
      showAppleDialog(
        context,
        title: "Sayaç İsmi",
        content: _AppleInput(controller: c, hint: "Örn: Ödev Teslimi"),
        actions: [
          ElevatedButton(
            onPressed: () {
              if (c.text.isNotEmpty) {
                setState(() {
                  _timers.add({'name': c.text, 'date': pick.toIso8601String()});
                  _save();
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Kur", style: TextStyle(color: Colors.black)),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                "SAYAÇLAR",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              centerTitle: true,
            ),
            backgroundColor: Colors.transparent,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 150),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((ctx, i) {
                final int diff =
                    DateTime.parse(
                      _timers[i]['date'],
                    ).difference(DateTime.now()).inDays +
                    1;
                return _PremiumCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _timers[i]['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            "Tarih Ayarlı",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            diff <= 0 ? "Tamam" : "$diff Gün",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: diff <= 0
                                  ? Colors.grey
                                  : const Color(0xFF34C759),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              CupertinoIcons.trash,
                              size: 18,
                              color: Colors.white24,
                            ),
                            onPressed: () {
                              setState(() {
                                _timers.removeAt(i);
                                _save();
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }, childCount: _timers.length),
            ),
          ),
        ],
      ),
      floatingActionButton: _AppleCapsuleBtn(
        text: "Sayaç Ekle",
        icon: CupertinoIcons.timer,
        onTap: _add,
      ),
    );
  }
}

// --- APPLE MODAL PENCERESİ ---
void showAppleDialog(
  BuildContext context, {
  required String title,
  required Widget content,
  required List<Widget> actions,
}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: "",
    pageBuilder: (ctx, a1, a2) => Container(),
    transitionBuilder: (ctx, a1, a2, child) {
      return Transform.scale(
        scale: Curves.easeInOutBack.transform(a1.value),
        child: Opacity(
          opacity: a1.value,
          child: AlertDialog(
            backgroundColor: const Color(0xFF1C1C1E).withValues(alpha: 0.95),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
              side: const BorderSide(color: Colors.white10),
            ),
            title: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: content,
            actions: actions,
          ),
        ),
      );
    },
  );
}

// --- DERS KARTI ---
class CourseCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onChanged, onDel;
  const CourseCard({
    super.key,
    required this.data,
    required this.onChanged,
    required this.onDel,
  });
  @override
  Widget build(BuildContext context) {
    double vVal = double.tryParse(data['vize'].toString()) ?? 0,
        fVal = double.tryParse(data['final'].toString()) ?? 0,
        avg = (vVal * 0.4) + (fVal * 0.6);
    bool ent =
        data['vize'].toString().isNotEmpty &&
        data['final'].toString().isNotEmpty;
    Color color = !ent
        ? Colors.white10
        : (avg >= 60 ? const Color(0xFF34C759) : Colors.redAccent);

    String needed = "";
    if (data['vize'].toString().isNotEmpty &&
        data['final'].toString().isEmpty) {
      double req = (60 - (vVal * 0.4)) / 0.6;
      needed = req <= 0
          ? "Geçtin!"
          : (req > 100 ? "Zor (100+)" : "Gereken: ${req.toStringAsFixed(0)}");
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data['name'],
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(CupertinoIcons.delete, color: Colors.white24),
                onPressed: onDel,
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _field("Vize", data['vize'], (s) {
                  data['vize'] = s;
                  onChanged();
                }),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _field("Final", data['final'], (s) {
                  data['final'] = s;
                  onChanged();
                }),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ent ? "Ortalama: ${avg.toStringAsFixed(1)}" : "Hesaplanıyor...",
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              if (needed.isNotEmpty)
                Text(
                  needed,
                  style: const TextStyle(
                    color: Color(0xFF34C759),
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _field(String l, String v, Function(String) c) => TextField(
    keyboardType: TextInputType.number,
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(3),
    ],
    onChanged: c,
    controller: TextEditingController.fromValue(
      TextEditingValue(
        text: v,
        selection: TextSelection.collapsed(offset: v.length),
      ),
    ),
    decoration: InputDecoration(
      labelText: l,
      labelStyle: const TextStyle(color: Colors.grey),
      border: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
    ),
  );
}

// --- DERS PROGRAMI ---
class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});
  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  File? _i;
  bool _z = false;
  @override
  void initState() {
    super.initState();
    _l();
  }

  _l() async {
    final SharedPreferences p = await SharedPreferences.getInstance();
    final String? path = p.getString('sch_path');
    if (path != null) setState(() => _i = File(path));
  }

  _p() async {
    final XFile? f = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (f != null) {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setString('sch_path', f.path);
      setState(() => _i = File(f.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: _i == null
                ? _AppleCapsuleBtn(
                    text: "Program Yükle",
                    icon: CupertinoIcons.photo,
                    onTap: _p,
                  )
                : GestureDetector(
                    onTap: () => setState(() => _z = true),
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Image.file(_i!),
                      ),
                    ),
                  ),
          ),
          if (_z && _i != null)
            Positioned.fill(
              child: Container(
                color: Colors.black,
                child: Stack(
                  children: [
                    Center(child: InteractiveViewer(child: Image.file(_i!))),
                    Positioned(
                      top: 50,
                      right: 30,
                      child: IconButton(
                        icon: const Icon(
                          CupertinoIcons.xmark_circle_fill,
                          size: 45,
                        ),
                        onPressed: () => setState(() => _z = false),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// --- TATİLLER ---
class HolidaysPage extends StatelessWidget {
  const HolidaysPage({super.key});
  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> hds = [
      {'n': "Yılbaşı", 'd': DateTime(2026, 1, 1)},
      {'n': "Ramazan", 'd': DateTime(2026, 3, 20)},
      {'n': "23 Nisan", 'd': DateTime(2026, 4, 23)},
      {'n': "1 Mayıs", 'd': DateTime(2026, 5, 1)},
      {'n': "19 Mayıs", 'd': DateTime(2026, 5, 19)},
      {'n': "Kurban", 'd': DateTime(2026, 5, 27)},
      {'n': "15 Temmuz", 'd': DateTime(2026, 7, 15)},
      {'n': "30 Ağustos", 'd': DateTime(2026, 8, 30)},
      {'n': "29 Ekim", 'd': DateTime(2026, 10, 29)},
    ];
    hds.sort((a, b) {
      bool aP = a['d'].isBefore(DateTime.now());
      bool bP = b['d'].isBefore(DateTime.now());
      if (aP != bP) return aP ? 1 : -1;
      return a['d'].compareTo(b['d']);
    });
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "TATİLLER",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 150),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
        ),
        itemCount: hds.length,
        itemBuilder: (ctx, i) {
          final int d = hds[i]['d'].difference(DateTime.now()).inDays + 1;
          bool p = d <= 0;
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: p
                    ? Colors.transparent
                    : const Color(0xFF34C759).withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  p ? "Bitti" : "$d",
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: p ? Colors.grey[800] : const Color(0xFF34C759),
                  ),
                ),
                Text(
                  hds[i]['n'],
                  style: TextStyle(
                    color: p ? Colors.grey[700] : Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// --- PREMIUM UI BİLEŞENLERİ ---
class _PremiumCard extends StatelessWidget {
  final Widget child;
  const _PremiumCard({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: child,
    );
  }
}

class _AppleInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const _AppleInput({required this.controller, required this.hint});
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 12,
        ),
      ),
    );
  }
}

class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ControlBtn(this.icon, this.onTap);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }
}

class _AppleCapsuleBtn extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;
  const _AppleCapsuleBtn({
    required this.text,
    required this.icon,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 110),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF34C759),
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF34C759).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.black, size: 20),
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
