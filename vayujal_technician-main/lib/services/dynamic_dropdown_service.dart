import 'package:cloud_firestore/cloud_firestore.dart';

class DynamicDropdownService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static Map<String, List<String>> _cachedDropdowns = {};
  static DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(minutes: 30);

  /// Fetch all dropdown options from Firestore
  static Future<Map<String, List<String>>> fetchDropdowns() async {
    try {
      print('> Fetching dropdown values from Firestore...');
      
      // Check if cache is still valid
      if (_lastFetchTime != null && 
          DateTime.now().difference(_lastFetchTime!) < _cacheDuration &&
          _cachedDropdowns.isNotEmpty) {
        print('> Using cached dropdown data');
        return _cachedDropdowns;
      }

      final DocumentSnapshot doc = await _firestore
          .collection('dropdown_List')
          .doc('Types_of_identified_issue')
          .get();

      if (!doc.exists) {
        print('> Warning: Dropdowns document not found, using fallback values');
        return _getFallbackDropdowns();
      }

      final data = doc.data() as Map<String, dynamic>;
      Map<String, List<String>> dropdowns = {};

      data.forEach((key, value) {
        if (value is List) {
          dropdowns[key] = value.cast<String>();
        }
      });

      _cachedDropdowns = dropdowns;
      _lastFetchTime = DateTime.now();
      
      print('> Dropdowns loaded successfully (${dropdowns.length} dropdowns)');
      return dropdowns;
      
    } catch (e) {
      print('> Error fetching dropdowns: $e');
      print('> Using fallback values');
      return _getFallbackDropdowns();
    }
  }

  /// Get specific dropdown options
  static Future<List<String>> getDropdownOptions(String dropdownKey) async {
    try {
      final dropdowns = await fetchDropdowns();
      return dropdowns[dropdownKey] ?? _getFallbackForDropdown(dropdownKey);
    } catch (e) {
      print('> Error getting dropdown options for $dropdownKey: $e');
      return _getFallbackForDropdown(dropdownKey);
    }
  }

  /// Get all available dropdown keys
  static Future<List<String>> getDropdownKeys() async {
    try {
      final dropdowns = await fetchDropdowns();
      return dropdowns.keys.toList();
    } catch (e) {
      print('> Error getting dropdown keys: $e');
      return _getFallbackDropdowns().keys.toList();
    }
  }

  /// Clear cache (useful for testing or forcing refresh)
  static void clearCache() {
    _cachedDropdowns.clear();
    _lastFetchTime = null;
    print('> Dropdown cache cleared');
  }

  /// Fetch a hierarchical dropdown (Map<String, List<String>>) from Firestore
  static Future<Map<String, List<String>>> getDropdownMap(String dropdownKey) async {
    try {
      print('> Fetching hierarchical dropdown "$dropdownKey" from Firestore...');
      final DocumentSnapshot doc = await _firestore
          .collection('dropdown_List')
          .doc('fields')
          .get();
      if (!doc.exists) {
        print('> Warning: Dropdowns document not found, using fallback values');
        return _getFallbackDropdownMap(dropdownKey);
      }
      final data = doc.data() as Map<String, dynamic>;
      if (data[dropdownKey] is Map) {
        final rawMap = data[dropdownKey] as Map<String, dynamic>;
        return rawMap.map((k, v) => MapEntry(k, (v as List).cast<String>()));
      }
      print('> Warning: "$dropdownKey" not found or not a map, using fallback');
      return _getFallbackDropdownMap(dropdownKey);
    } catch (e) {
      print('> Error fetching hierarchical dropdown: $e');
      return _getFallbackDropdownMap(dropdownKey);
    }
  }

  /// Fetch dropdown options from a document where each field is a numbered string and the value is the dropdown option.
  static Future<List<String>> fetchNumberedFieldsDropdown({
    required String collection,
    required String document,
  }) async {
    try {
      print('> Fetching numbered fields dropdown: $collection/$document');
      final doc = await FirebaseFirestore.instance.collection(collection).doc(document).get();
      if (!doc.exists) return [];
      final data = doc.data()!;
      final sortedKeys = data.keys.toList()
        ..sort((a, b) => int.tryParse(a)?.compareTo(int.tryParse(b) ?? 0) ?? a.compareTo(b));
      return sortedKeys.map((k) => data[k] as String).toList();
    } catch (e) {
      print('> Error fetching numbered fields dropdown: $e');
      return [];
    }
  }

  /// Fetch dropdown options from a document with mixed structure (numbered string fields + array fields).
  /// Returns a Map<String, List<String>> where keys are category names and values are options.
  static Future<Map<String, List<String>>> fetchMixedStructureDropdown({
    required String collection,
    required String document,
  }) async {
    try {
      print('> Fetching mixed structure dropdown: $collection/$document');
      final doc = await FirebaseFirestore.instance.collection(collection).doc(document).get();
      if (!doc.exists) return {};
      
      final data = doc.data()!;
      final Map<String, List<String>> result = {};
      
      data.forEach((key, value) {
        if (value is String) {
          // Numbered string field (like "01": "RELAY AND BASE", "02": "WATER PUMP")
          result['Direct'] = result['Direct'] ?? [];
          result['Direct']!.add(value);
        } else if (value is List) {
          // Array field (like "ADAPTER": ["1.5A ADAPTER", "2.5A ADAPTER", "UVI CHOKE 230VAC"])
          result[key] = List<String>.from(value);
        } else if (value is Map) {
          // Nested map with numbered keys (fallback for old structure)
          final sortedKeys = value.keys.toList()
            ..sort((a, b) => int.tryParse(a.toString())?.compareTo(int.tryParse(b.toString()) ?? 0) ?? a.toString().compareTo(b.toString()));
          result[key] = sortedKeys.map((k) => value[k] as String).toList();
        }
      });
      
      // Sort the direct options if they exist
      if (result['Direct'] != null) {
        result['Direct']!.sort();
      }
      
      return result;
    } catch (e) {
      print('> Error fetching mixed structure dropdown: $e');
      return {};
    }
  }

  /// Fallback dropdowns (hardcoded values for error cases)
  static Map<String, List<String>> _getFallbackDropdowns() {
    return {
      'designations': [
        'Technician',
        'Senior Technician',
        'Lead Technician',
        'Supervisor',
        'Manager',
        'Engineer',
        'Senior Engineer',
        'Field Engineer',
        'Technical Lead',
        'Team Leader',
        'Project Manager',
        'Operations Manager',
      ],
      'serviceTypes': [
        'Installation',
        'Maintenance',
        'Repair',
        'Inspection',
        'Calibration',
        'Testing',
        'Training',
        'Consultation',
      ],
      'priorityLevels': [
        'Low',
        'Medium',
        'High',
        'Critical',
        'Emergency',
      ],
      'statusOptions': [
        'Pending',
        'In Progress',
        'Completed',
        'Cancelled',
        'On Hold',
        'Rescheduled',
      ],
      'yesNoOptions': [
        'Yes',
        'No',
      ],
      'equipmentTypes': [
        'Pump',
        'Motor',
        'Valve',
        'Sensor',
        'Controller',
        'Filter',
        'Compressor',
        'Generator',
      ],
    };
  }

  /// Fallback for hierarchical dropdowns
  static Map<String, List<String>> _getFallbackDropdownMap(String dropdownKey) {
    if (dropdownKey == 'partsOptions') {
      return {
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
      };
    }
    return {};
  }

  /// Get fallback for specific dropdown
  static List<String> _getFallbackForDropdown(String dropdownKey) {
    final fallbacks = _getFallbackDropdowns();
    return fallbacks[dropdownKey] ?? ['No options available'];
  }
} 