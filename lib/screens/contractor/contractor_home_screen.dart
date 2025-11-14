// lib/screens/contractor/contractor_home_screen.dart
import 'package:assetarchiverflutter/models/mason_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For number input filtering
import 'dart:async'; // For FutureBuilder

// ✅ NEW IMPORTS
import 'package:assetarchiverflutter/api/api_service.dart';
import 'package:assetarchiverflutter/models/bag_lift_model.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'dart:io'; // --- ✅ ADD THIS ---
import 'package:image_picker/image_picker.dart';
// ---

// ✅ CONVERTED TO STATEFULWIDGET
class ContractorHomeScreen extends StatefulWidget {
  final Mason mason;
  const ContractorHomeScreen({super.key, required this.mason});

  @override
  State<ContractorHomeScreen> createState() => _ContractorHomeScreenState();
}

class _ContractorHomeScreenState extends State<ContractorHomeScreen> {
  // ✅ NEW STATE
  final ApiService _api = ApiService();
  final _bagCountController = TextEditingController();
  late Future<List<BagLift>> _historyFuture;
  bool _isSubmitting = false;
  File? _bagImageFile; // --- ✅ ADD THIS ---
  final ImagePicker _picker = ImagePicker();
  // ---

  @override
  void initState() {
    super.initState();
    // ✅ Load history on init
    _loadHistory();
  }

  @override
  void dispose() {
    _bagCountController.dispose();
    super.dispose();
  }

  void _loadHistory() {
    if (widget.mason.id == null) {
      // Set future to an error if mason has no ID
      setState(() {
        _historyFuture = Future.error('Mason ID is missing.');
      });
      return;
    }
    setState(() {
      _historyFuture = _api.fetchBagHistory(widget.mason.id!);
    });
  }

