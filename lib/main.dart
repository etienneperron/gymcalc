import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

const List<double> availablePlates = <double>[45, 25, 10, 5, 2.5];
const List<double> defaultPercentages = <double>[
  100,
  95,
  92.5,
  90,
  87.5,
  85,
  82.5,
  80,
  77.5,
  75,
  72.5,
  70,
  67.5,
  65,
  62.5,
  60,
  57.5,
  55,
  52.5,
  50,
];
const String maxWeightKey = 'max_weight';
const String barWeightKey = 'bar_weight';
const String repCountKey = 'rep_count';
const String percentagesKey = 'percentages';
const String darkModeKey = 'dark_mode';
const String projectUrl = 'https://github.com/etienneperron/gymcalc';
const String licenseInfo = 'GNU General Public License v3.0 (GPLv3)';
final Uri projectUri = Uri.parse(projectUrl);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    setState(() {
      _isDarkMode = preferences.getBool(darkModeKey) ?? false;
    });
  }

  Future<void> _setDarkMode(bool enabled) async {
    setState(() {
      _isDarkMode = enabled;
    });
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setBool(darkModeKey, enabled);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GymCalc',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF274C4D),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF274C4D),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: PlateCalculatorPage(
        isDarkMode: _isDarkMode,
        onDarkModeChanged: _setDarkMode,
      ),
    );
  }
}

class PlateCalculatorPage extends StatefulWidget {
  const PlateCalculatorPage({
    required this.isDarkMode,
    required this.onDarkModeChanged,
    super.key,
  });

  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;

  @override
  State<PlateCalculatorPage> createState() => _PlateCalculatorPageState();
}

class _PlateCalculatorPageState extends State<PlateCalculatorPage> {
  late final TextEditingController _maxWeightController;
  late final TextEditingController _barWeightController;
  late final List<TextEditingController> _percentageControllers;
  SharedPreferences? _preferences;

  int _repCount = 5;

  @override
  void initState() {
    super.initState();
    _maxWeightController = TextEditingController(text: '225');
    _barWeightController = TextEditingController(text: '45');
    _percentageControllers = List<TextEditingController>.generate(
      20,
      (int index) => TextEditingController(
        text: formatPercentage(defaultPercentages[index]),
      ),
    );
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final List<String>? savedPercentages = preferences.getStringList(
      percentagesKey,
    );

    if (!mounted) {
      return;
    }

    _preferences = preferences;
    setState(() {
      _maxWeightController.text = preferences.getString(maxWeightKey) ?? '225';
      _barWeightController.text = preferences.getString(barWeightKey) ?? '45';
      _repCount = preferences.getInt(repCountKey) ?? 5;

      if (savedPercentages == null) {
        return;
      }

      for (int index = 0; index < _percentageControllers.length; index++) {
        if (index >= savedPercentages.length) {
          break;
        }
        _percentageControllers[index].text = savedPercentages[index];
      }
    });
  }

  Future<void> _savePreferences() async {
    final SharedPreferences preferences =
        _preferences ?? await SharedPreferences.getInstance();
    _preferences = preferences;

    await preferences.setString(maxWeightKey, _maxWeightController.text);
    await preferences.setString(barWeightKey, _barWeightController.text);
    await preferences.setInt(repCountKey, _repCount);
    await preferences.setStringList(
      percentagesKey,
      _percentageControllers
          .map((TextEditingController controller) => controller.text)
          .toList(),
    );
  }

