import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gram_rakkha/core/api_client.dart';
import 'package:gram_rakkha/core/entities.dart';

class PriorityContactsScreen extends ConsumerStatefulWidget {
  const PriorityContactsScreen({super.key});

  @override
  ConsumerState<PriorityContactsScreen> createState() => _PriorityContactsScreenState();
}

class _PriorityContactsScreenState extends ConsumerState<PriorityContactsScreen> {
  final _searchController = TextEditingController();
  List<dynamic> _contacts = [];
  bool _isLoading = false;
  List<dynamic> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    setState(() => _isLoading = true);
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.get('/priority-contacts/');
      setState(() => _contacts = response.data);
    } catch (e) {
      debugPrint("Fetch contacts error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchUser() async {
    if (_searchController.text.isEmpty) return;
    setState(() {
      _isLoading = true;
      _searchResults = [];
    });
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.get('/priority-contacts/search', queryParameters: {'q': _searchController.text});
      setState(() => _searchResults = response.data);
      if (_searchResults.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No users found')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Search failed')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addContact(String contactUserId) async {
    try {
      final client = ref.read(apiClientProvider);
      await client.post('/priority-contacts/', data: {'contact_user_id': contactUserId});
      _searchController.clear();
      setState(() => _searchResults = []);
      _fetchContacts();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact added successfully')),
      );
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add contact')),
      );
    }
  }

  Future<void> _removeContact(String contactUserId) async {
    try {
      final client = ref.read(apiClientProvider);
      await client.dio.delete('${ApiClient.baseUrl}/priority-contacts/$contactUserId');
      _fetchContacts();
    } catch (e) {
      debugPrint("Remove contact error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text('PRIORITY LIST', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF16213E),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Search Header
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF16213E),
            child: Column(
              children: [
                const Text(
                  'Add trusted people who will be notified first in case of emergency.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search by name or phone...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    suffixIcon: IconButton(
                        icon: const Icon(Icons.search, color: Colors.blue),
                        onPressed: _searchUser,
                      ),
                  ),
                  onSubmitted: (_) => _searchUser(),
                ),
              ],
            ),
          ),

          if (_searchResults.isNotEmpty)
            Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.3),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.all(16),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final result = _searchResults[index];
                  return Card(
                    color: Colors.blue.withOpacity(0.1),
                    child: ListTile(
                      title: Text(result['full_name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text(result['phone_number'], style: const TextStyle(color: Colors.white70)),
                      trailing: ElevatedButton(
                        onPressed: () => _addContact(result['id']),
                        child: const Text('ADD'),
                      ),
                    ),
                  );
                },
              ),
            ),

          Expanded(
            child: _isLoading && _contacts.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _contacts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_add_disabled_outlined, size: 64, color: Colors.white.withOpacity(0.1)),
                            const SizedBox(height: 16),
                            const Text('No priority contacts yet', style: TextStyle(color: Colors.white38)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _contacts.length,
                        itemBuilder: (context, index) {
                          final contact = _contacts[index];
                          final user = contact['contact_user'];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF16213E),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.05)),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.withOpacity(0.2),
                                  child: Text(user['full_name'][0].toUpperCase(), style: const TextStyle(color: Colors.blue)),
                                ),
                                title: Text(user['full_name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                subtitle: Text(user['phone_number'], style: const TextStyle(color: Colors.white54)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                                  onPressed: () => _removeContact(user['id']),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
