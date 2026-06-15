import 'package:flutter/material.dart';

class AvatarPickerScreen extends StatefulWidget {
  final List<String> avatars;
  final String currentAvatar;

  const AvatarPickerScreen({
    super.key,
    required this.avatars,
    required this.currentAvatar,
  });

  @override
  State<AvatarPickerScreen> createState() => _AvatarPickerScreenState();
}

class _AvatarPickerScreenState extends State<AvatarPickerScreen> {
  late String _selected;

  static const Color _black = Color(0xFF0D0D0D);
  static const Color _darkGrey = Color(0xFF2C2C2C);
  static const Color _mediumGrey = Color(0xFF6B6B6B);
  static const Color _lightGrey = Color(0xFFD0D0D0);
  static const Color _softGrey = Color(0xFFF2F2F2);
  static const Color _white = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _selected = widget.currentAvatar;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _softGrey,
      appBar: AppBar(
        title: const Text(
          "Choose Avatar",
          style: TextStyle(
              fontSize: 17, fontWeight: FontWeight.bold, color: _white),
        ),
        centerTitle: true,
        backgroundColor: _black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: _white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // ── Preview ──────────────────────────────────────────
          Container(
            color: _black,
            width: double.infinity,
            padding: const EdgeInsets.only(top: 20, bottom: 28),
            child: Column(
              children: [
                // Avatar preview with white border ring
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _white, width: 3),
                    color: _darkGrey,
                  ),
                  child: CircleAvatar(
                    radius: 52,
                    backgroundColor: _darkGrey,
                    backgroundImage: NetworkImage(_selected),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "This is how you'll appear",
                  style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
                ),
              ],
            ),
          ),

          // ── Section label ─────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "SELECT AN AVATAR",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _mediumGrey,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),

          // ── Grid ─────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1,
                ),
                itemCount: widget.avatars.length,
                itemBuilder: (context, index) {
                  final avatar = widget.avatars[index];
                  final isSelected = _selected == avatar;
                  return GestureDetector(
                    onTap: () => setState(() => _selected = avatar),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? _black : Colors.transparent,
                          width: 3.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _black.withValues(
                                alpha: isSelected ? 0.25 : 0.07),
                            blurRadius: isSelected ? 14 : 6,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: double.infinity,
                            backgroundColor: _lightGrey,
                            backgroundImage: NetworkImage(avatar),
                          ),
                          if (isSelected)
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: _black,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check,
                                    color: _white, size: 14),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Confirm button ────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _selected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _black,
                    foregroundColor: _white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Use This Avatar",
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
