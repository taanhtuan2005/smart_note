import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';
import '../models/note.dart';
import '../services/local_storage.dart';
import 'note_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Note> _allNotes = [];
  List<Note> _displayedNotes = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final notes = await LocalStorageService.instance.loadNotes();
    setState(() {
      _allNotes = notes;
      _searchNotes(_searchController.text);
    });
  }

  void _searchNotes(String query) {
    setState(() {
      if (query.isEmpty) {
        _displayedNotes = List.from(_allNotes);
      } else {
        _displayedNotes = _allNotes
            .where(
              (note) => note.title.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  Future<void> _deleteNoteConfirmed(Note note, int index) async {
    // Optimistically remove from UI
    final deletedNote = note;
    setState(() {
      _allNotes.removeWhere((n) => n.id == note.id);
      _searchNotes(_searchController.text);
    });

    // Save to storage
    await LocalStorageService.instance.saveNotes(_allNotes);
  }

  Future<void> _navigateAndSave(Note? note) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NoteDetailScreen(note: note)),
    );

    // If result is returned (auto-save on back), update list
    if (result != null && result is Note) {
      setState(() {
        // Check if updating existing note or adding new
        final index = _allNotes.indexWhere((n) => n.id == result.id);
        if (index != -1) {
          _allNotes[index] = result;
        } else {
          _allNotes.add(result);
        }
        // Re-sort by date? Requirement doesn't explicitly say, but usually newest first is good.
        // Let's keep it simple or append as per standard list.
        // If we want newest first:
        // _allNotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        _searchNotes(_searchController.text);
      });
      await LocalStorageService.instance.saveNotes(_allNotes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // TODO: Sinh viên thay thế thông tin của mình vào đây
        title: const Text('Smart Note - Tạ Anh Tuấn - 2351060494'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              onChanged: _searchNotes,
            ),
          ),
          Expanded(
            child: _displayedNotes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.note_add,
                          size: 100,
                          color: Colors.grey.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Bạn chưa có ghi chú nào, hãy tạo mới nhé!',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : MasonryGridView.count(
                    padding: const EdgeInsets.all(8),
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    itemCount: _displayedNotes.length,
                    itemBuilder: (context, index) {
                      final note = _displayedNotes[index];
                      return Dismissible(
                        key: Key(note.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Xác nhận xóa'),
                              content: const Text(
                                'Bạn có chắc chắn muốn xóa ghi chú này không?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Hủy'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (direction) {
                          _deleteNoteConfirmed(note, index);
                        },
                        child: GestureDetector(
                          onTap: () => _navigateAndSave(note),
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    note.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    note.content,
                                    style: TextStyle(color: Colors.grey[700]),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        DateFormat(
                                          'dd/MM/yyyy HH:mm',
                                        ).format(note.createdAt),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateAndSave(null),
        child: const Icon(Icons.add),
      ),
    );
  }
}
