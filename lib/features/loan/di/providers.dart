import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/loan_service_interface.dart';
import '../data/services/loan_rollover_service.dart';
import '../presentation/state/loan_state.dart';

class LoanProviders extends StatefulWidget {
  final Widget child;

  const LoanProviders({super.key, required this.child});

  @override
  State<LoanProviders> createState() => _LoanProvidersState();
}

class _LoanProvidersState extends State<LoanProviders> {
  late Future<SharedPreferences> _prefsFuture;

  @override
  void initState() {
    super.initState();
    _prefsFuture = SharedPreferences.getInstance();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: _prefsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return MultiProvider(
          providers: [
            Provider<LoanServiceInterface>(
              create: (_) => LoanRolloverService(),
            ),
            Provider<SharedPreferences>.value(
              value: snapshot.data!,
            ),
            ChangeNotifierProxyProvider2<LoanServiceInterface, SharedPreferences, LoanState>(
              create: (context) => LoanState(
                loanService: context.read<LoanServiceInterface>(),
                prefs: context.read<SharedPreferences>(),
              ),
              update: (context, service, prefs, previous) => previous ?? LoanState(
                loanService: service,
                prefs: prefs,
              ),
            ),
          ],
          child: widget.child,
        );
      },
    );
  }
}
