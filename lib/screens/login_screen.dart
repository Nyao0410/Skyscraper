import 'package:flutter/material.dart';
import '../flutter_gen/gen_l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  final Function(String handle, String password) onLogin;
  final bool isLoading;
  final String? error;

  const LoginScreen({
    super.key,
    required this.onLogin,
    this.isLoading = false,
    this.error,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _handle = '';
  String _password = '';

  void _handleLogin() {
    if (_handle.isEmpty || _password.isEmpty) return;
    widget.onLogin(_handle.trim(), _password);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Navigator.canPop(context) ? AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ) : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildInfoCard(),
              const SizedBox(height: 16),
              _buildHandleField(),
              const SizedBox(height: 8),
              _buildPasswordField(),
              const SizedBox(height: 12),
              if (widget.error != null) _buildErrorCard(),
              const SizedBox(height: 12),
              _buildLoginButton(),
              const SizedBox(height: 8),
              _buildStatusText(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Container(
          height: 72,
          width: 72,
          decoration: BoxDecoration(
            color: const Color(0xFF00C300),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'S',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Skyscraper',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.login_subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blue, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.login_info,
              style: const TextStyle(fontSize: 12, color: Colors.blueAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandleField() {
    final l10n = AppLocalizations.of(context);
    return TextField(
      decoration: InputDecoration(
        labelText: l10n.login_handle_label,
        hintText: l10n.login_handle_hint,
      ),
      onChanged: (v) => setState(() => _handle = v),
      onSubmitted: (_) => _handleLogin(),
    );
  }

  Widget _buildPasswordField() {
    final l10n = AppLocalizations.of(context);
    return TextField(
      obscureText: true,
      decoration: InputDecoration(
        labelText: l10n.login_password_label,
        hintText: l10n.login_password_hint,
      ),
      onChanged: (v) => setState(() => _password = v),
      onSubmitted: (_) => _handleLogin(),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(child: Text(widget.error!)),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: widget.isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00C300),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: widget.isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(width: 8),
                  Text(l10n.login_loading),
                ],
              )
            : Text(l10n.login_button, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildStatusText() {
    final l10n = AppLocalizations.of(context);
    return Text(
      widget.isLoading ? l10n.login_status_checking : l10n.login_status_ready,
      style: const TextStyle(fontSize: 12, color: Colors.grey),
    );
  }
}
