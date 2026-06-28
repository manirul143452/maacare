import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../app_theme.dart';
import '../../../services/maacare_backend_service.dart';

class SubmitReportSheet extends StatefulWidget {
  final String patientId;
  final String doctorId;
  final Function(String fileUrl) onReportUploaded;

  const SubmitReportSheet({
    super.key,
    required this.patientId,
    required this.doctorId,
    required this.onReportUploaded,
  });

  @override
  State<SubmitReportSheet> createState() => _SubmitReportSheetState();
}

class _SubmitReportSheetState extends State<SubmitReportSheet> {
  String? _selectedFile;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _uploadedUrl;

  final List<Map<String, String>> _mockReports = [
    {
      'name': 'Thyroid_Stimulating_Hormone_TSH.pdf',
      'size': '1.4 MB',
      'url': 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf'
    },
    {
      'name': 'Hormonal_Health_Panel_2026.jpg',
      'size': '2.1 MB',
      'url': 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?q=80&w=600'
    },
    {
      'name': 'Pelvic_Ultrasound_Scan_Report.pdf',
      'size': '850 KB',
      'url': 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf'
    },
    {
      'name': 'Complete_Blood_Count_CBC.pdf',
      'size': '1.1 MB',
      'url': 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf'
    }
  ];

  void _simulateUpload(Map<String, String> report) async {
    setState(() {
      _selectedFile = report['name'];
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    // Simulate progress ticks
    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;
      setState(() {
        _uploadProgress = i * 0.1;
      });
    }

    // Submit to database
    final fileUrl = report['url']!;
    final success = await MaaCareBackendService.instance.submitPatientReport(
      patientId: widget.patientId,
      doctorId: widget.doctorId,
      fileUrl: fileUrl,
    );

    if (!mounted) return;

    if (success) {
      setState(() {
        _isUploading = false;
        _uploadedUrl = fileUrl;
      });
      widget.onReportUploaded(fileUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medical report uploaded and shared successfully! 📄'),
          backgroundColor: MaaColors.success,
        ),
      );
    } else {
      setState(() {
        _isUploading = false;
        _selectedFile = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit report metadata. Please try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: MaaColors.cardDark.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.description_outlined, color: MaaColors.pink, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Submit Clinical / Hormonal Lab Report',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Upload a PDF or JPG scan of your recent clinical report to securely share it with the doctor for advanced diagnostic triage.',
            style: GoogleFonts.outfit(color: MaaColors.textMuted, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 24),

          // Uploading State
          if (_isUploading) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                children: [
                  const CircularProgressIndicator(color: MaaColors.pink),
                  const SizedBox(height: 16),
                  Text(
                    'Uploading: $_selectedFile...',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: _uploadProgress,
                      backgroundColor: Colors.white10,
                      color: MaaColors.pink,
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${(_uploadProgress * 100).toInt()}% uploaded',
                    style: GoogleFonts.outfit(color: MaaColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ).animate().fadeIn(),
          ]
          // Uploaded State
          else if (_uploadedUrl != null) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: MaaColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: MaaColors.success.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle_outline_rounded, color: MaaColors.success, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Uploaded Successfully!',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedFile ?? '',
                    style: GoogleFonts.outfit(color: MaaColors.textMuted, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Dismiss & Continue',
                      style: GoogleFonts.poppins(color: MaaColors.pink, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
            ).animate().fadeIn(),
          ]
          // Choose mock report list
          else ...[
            Text(
              'Select a document to simulate upload:',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ..._mockReports.map((report) {
              return GestureDetector(
                onTap: () => _simulateUpload(report),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.picture_as_pdf_outlined, color: Colors.redAccent, size: 24),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              report['name']!,
                              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              report['size']!,
                              style: GoogleFonts.outfit(color: MaaColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.cloud_upload_outlined, color: MaaColors.pink, size: 20),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
