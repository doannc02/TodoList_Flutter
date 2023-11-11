import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:ui_todolist/CommonWidget/skeleton_loading.dart';
import 'package:ui_todolist/TaskScreen.dart';
import './models/task.dart';

class DetailTaskScreen extends StatefulWidget {
  final int id;

  const DetailTaskScreen({required this.id}) : super();

  @override
  State<StatefulWidget> createState() {
    return _DetailTaskScreenState();
  }
}

class _DetailTaskScreenState extends State<DetailTaskScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Details Task"),
      ),
      body: FutureBuilder(
        future: Future.delayed(Duration(milliseconds: 500), () {return fetchTaskById(http.Client(), widget.id);}),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return  Container(
              padding: EdgeInsets.only(top:0),
              child: SkeletonLoading(
                itemCount: 3, // Số lượng skeleton loading muốn hiển thị
                itemHeight: 30, // Chiều cao của mỗi skeleton loading
                itemWidth: 200, // Chiều rộng mặc định của mỗi skeleton loading
                itemMargin: EdgeInsets.symmetric(vertical: 8, horizontal: 16), // Khoảng cách giữa các skeleton loading
              ),
            );
          } else if (snapshot.hasError) {
            print(snapshot.error);
            return Text('Error: ${snapshot.error}');
          } else if (!snapshot.hasData) {
            return Text('No data available');
          } else {
            return DetailTask(task: snapshot.data as Task);
          }
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Doanh nghiệp',
          ),
        ],
      ),
    );
  }
}

class DetailTask extends StatefulWidget {
  final Task task;
  final callback;
  DetailTask({Key? key, this.callback, required this.task}) : super(key: key);

  @override
  _DetailTaskState createState() => _DetailTaskState();
}

class _DetailTaskState extends State<DetailTask> {

  late TextEditingController _textEditingController;
  Task task = new Task(id: 1, name: 'dd', isFinished: true, todoId: 1);
  bool isLoadedTask = false;

  var dataToPassBack;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController(text: widget.task.name);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadedTask == false) {
      setState(() {
        this.task = Task.fromTask(widget.task);
        this.isLoadedTask = true;
      });
    }
    final TextField _txtTaskName = TextField(
      decoration: InputDecoration(
        hintText: "Enter task's name",
        contentPadding: EdgeInsets.all(10.0),
        border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
      ),
      controller:_textEditingController,
      onChanged: (text) {
        // Xử lý khi có sự thay đổi trong TextField
        setState(() {
          this.task.name = text;
        });
      },
    );

    final Text _txtFinished =
        Text("Finished", style: TextStyle(fontSize: 16.0));
    final Checkbox _cbFinished = Checkbox(
      value: this.task.isFinished,
      onChanged: (bool? value) {
        setState(() {
          this.task.isFinished = value!;
        });
      },
    );

    final _btnSave = Material(
      elevation: 4,
      child: Ink(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: InkWell(
          onTap: () async {
            Map<String, dynamic> params = {
              'i': this.task.id,
              'Name': this.task.name,
              'IsFinished': this.task.isFinished ? true : false,
              'TodoId': this.task.todoId,
            };
            await update(http.Client(), params);
            final newData = await fetchTasksByIdTodo(http.Client(), this.task.todoId);
            Fluttertoast.showToast(msg: "Cập nhật thành công!",
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.TOP,
                backgroundColor: Colors.red,
                textColor: Colors.white,
                timeInSecForIosWeb: 2,
                fontSize: 18);
            Navigator.of(context).pop(newData); // Quay trở lại và gửi newData về TaskScreen
          },
          child: Container(
            alignment: Alignment.center,
            padding: EdgeInsets.all(10.0),
            child: Text(
              "Save",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );

    final _column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _txtTaskName,
        Container(

            child: Row(

              mainAxisAlignment: MainAxisAlignment.start,
              children: [_txtFinished, _cbFinished],
            )),
        Row(
          children: [Expanded(child: _btnSave),],
        )
      ],
    );
    return Container(
      margin: EdgeInsets.all(10.0),
      child: _column,
    );
  }


}
