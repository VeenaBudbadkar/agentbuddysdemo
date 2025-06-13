import 'package:url_launcher/url_launcher.dart';

Future<void> launchCaller(String phoneNumber) async {
  final Uri url = Uri(scheme: "tel", path: phoneNumber);
  if (await canLaunchUrl(url)) {
    await launchUrl(url);
  } else {
    throw 'Could not launch $url';
  }
}

Future<void> launchWhatsApp(String phoneNumber) async {
  final Uri url = Uri.parse("https://wa.me/$phoneNumber");
  if (await canLaunchUrl(url)) {
    await launchUrl(url);
  } else {
    throw 'Could not launch WhatsApp to $phoneNumber';
  }
}

Future<void> launchEmail(String email) async {
  final Uri url = Uri(
    scheme: 'mailto',
    path: email,
  );
  if (await canLaunchUrl(url)) {
    await launchUrl(url);
  } else {
    throw 'Could not launch email to $email';
  }
}
