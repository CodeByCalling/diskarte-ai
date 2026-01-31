import 'package:flutter/material.dart';
import '../../shared/widgets/message_bubble.dart';
import '../../../services/ai_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/services.dart';

class ResumeWizardScreen extends StatefulWidget {
  const ResumeWizardScreen({super.key});

  @override
  State<ResumeWizardScreen> createState() => _ResumeWizardScreenState();
}

class _ResumeWizardScreenState extends State<ResumeWizardScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;
  String? _generatedResume;
  
  // Step 1: Personal Info
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _locationController = TextEditingController();

  // Step 2: Experience
  // Simple list of strings for MVP, or structured if needed. 
  // Let's do structured but keep it simple in UI.
  final List<Map<String, String>> _experienceList = [];
  final _jobTitleController = TextEditingController();
  final _companyController = TextEditingController();
  final _yearsController = TextEditingController();

  // Step 3: Skills
  final List<String> _skillsList = [];
  final _skillController = TextEditingController();

  final List<String> _suggestedSkills = [
    'Customer Service', 'Sales', 'Microsoft Office', 'Tagalog', 'English', 
    'Cashier', 'Driver', 'Cooking', 'Cleaning'
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _contactController.dispose();
    _locationController.dispose();
    _jobTitleController.dispose();
    _companyController.dispose();
    _yearsController.dispose();
    _skillController.dispose();
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

  void _addExperience() {
    if (_jobTitleController.text.isNotEmpty && _companyController.text.isNotEmpty) {
      setState(() {
        _experienceList.add({
          'role': _jobTitleController.text,
          'company': _companyController.text,
          'years': _yearsController.text,
        });
        _jobTitleController.clear();
        _companyController.clear();
        _yearsController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job added! Add another or click Next.')),
      );
    }
  }

  void _addSkill(String skill) {
    if (skill.isNotEmpty && !_skillsList.contains(skill)) {
      setState(() {
        _skillsList.add(skill);
        _skillController.clear();
      });
    }
  }

  Future<void> _generateResume() async {
    setState(() {
      _isLoading = true;
    });

    // Construct Prompt
    final buffer = StringBuffer();
    buffer.writeln("Create a professional resume for ${_nameController.text}.");
    buffer.writeln("Contact: ${_contactController.text}, Location: ${_locationController.text}.");
    
    if (_experienceList.isNotEmpty) {
      buffer.writeln("\nExperience:");
      for (var job in _experienceList) {
        buffer.writeln("- ${job['role']} at ${job['company']} (${job['years']})");
      }
    } else {
      buffer.writeln("\nExperience: Entry Level / No formal experience.");
    }

    if (_skillsList.isNotEmpty) {
      buffer.writeln("\nSkills: ${_skillsList.join(', ')}.");
    }

    buffer.writeln("\nIMPORTANT: Use 'Diskarte' tone to highlight resourcefulness and reliability. Keep it professional but accessible for a Filipino employer. Format the output in clean Markdown.");

    try {
      final aiService = AiService();
      final result = await aiService.sendMessage(
        buffer.toString(),
        FeatureType.diskarteToolkit,
      );

      setState(() {
        _generatedResume = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _generatedResume = "Error generating resume. Please try again.";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume Builder', style: TextStyle(color: Colors.white)),
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
                  'Writing your resume...\nDiskarte Mode ON',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          )
        : _generatedResume != null
          ? _buildResultView()
          : Column(
              children: [
                _buildProgressIndicator(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(), // Prevent swipe
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
          _buildStepDot(1, "Work"),
          _buildStepLine(),
          _buildStepDot(2, "Skills"),
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
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine() {
    return Container(
      width: 40,
      height: 2,
      color: Colors.grey[300],
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12), // align with dot center roughly
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Let's start with you.", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF002D72))),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _contactController,
            decoration: const InputDecoration(labelText: 'Mobile Number / Email', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _locationController,
            decoration: const InputDecoration(labelText: 'City / Location (e.g. Cavite)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF002D72)),
              onPressed: _nextPage,
              child: const Text('Next: Work Experience', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Where have you worked?", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF002D72))),
          const Text("Skip if you have no experience yet.", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          
          // List of added jobs
          if (_experienceList.isNotEmpty) ...[
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _experienceList.length,
              itemBuilder: (context, index) {
                final job = _experienceList[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(job['role'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${job['company']} • ${job['years']}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _experienceList.removeAt(index);
                        });
                      },
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],

          const Text("Add a Job:", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _jobTitleController,
            decoration: const InputDecoration(labelText: 'Job Title (e.g. Service Crew)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _companyController,
            decoration: const InputDecoration(labelText: 'Company', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _yearsController,
            decoration: const InputDecoration(labelText: 'Years / Duration (e.g. 2021-2023)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _addExperience,
            icon: const Icon(Icons.add),
            label: const Text('Add Job to List'),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              TextButton(onPressed: _prevPage, child: const Text('Back')),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF002D72), minimumSize: const Size(150, 50)),
                onPressed: _nextPage,
                child: const Text('Next: Skills', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("What are you good at?", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF002D72))),
          const SizedBox(height: 24),

          Wrap(
            spacing: 8,
            children: _skillsList.map((skill) => Chip(
              label: Text(skill),
              onDeleted: () {
                setState(() {
                  _skillsList.remove(skill);
                });
              },
            )).toList(),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _skillController,
            decoration: InputDecoration(
              labelText: 'Add a Skill',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _addSkill(_skillController.text),
              ),
            ),
            onSubmitted: _addSkill,
          ),
          const SizedBox(height: 16),
          const Text("Suggestions:", style: TextStyle(color: Colors.grey)),
          Wrap(
            spacing: 8,
            children: _suggestedSkills.map((s) => ActionChip(
              label: Text(s),
              onPressed: () => _addSkill(s),
            )).toList(),
          ),

          const SizedBox(height: 32),
          Row(
            children: [
              TextButton(onPressed: _prevPage, child: const Text('Back')),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF002D72), minimumSize: const Size(150, 50)),
                onPressed: _generateResume, // Finish
                child: const Text('Finish & Generate', style: TextStyle(color: Colors.white)),
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
              const Expanded(child: Text("Resume Generated! You can copy it below.")),
              IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _generatedResume ?? ''));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Resume copied to clipboard!')),
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
              data: _generatedResume ?? '',
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
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF002D72)),
              onPressed: () {
                Navigator.of(context).pop(); // Or reset
              },
              child: const Text('Done / Back to Dashboard', style: TextStyle(color: Colors.white)),
            ),
          ),
        ),
      ],
    );
  }
}
