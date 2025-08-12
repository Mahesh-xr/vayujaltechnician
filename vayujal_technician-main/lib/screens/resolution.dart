import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:vayujal_technician/navigation/NormalAppBar.dart';
import 'package:vayujal_technician/screens/dbforresolution.dart';
import 'package:vayujal_technician/screens/service_acknowlwdgement_screen.dart.dart';
import 'package:video_player/video_player.dart';
import 'package:vayujal_technician/services/dynamic_dropdown_service.dart';

class ResolutionPage extends StatefulWidget {
  final String srNumber;
  
  const ResolutionPage({super.key, required this.srNumber});

  @override
  State<ResolutionPage> createState() => _ResolutionPageState();
}

class _ResolutionPageState extends State<ResolutionPage> {
  final ResolutionService _resolutionService = ResolutionService();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  
  // Controllers
  final TextEditingController _issueTypeController = TextEditingController();
  final TextEditingController _solutionController = TextEditingController();
  final TextEditingController _customSuggestionsController = TextEditingController();
  final TextEditingController _issueOthersController = TextEditingController();
  final TextEditingController _partsOthersController = TextEditingController();

  VideoPlayerController? _videoPlayerController;
  bool _isVideoPlaying = false;
  
  // Form data
  List<String> _selectedIssues = [];
  List<String> _selectedParts = [];
  final List<File> _resolutionImages = [];
  File? _resolutionVideo;
  DateTime _nextServiceDate = DateTime.now().add(Duration(days: 30));
  
  // Suggestions checkboxes
  final Map<String, bool> _suggestions = {
    'keepAirFilterClean': false,
    'supplyStableElectricity': false,
    'keepAwayFromSmells': false,
    'protectFromSunAndRain': false,
  };
  
  // Status
  String _selectedStatus = 'completed';
  bool _isLoading = false;

  // Dynamic dropdowns
  List<String> _dynamicIssueOptions = [];
  bool _isLoadingIssues = true;
  Map<String, List<String>> _dynamicPartsOptions = {};
  bool _isLoadingParts = true;

  @override
  void initState() {
    super.initState();
    _loadServiceRequestData();
    _fetchDynamicDropdowns();
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _issueTypeController.dispose();
    _solutionController.dispose();
    _customSuggestionsController.dispose();
    _issueOthersController.dispose();
    _partsOthersController.dispose();
    super.dispose();
  }

  // Load existing service request data
  Future<void> _loadServiceRequestData() async {
    try {
      final data = await _resolutionService.getServiceRequestData(widget.srNumber);
      if (data != null) {
        setState(() {
          // Pre-fill any existing resolution data
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _fetchDynamicDropdowns() async {
    setState(() {
      _isLoadingIssues = true;
      _isLoadingParts = true;
    });
    try {
      // Fetch Types of Identified Issues using the numbered fields structure
      print('> Attempting to fetch from: dropdown_List/Type_of_identified_issue');
      final issues = await DynamicDropdownService.fetchNumberedFieldsDropdown(
        collection: 'dropdown_List',
        document: 'Types_of_identified_issue',
      );
      
      print('> Fetched issues: ${issues.length} items');
      if (issues.isNotEmpty) {
        print('> First few issues: ${issues.take(5).toList()}');
      } else {
        print('> No issues fetched - using fallback values');
      }
      
      // Fetch Parts Replacement using the mixed structure
      final parts = await DynamicDropdownService.fetchMixedStructureDropdown(
        collection: 'dropdown_List',
        document: 'parts_replacement',
      );
      
      if (mounted) {
        setState(() {
          _dynamicIssueOptions = issues;
          _isLoadingIssues = false;
          _dynamicPartsOptions = parts;
          _isLoadingParts = false;
        });
      }
    } catch (e) {
      print('> Error loading dynamic dropdowns for Resolution: $e');
      if (mounted) {
        setState(() {
          _isLoadingIssues = false;
          _isLoadingParts = false;
        });
      }
    }
  }

  // Pick multiple images (up to 5) - FIXED VERSION
  Future<void> _pickImages(ImageSource source) async {
    try {
      if (source == ImageSource.camera) {
        final XFile? image = await _picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );
        if (image != null && _resolutionImages.length < 5) {
          setState(() {
            _resolutionImages.add(File(image.path));
          });
        }
      } else {
        final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );
        if (image != null && _resolutionImages.length < 5) {
          setState(() {
            _resolutionImages.add(File(image.path));
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking images: $e')),
        );
      }
    }
  }

  // Alternative method for picking multiple images from gallery
  Future<void> _pickMultipleImagesFromGallery() async {
    try {
      while (_resolutionImages.length < 5) {
        final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );
        
        if (image != null) {
          setState(() {
            _resolutionImages.add(File(image.path));
          });
          
          if (_resolutionImages.length < 5) {
            bool? addMore = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Add More Images'),
                content: Text('You have added ${_resolutionImages.length} image(s). Do you want to add more? (Max: 5)'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('No'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text('Yes'),
                  ),
                ],
              ),
            );
            
            if (addMore != true) break;
          }
        } else {
          break;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking images: $e')),
        );
      }
    }
  }

  // Pick video (10 seconds max)
  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: Duration(seconds: 10),
      );
      if (video != null) {
        _initializeVideoPlayer(File(video.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking video: $e')),
        );
      }
    }
  }