  // --- ✅ START: IMAGE PICKER METHODS ---
  Future<void> _showPickOptions() async {
    FocusScope.of(context).unfocus(); // Hide keyboard
    await showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickFile(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickFile(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickFile(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 80, // Compress image
      );
      if (picked == null) return;
      setState(() {
        _bagImageFile = File(picked.path);
      });
    } catch (e) {
      _toast('Failed to pick image: $e', isError: true);
    }
  }
  // --- ✅ END: IMAGE PICKER METHODS ---

  Future<void> _submitBags() async {
    if (_isSubmitting) return;

    // --- ✅ 1. VALIDATE IMAGE FIRST ---
    if (_bagImageFile == null) {
      _toast('Please take a picture of the bags.', isError: true);
      return;
    }
    // ---

    final count = int.tryParse(_bagCountController.text);
    if (count == null || count <= 0) {
      _toast('Please enter a valid number of bags.', isError: true);
      return;
    }

    final dealerId = widget.mason.dealerId;

    setState(() => _isSubmitting = true);

    try {
      // --- ✅ 2. UPLOAD IMAGE FIRST ---
      _toast('Uploading image...');
      final imageUrl = await _api.uploadImageToR2(_bagImageFile!);
      // ---

      // --- ✅ 3. SUBMIT WITH IMAGE URL ---
      _toast('Submitting bag count...');
      await _api.submitBags(
        masonId: widget.mason.id!,
        bagCount: count,
        dealerId: dealerId,
        imageUrl: imageUrl, // <-- Pass the URL
      );
      // ---

      _toast('Bag submission successful! Awaiting approval.');
      _bagCountController.clear();
      // --- ✅ 4. CLEAR IMAGE ON SUCCESS ---
      setState(() {
        _bagImageFile = null;
      });
      // ---
      _loadHistory(); // Refresh the history list
    } catch (e) {
      _toast('Submission failed: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _toast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : Colors.green,
      ),
    );
  }
  // ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Contractor Home')),
      body: RefreshIndicator(
        onRefresh: () async => _loadHistory(),
        child: SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(), // Allows pull-to-refresh
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. WELCOME MESSAGE ---
              Text(
                'Welcome Back,',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                widget.mason.name, // Use widget.mason
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.start,
              ),
              const SizedBox(height: 24),

              // --- 2. POINTS CARD ---
              _buildPointsCard(
                context,
                widget.mason.pointsBalance,
              ), // Use widget.mason

              const SizedBox(height: 24),

              // --- 3. SUBMIT BAGS CARD (REFINED) ---
              _buildSubmitCard(context),

              const SizedBox(height: 32),

              // --- 4. HISTORY LIST (NOW DYNAMIC) ---
              _buildHistoryList(context),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET 2: POINTS CARD (Unchanged) ---
  Widget _buildPointsCard(BuildContext context, int points) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.primary.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                Text(
                  'YOUR POINTS',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  points.toString(),
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET 3: SUBMIT BAGS CARD (REFINED) ---
  Widget _buildSubmitCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Submit Your Bags',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // --- IMAGE PICKER BUTTON ---
            OutlinedButton.icon(
              icon: Icon(
                _bagImageFile == null
                    ? Icons.camera_alt_outlined
                    : Icons.check_circle,
                color: _bagImageFile == null
                    ? theme.colorScheme.primary
                    : Colors.green,
              ),
              label: Text(
                _bagImageFile == null ? 'Take Photo of Bags' : 'Change Photo',
                style: TextStyle(
                  color: _bagImageFile == null
                      ? theme.colorScheme.primary
                      : Colors.green,
                ),
              ),
              onPressed: _showPickOptions,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: _bagImageFile == null
                      ? theme.colorScheme.primary.withOpacity(0.5)
                      : Colors.green.withOpacity(0.5),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            // --- Image Thumbnail ---
            if (_bagImageFile != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _bagImageFile!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            
            // --- BAG COUNT TEXTFIELD (Restored) ---
            const SizedBox(height: 16),
            TextField(
              controller: _bagCountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Number of bags',
                prefixIcon: Icon(
                  Icons.shopping_bag_outlined,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                border: const OutlineInputBorder(),
              ),
            ),

            // --- SUBMIT BUTTON (Restored) ---
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitBags, // ✅ WIRED
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'SUBMIT',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
            
            // --- PENDING CHIP ---
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.center,
              child: Chip(
                label: Text(
                  'Pending approval',
                  style: TextStyle(
                    color: Colors.orange[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: Colors.orange[100],
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET 4: HISTORY LIST (DYNAMIC) ---
  Widget _buildHistoryList(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'History',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // ✅ CONVERTED TO FUTUREBUILDER
        FutureBuilder<List<BagLift>>(
          future: _historyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No bag submission history found.'),
                ),
              );
            }

            final historyItems = snapshot.data!;

            return ListView.separated(
              physics: const NeverScrollableScrollPhysics(), // Important
              shrinkWrap: true,
              itemCount: historyItems.length,
              itemBuilder: (context, index) {
                final item = historyItems[index];
                return _buildHistoryItem(context, item: item);
              },
              separatorBuilder: (context, index) => const Divider(height: 1),
            );
          },
        ),
      ],
    );
  }

  // --- Reusable History Item (NOW USES BAGLIFT MODEL) ---
  Widget _buildHistoryItem(BuildContext context, {required BagLift item}) {
    Color statusColor;
    String statusText;

    switch (item.status.toLowerCase()) {
      case 'approved':
        statusColor = Colors.green;
        statusText = 'Approved';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Rejected';
        break;
      default:
        statusColor = Colors.orange;
        statusText = 'Pending';
    }

    // --- ✅ NEW: Add tap to view image ---
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: Icon(
        Icons.shopping_bag_outlined,
        size: 30,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(
        '${item.bagCount} bags',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: Text(DateFormat('MMM d, yyyy').format(item.purchaseDate)),
      trailing: Chip(
        label: Text(
          statusText,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: statusColor,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      // --- ✅ NEW: Add tap to view image ---
      onTap: item.imageUrl != null
          ? () => _showImageDialog(item.imageUrl!)
          : null,
    );
  }
  
  // --- ✅ NEW: Show Image Dialog ---
  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.all(8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(
              imageUrl,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (context, error, stack) {
                return const SizedBox(
                  height: 200,
                  child: Center(child: Icon(Icons.error, color: Colors.red)),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}