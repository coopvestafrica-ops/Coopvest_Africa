import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'widgets/profile_photo_upload.dart';
import 'screens/salary_deduction_consent_screen.dart';
import 'core/widgets/password_field.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // Basic Info Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Personal Info Controllers
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();
  final _bvnController = TextEditingController();
  String _selectedGender = 'Male';

  // Employment Info Controllers
  final _employerNameController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _workAddressController = TextEditingController();
  final _monthlyIncomeController = TextEditingController();
  final _employmentStartDateController = TextEditingController();
  String _employmentStatus = 'Permanent';
  String _selectedEmployer = 'Other';
  bool _showCustomEmployer = true;

  bool _isLoading = false;
  String? _errorMessage;
  String? _profilePhotoUrl;
  int _currentStep = 0;

  @override
  void dispose() {
    // Basic Info
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    // Personal Info
    _dobController.dispose();
    _addressController.dispose();
    _bvnController.dispose();

    // Employment Info
    _employerNameController.dispose();
    _jobTitleController.dispose();
    _workAddressController.dispose();
    _monthlyIncomeController.dispose();
    _employmentStartDateController.dispose();

    super.dispose();
  }

  void _handlePhotoUploaded(String photoUrl) {
    setState(() {
      _profilePhotoUrl = photoUrl;
    });
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    if (_profilePhotoUrl == null) {
      setState(() {
        _errorMessage = 'Please upload your profile photo';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Create user account
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Save user profile data
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        // Basic Information
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'photoUrl': _profilePhotoUrl,
        'createdAt': FieldValue.serverTimestamp(),

        // Personal Information
        'dateOfBirth': _dobController.text,
        'gender': _selectedGender,
        'address': _addressController.text.trim(),
        'bvn': _bvnController.text.trim(),

        // Employment Information
        'employerName': _employerNameController.text.trim(),
        'employmentStatus': _employmentStatus,
        'jobTitle': _jobTitleController.text.trim(),
        'workAddress': _workAddressController.text.trim(),
        'monthlyIncome': double.tryParse(
                _monthlyIncomeController.text.replaceAll('₦', '').trim()) ??
            0.0,
        'employmentStartDate': _employmentStartDateController.text,
      });

      if (!mounted) return;

      // Navigate to salary deduction consent screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SalaryDeductionConsentScreen(
            registrationData: {
              'email': _emailController.text.trim(),
              'username': _emailController.text.split('@')[0],
              'password': _passwordController.text,
              'first_name': _firstNameController.text.trim(),
              'last_name': _lastNameController.text.trim(),
              'uid': userCredential.user!.uid,
              'photo_url': _profilePhotoUrl,
              'phone': _phoneController.text.trim(),
            },
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentStep > 0) {
          setState(() {
            _currentStep -= 1;
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create Account'),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Stepper(
                  type: StepperType.horizontal,
                  currentStep: _currentStep,
                  onStepTapped: (step) => setState(() => _currentStep = step),
                  onStepContinue: () {
                    final isLastStep = _currentStep == 2;
                    if (isLastStep) {
                      _signup();
                    } else {
                      setState(() => _currentStep += 1);
                    }
                  },
                  controlsBuilder: (context, details) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: details.onStepContinue,
                              child: Text(
                                _currentStep == 2 ? 'Submit' : 'Next',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          if (_currentStep > 0) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: details.onStepCancel,
                                child: const Text(
                                  'Back',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                  steps: [
                    Step(
                      title: const Text('Basic'),
                      content: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 24),
                            Center(
                              child: ProfilePhotoUpload(
                                onPhotoUploaded: _handlePhotoUploaded,
                                currentPhotoUrl: _profilePhotoUrl,
                              ),
                            ),
                            const SizedBox(height: 32),
                            TextFormField(
                              controller: _firstNameController,
                              decoration: const InputDecoration(
                                labelText: 'First Name',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your first name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _lastNameController,
                              decoration: const InputDecoration(
                                labelText: 'Last Name',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your last name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!value.contains('@') ||
                                    !value.contains('.')) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: 'Phone Number',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your phone number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            PasswordField(
                              controller: _passwordController,
                              labelText: 'Password',
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 16),
                            ConfirmPasswordField(
                              controller: _confirmPasswordController,
                              originalPassword: _passwordController.text,
                              labelText: 'Confirm Password',
                              textInputAction: TextInputAction.done,
                            ),
                            if (_currentStep == 0) ...[
                              const SizedBox(height: 24),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pushNamed('/login'),
                                child: const Text(
                                    'Already have an account? Sign in'),
                              ),
                            ],
                          ],
                        ),
                      ),
                      isActive: _currentStep >= 0,
                      state: _currentStep > 0
                          ? StepState.complete
                          : StepState.indexed,
                    ),
                    Step(
                      title: const Text('Personal'),
                      content: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _dobController,
                              decoration: const InputDecoration(
                                labelText: 'Date of Birth',
                                border: OutlineInputBorder(),
                              ),
                              readOnly: true,
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now()
                                      .subtract(const Duration(days: 6570)),
                                  firstDate: DateTime.now()
                                      .subtract(const Duration(days: 36500)),
                                  lastDate: DateTime.now()
                                      .subtract(const Duration(days: 6570)),
                                );
                                if (date != null) {
                                  _dobController.text =
                                      DateFormat('yyyy-MM-dd').format(date);
                                }
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select your date of birth';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedGender,
                              decoration: const InputDecoration(
                                labelText: 'Gender',
                                border: OutlineInputBorder(),
                              ),
                              items: ['Male', 'Female']
                                  .map((gender) => DropdownMenuItem(
                                        value: gender,
                                        child: Text(gender),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() => _selectedGender = value!);
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _addressController,
                              decoration: const InputDecoration(
                                labelText: 'Address',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 2,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your address';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _bvnController,
                              decoration: const InputDecoration(
                                labelText: 'BVN',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              maxLength: 11,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your BVN';
                                }
                                if (value.length != 11) {
                                  return 'BVN must be 11 digits';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      isActive: _currentStep >= 1,
                      state: _currentStep > 1
                          ? StepState.complete
                          : StepState.indexed,
                    ),
                    Step(
                      title: const Text('Employment'),
                      content: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DropdownButtonFormField<String>(
                              initialValue: _selectedEmployer,
                              decoration: const InputDecoration(
                                labelText: 'Select Employer',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                // Polytechnics
                                'Federal Polytechnic Ayede',
                                'Federal Polytechnic Ede',
                                'Federal Polytechnic Offa',
                                'Federal Polytechnic Ilaro',
                                'Federal Polytechnic Ado-Ekiti',
                                'Federal Polytechnic Bauchi',
                                'Federal Polytechnic Bida',
                                'Federal Polytechnic Idah',
                                'Federal Polytechnic Oko',
                                'Federal Polytechnic Nekede',
                                'Federal Polytechnic Auchi',
                                'Federal Polytechnic Kaduna',
                                'Federal Polytechnic Kaura Namoda',
                                'Federal Polytechnic Mubi',
                                'Yaba College of Technology',
                                'Lagos State Polytechnic',
                                'Kwara State Polytechnic',
                                'The Polytechnic Ibadan',
                                'Moshood Abiola Polytechnic',
                                'Osun State Polytechnic Iree',

                                // Universities
                                'Bowen University Iwo',
                                'Ladoke Akintola University of Technology',
                                'Redeemers University Ede',
                                'University of Ibadan',
                                'University of Lagos',
                                'Lagos State University',
                                'Obafemi Awolowo University Ile-Ife',
                                'University of Nigeria Nsukka',
                                'Ahmadu Bello University Zaria',
                                'Covenant University Ota',
                                'Federal University of Technology Akure',
                                'University of Benin',
                                'University of Port Harcourt',
                                'Bayero University Kano',

                                // Medical Institutions
                                'Bowen University Teaching Hospital Ogbomoso',
                                'Federal Medical Centre Abeokuta',
                                'University College Hospital Ibadan',
                                'Lagos University Teaching Hospital',
                                'National Hospital Abuja',
                                'Aminu Kano Teaching Hospital',
                                'University of Nigeria Teaching Hospital',
                                'Lagos State University Teaching Hospital',

                                // Religious Institutions
                                'Nigerian Baptist Theological Seminary Ogbomoso',
                                'RCCG Redemption Camp',
                                'Living Faith Church Worldwide',

                                // Government Organizations
                                'Federal Ministry of Education',
                                'Federal Ministry of Health',
                                'Federal Ministry of Finance',
                                'Central Bank of Nigeria',
                                'Nigerian National Petroleum Corporation',
                                'Federal Inland Revenue Service',
                                'Nigerian Immigration Service',
                                'Nigerian Customs Service',

                                // Banks
                                'First Bank of Nigeria',
                                'United Bank for Africa',
                                'Zenith Bank',
                                'Guaranty Trust Bank',
                                'Access Bank',
                                'Stanbic IBTC Bank',
                                'Fidelity Bank',

                                // Telecommunications
                                'MTN Nigeria',
                                'Airtel Nigeria',
                                'Globacom Limited',
                                '9mobile',

                                // Oil & Gas Companies
                                'Shell Nigeria',
                                'ExxonMobil Nigeria',
                                'Chevron Nigeria',
                                'Total Nigeria',
                                'Oando PLC',

                                // Other Major Corporations
                                'Dangote Group',
                                'Nigerian Breweries',
                                'Nestle Nigeria',
                                'PZ Cussons Nigeria',
                                'Unilever Nigeria',
                                'Cadbury Nigeria',
                                'Nigerian Ports Authority',
                                'Federal Airports Authority of Nigeria',

                                // Option for Other Companies
                                'Other'
                              ]
                                  .map((employer) => DropdownMenuItem(
                                        value: employer,
                                        child: Text(employer),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedEmployer = value!;
                                  _showCustomEmployer = value == 'Other';
                                  if (value != 'Other') {
                                    _employerNameController.text = value;
                                  }
                                });
                              },
                            ),
                            if (_showCustomEmployer) ...[
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _employerNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Enter Employer Name',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your employer name';
                                  }
                                  return null;
                                },
                              ),
                            ],
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              initialValue: _employmentStatus,
                              decoration: const InputDecoration(
                                labelText: 'Employment Status',
                                border: OutlineInputBorder(),
                              ),
                              items: ['Permanent', 'Contract', 'Temporary']
                                  .map((status) => DropdownMenuItem(
                                        value: status,
                                        child: Text(status),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() => _employmentStatus = value!);
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _jobTitleController,
                              decoration: const InputDecoration(
                                labelText: 'Job Title',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your job title';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _workAddressController,
                              decoration: const InputDecoration(
                                labelText: 'Work Address',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 2,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your work address';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _monthlyIncomeController,
                              decoration: const InputDecoration(
                                labelText: 'Monthly Income',
                                border: OutlineInputBorder(),
                                prefixText: '₦ ',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your monthly income';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _employmentStartDateController,
                              decoration: const InputDecoration(
                                labelText: 'Employment Start Date',
                                border: OutlineInputBorder(),
                              ),
                              readOnly: true,
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(1970),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) {
                                  _employmentStartDateController.text =
                                      DateFormat('yyyy-MM-dd').format(date);
                                }
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select your employment start date';
                                }
                                return null;
                              },
                            ),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      isActive: _currentStep >= 2,
                      state: _currentStep > 2
                          ? StepState.complete
                          : StepState.indexed,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
