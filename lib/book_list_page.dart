import 'package:flutter/material.dart';
import 'package:login_signup/loginpage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Booklistpage extends StatefulWidget {
  const Booklistpage({super.key});

  @override
  State<Booklistpage> createState() => _BooklistpageState();
}

class _BooklistpageState extends State<Booklistpage> {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late Stream<List<Map<String, dynamic>>> _booksStream;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _booksStream = supabase
        .from('books')
        .stream(primaryKey: ['id'])
        .map((maps) => List<Map<String, dynamic>>.from(maps));

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  Future<void> _addBook() async {
    final title = _titleController.text;
    final author = _authorController.text;
    final userId = supabase.auth.currentUser!.id;

    if (title.isEmpty || author.isEmpty) return;

    try {
      await supabase.from('books').insert({
        'title': title,
        'author': author,
        'user_id': userId,
      });
      _titleController.clear();
      _authorController.clear();
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
    } catch (e) {
      _showSnackBar(e.toString());
    }
  }

  Future<void> _updateBook(int id) async {
    final title = _titleController.text;
    final author = _authorController.text;

    if (title.isEmpty || author.isEmpty) return;

    try {
      await supabase
          .from('books')
          .update({'title': title, 'author': author})
          .eq('id', id);
      _titleController.clear();
      _authorController.clear();
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
    } catch (e) {
      _showSnackBar(e.toString());
    }
  }

  Future<void> _deleteBook(int id) async {
    try {
      await supabase.from('books').delete().eq('id', id);
    } catch (e) {
      _showSnackBar(e.toString());
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blueGrey,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Book List"),
        backgroundColor: Colors.blueGrey,
        centerTitle: true,
        leading: IconButton(onPressed: () {}, icon: Icon(Icons.menu_book)),
        actions: [
          IconButton(
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              Navigator.pushReplacement(
                // ignore: use_build_context_synchronously
                context,
                MaterialPageRoute(builder: (_) => const Loginpage()),
              );
            },
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search books...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 20,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // Book List
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _booksStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final books = snapshot.data!;
                final filteredBooks = books.where((book) {
                  final title = book['title'].toString().toLowerCase();
                  final author = book['author'].toString().toLowerCase();
                  return title.contains(_searchQuery) ||
                      author.contains(_searchQuery);
                }).toList();

                if (filteredBooks.isEmpty) {
                  return const Center(child: Text("No books found!"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  itemCount: filteredBooks.length,
                  itemBuilder: (context, index) {
                    final book = filteredBooks[index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        title: Text(
                          book['title'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Text(
                          book['author'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Edit Button
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.orange,
                              ),
                              onPressed: () {
                                _titleController.text = book['title'];
                                _authorController.text = book['author'];
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    title: const Text("Update Book"),
                                    content: Form(
                                      key: _formKey,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextFormField(
                                            controller: _titleController,
                                            decoration: const InputDecoration(
                                              labelText: "Title",
                                            ),
                                            validator: (value) =>
                                                value == null || value.isEmpty
                                                ? "Can't be empty"
                                                : null,
                                          ),
                                          TextFormField(
                                            controller: _authorController,
                                            decoration: const InputDecoration(
                                              labelText: "Author",
                                            ),
                                            validator: (value) =>
                                                value == null || value.isEmpty
                                                ? "Can't be empty"
                                                : null,
                                          ),
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text("Cancel"),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          if (_formKey.currentState!
                                              .validate()) {
                                            _updateBook(book['id']);
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blueGrey,
                                        ),
                                        child: const Text("Update"),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            // Delete Button
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    title: const Text("Delete Book?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text("Cancel"),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        onPressed: () {
                                          _deleteBook(book['id']);
                                          Navigator.pop(context);
                                        },
                                        child: const Text("Delete"),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueGrey,
        elevation: 8,
        child: const Icon(Icons.add, size: 30),
        onPressed: () {
          _titleController.clear();
          _authorController.clear();
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: const Text("Add a Book"),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: "Title"),
                      validator: (value) => value == null || value.isEmpty
                          ? "Can't be empty"
                          : null,
                    ),
                    TextFormField(
                      controller: _authorController,
                      decoration: const InputDecoration(labelText: "Author"),
                      validator: (value) => value == null || value.isEmpty
                          ? "Can't be empty"
                          : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) _addBook();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                  ),
                  child: const Text("Add"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