  @override
  void dispose() {
    _maxWeightController.dispose();
    _barWeightController.dispose();
    for (final TextEditingController controller in _percentageControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double? maxWeight = parseInput(_maxWeightController.text);
    final double? barWeight = parseInput(_barWeightController.text);
    final List<RepCalculation> calculations = buildCalculations(
      maxWeight: maxWeight,
      barWeight: barWeight,
      percentageInputs: _percentageControllers
          .take(_repCount)
          .map((TextEditingController controller) => controller.text)
          .toList(),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('GymCalc'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Information',
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Plate Calculator',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Enter a max weight and adjust the percentage for each rep.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Dark mode'),
                value: widget.isDarkMode,
                onChanged: widget.onDarkModeChanged,
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: <Widget>[
                      TextField(
                        controller: _maxWeightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Max weight (lb)',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) {
                          setState(() {});
                          _savePreferences();
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _barWeightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Bar weight (lb)',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) {
                          setState(() {});
                          _savePreferences();
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue: _repCount,
                        decoration: const InputDecoration(
                          labelText: 'Number of reps',
                          border: OutlineInputBorder(),
                        ),
                        items: List<DropdownMenuItem<int>>.generate(
                          20,
                          (int index) => DropdownMenuItem<int>(
                            value: index + 1,
                            child: Text('${index + 1}'),
                          ),
                        ),
                        onChanged: (int? value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            _repCount = value;
                          });
                          _savePreferences();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (maxWeight == null || barWeight == null)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text('Enter valid numeric values to see calculations.'),
                ),
              ...calculations.map((RepCalculation calculation) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: RepCalculationCard(
                    calculation: calculation,
                    controller: _percentageControllers[calculation.rep - 1],
                    onChanged: () {
                      setState(() {});
                      _savePreferences();
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('About'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('Project URL:'),
              const SizedBox(height: 4),
              InkWell(
                onTap: () async {
                  await launchUrl(projectUri, mode: LaunchMode.externalApplication);
                },
                child: Text(
                  projectUrl,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('License:'),
              const SizedBox(height: 4),
              const Text(licenseInfo),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class RepCalculationCard extends StatelessWidget {
  const RepCalculationCard({
    required this.calculation,
    required this.controller,
    required this.onChanged,
    super.key,
  });

  final RepCalculation calculation;
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Rep ${calculation.rep}',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: '% of max',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => onChanged(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: <Widget>[
                StatChip(
                  label: 'Target',
                  value: calculation.displayTargetWeight,
                ),
                StatChip(
                  label: 'Per side',
                  value: calculation.displayPerSideWeight,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              calculation.plateSummary,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class StatChip extends StatelessWidget {
  const StatChip({
    required this.label,
    required this.value,
    super.key,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('$label: $value'),
    );
  }
}

class RepCalculation {
  const RepCalculation({
    required this.rep,
    required this.targetWeight,
    required this.perSideWeight,
    required this.plates,
    required this.percentage,
    required this.isValid,
  });

  final int rep;
  final double? percentage;
  final double targetWeight;
  final double perSideWeight;
  final List<double> plates;
  final bool isValid;

  String get displayTargetWeight => '${formatWeight(targetWeight)} lb';

  String get displayPerSideWeight => '${formatWeight(perSideWeight)} lb';

  String get plateSummary {
    if (!isValid || percentage == null) {
      return 'Enter a valid percentage.';
    }
    if (perSideWeight == 0) {
      return 'Use the empty bar.';
    }

    final Map<double, int> counts = <double, int>{};
    for (final double plate in plates) {
      counts.update(plate, (int value) => value + 1, ifAbsent: () => 1);
    }

    final List<String> parts = availablePlates
        .where(counts.containsKey)
        .map(
          (double plate) => '${formatWeight(plate)} lb x${counts[plate]}',
        )
        .toList();

    return 'Plates per side: ${parts.join(', ')}';
  }
}

List<RepCalculation> buildCalculations({
  required double? maxWeight,
  required double? barWeight,
  required List<String> percentageInputs,
}) {
  return List<RepCalculation>.generate(percentageInputs.length, (int index) {
    final double? percentage = parseInput(percentageInputs[index]);
    return calculateRep(
      rep: index + 1,
      maxWeight: maxWeight,
      barWeight: barWeight,
      percentage: percentage,
    );
  });
}

RepCalculation calculateRep({
  required int rep,
  required double? maxWeight,
  required double? barWeight,
  required double? percentage,
}) {
  if (maxWeight == null ||
      barWeight == null ||
      maxWeight <= 0 ||
      barWeight <= 0 ||
      percentage == null ||
      percentage < 0) {
    return RepCalculation(
      rep: rep,
      percentage: percentage,
      targetWeight: 0,
      perSideWeight: 0,
      plates: const <double>[],
      isValid: false,
    );
  }

  final double desiredTotal = maxWeight * (percentage / 100);
  final double rawPerSide = (desiredTotal - barWeight) / 2;
  final double perSideWeight =
      rawPerSide <= 0 ? 0 : roundToNearest(rawPerSide, 2.5);
  final double targetWeight = barWeight + (perSideWeight * 2);

  return RepCalculation(
    rep: rep,
    percentage: percentage,
    targetWeight: targetWeight,
    perSideWeight: perSideWeight,
    plates: buildPlateBreakdown(perSideWeight),
    isValid: true,
  );
}

List<double> buildPlateBreakdown(double perSideWeight) {
  double remaining = perSideWeight;
  final List<double> plates = <double>[];

  for (final double plate in availablePlates) {
    while (remaining + 0.001 >= plate) {
      plates.add(plate);
      remaining -= plate;
    }
  }

  return plates;
}

double roundToNearest(double value, double increment) {
  return (value / increment).round() * increment;
}

double? parseInput(String value) {
  return double.tryParse(value.trim());
}

String formatWeight(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(1);
}

String formatPercentage(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(1);
}