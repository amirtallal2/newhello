import 'package:flutter/material.dart';

import '../../../../core/widgets/app_placeholder_screen.dart';

class ProjectBootstrapScreen extends StatelessWidget {
  const ProjectBootstrapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPlaceholderScreen(
      badge: 'Project Ready',
      title: 'الأساس جاهز لبناء تطبيق اللايفات الصوتية',
      subtitle:
          'رتبت المشروع كبداية نظيفة علشان نستقبل شاشات الفيجما واحدة واحدة ونحولها لتطبيق Flutter حقيقي بدون تكسير أو إعادة شغل.',
      highlights: [
        'كل شاشة جديدة هنحولها لواجهة مطابقة للتصميم قدر الإمكان.',
        'هنربط التنقل بين الصفحات أثناء التنفيذ بمسارات واضحة.',
        'هنشتغل في البداية على بيانات وهمية منظمة لسرعة الإنجاز.',
        'بعد ثبات التدفقات الرئيسية نوصل الباك اند الحقيقي بدون إعادة بناء الواجهات.',
      ],
      footer:
          'ابعت أول صفحة من الفيجما، وأنا هبدأ مباشرة في استخراج الألوان والمقاسات والعناصر وبناء الشاشة وربطها داخل التطبيق.',
    );
  }
}
