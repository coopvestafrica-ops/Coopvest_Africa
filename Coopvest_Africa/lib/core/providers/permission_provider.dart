import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_role.dart';

class PermissionProvider extends ChangeNotifier {
  final AuthService _authService = AuthService.instance;
  SharedPreferences? _prefs;
  
  List<String> _permissions = [];
  UserRole? _currentRole;
  bool _isLoading = false;
  String? _error;

  static const String _permissionKey = 'user_permissions';
  static const String _roleKey = 'user_role';

  // Define role-based permissions mapping
  static const Map<UserRole, List<String>> _rolePermissions = {
    UserRole.admin: [
      'view_dashboard',
      'manage_users',
      'manage_loans',
      'manage_investments',
      'manage_settings',
      'approve_loans',
      'view_reports',
      'manage_staff',
      'view_audit_logs',
      'manage_configurations',
    ],
    UserRole.loanStaff: [
      'view_dashboard',
      'view_loans',
      'process_loans',
      'view_reports',
      'manage_loan_applications',
      'view_client_history',
    ],
    UserRole.financeOfficer: [
      'view_dashboard',
      'view_investments',
      'process_investments',
      'view_reports',
      'manage_investment_applications',
    ],
    UserRole.member: [
      'view_dashboard',
      'view_own_loans',
      'apply_loan',
      'view_own_investments',
      'make_investment',
      'view_own_profile',
      'make_deposits',
      'view_statements',
    ],
  };

  PermissionProvider() {
    _initializeProvider();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<String> get permissions => List.unmodifiable(_permissions);

  Future<void> _initializeProvider() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authService.getCurrentUser();
      if (user == null) {
        _permissions = [];
        _currentRole = null;
        _error = 'User not authenticated';
      } else {
        _currentRole = user.role;
        
        // Save current role
        await _prefs?.setString(_roleKey, user.role.toString());
        
        // Get base permissions from role
        _permissions = _getPermissionsForRole(_currentRole!);
        
        // Add any additional persisted permissions
        final additionalPermissions = _prefs?.getStringList(_permissionKey);
        if (additionalPermissions != null) {
          _permissions = <String>{
            ..._permissions,
            ...additionalPermissions,
          }.toList();
        }
      }
    } catch (e) {
      _error = 'Failed to load permissions: $e';
      _permissions = [];
      _currentRole = null;
      
      // Clear stored role on error
      await _prefs?.remove(_roleKey);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<String> _getPermissionsForRole(UserRole role) {
    return _rolePermissions[role] ?? [];
  }

  /// Gets the current role of the user
  UserRole? get currentRole => _currentRole;

  /// Gets all available roles
  List<UserRole> get availableRoles => _rolePermissions.keys.toList();

  /// Gets all permissions for a specific role
  List<String> getPermissionsForRole(UserRole role) {
    return _rolePermissions[role] ?? [];
  }

  /// Gets all possible permissions across all roles
  Set<String> get allPossiblePermissions {
    return _rolePermissions.values
        .expand((permissions) => permissions)
        .toSet();
  }

  /// Checks if user has a specific permission
  bool hasPermission(String permission) {
    if (_error != null) return false;
    if (!_isLoading && _currentRole != null) {
      return _permissions.contains(permission.toLowerCase());
    }
    return false;
  }

  /// Checks if user has any of the specified permissions
  bool hasAnyPermission(List<String> requiredPermissions) {
    if (_error != null) return false;
    if (!_isLoading && _currentRole != null) {
      return requiredPermissions.any(
        (permission) => _permissions.contains(permission.toLowerCase())
      );
    }
    return false;
  }

  /// Checks if user has all specified permissions
  bool hasAllPermissions(List<String> requiredPermissions) {
    if (_error != null) return false;
    if (!_isLoading && _currentRole != null) {
      return requiredPermissions.every(
        (permission) => _permissions.contains(permission.toLowerCase())
      );
    }
    return false;
  }

  /// Grants additional permissions to the current user
  Future<void> grantPermissions(List<String> newPermissions) async {
    // Normalize permissions first
    final normalizedPermissions = newPermissions.map((p) => p.toLowerCase()).toList();
    
    // Add to existing permissions
    _permissions = <String>{..._permissions, ...normalizedPermissions}.toList();
    
    // Save to persistent storage
    await _prefs?.setStringList(_permissionKey, _permissions);
    notifyListeners();
  }

  /// Revokes specific permissions from the current user
  Future<void> revokePermissions(List<String> permissionsToRevoke) async {
    final normalizedPermissions = permissionsToRevoke.map((p) => p.toLowerCase()).toSet();
    _permissions.removeWhere((p) => normalizedPermissions.contains(p.toLowerCase()));
    
    await _prefs?.setStringList(_permissionKey, _permissions);
    notifyListeners();
  }

  /// Clears all additional permissions (resets to role-based permissions only)
  Future<void> clearAdditionalPermissions() async {
    if (_currentRole != null) {
      _permissions = _getPermissionsForRole(_currentRole!);
    } else {
      _permissions = [];
    }
    
    await Future.wait([
      if (_prefs != null) _prefs!.remove(_permissionKey),
      if (_prefs != null) _prefs!.remove(_roleKey),
    ]);
    
    notifyListeners();
  }

  /// Clears all permissions and role data 
  Future<void> clear() async {
    _permissions = [];
    _currentRole = null;
    _error = null;
    
    await Future.wait([
      if (_prefs != null) _prefs!.remove(_permissionKey),
      if (_prefs != null) _prefs!.remove(_roleKey),
    ]);
    
    notifyListeners();
  }

  /// Refreshes permissions from the auth service
  Future<void> refresh() => _loadPermissions();
}
