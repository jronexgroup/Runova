import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../state/worker_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bilingual_text.dart';

class IntakeModal extends StatefulWidget {
  const IntakeModal({super.key});

  @override
  State<IntakeModal> createState() => _IntakeModalState();
}

class _IntakeModalState extends State<IntakeModal> {
  final _deviceCtrl = TextEditingController();
  final _reportedCtrl = TextEditingController();
  final _inspectedCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _customerNameCtrl = TextEditingController();
  final _customerPhoneCtrl = TextEditingController();

  bool _selfAssign = true;
  bool _isListening = false;
  late stt.SpeechToText _speech;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    _deviceCtrl.dispose();
    _reportedCtrl.dispose();
    _inspectedCtrl.dispose();
    _descCtrl.dispose();
    _customerNameCtrl.dispose();
    _customerPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleVoiceInput(TextEditingController controller) async {
    try {
      if (!_isListening) {
        final available = await _speech.initialize(
          onStatus: (status) {
            if (status == 'notListening' || status == 'done') {
              if (mounted) setState(() => _isListening = false);
            }
          },
          onError: (err) {
            if (mounted) setState(() => _isListening = false);
          },
        );

        if (available) {
          setState(() => _isListening = true);
          _speech.listen(
            onResult: (result) {
              setState(() {
                controller.text = result.recognizedWords;
              });
            },
          );
        }
      } else {
        setState(() => _isListening = false);
        await _speech.stop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isListening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech-to-text not available on this device')),
        );
      }
    }
  }

  Future<void> _saveIntake() async {
    final device = _deviceCtrl.text.trim();
    final reported = _reportedCtrl.text.trim();
    final inspected = _inspectedCtrl.text.trim();
    final desc = _descCtrl.text.trim();

    if (device.isEmpty || reported.isEmpty || inspected.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in Device, Reported Problem, Inspected Problem, and Description.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    await WorkerState.instance.registerRepairTicket(
      deviceName: device,
      reportedProblem: reported,
      inspectedProblem: inspected,
      description: desc,
      customerName: _customerNameCtrl.text.trim(),
      customerPhone: _customerPhoneCtrl.text.trim(),
      selfAssign: _selfAssign,
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const BilingualText(
                  primary: 'New Repair Intake',
                  secondary: 'নতুন মেরামত নথিভুক্তকরণ',
                  primaryStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 16),

            TextField(
              controller: _deviceCtrl,
              decoration: const InputDecoration(
                labelText: 'Device Name (e.g. Redmi Note 11)',
                prefixIcon: Icon(Icons.smartphone_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _reportedCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Reported Problem (গ্রাহকের অভিযোগ)',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening ? AppColors.error : AppColors.primaryContainer,
                  ),
                  tooltip: 'Voice Input',
                  onPressed: () => _toggleVoiceInput(_reportedCtrl),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inspectedCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Technician Inspection (প্রাথমিক পরীক্ষা)',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening ? AppColors.error : AppColors.primaryContainer,
                  ),
                  tooltip: 'Voice Input',
                  onPressed: () => _toggleVoiceInput(_inspectedCtrl),
                ),
              ],
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Work Plan / Description (কাজের বিবরণ)',
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customerNameCtrl,
                    decoration: const InputDecoration(labelText: 'Customer Name'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _customerPhoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Phone Number'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Assign job directly to me (আমার নামে অ্যাসাইন করুন)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              value: _selfAssign,
              onChanged: (val) => setState(() => _selfAssign = val ?? true),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryContainer,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _saveIntake,
              child: const Text('Register Ticket • জমা দিন', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
