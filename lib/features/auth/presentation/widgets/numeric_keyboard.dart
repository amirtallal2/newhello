import 'package:flutter/material.dart';

class NumericKeyboard extends StatelessWidget {
  const NumericKeyboard({
    super.key,
    required this.onDigitPressed,
    required this.onDeletePressed,
  });

  final ValueChanged<String> onDigitPressed;
  final VoidCallback onDeletePressed;

  static const Color _background = Color.fromRGBO(206, 210, 217, 0.9);

  @override
  Widget build(BuildContext context) {
    const labels = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];
    const subtitles = [
      ['', 'ABC', 'DEF'],
      ['GHI', 'JKL', 'MNO'],
      ['PQRS', 'TUV', 'WXYZ'],
    ];

    return Container(
      color: _background,
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var row = 0; row < labels.length; row++) ...[
            Row(
              children: [
                for (var column = 0; column < labels[row].length; column++) ...[
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: column == 2 ? 0 : 6,
                        bottom: row == 2 ? 7 : 6,
                      ),
                      child: _KeyboardKey(
                        key: ValueKey('numeric-key-${labels[row][column]}'),
                        label: labels[row][column],
                        subtitle: subtitles[row][column],
                        onTap: () => onDigitPressed(labels[row][column]),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _KeyboardSideKey(
                    key: const ValueKey('numeric-key-side'),
                    label: '+ * #',
                    onTap: () {},
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _KeyboardKey(
                    key: const ValueKey('numeric-key-0'),
                    label: '0',
                    subtitle: '',
                    onTap: () => onDigitPressed('0'),
                  ),
                ),
              ),
              Expanded(
                child: _KeyboardDeleteKey(
                  key: const ValueKey('numeric-key-delete'),
                  onTap: onDeletePressed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KeyboardKey extends StatelessWidget {
  const _KeyboardKey({
    super.key,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.3),
              offset: Offset(0, 1),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 25,
                fontWeight: FontWeight.w400,
                height: 1,
              ),
            ),
            if (subtitle.isNotEmpty)
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.7,
                  height: 1.2,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _KeyboardSideKey extends StatelessWidget {
  const _KeyboardSideKey({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: SizedBox(
        height: 46,
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _KeyboardDeleteKey extends StatelessWidget {
  const _KeyboardDeleteKey({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: SizedBox(
        height: 46,
        child: const Center(
          child: Icon(Icons.backspace_outlined, color: Colors.black, size: 26),
        ),
      ),
    );
  }
}
