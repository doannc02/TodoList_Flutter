import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:ui_todolist/CommonWidget/skeleton_loading.dart';
import 'package:ui_todolist/models/task.dart';
import 'TaskScreen.dart';
import 'TodosStatusFinishScreen.dart';
import 'main.dart';
import 'models/todo.dart';
import 'CommonWidget/todo_item.dart';

class Home extends StatefulWidget {


  Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with RouteAware  {
  int _currentIndex = 0;
  int countItemsStatus = 0;
  List<Todo> todos = [];
  bool showNoResults = false;
  bool showSearchBar = false;
  bool isShowContent = false;
  final _todoController = TextEditingController();
  void _refreshData() async {
    final updatedTodos = await fetchListTodos(http.Client());
    setState(() {
      todos = updatedTodos;
    });
  }
  @override
  Widget build(BuildContext context) {
      return Scaffold(
      backgroundColor:  Color(0xFFEEEFF5),
      appBar: showSearchBar == true ? searchBox() : _buildAppBar(),
      drawer: _buildDrawer(),
      body: FutureBuilder<List<Todo>>(
        future: Future.delayed(Duration(milliseconds: 500), () {
          return fetchListTodos(http.Client());
        }),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Xử lý trạng thái đang tải dữ liệu
            return  Container(
              padding: EdgeInsets.only(top:45),
              child: SkeletonLoading(
                itemCount: 8, // Số lượng skeleton loading muốn hiển thị
                itemHeight: 70, // Chiều cao của mỗi skeleton loading
                itemWidth: 200, // Chiều rộng mặc định của mỗi skeleton loading
                itemMargin: EdgeInsets.symmetric(vertical: 8, horizontal: 16), // Khoảng cách giữa các skeleton loading
              ),
            );
          } else if (snapshot.hasError) {
            // Xử lý trường hợp lỗi
            print(snapshot);
            return Text('Error: ${snapshot}');
          } else if (!snapshot.hasData) {
            // Xử lý trường hợp không có dữ liệu
            return Text('Không có todo nào.');
          } else {
            if(todos.length == 0){
              todos = snapshot.data ?? [];
            }else
              print(todos.length);
            return Scaffold(
              backgroundColor: Color(0xFFEEEFF5),
              body: Column(
                children: [
                  Container(
                    color: Colors.deepPurple[300],
                    child: SizedBox(
                      height: 8,
                    ),
                  ),
                  Expanded(
                    child: isShowContent == true ? Text("Nhập từ khóa tìm kiếm") : showNoResults == true ? Text("Không tìm thấy item nào") : SingleChildScrollView(
                      child: Column(
                        children: [
                          for (Todo todoo in todos)
                            ToDoItem(
                              todo: todoo,
                              Priority: todoo.priority,
                              onToDoChanged: _handleToDoChange,
                              onDeleteItem: _deleteToDoItem,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: _currentIndex,
                items: [
                  BottomNavigationBarItem(
                    tooltip: "Item đã hoàn thành",
                    icon: Icon(Icons.star, color: Colors.yellow),
                      label: "Xem các công việc chưa hoàn thành"

                  ),
                  BottomNavigationBarItem(
                    tooltip: "Item chưa hoàn thành",
                    icon: Icon(Icons.star_border_outlined, color: Colors.black),
                      label: "Xem các công việc đã hoàn thành"
                  ),
                ],
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });

                  // Chuyển hướng sang trang TodosStatusFinishScreen khi người dùng nhấn vào các nút
                  if (_currentIndex == 0) {
                    _fetchTodosFinished(false);
                  } else if (_currentIndex == 1) {
                    _fetchTodosFinished(true);
                  }
                },
              ),
            );
          }
        },
      ),

    );
  }

  void _fetchTodosFinished(bool isFinished)async{
    if(isFinished){
      var res = await fetchTodoFinished(http.Client());
      setState(() {
        todos = res.todos;
      });
    }else {
     var res = await fetchTodoUnFinished(http.Client());
    setState(() {
      todos = res.todos;
    });
    }
  }

  void _showAddTodoModal(BuildContext context) {
    DateTime? selectedDate;
  String todoText = '';
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 1.0), // Đặt border
                borderRadius: BorderRadius.circular(10.0), // Điều chỉnh góc bo tròn
              ),
              width: double.infinity,
              height: 200,
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Add a new todo item', style: TextStyle(fontSize: 20)),
                  TextField(
                    onChanged:(value) {
                      setState(){
                        todoText = value;
                      };
                    },
                    controller: _todoController,
                    decoration: InputDecoration(hintText: 'Name item...'),
                  ),
                  Row(
                    children: [
                      Expanded( // Sử dụng Expanded để mở rộng ngang
                        child: Text(
                          selectedDate != null
                              ? DateFormat.yMMMd().format(selectedDate!)
                              : 'Select a deadline',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.date_range),
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2101),
                          );
                          if (picked != null) {
                            setState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                     Expanded(child:

                     ElevatedButton(
                       style: ElevatedButton.styleFrom(
                         primary: Colors.red,
                         padding: EdgeInsets.all(10),
                         shape: RoundedRectangleBorder(
                           borderRadius: BorderRadius.circular(20),
                         ),
                       ),
                       onPressed: () {
                         Navigator.pop(context);
                       },
                       child: Text(
                         'Hủy',
                         style: TextStyle(
                           fontSize: 16,
                           color: Colors.white,
                         ),
                       ),
                     ),
                      ),
                      Expanded(child:
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          primary: Colors.deepPurple,
                          padding: EdgeInsets.only(top: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () async{
                          if(_todoController.text == ""){
                            Fluttertoast.showToast(msg: "Tên item không được để trống!",
                            toastLength: Toast.LENGTH_LONG,
                            gravity: ToastGravity.TOP,
                            backgroundColor: Colors.red,
                            textColor: Colors.white,
                            timeInSecForIosWeb: 2,
                            fontSize: 18);
                          }else if(selectedDate == null){
                            Fluttertoast.showToast(msg: "Hãy chọn 1 dealine!",
                                toastLength: Toast.LENGTH_LONG,
                                gravity: ToastGravity.TOP,
                                backgroundColor: Colors.red,
                                textColor: Colors.white,
                                timeInSecForIosWeb: 2,
                                fontSize: 18);
                          }
                          else{

                            int prirority = 1;
                            DateTime currentDateTime = DateTime.parse(selectedDate.toString());
                            var date =  DateFormat('yyyy-MM-ddTHH:mm:ss').format(currentDateTime);
                            String todoText = _todoController.text;
                            Map<String, dynamic> params = {
                              'name': todoText,
                              'priority':  prirority,
                              'description': ' ',
                              'dueDate': date,
                            };
                            final response = await create(http.Client(), params);
                            if (response) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Tạo thành công item!"),
                                ),
                              );
                              _todoController.text = '';
                              selectedDate= null;
                              _refreshData();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Lỗi khi tạo item!"),
                                ),
                              );
                            }
                            Navigator.pop(context);
                          }

                        },
                        child: Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ))
                    ],

                  ),
                ],
              ),
            )
            ;
          },
        );
      },
    );
  }

  void _handleToDoChange(Todo todo) async{
    setState(() {
    //  todo.isDone = !todo.isDone;

    });
    var res = await  Navigator.push(context,
          MaterialPageRoute(builder: (context) => TaskScreen(todoId: todo.id, todoName: todo.name, priority: todo.priority,backToHomeByOption: 1,))
      ).then((_) {
        _refreshData();
      });
 print('đây này 2');
  }

  void _deleteToDoItem(int id) {
    deleteItem(http.Client(), id).then((result) {
      if (result != "") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xóa thành công'),
          ),
        );
        setState(() {
          _refreshData();
        });
      }
    });
  }

  void _addToDoItem(String toDo) {
    setState(() {

    });
    _todoController.clear();
  }

  void _runFilter(String enteredKeyword) async {
    List<Todo> results = await searchItems(http.Client(), enteredKeyword);
 print(enteredKeyword);
    isShowContent = false;
      if(results.length != 0){
        showNoResults = false;
      }else showNoResults = true;
      setState(() {
        todos = results;
      });

  }

  PreferredSizeWidget searchBox() {
    return PreferredSize(
      preferredSize: Size.fromHeight(65),
      child: SingleChildScrollView(
        child: Container(
          height: 65,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.black, // Màu của border
                width: 1.0,           // Độ dày của border
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(onPressed: ()async{
                List<Todo> results = await searchItems(http.Client(), " ");
                if(results.toList().length != 0){
                  todos=results;
                }
                setState(() {
                  isShowContent = false;
                  showSearchBar = false;
                  showNoResults = false;
                });
              }, icon: Icon(Icons.arrow_back_outlined)),
              Container(
                child: SizedBox(height: 5,),
              ),
              Container(
                height: 48,
                width: 400,
                padding: EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  onChanged: (value) {
                    _runFilter(value);
                  },
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.search,
                      color: Color(0xFF3A3A3A),
                      size: 25,
                    ),
                    prefixIconConstraints: BoxConstraints(
                      maxHeight: 55,
                      minWidth: 35,
                    ),
                    border: InputBorder.none,
                    hintText: 'Search',
                    hintStyle: TextStyle(color: Color(0xFF717171)),
                  ),
                ),
              ),
              Container(
                child: SizedBox(height: 5,),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(

      child: ListView(

        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text("Nguyễn Công Đoàn"),
            accountEmail: Text("sillver47108@gmail.com"),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Container(
                height: 50,
                width: 50,
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: Image.network(
                      "data:image/png;base64,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",
                    )
                ),
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.library_add_check_rounded),
            title: Text("Các danh mục đã hoàn thành"),
            onTap: () {
              // Xử lý khi chọn danh mục 2
            },
          ),
          ListTile(
            leading: Icon(Icons.pending_actions),
            title: Text("Các danh mục cần thực hiện"),
            onTap: () {
              // Xử lý khi chọn danh mục 2
            },
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text("Cài đặt tài khoản."),
            onTap: () {
              // Xử lý khi chọn danh mục 1
            },
          ),
          // Thêm danh sách các mục menu khác ở đây
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.deepPurple,
      elevation: 0,
      title: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
       Expanded(child:Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
         children: [
           Container(
             width: 280.0, // Độ rộng của Container.
             child: Text('Todo list: ${todos.length} items'),
           ),
           MouseRegion(
             cursor: SystemMouseCursors.click,
             child: GestureDetector(
               onTap: () {
                 _showAddTodoModal(context);
               },
               child: Container(
                 decoration: BoxDecoration(
                   borderRadius: BorderRadius.circular(70),
                   color: Colors.black26,
                 ),
                 height: 32,
                 width: 32,
                 child: ClipRRect(
                   borderRadius: BorderRadius.circular(60),
                   child: Icon(Icons.add),
                 ),
               ),
             ),
           ),
           MouseRegion(
             cursor: SystemMouseCursors.click,
             child: GestureDetector(
               onTap: () {
              setState(() {
                showSearchBar = true;
                isShowContent = true;
              });
               },
               child: Container(
                 decoration: BoxDecoration(borderRadius: BorderRadius.circular(70), color: Colors.black26),
                 height: 32,
                 width: 32,
                 child: ClipRRect(
                     borderRadius: BorderRadius.circular(60),
                     child: Icon(Icons.search_rounded)
                 ),
               ),
             ),
           ),
           // Thêm các phần tử khác theo nhu cầu của bạn.
        Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(70), color: Colors.black26),
          height: 30,
          width: 30,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(60),
            child: Image.network(
              "data:image/png;base64,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",
            )
          ),
        ),
      ]),
    )]));
  }


}