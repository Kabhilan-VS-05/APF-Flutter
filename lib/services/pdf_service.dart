import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PDFService {
  static Future<void> generateAndShareReport(Map<String, dynamic> report) async {
    final pdf = pw.Document();
    final isTherapistReport = report['status'] == 'therapist_assessment';
    
    // Add page to PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(report, isTherapistReport),
            pw.SizedBox(height: 20),
            _buildReportInfo(report),
            pw.SizedBox(height: 30),
            _buildReportContent(report, isTherapistReport),
            pw.SizedBox(height: 20),
            _buildFooter(),
          ];
        },
      ),
    );

    // Save PDF to file
    final directory = await getApplicationDocumentsDirectory();
    final fileName = '${isTherapistReport ? 'Assessment' : 'Parent_Q&A'}_Report_${report['childName']}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    // Share PDF
    await Share.shareXFiles([XFile(file.path)], text: 'Child Report: ${report['childName']}');
  }

  static pw.Widget _buildHeader(Map<String, dynamic> report, bool isTherapistReport) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              isTherapistReport ? 'THERAPIST ASSESSMENT REPORT' : 'PARENT Q&A REPORT',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: pw.BoxDecoration(
                color: isTherapistReport ? PdfColors.blue100 : PdfColors.green100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Text(
                isTherapistReport ? 'THERAPIST' : 'PARENT Q&A',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: isTherapistReport ? PdfColors.blue800 : PdfColors.green800,
                ),
              ),
            ),
          ],
        ),
        pw.Divider(thickness: 2, color: PdfColors.blue300),
      ],
    );
  }

  static pw.Widget _buildReportInfo(Map<String, dynamic> report) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildInfoRow('Child Name:', report['childName'] ?? 'N/A'),
              ),
              pw.Expanded(
                child: _buildInfoRow('Report Type:', report['status'] == 'therapist_assessment' ? 'Therapist Assessment' : 'Parent Q&A'),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildInfoRow('Created Date:', _formatDate(report['createdAt'])),
              ),
              pw.Expanded(
                child: _buildInfoRow('Therapist:', report['therapistName'] ?? 'N/A'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 80,
          child: pw.Text(
            label,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Text(value),
      ],
    );
  }

  static pw.Widget _buildReportContent(Map<String, dynamic> report, bool isTherapistReport) {
    if (isTherapistReport) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildSection('Summary', report['summary']),
          _buildSection('Recommendations', report['recommendations']),
          _buildSection('Next Session Focus', report['nextSessionFocus']),
        ],
      );
    } else {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildSection('Summary', report['summary']),
          if (report['detailedAssessment'] != null)
            _buildDetailedQASection(report['detailedAssessment']),
        ],
      );
    }
  }

  static pw.Widget _buildSection(String title, String? content) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey50,
              borderRadius: pw.BorderRadius.circular(4),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Text(
              content ?? 'No information available',
              style: const pw.TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildDetailedQASection(Map<String, dynamic> detailedAssessment) {
    try {
      print('Building detailed QA section...');
      print('Type: ${detailedAssessment['type']}');
      
      final type = detailedAssessment['type'];
      
      if (type == 'hierarchical_parent_qa') {
        return _buildHierarchicalQASection(detailedAssessment);
      } else if (type == 'parent_qa') {
        return _buildFlatQASection(detailedAssessment);
      } else {
        print('Unknown QA type: $type');
        return pw.SizedBox();
      }
    } catch (e) {
      print('Error in buildDetailedQASection: $e');
      print('Stack trace: ${StackTrace.current}');
      return pw.SizedBox();
    }
  }

  static pw.Widget _buildHierarchicalQASection(Map<String, dynamic> detailedAssessment) {
    try {
      final questionSet = detailedAssessment['questionSet'] as Map<String, dynamic>?;
      if (questionSet == null) {
        print('No questionSet found in hierarchical assessment');
        return pw.SizedBox();
      }

      final questions = questionSet['questions'] as List?;
      final responses = questionSet['responses'] as List?;
      
      if (questions == null || responses == null || questions.isEmpty || responses.isEmpty) {
        print('No questions or responses found in hierarchical assessment');
        return pw.SizedBox();
      }

      // Group responses by main question
      final Map<String, List<Map<String, dynamic>>> groupedResponses = {};
      final Map<String, Map<String, dynamic>> mainQuestions = {};
      
      // First, get all main questions
      for (final question in questions) {
        if (question is Map<String, dynamic>) {
          mainQuestions[question['id']] = question;
          groupedResponses[question['id']] = [];
        }
      }
      
      // Then, group responses by their parent question
      for (final response in responses) {
        if (response is Map<String, dynamic>) {
          final questionId = response['questionId'] as String?;
          final isMainQuestion = response['isMainQuestion'] as bool? ?? false;
          
          if (isMainQuestion) {
            // This is a main question response
            if (questionId != null && groupedResponses.containsKey(questionId)) {
              groupedResponses[questionId]!.insert(0, response);
            }
          } else {
            // This is a subquestion response, find its parent
            final parentQuestionId = response['parentQuestionId'] as String?;
            if (parentQuestionId != null && groupedResponses.containsKey(parentQuestionId)) {
              groupedResponses[parentQuestionId]!.add(response);
            }
          }
        }
      }

      final qaItems = <pw.Widget>[];
      int mainQuestionNumber = 1;
      
      for (final mainQuestionId in mainQuestions.keys) {
        final mainQuestion = mainQuestions[mainQuestionId]!;
        final responses = groupedResponses[mainQuestionId] ?? [];
        
        // Add main question
        qaItems.add(_buildMainQuestionPDF(mainQuestionNumber, mainQuestion, responses));
        
        // Add subquestions if any
        if (responses.length > 1) {
          int subQuestionNumber = 1;
          for (final response in responses.skip(1)) {
            qaItems.add(_buildSubQuestionPDF(mainQuestionNumber, subQuestionNumber, response));
            subQuestionNumber++;
          }
        }
        
        mainQuestionNumber++;
      }

      if (qaItems.isEmpty) {
        return pw.SizedBox();
      }

      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 20),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Hierarchical Questions & Answers',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
            pw.SizedBox(height: 12),
            ...qaItems,
          ],
        ),
      );
    } catch (e) {
      print('Error in buildHierarchicalQASection: $e');
      return pw.SizedBox();
    }
  }

  static pw.Widget _buildFlatQASection(Map<String, dynamic> detailedAssessment) {
    try {
      final questions = detailedAssessment['questions'] as List?;
      final responses = detailedAssessment['responses'] as List?;
      
      if (questions == null || responses == null || questions.isEmpty || responses.isEmpty) {
        return pw.SizedBox();
      }
      
      final qaItems = <pw.Widget>[];
      final maxLength = questions.length < responses.length ? questions.length : responses.length;
      
      for (int index = 0; index < maxLength && index < 100; index++) {
        try {
          if (index >= questions.length || index >= responses.length) {
            break;
          }
          
          final questionData = questions[index];
          final responseData = responses[index];
          
          String question = 'Question not available';
          if (questionData != null) {
            question = questionData.toString();
          }
          
          Map<String, dynamic> response = {};
          if (responseData is Map<String, dynamic>) {
            response = responseData;
          }
          
          qaItems.add(_buildQAItem(index + 1, question, response));
        } catch (e) {
          continue;
        }
      }
      
      if (qaItems.isEmpty) {
        return pw.SizedBox();
      }
      
      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 20),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Questions & Answers',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
            pw.SizedBox(height: 12),
            ...qaItems,
          ],
        ),
      );
    } catch (e) {
      return pw.SizedBox();
    }
  }

  static pw.Widget _buildMainQuestionPDF(int questionNumber, Map<String, dynamic> mainQuestion, List<Map<String, dynamic>> responses) {
    final questionText = mainQuestion['text']?.toString() ?? 'Question not available';
    final mainAnswer = responses.isNotEmpty ? responses[0]['answer']?.toString() ?? 'No answer provided' : 'No answer provided';
    
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Main question header
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue800,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              'MAIN QUESTION $questionNumber',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 8),
          
          // Question text
          pw.Text(
            questionText,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 8),
          
          // Answer
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.green50,
              borderRadius: pw.BorderRadius.circular(4),
              border: pw.Border.all(color: PdfColors.green200),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Parent Answer:',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green800,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  mainAnswer,
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSubQuestionPDF(int mainQuestionNumber, int subQuestionNumber, Map<String, dynamic> response) {
    final questionText = response['questionText']?.toString() ?? response['question']?.toString() ?? 'Subquestion not available';
    final answer = response['answer']?.toString() ?? 'No answer provided';
    
    return pw.Container(
      margin: const pw.EdgeInsets.only(left: 20, bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue600,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              'Q${mainQuestionNumber}.${subQuestionNumber}',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 6),
          
          pw.Text(
            questionText,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue700,
            ),
          ),
          pw.SizedBox(height: 6),
          
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(4),
              border: pw.Border.all(color: PdfColors.blue200),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Answer:',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  answer,
                  style: const pw.TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildQAItem(int number, String question, Map<String, dynamic> response) {
    final answer = response['answer']?.toString() ?? 'No answer provided';
    final answeredAt = response['answeredAt']?.toString() ?? 'Unknown time';
    
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: PdfColors.grey200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Q$number: $question',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Answer: $answer',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Answered: $answeredAt',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(thickness: 1, color: PdfColors.grey300),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generated by APF Therapy System',
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey600,
              ),
            ),
            pw.Text(
              'Date: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown date';
    
    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is String) {
        date = DateTime.parse(timestamp);
      } else {
        return 'Unknown date';
      }
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }
}