  Future<void> _pickVideoFromGallery() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: Duration(seconds: 10),
      );
      if (video != null) {
        _initializeVideoPlayer(File(video.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking video: $e')),
        );
      }
    }
  }

  Future<void> _initializeVideoPlayer(File videoFile) async {
    if (_videoPlayerController != null) {
      await _videoPlayerController!.dispose();
    }

    setState(() {
      _resolutionVideo = videoFile;
      _videoPlayerController = VideoPlayerController.file(videoFile)
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
          }
        });
    });
  }

  // Remove image
  void _removeImage(int index) {
    setState(() {
      _resolutionImages.removeAt(index);
    });
  }

  // Remove video
  Future<void> _removeVideo() async {
    if (_videoPlayerController != null) {
      await _videoPlayerController!.dispose();
    }
    setState(() {
      _resolutionVideo = null;
      _videoPlayerController = null;
      _isVideoPlaying = false;
    });
  }

  // Show image picker dialog
  void _showImagePickerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImages(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Gallery (Single)'),
              onTap: () {
                Navigator.pop(context);
                _pickImages(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library_outlined),
              title: Text('Gallery (Multiple)'),
              onTap: () {
                Navigator.pop(context);
                _pickMultipleImagesFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  // Show video picker dialog
  void _showVideoPickerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Video Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.videocam),
              title: Text('Camera (10 sec max)'),
              onTap: () {
                Navigator.pop(context);
                _pickVideo();
              },
            ),
            ListTile(
              leading: Icon(Icons.video_library),
              title: Text('Gallery (10 sec max)'),
              onTap: () {
                Navigator.pop(context);
                _pickVideoFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  // Show issue selection dialog with multiple selection
  void _showIssueSelectionDialog() {
    List<String> tempSelectedIssues = List.from(_selectedIssues);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Select Issues (Multiple Selection)'),
          content: _isLoadingIssues
              ? SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                )
              : SizedBox(
                  width: double.maxFinite,
                  height: 400,
                  child: ListView(
                    children: (_dynamicIssueOptions.isNotEmpty
                            ? _dynamicIssueOptions
                            : [
                                'Adapet', 'OLR', 'Contactor', 'LP/HP switch', 'sensor', 'LED', 'switch', 'controllers',
                                'capacitor', 'fan', 'air filter', 'gas leakage', 'compressor', 'Icing', 'pump', 'filters',
                                'plumbing', 'rusting', 'cracks', 'bucking', 'bending', 'environmental', 'none', 'Others'
                              ])
                        .map((issue) => CheckboxListTile(
                              title: Text(issue),
                              value: tempSelectedIssues.contains(issue),
                              onChanged: (value) {
                                setDialogState(() {
                                  if (value == true) {
                                    tempSelectedIssues.add(issue);
                                  } else {
                                    tempSelectedIssues.remove(issue);
                                  }
                                });
                              },
                            ))
                        .toList(),
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedIssues = tempSelectedIssues;
                });
                Navigator.pop(context);
              },
              child: Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  // Show parts selection dialog with hierarchical structure and multiple selection
  void _showPartsSelectionDialog() {
    List<String> tempSelectedParts = List.from(_selectedParts);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Select Parts (Multiple Selection)'),
          content: _isLoadingParts
              ? SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                )
              : SizedBox(
                  width: double.maxFinite,
                  height: 500,
                  child: ListView(
                    children: (_dynamicPartsOptions.isNotEmpty
                            ? _dynamicPartsOptions.entries
                            : {
                                'ROCKER SWITCH': ['RED DPST', 'BLUE DPST', 'PUSH LOCK BUTTON'],
                                'ADAPTER': ['1.5A ADAPTER', '2.5A ADAPTER', 'UVI CHOKE 230VAC'],
                                'RELAY AND BASE': [],
                                'WATER PUMP': [],
                                'CAPACITOR': [],
                                'OLR': [],
                                'CONTACTOR': [],
                                'TIMER': [],
                                'FILTERS': ['SEDIMENT', 'PRE CARBON', 'POST CARBON', 'MINERALS', 'UF MEMBRANE', 'UV', 'OZONE-GENERATOR'],
                                'FAN': [],
                                'REFRIGERANT': [],
                                'WHEELS': [],
                                'MCB': [],
                                'PLUG-IN 3 TOP': [],
                                'PRESSURE SWITCH': [],
                                'CONTROLLERS': ['SZ 2911', 'SZ 7510T', 'SZ 7524T'],
                                'Others': [],
                              }.entries)
                        .map((entry) {
                      final mainItem = entry.key;
                      final subItems = entry.value;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CheckboxListTile(
                            title: Text(
                              mainItem,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                            value: tempSelectedParts.contains(mainItem),
                            onChanged: (value) {
                              setDialogState(() {
                                if (value == true) {
                                  tempSelectedParts.add(mainItem);
                                } else {
                                  tempSelectedParts.remove(mainItem);
                                }
                              });
                            },
                          ),
                          ...subItems.map((subItem) => Padding(
                                padding: EdgeInsets.only(left: 32),
                                child: CheckboxListTile(
                                  title: Text(
                                    subItem,
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  value: tempSelectedParts.contains(subItem),
                                  onChanged: (value) {
                                    setDialogState(() {
                                      if (value == true) {
                                        tempSelectedParts.add(subItem);
                                      } else {
                                        tempSelectedParts.remove(subItem);
                                      }
                                    });
                                  },
                                ),
                              )),
                          if (subItems.isNotEmpty) Divider(),
                        ],
                      );
                    }).toList(),
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedParts = tempSelectedParts;
                });
                Navigator.pop(context);
              },
              child: Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  // Select next service date
  Future<void> _selectNextServiceDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _nextServiceDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null && picked != _nextServiceDate) {
      setState(() {
        _nextServiceDate = picked;
      });
    }
  }

  // Get suggestion text
  String _getSuggestionText(String key) {
    switch (key) {
      case 'keepAirFilterClean':
        return 'Keep air filter clean';
      case 'supplyStableElectricity':
        return 'Supply stable electricity';
      case 'keepAwayFromSmells':
        return 'Keep away from smells';
      case 'protectFromSunAndRain':
        return 'Protect from sun and rain';
      default:
        return key;
    }
  }

  // Build section widget
  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black
            ),
          ),
          SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // Submit resolution
  Future<void> _submitResolution() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedIssues.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select at least one issue')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _resolutionService.completeResolution(
        srNumber: widget.srNumber,
        issueIdentification: _selectedIssues.join(', '),
        issueType: _issueTypeController.text,
        solutionProvided: _solutionController.text,
        partsReplaced: _selectedParts.join(', '),
        resolutionImages: _resolutionImages,
        resolutionVideo: _resolutionVideo,
        nextServiceDate: _nextServiceDate,
        suggestions: _suggestions,
        customSuggestions: _customSuggestionsController.text,
        status: _selectedStatus,
        issueOthers: _issueOthersController.text,
        partsOthers: _partsOthersController.text,
        serialNumber: '',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Resolution submitted successfully!')),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceAcknowledgmentScreen(
              srNumber: widget.srNumber,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting resolution: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Normalappbar(
        title:'Resolution'
        
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Service Request Information
                      _buildSection(
                        title: 'Service Request Information',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('SR Number: ${widget.srNumber}', style: TextStyle(fontWeight: FontWeight.w500)),
                            SizedBox(height: 16),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 20),
                      
                      // Issue Identification
                      _buildSection(
                        title: 'Issue Identification',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Select Identified Issues (Multiple Selection)'),
                            SizedBox(height: 8),
                            InkWell(
                              onTap: _showIssueSelectionDialog,
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedIssues.isEmpty 
                                          ? 'Tap to select issues'
                                          : 'Selected Issues (${_selectedIssues.length}):',
                                      style: TextStyle(
                                        color: _selectedIssues.isEmpty ? Colors.grey : Colors.blue[800],
                                        fontWeight: _selectedIssues.isEmpty ? FontWeight.normal : FontWeight.bold,
                                      ),
                                    ),
                                    if (_selectedIssues.isNotEmpty) ...[
                                      SizedBox(height: 8),
                                      Text(
                                        _selectedIssues.join(', '),
                                        style: TextStyle(color: Colors.black87),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            if (_selectedIssues.contains('Others')) ...[
                              SizedBox(height: 16),
                              Text('Specify Others'),
                              SizedBox(height: 8),
                              TextFormField(
                                controller: _issueOthersController,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'Enter other issues',
                                ),
                                validator: (value) {
                                  if (_selectedIssues.contains('Others') && (value == null || value.isEmpty)) {
                                    return 'Please specify other issues';
                                  }
                                  return null;
                                },
                              ),
                            ],
                            SizedBox(height: 16),
                            Text('Type of identified issue'),
                            SizedBox(height: 8),
                            TextFormField(
                              controller: _issueTypeController,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'Mention if others.',
                              ),
                            ),
                            SizedBox(height: 16),
                            Text('Solution Provided'),
                            SizedBox(height: 8),
                            TextFormField(
                              controller: _solutionController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'Describe the solution provided',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please describe the solution';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 20),
                      
                      // Parts Replacement
                      _buildSection(
                        title: 'Parts Replacement',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Select Parts Replaced (Multiple Selection)'),
                            SizedBox(height: 8),
                            InkWell(
                              onTap: _showPartsSelectionDialog,
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedParts.isEmpty 
                                          ? 'Tap to select parts'
                                          : 'Selected Parts (${_selectedParts.length}):',
                                      style: TextStyle(
                                        color: _selectedParts.isEmpty ? Colors.grey : Colors.blue[800],
                                        fontWeight: _selectedParts.isEmpty ? FontWeight.normal : FontWeight.bold,
                                      ),
                                    ),
                                    if (_selectedParts.isNotEmpty) ...[
                                      SizedBox(height: 8),
                                      Text(
                                        _selectedParts.join(', '),
                                        style: TextStyle(color: Colors.black87),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            if (_selectedParts.contains('Others')) ...[
                              SizedBox(height: 16),
                              Text('Specify Others'),
                              SizedBox(height: 8),
                              TextFormField(
                                controller: _partsOthersController,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'Enter other parts',
                                ),
                                validator: (value) {
                                  if (_selectedParts.contains('Others') && (value == null || value.isEmpty)) {
                                    return 'Please specify other parts';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 20),
                      
                      // Upload Resolution Photos and Video
                      _buildSection(
                        title: 'Upload Post Resolution Photos & Video',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Photos (up to 5)'),
                            SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              height: 120,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: _resolutionImages.isNotEmpty
                                  ? ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _resolutionImages.length,
                                      itemBuilder: (context, index) {
                                        return Container(
                                          width: 100,
                                          margin: EdgeInsets.all(8),
                                          child: Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.file(
                                                  _resolutionImages[index],
                                                  fit: BoxFit.cover,
                                                  width: 100,
                                                  height: 100,
                                                ),
                                              ),
                                              Positioned(
                                                right: 0,
                                                top: 0,
                                                child: GestureDetector(
                                                  onTap: () => _removeImage(index),
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.red,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(
                                                      Icons.close,
                                                      color: Colors.white,
                                                      size: 20,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                                        SizedBox(height: 8),
                                        Text('No Photos uploaded', style: TextStyle(color: Colors.grey)),
                                      ],
                                    ),
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _resolutionImages.length < 5 ? _showImagePickerDialog : null,
                                    child: Text('Upload Photos (${_resolutionImages.length}/5)'),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _resolutionImages.length < 5 ? () => _pickImages(ImageSource.camera) : null,
                                    child: Text('Take Photos'),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            Text('Video (10 seconds max)'),
                            SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              height: 200,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.black.withOpacity(0.1),
                              ),
                              child: _resolutionVideo != null
                                  ? Stack(
                                      children: [
                                        Center(
                                          child: AspectRatio(
                                            aspectRatio: _videoPlayerController?.value.aspectRatio ?? 16/9,
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: _videoPlayerController != null && 
                                                     _videoPlayerController!.value.isInitialized
                                                  ? VideoPlayer(_videoPlayerController!)
                                                  : Container(
                                                      color: Colors.black,
                                                      child: Center(
                                                        child: CircularProgressIndicator(
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        ),
                                        Center(
                                          child: IconButton(
                                            icon: Icon(
                                              _isVideoPlaying ? Icons.pause : Icons.play_arrow,
                                              size: 50,
                                              color: Colors.white.withOpacity(0.8),
                                            ),
                                            onPressed: () {
                                              if (_videoPlayerController != null) {
                                                setState(() {
                                                  if (_isVideoPlaying) {
                                                    _videoPlayerController!.pause();
                                                  } else {
                                                    _videoPlayerController!.play();
                                                  }
                                                  _isVideoPlaying = !_isVideoPlaying;
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                        if (_videoPlayerController != null &&
                                            _videoPlayerController!.value.isInitialized)
                                          Positioned(
                                            left: 8,
                                            right: 8,
                                            bottom: 8,
                                            child: VideoProgressIndicator(
                                              _videoPlayerController!,
                                              allowScrubbing: true,
                                              colors: VideoProgressColors(
                                                playedColor: Colors.red,
                                                bufferedColor: Colors.grey.shade600,
                                                backgroundColor: Colors.grey.shade800,
                                              ),
                                            ),
                                          ),
                                        Positioned(
                                          right: 8,
                                          top: 8,
                                          child: GestureDetector(
                                            onTap: _removeVideo,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.close,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.videocam, size: 40, color: Colors.grey),
                                        SizedBox(height: 8),
                                        Text('No Video uploaded', style: TextStyle(color: Colors.grey)),
                                      ],
                                    ),
                            ),
                            SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: _resolutionVideo == null ? _showVideoPickerDialog : null,
                                child: Text('Upload Video (10 sec max)'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 20),
                      
                      // Next Service Date
                      _buildSection(
                        title: 'Next Service Date',
                        child: InkWell(
                          onTap: _selectNextServiceDate,
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(DateFormat('dd-MM-yyyy').format(_nextServiceDate)),
                                Icon(Icons.calendar_today, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 20),
                      
                      // Suggestions
                      _buildSection(
                        title: 'Suggestions',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Provide customer suggestions'),
                            SizedBox(height: 16),
                            ..._suggestions.entries.map((entry) => CheckboxListTile(
                              title: Text(_getSuggestionText(entry.key)),
                              value: entry.value,
                              onChanged: (value) {
                                setState(() {
                                  _suggestions[entry.key] = value ?? false;
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                            )),
                            SizedBox(height: 16),
                            Text('Custom Suggestions'),
                            SizedBox(height: 8),
                            TextFormField(
                              controller: _customSuggestionsController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'Enter any additional suggestions',
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 20),
                      
                      // Status - FIXED: Removed Expanded widgets
                      _buildSection(
                        title: 'Status',
                        child: Column(
                          children: [
                            CheckboxListTile(
                              title: Text('Completed'),
                              value: _selectedStatus == 'completed',
                              onChanged: (value) {
                                setState(() {
                                  _selectedStatus = value! ? 'completed' : 'pending';
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                            CheckboxListTile(
                              title: Text('Pending'),
                              value: _selectedStatus == 'pending',
                              onChanged: (value) {
                                setState(() {
                                  _selectedStatus = value! ? 'pending' : 'completed';
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                            CheckboxListTile(
                              title: Text('In Progress'),
                              value: _selectedStatus == 'in_progress',
                              onChanged: (value) {
                                setState(() {
                                  _selectedStatus = value! ? 'in_progress' : 'completed';
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 30),
                      
                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitResolution,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.black
                          ),
                          child: Text(
                            'SUBMIT RESOLUTION',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
