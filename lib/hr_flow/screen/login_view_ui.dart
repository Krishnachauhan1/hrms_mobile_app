// import 'package:employee_app/hr_flow/controller/login_controller.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// class LoginView extends GetView<LoginController> {
//   const LoginView({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Center(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(24.0),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 // Logo/Icon
//                 Container(
//                   width: 120,
//                   height: 120,
//                   decoration: BoxDecoration(
//                     color: Colors.orange.withOpacity(0.1),
//                     shape: BoxShape.circle,
//                   ),
//                   child: const Icon(
//                     Icons.business_center,
//                     size: 60,
//                     color: Colors.orange,
//                   ),
//                 ),
//                 const SizedBox(height: 32),

//                 // Title
//                 Text(
//                   'HR Management',
//                   style: Theme.of(context).textTheme.displayLarge?.copyWith(
//                     fontSize: 32,
//                     color: Colors.orange,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   'Login to your account',
//                   style: Theme.of(context).textTheme.bodyMedium,
//                 ),
//                 const SizedBox(height: 48),

//                 // Email Field
//                 TextField(
//                   controller: controller.emailController,
//                   decoration: InputDecoration(
//                     labelText: 'Email',
//                     prefixIcon: const Icon(Icons.email_outlined),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   keyboardType: TextInputType.emailAddress,
//                 ),
//                 const SizedBox(height: 16),

//                 // Password Field
//                 GetBuilder<LoginController>(
//                   builder: (controller) => TextField(
//                     controller: controller.passwordController,
//                     obscureText: !controller.isPasswordVisible,
//                     decoration: InputDecoration(
//                       labelText: 'Password',
//                       prefixIcon: const Icon(Icons.lock_outline),
//                       suffixIcon: IconButton(
//                         icon: Icon(
//                           controller.isPasswordVisible
//                               ? Icons.visibility_outlined
//                               : Icons.visibility_off_outlined,
//                         ),
//                         onPressed: controller.togglePasswordVisibility,
//                       ),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 24),

//                 // Login Button
//                 GetBuilder<LoginController>(
//                   builder: (controller) => SizedBox(
//                     width: double.infinity,
//                     height: 56,
//                     child: ElevatedButton(
//                       onPressed: controller.isLoading
//                           ? null
//                           : controller.login,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.orange,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                       child: controller.isLoading
//                           ? const CircularProgressIndicator(color: Colors.white)
//                           : const Text(
//                               'Login',
//                               style: TextStyle(
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 24),

//                 // Demo Credentials
//                 Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: Colors.orangeAccent.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(
//                       color: Colors.orangeAccent.withOpacity(0.3),
//                     ),
//                   ),
//                   child: Column(
//                     children: [
//                       Row(
//                         children: const [
//                           Icon(
//                             Icons.info_outline,
//                             color: Colors.orangeAccent,
//                             size: 20,
//                           ),
//                           SizedBox(width: 8),
//                           Text(
//                             'Demo Credentials',
//                             style: TextStyle(
//                               fontWeight: FontWeight.w600,
//                               color: Colors.orangeAccent,
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 8),
//                       const Text('Email: hr@company.com'),
//                       const Text('Password: hr123'),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
