import 'package:flutter/material.dart';
import '../services/supabase_connection_test.dart';
import '../services/schema_verifier.dart';

class SupabaseTestScreen extends StatefulWidget {
  const SupabaseTestScreen({super.key});

  @override
  State<SupabaseTestScreen> createState() => _SupabaseTestScreenState();
}

class _SupabaseTestScreenState extends State<SupabaseTestScreen> {
  Map<String, dynamic>? _connectionResults;
  Map<String, dynamic>? _schemaResults;
  Map<String, dynamic>? _seedDataResults;
  bool _isLoading = false;
  String? _error;
  String _activeTab = 'connection';

  @override
  void initState() {
    super.initState();
    _runAllTests();
  }

  Future<void> _runAllTests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Test connection
      final connectionResults = await SupabaseConnectionTest.testConnection();
      
      // Verify schema
      final schemaResults = await SchemaVerifier.verifyAllTables();
      
      // Verify seed data
      final seedDataResults = await SchemaVerifier.verifySeedData();

      setState(() {
        _connectionResults = connectionResults;
        _schemaResults = schemaResults;
        _seedDataResults = seedDataResults;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supabase Test Suite'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _runAllTests,
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab bar
          Container(
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Row(
              children: [
                _buildTab('connection', 'Connection'),
                _buildTab('schema', 'Schema'),
                _buildTab('seed', 'Seed Data'),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorCard()
                    : _buildTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String id, String label) {
    final isActive = _activeTab == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_activeTab) {
      case 'connection':
        return _buildConnectionTab();
      case 'schema':
        return _buildSchemaTab();
      case 'seed':
        return _buildSeedTab();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildConnectionTab() {
    if (_connectionResults == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatusCard(
          'Connection Status',
          _connectionResults!['overall'] == 'success',
          _connectionResults!['message'],
        ),
        const SizedBox(height: 8),
        ..._connectionResults!.entries
            .where((e) => e.key != 'overall' && e.key != 'message')
            .map((entry) => _buildResultCard(entry.key, entry.value)),
      ],
    );
  }

  Widget _buildSchemaTab() {
    if (_schemaResults == null) return const SizedBox.shrink();

    final existing = _schemaResults!['existing_tables'] as List;
    final missing = _schemaResults!['missing_tables'] as List;
    final inaccessible = _schemaResults!['inaccessible_tables'] as Map;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatusCard(
          'Schema Status',
          _schemaResults!['all_tables_exist'] == true,
          '${existing.length}/${_schemaResults!['total_tables']} tables exist',
        ),
        const SizedBox(height: 16),
        if (missing.isNotEmpty) ...[
          Text(
            'Missing Tables (${missing.length})',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.red,
                ),
          ),
          const SizedBox(height: 8),
          ...missing.map((table) => Card(
                child: ListTile(
                  leading: const Icon(Icons.error, color: Colors.red),
                  title: Text(table),
                ),
              )),
          const SizedBox(height: 16),
        ],
        if (inaccessible.isNotEmpty) ...[
          Text(
            'Inaccessible Tables (${inaccessible.length})',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.orange,
                ),
          ),
          const SizedBox(height: 8),
          ...inaccessible.entries.map((entry) => Card(
                child: ListTile(
                  leading: const Icon(Icons.warning, color: Colors.orange),
                  title: Text(entry.key),
                  subtitle: Text(entry.value.toString()),
                ),
              )),
          const SizedBox(height: 16),
        ],
        if (existing.isNotEmpty) ...[
          Text(
            'Existing Tables (${existing.length})',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.green,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: existing
                .map((table) => Chip(
                      avatar: const Icon(Icons.check_circle, size: 18),
                      label: Text(table),
                      backgroundColor: Colors.green.shade50,
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildSeedTab() {
    if (_seedDataResults == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatusCard(
          'Seed Data Status',
          _seedDataResults!['seed_data_complete'] == true,
          _seedDataResults!['seed_data_complete']
              ? 'All seed data present'
              : 'Some seed data missing',
        ),
        const SizedBox(height: 16),
        _buildSeedItem('Zones', _seedDataResults!['zones_count'] ?? 0, 7),
        _buildSeedItem(
            'Waste Categories', _seedDataResults!['categories_count'] ?? 0, 10),
        _buildSeedItem('Reward Tiers', _seedDataResults!['tiers_count'] ?? 0, 4),
        _buildSeedItem(
            'Admin Settings', _seedDataResults!['settings_count'] ?? 0, 5),
      ],
    );
  }

  Widget _buildSeedItem(String name, int current, int expected) {
    final isComplete = current >= expected;
    return Card(
      child: ListTile(
        leading: Icon(
          isComplete ? Icons.check_circle : Icons.info,
          color: isComplete ? Colors.green : Colors.orange,
        ),
        title: Text(name),
        trailing: Chip(
          label: Text('$current / $expected'),
          backgroundColor: isComplete ? Colors.green.shade50 : Colors.orange.shade50,
        ),
      ),
    );
  }

  Widget _buildStatusCard(String title, bool isSuccess, String message) {
    return Card(
      color: isSuccess ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: isSuccess ? Colors.green : Colors.red,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    message,
                    style: TextStyle(
                      color: isSuccess ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Center(
      child: Card(
        color: Colors.red.shade50,
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Test Failed',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _runAllTests,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(String title, dynamic result) {
    Color statusColor;
    IconData statusIcon;

    if (result is Map<String, dynamic>) {
      final status = result['status'] as String? ?? 'unknown';
      switch (status) {
        case 'connected':
        case 'authenticated':
        case 'accessible':
        case 'available':
        case 'success':
          statusColor = Colors.green;
          statusIcon = Icons.check_circle;
          break;
        case 'tables_not_found':
          statusColor = Colors.orange;
          statusIcon = Icons.warning;
          break;
        case 'error':
          statusColor = Colors.red;
          statusIcon = Icons.error;
          break;
        default:
          statusColor = Colors.grey;
          statusIcon = Icons.help_outline;
      }
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.help_outline;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(statusIcon, color: statusColor),
        title: Text(title.toUpperCase()),
        subtitle: result is Map<String, dynamic>
            ? Text(result['message'] ?? 'No message')
            : Text(result.toString()),
      ),
    );
  }
}
