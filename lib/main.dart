import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:notes_and_todo_app/notes_todo_provider.dart';
import 'package:notes_and_todo_app/sqlhelper.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SQLHelper().getDatabase();
  runApp(
    ChangeNotifierProvider(
      create: (_) => DatabaseProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Notes & Todo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notes & Todo"),
        actions: [
          IconButton(
            onPressed: () {
              context.read<DatabaseProvider>().deleteAllNotes();
              context.read<DatabaseProvider>().deleteAllTodos();
            },
            icon: const Icon(Icons.delete_forever),
          ),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder(
                future: context.read<DatabaseProvider>().loadNotes(),
                builder:
                    (BuildContext context, AsyncSnapshot<List<Map>> snapshot) {
                  if (snapshot.connectionState == ConnectionState.done &&
                      snapshot.hasData) {
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        return Dismissible(
                          key: UniqueKey(),
                          onDismissed: (direction) => context
                              .read<DatabaseProvider>()
                              .deleteNote(snapshot.data![index]['id']),
                          child: Card(
                            color: Colors.purpleAccent,
                            child: Column(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    showMyDialogEdit(
                                      context,
                                      snapshot.data![index]['title'],
                                      snapshot.data![index]['content'],
                                      snapshot.data![index]['id'],
                                    );
                                  },
                                  icon: const Icon(Icons.edit),
                                ),
                                Text(
                                  ('id:  ') +
                                      (snapshot.data![index]['id'].toString()),
                                ),
                                Text(
                                  ('title:  ') +
                                      (snapshot.data![index]['title']
                                          .toString()),
                                ),
                                Text(
                                  ('content:  ') +
                                      (snapshot.data![index]['content']
                                          .toString()),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                },
              ),
            ),
            Expanded(
              child: Consumer<DatabaseProvider>(
                  builder: (context, provider, child) {
                return FutureBuilder(
                  future: SQLHelper().loadTodos(),
                  builder: (BuildContext context,
                      AsyncSnapshot<List<Map>> snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (snapshot.hasData) {
                        return ListView.builder(
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            bool isDone = snapshot.data![index]['value'] == 0
                                ? false
                                : true;
                            return Card(
                              color:
                                  isDone == false ? Colors.red : Colors.green,
                              child: GestureDetector(
                                onTap: () {
                                  context
                                      .read<DatabaseProvider>()
                                      .updateTodoChecked(
                                        snapshot.data![index]['id'],
                                        snapshot.data![index]['value'],
                                      );
                                },
                                child: Row(
                                  children: [
                                    Checkbox(
                                      activeColor: Colors.red,
                                      value: isDone,
                                      onChanged: null,
                                    ),
                                    Text(
                                      snapshot.data![index]['title'],
                                      style: TextStyle(
                                        color: isDone == false
                                            ? Colors.black
                                            : Colors.white,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }
                    }
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            backgroundColor: Colors.purpleAccent,
            onPressed: () async {
              showMyDialog(context);
            },
            tooltip: 'Increment',
            child: const Icon(Icons.add),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FloatingActionButton(
              backgroundColor: Colors.green,
              onPressed: () async {
                showMyDialogTodo(context);
              },
              tooltip: 'Increment',
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }

  void showMyDialog(context) {
    TextEditingController titleController = TextEditingController();

    TextEditingController contentController = TextEditingController();
    showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext context) => Material(
        color: Colors.white.withOpacity(0.3),
        child: CupertinoAlertDialog(
          title: const Text('Add New Note'),
          content: Column(
            children: [
              TextField(
                controller: titleController,
              ),
              TextField(
                controller: contentController,
              ),
            ],
          ),
          actions: <CupertinoDialogAction>[
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('No'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                context.read<DatabaseProvider>().insertNote(
                      Note(
                        title: titleController.text,
                        content: contentController.text,
                      ),
                    );
                titleController.clear();
                contentController.clear();
                Navigator.pop(context);
              },
              child: const Text('Yes'),
            ),
          ],
        ),
      ),
    );
  }

  void showMyDialogTodo(context) {
    TextEditingController titleController = TextEditingController();

    showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext context) => Material(
        color: Colors.white.withOpacity(0.3),
        child: CupertinoAlertDialog(
          title: const Text('Add New Todo'),
          content: TextField(
            controller: titleController,
          ),
          actions: <CupertinoDialogAction>[
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('No'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                context.read<DatabaseProvider>().insertTodo(
                      Todo(
                        title: titleController.text,
                      ),
                    );
                titleController.clear();
                Navigator.pop(context);
              },
              child: const Text('Yes'),
            )
          ],
        ),
      ),
    );
  }

  void showMyDialogEdit(context, String titleInit, String contentInit, int id) {
    TextEditingController titleController = TextEditingController();

    TextEditingController contentController = TextEditingController();
    String newTitle = titleInit;
    String newContent = contentInit;
    showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext context) => Material(
        color: Colors.white.withOpacity(0.3),
        child: CupertinoAlertDialog(
          title: const Text('Edit  Note'),
          content: Column(
            children: [
              TextFormField(
                initialValue: titleInit,
                onChanged: (value) {
                  newTitle = value;
                },
              ),
              TextFormField(
                initialValue: contentInit,
                onChanged: (value) {
                  newContent = value;
                },
              ),
            ],
          ),
          actions: <CupertinoDialogAction>[
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('No'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                context.read<DatabaseProvider>().updateNote(
                      Note(
                        id: id,
                        title: newTitle,
                        content: newContent,
                      ),
                    );
                titleController.clear();
                contentController.clear();
                Navigator.pop(context);
              },
              child: const Text('Yes'),
            )
          ],
        ),
      ),
    );
  }
}
