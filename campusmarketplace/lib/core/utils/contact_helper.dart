import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactHelper {
  ContactHelper._();

  static String cleanPhoneNumber(String phone) {
    return phone.replaceAll(RegExp(r'[^\d+]'), '');
  }

  // Open WhatsApp
  static Future<bool> openWhatsApp({
    required String phone,
    required String sellerName,
    required String listingTitle,
    required BuildContext context,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final cleaned = cleanPhoneNumber(phone);

    if (cleaned.isEmpty) {
      _showError(messenger, 'Seller has not provided a phone number.');
      return false;
    }

    String formattedPhone = cleaned;
    if (formattedPhone.startsWith('+')) {
      formattedPhone = formattedPhone.substring(1);
    }
    if (formattedPhone.length == 10) {
      formattedPhone = '91$formattedPhone';
    }

    final message = Uri.encodeComponent(
      "Hi $sellerName, I'm interested in your listing '$listingTitle' on Campus Marketplace!",
    );

    final url = Uri.parse('https://wa.me/$formattedPhone?text=$message');

    try {
      final canLaunch = await canLaunchUrl(url);
      if (canLaunch) {
        return await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        return await openPhoneDialerWithMessenger(phone: phone, messenger: messenger);
      }
    } catch (e) {
      _showError(messenger, 'Could not open WhatsApp: $e');
      return false;
    }
  }

  // Open Phone Dialer
  static Future<bool> openPhoneDialer({
    required String phone,
    required BuildContext context,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    return openPhoneDialerWithMessenger(phone: phone, messenger: messenger);
  }

  static Future<bool> openPhoneDialerWithMessenger({
    required String phone,
    required ScaffoldMessengerState messenger,
  }) async {
    final cleaned = cleanPhoneNumber(phone);
    if (cleaned.isEmpty) {
      _showError(messenger, 'No phone number available.');
      return false;
    }

    final url = Uri.parse('tel:$cleaned');
    try {
      if (await canLaunchUrl(url)) {
        return await launchUrl(url);
      } else {
        _showError(messenger, 'Could not open dialer.');
        return false;
      }
    } catch (e) {
      _showError(messenger, 'Dialer error: $e');
      return false;
    }
  }

  // Open SMS
  static Future<bool> openSms({
    required String phone,
    required String sellerName,
    required String listingTitle,
    required BuildContext context,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final cleaned = cleanPhoneNumber(phone);
    final message = Uri.encodeComponent(
      "Hi $sellerName, I'm interested in your listing '$listingTitle' on Campus Marketplace.",
    );
    final url = Uri.parse('sms:$cleaned?body=$message');

    try {
      if (await canLaunchUrl(url)) {
        return await launchUrl(url);
      } else {
        return await openPhoneDialerWithMessenger(phone: phone, messenger: messenger);
      }
    } catch (e) {
      _showError(messenger, 'SMS error: $e');
      return false;
    }
  }

  static void _showError(ScaffoldMessengerState messenger, String message) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
