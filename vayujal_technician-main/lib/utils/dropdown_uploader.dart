import 'package:cloud_firestore/cloud_firestore.dart';

class DropdownUploader {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// One-time function to upload initial dropdown data to Firestore
  /// Call this only once during setup
  static Future<bool> uploadInitialDropdowns() async {
    try {
      print('> Initializing dropdown upload...');
      
      final Map<String, List<String>> initialDropdowns = {
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
        'issueTypes': [
          'Mechanical',
          'Electrical',
          'Software',
          'Hardware',
          'Network',
          'Performance',
          'Safety',
          'Compliance',
        ],
        'locations': [
          'Factory Floor',
          'Office Building',
          'Warehouse',
          'Outdoor Site',
          'Remote Location',
          'Customer Site',
          'Data Center',
          'Laboratory',
        ],
        'departments': [
          'Operations',
          'Maintenance',
          'Engineering',
          'Quality Control',
          'Safety',
          'IT Support',
          'Facilities',
          'Production',
        ],
      };

      print('> Uploading ${initialDropdowns.length} dropdowns to Firestore...');
      
      await _firestore
          .collection('dropdowns')
          .doc('fields')
          .set(initialDropdowns);

      print('> Upload complete. All dropdowns uploaded successfully!');
      print('> You can now manage these dropdowns directly in Firestore Console.');
      print('> Collection: dropdowns');
      print('> Document: fields');
      
      return true;
      
    } catch (e) {
      print('> Error uploading dropdowns: $e');
      return false;
    }
  }

  /// Function to add a new dropdown (for future use)
  static Future<bool> addNewDropdown(String dropdownKey, List<String> options) async {
    try {
      print('> Adding new dropdown: $dropdownKey');
      
      await _firestore
          .collection('dropdowns')
          .doc('fields')
          .update({dropdownKey: options});

      print('> New dropdown added successfully!');
      return true;
      
    } catch (e) {
      print('> Error adding new dropdown: $e');
      return false;
    }
  }

  /// Function to update existing dropdown options
  static Future<bool> updateDropdownOptions(String dropdownKey, List<String> newOptions) async {
    try {
      print('> Updating dropdown: $dropdownKey');
      
      await _firestore
          .collection('dropdowns')
          .doc('fields')
          .update({dropdownKey: newOptions});

      print('> Dropdown updated successfully!');
      return true;
      
    } catch (e) {
      print('> Error updating dropdown: $e');
      return false;
    }
  }

  /// Function to delete a dropdown
  static Future<bool> deleteDropdown(String dropdownKey) async {
    try {
      print('> Deleting dropdown: $dropdownKey');
      
      await _firestore
          .collection('dropdowns')
          .doc('fields')
          .update({dropdownKey: FieldValue.delete()});

      print('> Dropdown deleted successfully!');
      return true;
      
    } catch (e) {
      print('> Error deleting dropdown: $e');
      return false;
    }
  }
} 