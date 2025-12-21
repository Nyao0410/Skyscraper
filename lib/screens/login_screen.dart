import 'package:flutter/material.dart';

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
              'B',
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
        const Text(
          'Bluesky LINE Client',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'トーク形式で楽しむBluesky',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
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
              'ログイン方法: Blueskyでアプリパスワードを作成し、'
              'ハンドル名（example.bsky.social）と入力してください。',
              style: const TextStyle(fontSize: 12, color: Colors.blueAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandleField() {
    return TextField(
      decoration: const InputDecoration(
        labelText: 'HANDLE',
        hintText: 'example.bsky.social',
      ),
      onChanged: (v) => setState(() => _handle = v),
      onSubmitted: (_) => _handleLogin(),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      obscureText: true,
      decoration: const InputDecoration(
        labelText: 'APP PASSWORD',
        hintText: 'abcd-1234-efgh-5678',
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
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(width: 8),
                  Text('ログイン中...'),
                ],
              )
            : const Text('ログイン', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildStatusText() {
    return Text(
      widget.isLoading ? 'SDK動作確認中...' : 'Bluesky SDK準備完了',
      style: const TextStyle(fontSize: 12, color: Colors.grey),
    );
  }
}
