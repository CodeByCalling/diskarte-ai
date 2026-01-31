import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../services/ai_service.dart';

class BureaucracyWizardScreen extends StatefulWidget {
  const BureaucracyWizardScreen({super.key});

  @override
  State<BureaucracyWizardScreen> createState() => _BureaucracyWizardScreenState();
}

class _BureaucracyWizardScreenState extends State<BureaucracyWizardScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;
  String? _generatedLetter;

  // Step 1: User Info
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _addressController = TextEditingController();

  // Step 2: Request Type & Recipient
  final _recipientController = TextEditingController(); // e.g., "Hon. Joy Belmonte"
  String? _selectedRequestType;
  final List<String> _requestTypes = [
    'Barangay Indigency',
    'Medical Assistance',
    'Financial Assistance (Solicitation)',
    'Complaint (Reklamo)',
    'Other (Barangay Clearance/Permit)',
  ];

  // Step 3: Details
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _recipientController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep++;
      });
    }
  }

  void _prevPage() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _generateLetter() async {
    setState(() {
      _isLoading = true;
    });

    // Construct Prompt
    final buffer = StringBuffer();
    // buffer.writeln("Act as the Bureaucracy Breaker."); // Implicit via FeatureType
    buffer.writeln("Write a formal request letter for: ${_selectedRequestType ?? 'General Request'}.");
    buffer.writeln("Addressed To: ${_recipientController.text}.");
    buffer.writeln("\nSENDER DETAILS:");
    buffer.writeln("Name: ${_nameController.text}");
    buffer.writeln("Age: ${_ageController.text}");
    buffer.writeln("Address: ${_addressController.text}");
    
    buffer.writeln("\nREASON / DETAILS:");
    buffer.writeln(_reasonController.text);

    buffer.writeln("\nINSTRUCTIONS:");
    buffer.writeln("Use formal technical 'High Taglish' suitable for government officials.");
    buffer.writeln("Be respectful (use 'Po/Opo', 'Honorable', etc.).");
    buffer.writeln("Ensure the letter format is correct (Date, Recipient, Salutation, Body, Closing, Signature Line).");

    try {
      final aiService = AiService();
      final result = await aiService.sendMessage(
        buffer.toString(),
        FeatureType.bureaucracyBreaker,
      );

      setState(() {
        _generatedLetter = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _generatedLetter = "Error generating letter. Please try again. ($e)";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bureaucracy Breaker', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF002D72),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF002D72)),
                  const SizedBox(height: 16),
                  Text(
                    'Drafting your letter...\nAdding formal touches...',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            )
          : _generatedLetter != null
              ? _buildResultView()
              : Column(
                  children: [
                    _buildProgressIndicator(),
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildStep1(),
                          _buildStep2(),
                          _buildStep3(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepDot(0, "Info"),
          _buildStepLine(),
          _buildStepDot(1, "Type"),
          _buildStepLine(),
          _buildStepDot(2, "Details"),
        ],
      ),
    );
  }

  Widget _buildStepDot(int step, String label) {
    bool isActive = _currentStep >= step;
    return Column(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: isActive ? const Color(0xFF002D72) : Colors.grey[300],
          child: Text(
            '${step + 1}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
              fontSize: 10,
              color: isActive ? const Color(0xFF002D72) : Colors.grey,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal),
        ),
      ],
    );
  }

  Widget _buildStepLine() {
    return Container(
      width: 40,
      height: 2,
      color: Colors.grey[300],
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
    );
  }

  // Step 1: User Info
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Who is making the request?",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF002D72))),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
                labelText: 'Full Name (Juan Dela Cruz)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: 'Age',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.cake)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _addressController,
            decoration: const InputDecoration(
                labelText: 'Complete Address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.home)),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF002D72)),
              onPressed: _nextPage,
              child: const Text('Next: Request Type',
                  style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  // Step 2: Request Type
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("What do you need?",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF002D72))),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            value: _selectedRequestType,
            decoration: const InputDecoration(
              labelText: 'Type of Request',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description),
            ),
            items: _requestTypes.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                _selectedRequestType = newValue;
              });
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _recipientController,
            decoration: const InputDecoration(
                labelText: "Recipient (e.g. 'To the Mayor')",
                hintText: "Hon. Joy Belmonte / Kap. Tiyago",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.send)),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              TextButton(onPressed: _prevPage, child: const Text('Back')),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF002D72),
                    minimumSize: const Size(150, 50)),
                onPressed: _nextPage,
                child: const Text('Next: Details',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Step 3: Details
  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Tell us more.",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF002D72))),
          const SizedBox(height: 8),
          const Text("Why do you need this? Be specific for better results.",
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          TextField(
            controller: _reasonController,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Reason / Explanation',
              hintText:
                  'I need medical assistance for my hospitalization at PGH due to kidney failure...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              TextButton(onPressed: _prevPage, child: const Text('Back')),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF002D72),
                    minimumSize: const Size(150, 50)),
                onPressed: _generateLetter,
                child: const Text('Generate Letter',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.green[50],
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              const Expanded(
                  child: Text("Letter Generated! Copy or Edit below.")),
              IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(
                      ClipboardData(text: _generatedLetter ?? ''));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Letter copied to clipboard!')),
                  );
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: MarkdownBody(
              data: _generatedLetter ?? '',
              selectable: true,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF002D72)),
              onPressed: () {
                Navigator.of(context).pop(); 
              },
              child: const Text('Done / Back to Dashboard',
                  style: TextStyle(color: Colors.white)),
            ),
          ),
        ),
      ],
    );
  }
}
