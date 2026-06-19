// /// Certificate View Screen
// library;
//
// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';
// import '../../models/certificate.dart';
// import '../../utils/app_colors.dart';
//
// class CertificateViewScreen extends StatelessWidget {
//   final Certificate cert;
//
//   const CertificateViewScreen({super.key, required this.cert});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.bgOf(context),
//       appBar: AppBar(
//         backgroundColor: AppColors.primary,
//         foregroundColor: Colors.white,
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Certificate',
//               style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
//             ),
//             Text(
//               cert.certificateNumber,
//               style: const TextStyle(fontSize: 11, color: Colors.white70),
//               overflow: TextOverflow.ellipsis,
//             ),
//           ],
//         ),
//         elevation: 0,
//       ),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 32),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Icon(Icons.verified_rounded,
//                   size: 72, color: AppColors.cyan),
//               const SizedBox(height: 16),
//               Text(
//                 cert.courseName,
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.w800,
//                   color: AppColors.textOf(context),
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 cert.certificateNumber,
//                 style: TextStyle(
//                   fontSize: 13,
//                   color: AppColors.text2Of(context),
//                 ),
//               ),
//               const SizedBox(height: 32),
//               GestureDetector(
//                 onTap: () async {
//                   final uri = Uri.parse(cert.certificateUrl);
//                   await launchUrl(uri, mode: LaunchMode.externalApplication);
//                 },
//                 child: Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   decoration: BoxDecoration(
//                     gradient: const LinearGradient(
//                         colors: [AppColors.cyan, AppColors.cyanDark]),
//                     borderRadius: BorderRadius.circular(14),
//                     boxShadow: [
//                       BoxShadow(
//                           color: AppColors.cyan.withOpacity(0.35),
//                           blurRadius: 18,
//                           offset: const Offset(0, 7))
//                     ],
//                   ),
//                   child: const Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(Icons.open_in_browser_rounded,
//                           color: Colors.white, size: 18),
//                       SizedBox(width: 8),
//                       Text('View & Download',
//                           style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 15,
//                               fontWeight: FontWeight.w700)),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }