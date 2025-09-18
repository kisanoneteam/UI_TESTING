import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? savedLocaleCode = prefs.getString('localeCode');
  final bool isDark = prefs.getBool('isDark') ?? false;
  final String? farmerName = prefs.getString('farmerName');
  final String? phone = prefs.getString('phone');
  runApp(KisanOneApp(
    initialLocaleCode: savedLocaleCode,
    initialIsDark: isDark,
    initialName: farmerName,
    initialPhone: phone,
  ));
}

class KisanOneApp extends StatefulWidget {
  const KisanOneApp({
    super.key,
    this.initialLocaleCode,
    this.initialIsDark = false,
    this.initialName,
    this.initialPhone,
  });

  final String? initialLocaleCode;
  final bool initialIsDark;
  final String? initialName;
  final String? initialPhone;

  @override
  State<KisanOneApp> createState() => _KisanOneAppState();
}

class _KisanOneAppState extends State<KisanOneApp> {
  late AppState appState;

  @override
  void initState() {
    super.initState();
    appState = AppState(
      locale: _localeFromCode(widget.initialLocaleCode) ?? const Locale('en'),
      isDark: widget.initialIsDark,
      farmerName: widget.initialName,
      phoneNumber: widget.initialPhone,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData lightTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF22C55E),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      fontFamily: 'Roboto',
    );
    final ThemeData darkTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF22C55E),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      fontFamily: 'Roboto',
    );

    return AppStateScope(
      appState: appState,
      notifier: appState,
      child: AnimatedBuilder(
        animation: appState,
        builder: (context, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'KisanOne',
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: appState.isDark ? ThemeMode.dark : ThemeMode.light,
            locale: appState.locale,
            supportedLocales: const [
              Locale('en'),
              Locale('hi'),
              Locale('bn'),
              Locale('kh'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            home: SplashScreen(),
          );
        },
      ),
    );
  }
}

Locale? _localeFromCode(String? code) {
  if (code == null) return null;
  switch (code) {
    case 'hi':
      return const Locale('hi');
    case 'bn':
      return const Locale('bn');
    case 'kh':
      return const Locale('kh');
    default:
      return const Locale('en');
  }
}

class AppState extends ChangeNotifier {
  AppState({
    required this.locale,
    required this.isDark,
    this.farmerName,
    this.phoneNumber,
  });

  Locale locale;
  bool isDark;
  String? farmerName;
  String? phoneNumber;

  Future<void> setLocale(Locale newLocale) async {
    locale = newLocale;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('localeCode', newLocale.languageCode);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    isDark = !isDark;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', isDark);
    notifyListeners();
  }

  Future<void> saveUser(String name, String phone) async {
    farmerName = name;
    phoneNumber = phone;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('farmerName', name);
    await prefs.setString('phone', phone);
    notifyListeners();
  }
}

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required super.notifier,
    required this.appState,
    required super.child,
  });

  final AppState appState;

  static AppState of(BuildContext context) {
    final AppStateScope? scope =
        context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'AppStateScope not found in context');
    return scope!.appState;
  }
}

// Splash Screen
class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      final AppState app = AppStateScope.of(context);
      if (app.farmerName != null && app.phoneNumber != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const RootShell()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LanguageSelectPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const FancyBackground(),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/images/1000178814.png',
                    width: 140,
                    height: 140,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'KisanOne',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your Agricultural Partner',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Language Selection
class LanguageSelectPage extends StatelessWidget {
  const LanguageSelectPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState app = AppStateScope.of(context);
    final List<_Lang> langs = [
      _Lang('English', 'en'),
      _Lang('हिंदी', 'hi'),
      _Lang('বাংলা', 'bn'),
      _Lang('खोरठा', 'kh'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Select Language')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final _Lang l in langs)
            _LangTile(
              title: l.title,
              selected: app.locale.languageCode == l.code,
              onTap: () => app.setLocale(Locale(l.code)),
            ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}

class _Lang {
  _Lang(this.title, this.code);
  final String title;
  final String code;
}

class _LangTile extends StatelessWidget {
  const _LangTile({
    required this.title,
    required this.selected,
    required this.onTap,
  });
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(title),
        trailing: selected
            ? Icon(Icons.check_circle,
                color: Theme.of(context).colorScheme.primary)
            : const Icon(Icons.circle_outlined),
      ),
    );
  }
}

// Login
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 16),
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset('assets/images/1000178814.png',
                      height: 100, width: 100, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Welcome to KisanOne',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Enter your details to log in to your account',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: "Farmer's Name",
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Please enter name'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (v) => v != null && v.length == 10
                    ? null
                    : 'Enter 10-digit phone',
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => OtpPage(
                          name: nameCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                        ),
                      ),
                    );
                  }
                },
                child: const Text('Continue'),
              ),
              const SizedBox(height: 12),
              Text(
                'By continuing, you agree to our Terms of Service and Privacy Policy.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// OTP
class OtpPage extends StatefulWidget {
  const OtpPage({super.key, required this.name, required this.phone});
  final String name;
  final String phone;

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final List<TextEditingController> ctrls =
      List.generate(6, (_) => TextEditingController());
  int seconds = 59;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (seconds == 0) return;
      setState(() => seconds--);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    for (final c in ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OTP Verification')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 16),
          Center(
            child: Icon(Icons.lock_outline,
                size: 72, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Text('Enter OTP',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'We have sent a 6-digit verification code to +91-XXXXXX-${widget.phone.substring(widget.phone.length - 4)}',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (int i = 0; i < 6; i++)
                SizedBox(
                  width: 48,
                  child: TextField(
                    controller: ctrls[i],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(1),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () async {
              // Mock success
              await AppStateScope.of(context)
                  .saveUser(widget.name, widget.phone);
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const RootShell()),
                  (route) => false,
                );
              }
            },
            child: const Text('Verify'),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Resend in 00:${seconds.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Root shell with bottom navigation
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const HomePage(),
      const AiHelpHubPage(),
      const StorePage(),
      const SchemesPage(),
      const SettingsPage(),
    ];
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.psychology_outlined), label: 'AI Help'),
          NavigationDestination(icon: Icon(Icons.store_outlined), label: 'Store'),
          NavigationDestination(icon: Icon(Icons.account_balance_outlined), label: 'Schemes'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}

// Home page with weather and quick actions
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState app = AppStateScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(app.farmerName ?? 'Farmer'),
            Text(
              app.phoneNumber ?? '',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Toggle Theme',
            onPressed: app.toggleTheme,
            icon: Icon(app.isDark ? Icons.light_mode : Icons.dark_mode),
          ),
          PopupMenuButton<String>(
            icon: const CircleAvatar(child: Icon(Icons.person)),
            onSelected: (v) async {
              if (v == 'logout') {
                final SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.remove('farmerName');
                await prefs.remove('phone');
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => SplashScreen()),
                  (route) => false,
                );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(value: 'logout', child: Text('Log out')),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          const FancyBackground(),
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text("Today's Weather",
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: const [
                  WeatherTile(label: 'Temperature', value: '28°C', icon: Icons.thermostat),
                  WeatherTile(label: 'Humidity', value: '60%', icon: Icons.water_drop),
                  WeatherTile(label: 'Rainfall', value: '5mm', icon: Icons.cloudy_snowing),
                  WeatherTile(label: 'Wind', value: '10 km/h', icon: Icons.air),
                ],
              ),
              const SizedBox(height: 24),
              Text('Quick Actions',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  QuickAction(
                    label: 'Crop Advisory',
                    icon: Icons.agriculture,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CropAdvisoryPage()),
                    ),
                  ),
                  QuickAction(
                    label: 'Soil Advisory',
                    icon: Icons.science_outlined,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CropRecommendationPage()),
                    ),
                  ),
                  QuickAction(
                    label: 'Crop Doctor',
                    icon: Icons.health_and_safety_outlined,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CropDoctorPage()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class WeatherTile extends StatelessWidget {
  const WeatherTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text(value,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}

class QuickAction extends StatelessWidget {
  const QuickAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.15),
              Theme.of(context).colorScheme.secondary.withOpacity(0.15),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(label, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

// AI Help Hub
class AiHelpHubPage extends StatelessWidget {
  const AiHelpHubPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Help')),
      body: Stack(
        children: [
          const FancyBackground(),
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _FeatureTile(
                icon: Icons.agriculture,
                title: 'Crop Advisory',
                subtitle: 'Ask by text or voice',
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const CropAdvisoryPage())),
              ),
              _FeatureTile(
                icon: Icons.science_outlined,
                title: 'Crop Recommendation',
                subtitle: 'Location and soil based',
                onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CropRecommendationPage())),
              ),
              _FeatureTile(
                icon: Icons.health_and_safety_outlined,
                title: 'Crop Doctor',
                subtitle: 'Upload crop image',
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const CropDoctorPage())),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

// Crop Advisory - text or voice input
class CropAdvisoryPage extends StatefulWidget {
  const CropAdvisoryPage({super.key});
  @override
  State<CropAdvisoryPage> createState() => _CropAdvisoryPageState();
}

class _CropAdvisoryPageState extends State<CropAdvisoryPage> {
  final TextEditingController queryCtrl = TextEditingController();
  final stt.SpeechToText sttInstance = stt.SpeechToText();
  bool listening = false;
  String answer = '';

  Future<void> _toggleListen() async {
    if (listening) {
      await sttInstance.stop();
      setState(() => listening = false);
      return;
    }
    bool available = await sttInstance.initialize();
    if (available) {
      setState(() => listening = true);
      await sttInstance.listen(onResult: (r) {
        setState(() => queryCtrl.text = r.recognizedWords);
      });
    }
  }

  Future<void> _submit() async {
    final String q = queryCtrl.text.trim();
    if (q.isEmpty) return;
    // Mock AI response
    await Future<void>.delayed(const Duration(milliseconds: 500));
    setState(() {
      answer = 'Recommended steps for "$q":\n'
          '- Select high-yield seeds\n'
          '- Maintain soil moisture\n'
          '- Apply balanced NPK based on soil test';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crop Advisory')),
      body: Stack(
        children: [
          const FancyBackground(),
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: queryCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Describe your crop question... ',
                  suffixIcon: IconButton(
                    onPressed: _toggleListen,
                    icon: Icon(listening ? Icons.mic : Icons.mic_none),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(onPressed: _submit, child: const Text('Ask')),
              const SizedBox(height: 16),
              if (answer.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(answer),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// Crop Recommendation - location + soil inputs
class CropRecommendationPage extends StatefulWidget {
  const CropRecommendationPage({super.key});
  @override
  State<CropRecommendationPage> createState() => _CropRecommendationPageState();
}

class _CropRecommendationPageState extends State<CropRecommendationPage> {
  String? soil;
  String? climate;
  String? irrigation;
  String? latLng;
  String? result;

  Future<void> _getLocation() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever ||
        perm == LocationPermission.denied) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Location permission denied')));
      return;
    }
    final Position pos = await Geolocator.getCurrentPosition();
    setState(() => latLng = '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}');
  }

  Future<void> _recommend() async {
    if (soil == null || climate == null || irrigation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 600));
    setState(() {
      result = 'Best crops for $soil in $climate with $irrigation irrigation: \n'
          '- Wheat\n- Maize\n- Pulses';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crop Recommendation')),
      body: Stack(
        children: [
          const FancyBackground(),
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<String>(
                value: soil,
                decoration: const InputDecoration(labelText: 'Select Soil Type'),
                items: const [
                  DropdownMenuItem(value: 'Alluvial', child: Text('Alluvial')),
                  DropdownMenuItem(value: 'Black', child: Text('Black')),
                  DropdownMenuItem(value: 'Red', child: Text('Red')),
                ],
                onChanged: (v) => setState(() => soil = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: climate,
                decoration: const InputDecoration(labelText: 'Select Climate'),
                items: const [
                  DropdownMenuItem(value: 'Tropical', child: Text('Tropical')),
                  DropdownMenuItem(value: 'Temperate', child: Text('Temperate')),
                  DropdownMenuItem(value: 'Arid', child: Text('Arid')),
                ],
                onChanged: (v) => setState(() => climate = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: irrigation,
                decoration: const InputDecoration(labelText: 'Select Irrigation Type'),
                items: const [
                  DropdownMenuItem(value: 'Rainfed', child: Text('Rainfed')),
                  DropdownMenuItem(value: 'Canal', child: Text('Canal')),
                  DropdownMenuItem(value: 'Drip', child: Text('Drip')),
                ],
                onChanged: (v) => setState(() => irrigation = v),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Location (lat, lng)',
                        hintText: latLng ?? 'Not fetched',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _getLocation,
                    icon: const Icon(Icons.my_location),
                    label: const Text('Use GPS'),
                  )
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _recommend,
                child: const Text('Get Recommendations'),
              ),
              const SizedBox(height: 16),
              if (result != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(result!),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// Crop Doctor - image upload & mock diagnosis
class CropDoctorPage extends StatefulWidget {
  const CropDoctorPage({super.key});
  @override
  State<CropDoctorPage> createState() => _CropDoctorPageState();
}

class _CropDoctorPageState extends State<CropDoctorPage> {
  Uint8List? imageBytes;
  String? diagnosis;

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: source, imageQuality: 85);
    if (file != null) {
      final Uint8List bytes = await file.readAsBytes();
      setState(() => imageBytes = bytes);
    }
  }

  Future<void> _analyze() async {
    if (imageBytes == null) return;
    await Future<void>.delayed(const Duration(milliseconds: 700));
    setState(() {
      diagnosis = 'Crop: Tomato\nDisease: Early Blight\n'
          'Symptoms: Dark spots on leaves\n'
          'Cause: Fungus Alternaria solani\n'
          'Management: Remove infected leaves, apply fungicide\n'
          'Prevention: Crop rotation, resistant varieties';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crop Doctor')),
      body: Stack(
        children: [
          const FancyBackground(),
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
            height: 220,
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: imageBytes == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_upload_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 8),
                      const Text('Upload Your Crop Image'),
                    ],
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(imageBytes!, fit: BoxFit.cover, width: double.infinity),
                  ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Gallery'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Camera'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _analyze,
                icon: const Icon(Icons.biotech_outlined),
                label: const Text('Analyze'),
              ),
              const SizedBox(height: 16),
              if (diagnosis != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(diagnosis!),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// Store - sample catalog
class StorePage extends StatelessWidget {
  const StorePage({super.key});
  @override
  Widget build(BuildContext context) {
    final List<_StoreItem> items = [
      _StoreItem('Organic Pesticide', '₹299', Icons.bug_report_outlined),
      _StoreItem('NPK 19-19-19', '₹499', Icons.grass_outlined),
      _StoreItem('Drip Kit', '₹1,999', Icons.water_drop_outlined),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Store')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (c, i) {
          final _StoreItem it = items[i];
          return Card(
            child: ListTile(
              leading: Icon(it.icon,
                  color: Theme.of(context).colorScheme.primary),
              title: Text(it.name),
              subtitle: Text(it.price),
              trailing: FilledButton(onPressed: () {}, child: const Text('Buy')),
            ),
          );
        },
      ),
    );
  }
}

class _StoreItem {
  _StoreItem(this.name, this.price, this.icon);
  final String name;
  final String price;
  final IconData icon;
}

// Schemes - sample list
class SchemesPage extends StatelessWidget {
  const SchemesPage({super.key});
  @override
  Widget build(BuildContext context) {
    final List<_Scheme> schemes = [
      _Scheme('PM-Kisan', 'Income support for farmers'),
      _Scheme('KCC', 'Kisan Credit Card for easy loans'),
      _Scheme('Soil Health Card', 'Improve soil fertility'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Schemes')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: schemes.length,
        itemBuilder: (c, i) {
          final _Scheme s = schemes[i];
          return Card(
            child: ListTile(
              leading: Icon(Icons.account_balance,
                  color: Theme.of(context).colorScheme.primary),
              title: Text(s.title),
              subtitle: Text(s.desc),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          );
        },
      ),
    );
  }
}

class _Scheme {
  _Scheme(this.title, this.desc);
  final String title;
  final String desc;
}

// Settings page (profile + theme)
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final AppState app = AppStateScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(app.farmerName ?? 'Farmer'),
            subtitle: Text(app.phoneNumber ?? ''),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Dark Theme'),
            value: app.isDark,
            onChanged: (_) => app.toggleTheme(),
          ),
          ListTile(
            title: const Text('Change Language'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LanguageSelectPage()),
              );
            },
          ),
          ListTile(
            title: const Text('Log out'),
            leading: const Icon(Icons.logout),
            onTap: () async {
              final SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.remove('farmerName');
              await prefs.remove('phone');
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => SplashScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}

// Animated gradient background
class FancyBackground extends StatefulWidget {
  const FancyBackground({super.key});
  @override
  State<FancyBackground> createState() => _FancyBackgroundState();
}

class _FancyBackgroundState extends State<FancyBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _x;
  late final Animation<double> _y;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat(reverse: true);
    _x = Tween<double>(begin: -0.2, end: 0.2).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _y = Tween<double>(begin: 0.8, end: 0.4).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cs.primaryContainer.withOpacity(0.3),
                cs.secondaryContainer.withOpacity(0.3),
                cs.tertiaryContainer.withOpacity(0.3),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: MediaQuery.of(context).size.width * _x.value,
                top: 40,
                child: _blob(cs.primary.withOpacity(0.15), 180),
              ),
              Positioned(
                right: 16,
                top: MediaQuery.of(context).size.height * _y.value,
                child: _blob(cs.secondary.withOpacity(0.15), 140),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _blob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

