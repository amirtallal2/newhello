import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';

class PostCreateScreen extends StatefulWidget {
  const PostCreateScreen({super.key});

  @override
  State<PostCreateScreen> createState() => _PostCreateScreenState();
}

class _PostCreateScreenState extends State<PostCreateScreen> {
  static const Color _primaryBlue = Color(0xFF285F98);
  static const Color _lightBlue = Color(0xFFB4D1EF);
  static const Color _background = Color(0xFFF6F6F6);

  final TextEditingController _postController = TextEditingController();

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(17, 70, 17, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: Semantics(
                          label: 'post-create-back',
                          button: true,
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                            borderRadius: BorderRadius.circular(19),
                            child: Container(
                              width: 38,
                              height: 37,
                              decoration: const BoxDecoration(
                                color: _lightBlue,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                color: _primaryBlue,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Center(
                        child: Text(
                          'نشر لحظات',
                          style: TextStyle(
                            color: _primaryBlue,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'نشر الاخبار ، والتعرف علي المزيد من الناس متعة',
                          style: TextStyle(
                            color: _primaryBlue,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Expanded(
                        child: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _postController,
                          builder: (context, value, _) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: TextField(
                                    key: const ValueKey('post-create-editor'),
                                    controller: _postController,
                                    maxLength: 1000,
                                    maxLines: null,
                                    expands: true,
                                    textAlign: TextAlign.right,
                                    textDirection: TextDirection.rtl,
                                    style: const TextStyle(
                                      color: _primaryBlue,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      height: 1.5,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: '',
                                      border: InputBorder.none,
                                      counterText: '',
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Text(
                                    '${value.text.characters.length}/1000',
                                    style: const TextStyle(
                                      color: _primaryBlue,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Semantics(
                          label: 'post-create-add-image',
                          button: true,
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).pushNamed(
                                AppRoutes.bootstrap,
                              );
                            },
                            borderRadius: BorderRadius.circular(5),
                            child: Container(
                              width: 85,
                              height: 85,
                              decoration: BoxDecoration(
                                color: _lightBlue,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                '+',
                                style: TextStyle(
                                  color: _primaryBlue,
                                  fontSize: 48,
                                  fontWeight: FontWeight.w400,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 60),
                      SizedBox(
                        height: 36,
                        child: ElevatedButton(
                          key: const ValueKey('post-create-submit'),
                          onPressed: () {
                            Navigator.of(context).pushNamed(
                              AppRoutes.bootstrap,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: const Text(
                            'نشر البوست الان',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ),
            ),
            const _ComposerBottomNavigation(),
          ],
        ),
      ),
    );
  }
}

class _ComposerBottomNavigation extends StatelessWidget {
  const _ComposerBottomNavigation();

  static const Color _primaryBlue = Color(0xFF285F98);
  static const Color _inactive = Color(0xFF9DB2CE);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 77,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ComposerBottomNavItem(
            label: 'Home',
            icon: Icons.home_rounded,
            color: _primaryBlue,
            onTap: () {
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.home,
                (route) => false,
              );
            },
          ),
          _ComposerBottomNavItem(
            label: 'Chat',
            icon: Icons.chat_bubble_outline_rounded,
            color: _inactive,
            onTap: () {
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.chatInbox,
                (route) => false,
              );
            },
          ),
          _ComposerBottomNavItem(
            label: 'Post',
            icon: Icons.add_circle_outline_rounded,
            color: _inactive,
            onTap: () {
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.post,
                (route) => false,
              );
            },
          ),
          _ComposerBottomNavItem(
            label: 'Profile',
            icon: Icons.person_outline_rounded,
            color: _inactive,
            onTap: () {
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.profile,
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ComposerBottomNavItem extends StatelessWidget {
  const _ComposerBottomNavItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
